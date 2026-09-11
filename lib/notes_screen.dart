import 'package:flutter/material.dart';

import 'database.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> filteredNotes = [];

  final TextEditingController titleController = TextEditingController();

  final TextEditingController contentController = TextEditingController();

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadNotes();

    searchController.addListener(searchNotes);
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================

  void loadNotes() {
    final loadedNotes = DatabaseService.getNotes();

    setState(() {
      notes = loadedNotes;
      filteredNotes = loadedNotes;
    });
  }

  // ============================================================
  // SEARCH NOTES
  // ============================================================

  void searchNotes() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredNotes = notes;
      } else {
        filteredNotes = notes.where((note) {
          final title = note['title'].toString().toLowerCase();

          final content = note['content'].toString().toLowerCase();

          return title.contains(query) || content.contains(query);
        }).toList();
      }
    });
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);

      final day = date.day.toString().padLeft(2, '0');

      final month = date.month.toString().padLeft(2, '0');

      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');

      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year  $hour:$minute';
    } catch (_) {
      return 'Unknown date';
    }
  }

  // ============================================================
  // ADD NOTE
  // ============================================================

  void addNote() {
    titleController.clear();
    contentController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add New Note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Note Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: contentController,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Note Content',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();

                final content = contentController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter title and content.'),
                    ),
                  );

                  return;
                }

                await DatabaseService.addNote(title: title, content: content);

                loadNotes();

                if (context.mounted) {
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

  // ============================================================
  // VIEW NOTE
  // ============================================================

  void viewNote(int index) {
    final note = filteredNotes[index];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            note['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['content'],
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),

                const SizedBox(height: 20),

                const Divider(),

                const SizedBox(height: 8),

                Text(
                  'Created: ${formatDate(note['createdAt'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 5),

                Text(
                  'Updated: ${formatDate(note['updatedAt'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EDIT NOTE
  // ============================================================

  void editNote(int index) {
    final note = filteredNotes[index];

    titleController.text = note['title'];
    contentController.text = note['content'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Note Title',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: contentController,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Note Content',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();

                final content = contentController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  return;
                }

                await DatabaseService.updateNote(
                  key: note['key'],
                  title: title,
                  content: content,
                );

                loadNotes();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE NOTE
  // ============================================================

  void deleteNote(int index) async {
    final note = filteredNotes[index];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note?'),

          content: Text('Delete "${note['title']}"?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await DatabaseService.deleteNote(note['key']);

      loadNotes();
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
          'My Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ======================================================
          // SEARCH BAR
          // ======================================================

          Padding(
            padding: const EdgeInsets.all(15),

            child: TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: 'Search notes...',

                prefixIcon: const Icon(Icons.search),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ======================================================
          // NOTES LIST
          // ======================================================
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        const Icon(
                          Icons.note_alt_outlined,
                          size: 75,
                          color: Colors.grey,
                        ),

                        const SizedBox(height: 15),

                        Text(
                          notes.isEmpty ? 'No notes yet' : 'No matching notes',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          notes.isEmpty
                              ? 'Tap + to create your first note.'
                              : 'Try another search.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),

                    itemCount: filteredNotes.length,

                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];

                      return Card(
                        elevation: 2,

                        margin: const EdgeInsets.only(bottom: 12),

                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),

                          leading: const CircleAvatar(child: Icon(Icons.note)),

                          title: Text(
                            note['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const SizedBox(height: 5),

                              Text(
                                note['content'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 7),

                              Text(
                                'Updated: ${formatDate(note['updatedAt'])}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          onTap: () {
                            viewNote(index);
                          },

                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                editNote(index);
                              }

                              if (value == 'delete') {
                                deleteNote(index);
                              }
                            },

                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',

                                child: Row(
                                  children: [
                                    Icon(Icons.edit),

                                    SizedBox(width: 10),

                                    Text('Edit'),
                                  ],
                                ),
                              ),

                              const PopupMenuItem(
                                value: 'delete',

                                child: Row(
                                  children: [
                                    Icon(Icons.delete),

                                    SizedBox(width: 10),

                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ========================================================
      // ADD NOTE BUTTON
      // ========================================================
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,

        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    searchController.dispose();

    super.dispose();
  }
}
