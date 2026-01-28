
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notu/screens/settings_screen.dart';
import 'package:notu/screens/todo_screen.dart';
import 'package:notu/utils/book_importer_exporter.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'package:notu/models/book.dart';
import 'package:notu/screens/add_book_screen.dart';
import 'package:notu/screens/book_details_screen.dart';
import 'package:notu/utils/database_helper.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const NOTU(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class NOTU extends StatelessWidget {
  const NOTU({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.teal;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
      bodyMedium: GoogleFonts.openSans(fontSize: 14, fontStyle: FontStyle.italic),
      labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: primarySeedColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
      ),
    );

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: darkColorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.secondary,
        foregroundColor: darkColorScheme.onSecondary,
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'NOTU',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Book>> _booksFuture;
  final dbHelper = DatabaseHelper();
  final bookImporterExporter = BookImporterExporter();

  @override
  void initState() {
    super.initState();
    _booksFuture = dbHelper.getBooks();
  }

  void _addBook(Book book) {
    dbHelper.insertBook(book).then((_) {
      setState(() {
        _booksFuture = dbHelper.getBooks();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added!')),
        );
      }
    });
  }

  void _deleteBook(int id) {
    dbHelper.deleteBook(id).then((_) {
      setState(() {
        _booksFuture = dbHelper.getBooks();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted!')),
        );
      }
    });
  }

  void _editBook(Book book) {
    dbHelper.updateBook(book).then((_) {
      setState(() {
        _booksFuture = dbHelper.getBooks();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book updated!')),
        );
      }
    });
  }

  void _importBook() async {
    final success = await bookImporterExporter.importBook();
    if (success) {
      setState(() {
        _booksFuture = dbHelper.getBooks();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book imported!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import failed.')),
        );
      }
    }
  }

  void _exportBook(Book book) async {
    final success = await bookImporterExporter.exportBook(book);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Book exported!' : 'Export failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('NOTU', style: Theme.of(context).appBarTheme.titleTextStyle,),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_box_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TodoScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withAlpha(150),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Book>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }
            final books = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return GestureDetector(
                  onLongPressStart: (details) => _showBookContextMenu(context, book, details.globalPosition),
                  child: OpenContainer(
                      transitionType: ContainerTransitionType.fade,
                      transitionDuration: const Duration(milliseconds: 500),
                      closedElevation: 5,
                      closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      closedBuilder: (BuildContext context, void Function() action) {
                        return GridTile(
                          footer: GridTileBar(
                            backgroundColor: Colors.black45,
                            title: Text(book.title, style: const TextStyle(color: Colors.white),),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: book.thumbnail != null
                                ? Image.file(File(book.thumbnail!), fit: BoxFit.cover)
                                : Container(color: Colors.grey[300]),
                          ),
                        );
                      },
                      openBuilder: (BuildContext context, void Function() action) {
                        return BookDetailsScreen(
                          book: book,
                          onBookUpdate: _editBook,
                          onBookDelete: () => _deleteBook(book.id!),
                        );
                      }),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AddBookScreen(onAddBook: _addBook);
              },
            ),
          );
        },
        label: const Text('New Book'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 100, color: Theme.of(context).colorScheme.primary.withAlpha(128)),
          const SizedBox(height: 20),
          Text('No books yet', style: Theme.of(context).textTheme.headlineMedium,),
          const SizedBox(height: 10),
          Text(
            'Create a new book to start your collection.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleContextMenuSelection(String value, Book book) {
    switch (value) {
      case 'edit':
        _showEditBookDialog(context, book);
        break;
      case 'delete':
        _deleteBook(book.id!);
        break;
      case 'export':
        _exportBook(book);
        break;
      case 'import':
        _importBook();
        break;
    }
  }

  void _showBookContextMenu(BuildContext context, Book book, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'export',
          child: Text('Export'),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Text('Import'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuSelection(value, book);
      }
    });
  }

  void _showEditBookDialog(BuildContext context, Book book) {
    final titleController = TextEditingController(text: book.title);
    String? thumbnailPath = book.thumbnail;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Book'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (thumbnailPath != null)
                    Image.file(
                      File(thumbnailPath!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          thumbnailPath = pickedFile.path;
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Change Thumbnail'),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                ],
              );
            },
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
                  _editBook(Book(id: book.id, title: newTitle, thumbnail: thumbnailPath));
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
