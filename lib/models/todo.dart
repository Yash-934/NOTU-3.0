class Todo {
  final int? id;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  Todo({this.id, required this.title, this.isDone = false, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
