
import 'package:flutter/material.dart';
import 'package:notu/models/book.dart';
import 'package:notu/models/chapter.dart';
import 'package:notu/screens/add_chapter_screen.dart';
import 'package:notu/screens/chapter_details_screen.dart';
import 'package:notu/utils/database_helper.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final void Function(Book) onBookUpdate;
  final VoidCallback onBookDelete;

  const BookDetailsScreen({super.key, required this.book, required this.onBookUpdate, required this.onBookDelete});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Future<List<Chapter>> _chaptersFuture;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _chaptersFuture = dbHelper.getChapters(widget.book.id!);
  }

  void _addChapter(Chapter chapter) async {
    await dbHelper.insertChapter(chapter);
    setState(() {
      _chaptersFuture = dbHelper.getChapters(widget.book.id!);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter added!')),
      );
    }
  }

  void _deleteChapter(int id) async {
    await dbHelper.deleteChapter(id);
    setState(() {
      _chaptersFuture = dbHelper.getChapters(widget.book.id!);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter deleted!')),
      );
    }
  }

  void _editChapter(Chapter chapter) async {
    await dbHelper.updateChapter(chapter);
    setState(() {
      _chaptersFuture = dbHelper.getChapters(widget.book.id!);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: FutureBuilder<List<Chapter>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }
          final chapters = snapshot.data!;
          return ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return ListTile(
                title: Text(chapter.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChapterDetailsScreen(chapter: chapter, onChapterUpdate: _editChapter),
                    ),
                  );
                },
                onLongPress: () => _showChapterContextMenu(context, chapter, _getTapPosition(context)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddChapterScreen(bookId: widget.book.id!, onAddChapter: _addChapter),
            ),
          );
        },
        label: const Text('New Chapter'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Offset _getTapPosition(BuildContext context) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return overlay.localToGlobal(Offset.zero);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subtitles_off, size: 100, color: Theme.of(context).colorScheme.primary.withAlpha(128)),
          const SizedBox(height: 20),
          Text('No chapters yet', style: Theme.of(context).textTheme.headlineMedium,),
          const SizedBox(height: 10),
          Text(
            'Create a new chapter to start writing.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showChapterContextMenu(BuildContext context, Chapter chapter, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: const Text('Edit'),
          onTap: () => _showEditChapterDialog(context, chapter),
        ),
        PopupMenuItem(
          child: const Text('Delete'),
          onTap: () => _deleteChapter(chapter.id!),
        ),
      ],
    );
  }

  void _showEditChapterDialog(BuildContext context, Chapter chapter) {
    final titleController = TextEditingController(text: chapter.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Chapter'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTitle = titleController.text;
                if (newTitle.isNotEmpty) {
                  _editChapter(Chapter(id: chapter.id, bookId: chapter.bookId, title: newTitle, content: chapter.content));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
