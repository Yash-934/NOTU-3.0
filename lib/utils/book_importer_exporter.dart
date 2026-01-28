import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:notu/models/book.dart';
import 'package:notu/models/chapter.dart';
import 'package:notu/utils/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class BookImporterExporter {
  final dbHelper = DatabaseHelper();

  Future<void> exportBook(Book book) async {
    final chapters = await dbHelper.getChapters(book.id!);
    final bookMap = {
      'book': book.toMap(),
      'chapters': chapters.map((c) => c.toMap()).toList(),
    };

    final jsonString = jsonEncode(bookMap);
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/${book.title}.json');
    await file.writeAsString(jsonString);
  }

  Future<void> importBook() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final bookMap = jsonDecode(jsonString);

      final book = Book.fromMap(bookMap['book']);
      final chapters = (bookMap['chapters'] as List).map((c) => Chapter.fromMap(c)).toList();

      final bookId = await dbHelper.insertBook(book);
      for (final chapter in chapters) {
        chapter.bookId = bookId;
        await dbHelper.insertChapter(chapter);
      }
    }
  }
}
