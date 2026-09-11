import 'package:flutter/material.dart';

import 'database.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<Map<String, dynamic>> tasks = [];

  bool isLoading = true;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // ============================================================
  // LOAD TASKS FROM DATABASE
  // ============================================================

  Future<void> loadTasks() async {
    final savedTasks = DatabaseService.getPlannerTasks();

    if (!mounted) return;

    setState(() {
      tasks = savedTasks;
      isLoading = false;
    });
  }

  // ============================================================
  // ADD TASK
  // ============================================================

  void addTask() {
    final TextEditingController subjectController = TextEditingController();

    final TextEditingController topicController = TextEditingController();

    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Study Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // SUBJECT
                    // ==================================================

                    TextField(
                      controller: subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Example: DBMS',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // TOPIC
                    // ==================================================
                    TextField(
                      controller: topicController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'Example: Normalization',
                        prefixIcon: Icon(Icons.topic),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // PRIORITY
                    // ==================================================
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          priority = value ?? 'Medium';
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ========================================================
              // BUTTONS
              // ========================================================
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Task'),

                  onPressed: () async {
                    final String subject = subjectController.text.trim();

                    final String topic = topicController.text.trim();

                    // Check empty fields
                    if (subject.isEmpty || topic.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter both subject and topic.'),
                        ),
                      );

                      return;
                    }

                    // ==================================================
                    // CLOSE DIALOG FIRST
                    // ==================================================

                    Navigator.pop(dialogContext);

                    // ==================================================
                    // SAVE TO HIVE DATABASE
                    // ==================================================

                    await DatabaseService.addPlannerTask(
                      subject: subject,
                      topic: topic,
                      priority: priority,
                    );

                    if (!mounted) return;

                    // ==================================================
                    // RELOAD FROM DATABASE
                    // ==================================================

                    await loadTasks();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Study task saved successfully! ✅'),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE TASK
  // ============================================================

  Future<void> deleteTask(int index) async {
    final dynamic key = tasks[index]['key'];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task?'),

          content: const Text(
            'Are you sure you want to delete this study task?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    // ============================================================
    // DELETE FROM DATABASE
    // ============================================================

    await DatabaseService.deletePlannerTask(key);

    if (!mounted) return;

    await loadTasks();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Task deleted.')));
  }

  // ============================================================
  // TOGGLE COMPLETED
  // ============================================================

  Future<void> toggleTask(int index) async {
    final Map<String, dynamic> task = tasks[index];

    final bool currentCompleted = task['completed'] == true;

    final bool newCompleted = !currentCompleted;

    await DatabaseService.updatePlannerTask(
      key: task['key'],
      subject: task['subject'].toString(),
      topic: task['topic'].toString(),
      priority: task['priority'].toString(),
      completed: newCompleted,
    );

    if (!mounted) return;

    await loadTasks();
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }

    try {
      final DateTime date = DateTime.parse(dateString);

      final String day = date.day.toString().padLeft(2, '0');

      final String month = date.month.toString().padLeft(2, '0');

      final String year = date.year.toString();

      final String hour = date.hour.toString().padLeft(2, '0');

      final String minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year  $hour:$minute';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;

      case 'Low':
        return Colors.green;

      case 'Medium':
      default:
        return Colors.orange;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Study Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // ==========================================================
      // ADD TASK BUTTON
      // ==========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? buildEmptyPlanner()
          : buildTaskList(),
    );
  }

  // ============================================================
  // EMPTY PLANNER
  // ============================================================

  Widget buildEmptyPlanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.calendar_month, size: 90, color: Colors.indigo),

            const SizedBox(height: 20),

            const Text(
              'No study tasks yet',

              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Create your first study task '
              'using the button below.',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: addTask,
              icon: const Icon(Icons.add),
              label: const Text('Create Study Task'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TASK LIST
  // ============================================================

  Widget buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),

      itemCount: tasks.length,

      itemBuilder: (context, index) {
        return buildTaskCard(index);
      },
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget buildTaskCard(int index) {
    final Map<String, dynamic> task = tasks[index];

    final bool completed = task['completed'] == true;

    final String subject = task['subject'].toString();

    final String topic = task['topic'].toString();

    final String priority = task['priority'].toString();

    final String createdAt = task['createdAt'].toString();

    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        // ========================================================
        // CHECKBOX
        // ========================================================
        leading: Checkbox(
          value: completed,

          onChanged: (_) {
            toggleTask(index);
          },
        ),

        // ========================================================
        // SUBJECT
        // ========================================================
        title: Text(
          subject,

          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,

            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),

        // ========================================================
        // DETAILS
        // ========================================================
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                topic,

                style: TextStyle(
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),

              const SizedBox(height: 6),

              // Priority
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: getPriorityColor(priority)),

                  const SizedBox(width: 4),

                  Text(
                    'Priority: $priority',

                    style: TextStyle(
                      color: getPriorityColor(priority),

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Created date
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),

                    const SizedBox(width: 4),

                    Text(
                      'Created: ${formatDate(createdAt)}',

                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        isThreeLine: true,

        // ========================================================
        // DELETE BUTTON
        // ========================================================
        trailing: IconButton(
          tooltip: 'Delete Task',

          icon: const Icon(Icons.delete, color: Colors.red),

          onPressed: () {
            deleteTask(index);
          },
        ),
      ),
    );
  }
}
