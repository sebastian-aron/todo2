import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure widgets are initialized
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter()); // Register the Todo adapter
  await Hive.openBox<Todo>('todos'); // Open the box
  runApp(MyApp());
}

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late bool isDone;

  Todo(this.title, {this.isDone = false});
}

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    return Todo(
      reader.readString(),
      isDone: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer.writeString(obj.title);
    writer.writeBool(obj.isDone);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final customColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.red,
      accentColor: Colors.red,
    );

    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData.from(colorScheme: customColorScheme),
      debugShowCheckedModeBanner: false, // Remove the debug banner
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(224, 213, 59, 48),
        // Setting app bar background color to red
        elevation: 4, // Adding elevation to the app bar
        title: Text(
          'To do na toh!',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color.fromARGB(223, 255, 255, 255)),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Todo>('todos').listenable(),
        builder: (context, Box<Todo> box, _) {
          if (box.isEmpty) {
            // If the todo list is empty, display an image
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://media.tenor.com/pFz1Q12_hXEAAAAM/cat-holding-head-cat.gif', // Add the URL to your empty todo image
                    width: 200,
                    height: 200,
                  ),
                  Text(
                    'Empty List',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          } else {
            // If the todo list is not empty, display the list
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final todo = box.getAt(index)!;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: todo.isDone
                        ? Color.fromARGB(224, 213, 59, 48)
                        : null, // Setting red accent color for completed todos
                  ),
                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (value) {
                        todo.isDone = value!;
                        todo.save(); // Save the updated todo
                      },
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: todo.isDone
                            ? const Color.fromARGB(255, 158, 158, 158)
                            : Colors.black,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete,
                          color: Color.fromARGB(255, 255, 255,
                              255)), // Setting delete button color to red
                      onPressed: () {
                        box.deleteAt(index);
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTodo(context);
        },
        tooltip: 'Add Todo',
        child: Icon(Icons.add),
      ),
    );
  }

  void _addTodo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _controller = TextEditingController();
        return AlertDialog(
          title: Text('Add Todo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Enter todo title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = _controller.text.trim();
                if (title.isNotEmpty) {
                  final todoBox = Hive.box<Todo>('todos');
                  todoBox.add(Todo(title));
                }
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Todo List'),
    ),
    body: ValueListenableBuilder(
      valueListenable: Hive.box<Todo>('todos').listenable(),
      builder: (context, Box<Todo> box, _) {
        return ListView.builder(
          itemCount: box.length,
          itemBuilder: (context, index) {
            final todo = box.getAt(index)!;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: todo.isDone
                    ? const Color.fromARGB(255, 141, 0, 21)
                    : null, // Setting red accent color for completed todos
              ),
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                leading: Checkbox(
                  value: todo.isDone,
                  onChanged: (value) {
                    todo.isDone = value!;
                    todo.save(); // Save the updated todo
                  },
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: todo.isDone
                        ? const Color.fromARGB(255, 158, 158, 158)
                        : Colors.black,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete,
                      color: Colors.red), // Setting delete button color to red
                  onPressed: () {
                    box.deleteAt(index);
                  },
                ),
              ),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        _addTodo(context);
      },
      tooltip: 'Add Todo',
      child: Icon(Icons.add),
    ),
  );
}

void _addTodo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController _controller = TextEditingController();
      return AlertDialog(
        title: Text('Add Todo'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Enter todo title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = _controller.text.trim();
              if (title.isNotEmpty) {
                final todoBox = Hive.box<Todo>('todos');
                todoBox.add(Todo(title));
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      );
    },
  );
}
