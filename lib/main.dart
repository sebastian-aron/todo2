import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  await Hive.openBox<Todo>('todos');
  runApp(MyApp());
}

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late bool isDone;

  @HiveField(2)
  DateTime? dueDateTime;

  @HiveField(3)
  String content = '';

  @HiveField(4)
  bool isUrgent = false;

  @HiveField(5)
  DateTime? startTime; // Added startTime field

  @HiveField(6)
  DateTime? endTime; // Added endTime field

  Todo(this.title, {
    this.isDone = false,
    this.dueDateTime,
    this.content = '',
    this.isUrgent = false,
    this.startTime,
    this.endTime,
  });
}

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    final title = reader.readString();
    final isDone = reader.readBool();
    final hasDueDateTime = reader.readBool();
    DateTime? dueDateTime;
    if (hasDueDateTime) {
      dueDateTime = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    }
    final content = reader.readString();
    final isUrgent = reader.readBool();
    DateTime? startTime = reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null; // Added reading startTime
    DateTime? endTime = reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null; // Added reading endTime

    return Todo(
      title,
      isDone: isDone,
      dueDateTime: dueDateTime,
      content: content,
      isUrgent: isUrgent,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer.writeString(obj.title);
    writer.writeBool(obj.isDone);
    final hasDueDateTime = obj.dueDateTime != null;
    writer.writeBool(hasDueDateTime);
    if (hasDueDateTime) {
      writer.writeInt(obj.dueDateTime!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.content);
    writer.writeBool(obj.isUrgent);
    writer.writeBool(obj.startTime != null); // Added writing startTime flag
    if (obj.startTime != null) {
      writer.writeInt(obj.startTime!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.endTime != null); // Added writing endTime flag
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
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
      debugShowCheckedModeBanner: false,
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 88, 143),
        title: Row(
          children: [
            Text(
              'To do List',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  // Handle new date if needed
                }
              },
              child: Row(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 16),
                  ),
                  Icon(
                    Icons.date_range,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue,
              Colors.deepPurple,
            ],
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Todo>('todos').listenable(),
          builder: (context, Box<Todo> box, _) {
            if (box.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://media.tenor.com/gjTjxUCoP3sAAAAj/jumping-gatito.gif',
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
              return ListView.builder(
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final todo = box.getAt(index)!;
                  return Card(
                    margin: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    color: todo.isUrgent ? Colors.lightBlue[100] : Colors.white,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      leading: Checkbox(
                        value: todo.isDone,
                        onChanged: todo.isDone
                            ? null
                            : (value) async {
                          if (value == true) {
                            // Show confirmation dialog before marking as done
                            bool confirm = await _showConfirmationDialog(context);
                            if (confirm) {
                              todo.isDone = value!;
                              todo.save();
                            }
                          }
                        },
                      ),
                      title: GestureDetector(
                        onTap: () {
                          _showTodoDetailsReadonly(context, todo);
                        },
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: todo.isDone ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          bool confirmDelete = await _showDeleteConfirmationDialog(context);
                          if (confirmDelete) {
                            box.deleteAt(index);
                          }
                        },
                      ),

                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTodoDialog(context);
        },
        tooltip: 'Add Todo',
        child: Icon(Icons.add),
      ),
    );
  }

  void _addTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;
    bool isUrgent = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Todo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter Title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          hintText: 'Enter Content',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CheckboxListTile(
                        title: Text('Urgent'),
                        value: isUrgent,
                        onChanged: (bool? newValue) {
                          setState(() {
                            isUrgent = newValue!;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          selectedDate != null
                              ? 'Due Date: ${DateFormat.yMd().format(selectedDate!)}'
                              : 'Set Due Date',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        onPressed: () async {
                          final pickedStartTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedStartTime != null) {
                            setState(() {
                              selectedStartTime = pickedStartTime;
                            });
                          }
                        },
                        child: Text(
                          selectedStartTime != null
                              ? 'Start Time: ${selectedStartTime!.format(context)}'
                              : 'Set Start Time',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        onPressed: () async {
                          final pickedEndTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedEndTime != null) {
                            setState(() {
                              selectedEndTime = pickedEndTime;
                            });
                          }
                        },
                        child: Text(
                          selectedEndTime != null
                              ? 'End Time: ${selectedEndTime!.format(context)}'
                              : 'Set End Time',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) { // Check if title is not empty
                      final newTodo = Todo(
                        titleController.text,
                        content: contentController.text,
                        isUrgent: isUrgent,
                        dueDateTime: selectedDate,
                        startTime: selectedStartTime != null
                            ? DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          selectedStartTime!.hour,
                          selectedStartTime!.minute,
                        )
                            : null,
                        endTime: selectedEndTime != null
                            ? DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          selectedEndTime!.hour,
                          selectedEndTime!.minute,
                        )
                            : null,
                      );

                      Hive.box<Todo>('todos').add(newTodo);
                      Navigator.of(context).pop();
                    } else {
                      // Show error message or handle empty title case
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a title.'),
                        ),
                      );
                    }
                  },
                  child: Text('Add Todo'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _showTodoDetailsReadonly(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(todo.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add padding below the content
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('${todo.content}'),
                ),
                if (todo.dueDateTime != null)
                  Text('Due Date: ${DateFormat.yMd().format(todo.dueDateTime!)}'),
                if (todo.startTime != null)
                  Text('Start Time: ${DateFormat.jm().format(todo.startTime!)}'),
                if (todo.endTime != null)
                  Text('End Time: ${DateFormat.jm().format(todo.endTime!)}'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


  Future<bool> _showConfirmationDialog(BuildContext context) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to mark this todo as done?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                confirm = true;
                Navigator.of(context).pop();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
    return confirm;
  }
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    bool confirmDelete = false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this todo?'),
          actions: [
            TextButton(
              onPressed: () {
                confirmDelete = false;
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                confirmDelete = true;
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
    return confirmDelete;
  }

}
