
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:notu/models/chapter.dart';
import 'package:notu/utils/database_helper.dart';
import 'package:notu/utils/pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webview_flutter/webview_flutter.dart';

class ChapterDetailsScreen extends StatefulWidget {
  final Chapter chapter;
  final Function(Chapter) onChapterUpdate;

  const ChapterDetailsScreen({super.key, required this.chapter, required this.onChapterUpdate});

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen> {
  bool _isEditing = false;
  late TextEditingController _contentController;
  final dbHelper = DatabaseHelper();
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.chapter.content);
    if (widget.chapter.contentType == ContentType.html) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.chapter.contentType == ContentType.html && !_isEditing) {
      _loadThemedHtml(widget.chapter.content);
    }
  }

  void _loadThemedHtml(String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String themedContent = content;

    if (isDarkMode) {
      const String style = '''
      <style>
        body, h1, h2, h3, h4, h5, h6, p, li, blockquote, b, strong, i, em {
          color: white !important;
        }
      </style>
      ''';

      final headTag = RegExp(r'<head>', caseSensitive: false);
      if (themedContent.contains(headTag)) {
        themedContent = themedContent.replaceFirst(headTag, '<head>$style');
      } else {
        themedContent = style + themedContent;
      }
    }
    _webViewController.loadHtmlString(themedContent);
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChapter() async {
    final updatedChapter = Chapter(
      id: widget.chapter.id,
      bookId: widget.chapter.bookId,
      title: widget.chapter.title,
      content: _contentController.text,
      contentType: widget.chapter.contentType,
    );
    await dbHelper.updateChapter(updatedChapter);
    widget.onChapterUpdate(updatedChapter);
    if (widget.chapter.contentType == ContentType.html) {
      _loadThemedHtml(_contentController.text);
    }
    _toggleEditing();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final blockquoteColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final bodyPadding = const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveChapter : _toggleEditing,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'pdf') {
                PdfGenerator.generate(widget.chapter.title, _contentController.text);
              } else if (value == 'print') {
                final doc = pw.Document();
                doc.addPage(pw.Page(
                    pageFormat: PdfPageFormat.a4,
                    build: (pw.Context context) {
                      return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(widget.chapter.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 16),
                            pw.Text(_contentController.text),
                          ]);
                    }));
                await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => doc.save());
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Text('Save as PDF'),
              ),
              const PopupMenuItem<String>(
                value: 'print',
                child: Text('Print'),
              ),
            ],
          ),
        ],
      ),
      body: _isEditing
          ? Padding(
              padding: bodyPadding,
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your notes here...',
                  border: InputBorder.none,
                ),
              ),
            )
          : (widget.chapter.contentType == ContentType.markdown
              ? Padding(
                  padding: bodyPadding,
                  child: Markdown(
                    data: _contentController.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                      h1: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                      h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                      blockquoteDecoration: BoxDecoration(
                        color: blockquoteColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              : WebViewWidget(controller: _webViewController)),
    );
  }
}
