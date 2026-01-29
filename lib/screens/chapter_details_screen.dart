
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
        ..setBackgroundColor(Colors.transparent); // Make webview background transparent
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load the initial HTML content here where context is available
    if (widget.chapter.contentType == ContentType.html) {
       _webViewController.loadHtmlString(_getHtmlContent());
    }
  }

  String _getHtmlContent() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? 'white' : 'black';

    // By setting the background to transparent, the webview will show the underlying Scaffold background.
    return """
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              background-color: transparent; /* Make HTML background transparent */
              color: $textColor;
              font-family: sans-serif;
              font-size: 16px;
              margin: 0;
              padding: 0; /* Let Flutter handle the padding */
            }
          </style>
        </head>
        <body>
          ${widget.chapter.content}
        </body>
      </html>
    """;
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
      _webViewController.loadHtmlString(_getHtmlContent());
    }
    _toggleEditing();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final blockquoteColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    // Use consistent padding for all content types
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
      body: Padding(
        padding: bodyPadding,
        child: _isEditing
            ? TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your notes here...',
                  border: InputBorder.none,
                ),
              )
            : (widget.chapter.contentType == ContentType.markdown
                ? Markdown(
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
                  )
                : WebViewWidget(controller: _webViewController)),
      ),
    );
  }
}
