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

  Todo(this.title, {this.isDone = false, this.dueDateTime, this.content = ''});
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

    return Todo(
      title,
      isDone: isDone,
      dueDateTime: dueDateTime,
      content: content,
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
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final customColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.lightBlue,
      accentColor: Colors.purple,
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
            colors: [Colors.lightBlue, Colors.deepPurple], // Your gradient colors here
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
                      'https://media.tenor.com/pFz1Q12_hXEAAAAM/cat-holding-head-cat.gif',
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
                    margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      leading: Checkbox(
                        value: todo.isDone,
                        onChanged: todo.isDone
                            ? null // Disable unchecking if task is already marked as done
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
                            decoration: todo.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                            color: todo.isDone ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
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
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTodoDialog(context);
        },
        tooltip: 'Add To do',
        child: Icon(Icons.add),
      ),
    );
  }

  void _addTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add To do'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: 'Enter Title'),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(hintText: 'Enter Description'),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() => selectedDate = pickedDate);
                          }
                        },
                        child: Text('Select Date'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() => selectedTime = pickedTime);
                          }
                        },
                        child: Text('Select Time'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (selectedDate != null && selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                          ),
                          Text(
                            'Time: ${selectedTime!.format(context)}',
                          ),
                        ],
                      ),
                    ),
                ],
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
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isNotEmpty) {
                      DateTime? dueDateTime;
                      if (selectedDate != null && selectedTime != null) {
                        dueDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                      }

                      final todoBox = Hive.box<Todo>('todos');
                      final newTodo = Todo(
                        title,
                        isDone: false,
                        dueDateTime: dueDateTime,
                        content: content,
                      );
                      todoBox.add(newTodo);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add'),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(todo.content),
              SizedBox(height: 16),
              if (todo.dueDateTime != null)
                Text(
                  'Due date: ${DateFormat('yyyy-MM-dd HH:mm').format(todo.dueDateTime!)}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to mark this task as done?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('No'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
