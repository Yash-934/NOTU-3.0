
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:notu/models/book.dart';
import 'package:notu/models/chapter.dart';
import 'package:notu/utils/database_helper.dart';

class BookImporterExporter {
  final dbHelper = DatabaseHelper();

  Future<bool> exportBook(Book book) async {
    try {
      final chapters = await dbHelper.getChapters(book.id!);
      final bookMap = {
        'book': book.toMap(),
        'chapters': chapters.map((c) => c.toMap()).toList(),
      };

      final jsonString = jsonEncode(bookMap);
      final Uint8List fileBytes = Uint8List.fromList(utf8.encode(jsonString));

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: '${book.title}.json',
        bytes: fileBytes,
      );

      return outputFile != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        String jsonString;
        if (kIsWeb) {
          if (result.files.single.bytes == null) return false;
          final fileBytes = result.files.single.bytes!;
          jsonString = utf8.decode(fileBytes);
        } else {
          if (result.files.single.path == null) return false;
          final file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        }

        final bookMap = jsonDecode(jsonString);

        final newBook = Book.fromMap(bookMap['book']..remove('id'));
        final chapters = (bookMap['chapters'] as List).map((c) => Chapter.fromMap(c..remove('id'))).toList();

        final newBookId = await dbHelper.insertBook(newBook);
        for (final chapter in chapters) {
          chapter.bookId = newBookId;
          await dbHelper.insertChapter(chapter);
        }

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
