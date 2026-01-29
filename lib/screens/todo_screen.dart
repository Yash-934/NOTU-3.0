import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notu/models/todo.dart';
import 'package:notu/utils/database_helper.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<Todo>> _todosFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _todosFuture = dbHelper.getTodos();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _addTodo(String title) async {
    if (title.isNotEmpty) {
      await dbHelper.insertTodo(Todo(title: title, createdAt: DateTime.now()));
      setState(() {
        _todosFuture = dbHelper.getTodos();
      });
    }
  }

  void _toggleTodo(Todo todo) async {
    await dbHelper.updateTodo(Todo(id: todo.id, title: todo.title, isDone: !todo.isDone, createdAt: todo.createdAt));
    setState(() {
      _todosFuture = dbHelper.getTodos();
    });
  }

  void _deleteTodo(int id) async {
    await dbHelper.deleteTodo(id);
    setState(() {
      _todosFuture = dbHelper.getTodos();
    });
  }

  void _updateTodoTitle(Todo todo, String newTitle) async {
    if (newTitle.isNotEmpty) {
      await dbHelper.updateTodo(Todo(id: todo.id, title: newTitle, isDone: todo.isDone, createdAt: todo.createdAt));
      setState(() {
        _todosFuture = dbHelper.getTodos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-do List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Todo>>(
              future: _todosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No to-dos yet!'));
                }
                final todos = snapshot.data!.where((todo) {
                  return todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return GestureDetector(
                      onLongPress: () => _showEditDeleteDialog(todo),
                      child: ListTile(
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                            decorationColor: Colors.red,
                            decorationThickness: 2.0,
                          ),
                        ),
                        subtitle: Text(DateFormat.yMMMd().add_jm().format(todo.createdAt)),
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (value) => _toggleTodo(todo),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add To-do'),
      ),
    );
  }

  void _showAddTodoDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New To-do'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter to-do title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addTodo(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDeleteDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(todo.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTodoDialog(todo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  _deleteTodo(todo.id!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTodoDialog(Todo todo) {
    final controller = TextEditingController(text: todo.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit To-do'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter to-do title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateTodoTitle(todo, controller.text);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
