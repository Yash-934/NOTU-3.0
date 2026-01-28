import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

      String? outputPath = await FilePicker.platform.getDirectoryPath();
      if (outputPath == null) {
        return false;
      }

      final String fileName = 'notu_backup_${DateTime.now().toIso8601String()}.json';
      final File file = File('$outputPath/$fileName');
      await file.writeAsString(jsonString);

      return true;
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

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final File file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      final List<dynamic> bookList = backupData['books'];
      final List<dynamic> chapterList = backupData['chapters'];

      await dbHelper.deleteAllBooks();
      await dbHelper.deleteAllChapters();

      for (final bookMap in bookList) {
        await dbHelper.insertBook(Book.fromMap(bookMap));
      }

      for (final chapterMap in chapterList) {
        await dbHelper.insertChapter(Chapter.fromMap(chapterMap));
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
