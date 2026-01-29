
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:notu/models/book.dart';
import 'package:notu/models/chapter.dart';
import 'package:notu/utils/database_helper.dart';

class BackupService {
  final dbHelper = DatabaseHelper();

  Future<bool> backupData() async {
    try {
      final books = await dbHelper.getBooks();
      final chapters = await dbHelper.getAllChapters();

      if (books.isEmpty && chapters.isEmpty) {
        return false;
      }

      final Map<String, dynamic> backupData = {
        'books': books.map((book) => book.toMap()).toList(),
        'chapters': chapters.map((chapter) => chapter.toMap()).toList(),
      };

      final String jsonString = jsonEncode(backupData);
      final Uint8List fileBytes = Uint8List.fromList(utf8.encode(jsonString));

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'notu_backup_${DateTime.now().toIso8601String()}.json',
        bytes: fileBytes,
      );

      return outputFile != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreData() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        return false;
      }

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

      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      final List<dynamic> bookList = backupData['books'];
      final List<dynamic> chapterList = backupData['chapters'];

      await dbHelper.deleteAllBooks();
      await dbHelper.deleteAllChapters();

      final Map<int, int> oldToNewBookIds = {};

      for (final bookMap in bookList) {
        final oldBookId = bookMap['id'];
        final newBook = Book.fromMap(bookMap..remove('id'));
        final newBookId = await dbHelper.insertBook(newBook);
        oldToNewBookIds[oldBookId] = newBookId;
      }

      for (final chapterMap in chapterList) {
        final oldBookId = chapterMap['bookId'];
        final newBookId = oldToNewBookIds[oldBookId];
        if (newBookId != null) {
          final newChapter = Chapter.fromMap(chapterMap..remove('id'))..bookId = newBookId;
          await dbHelper.insertChapter(newChapter);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
