import 'package:flutter/material.dart';

import 'database.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // ============================================================
  // LOAD QUIZ HISTORY
  // ============================================================

  void loadHistory() {
    setState(() {
      history = DatabaseService.getQuizHistory();
    });
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(String dateTime) {
    if (dateTime.isEmpty) {
      return 'Unknown date';
    }

    try {
      final DateTime date = DateTime.parse(dateTime);

      final String day = date.day.toString().padLeft(2, '0');

      final String month = date.month.toString().padLeft(2, '0');

      final String year = date.year.toString();

      final String hour = date.hour.toString().padLeft(2, '0');

      final String minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year  $hour:$minute';
    } catch (_) {
      return dateTime;
    }
  }

  // ============================================================
  // DELETE ONE RESULT
  // ============================================================

  Future<void> deleteResult(dynamic key) async {
    await DatabaseService.deleteQuizHistory(key);

    if (!mounted) {
      return;
    }

    loadHistory();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Quiz result deleted')));
  }

  // ============================================================
  // CLEAR ALL HISTORY
  // ============================================================

  Future<void> clearAllHistory() async {
    if (history.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear Quiz History',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete all '
            'quiz history?\n\nThis action cannot be undone.',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DatabaseService.clearQuizHistory();

    if (!mounted) {
      return;
    }

    loadHistory();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Quiz history cleared')));
  }

  // ============================================================
  // SCORE COLOR
  // ============================================================

  Color getScoreColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    }

    if (percentage >= 50) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // QUIZ HISTORY CARD
  // ============================================================

  Widget buildHistoryCard(Map<String, dynamic> result) {
    final dynamic key = result['key'];

    final String topic = result['topic']?.toString() ?? 'Quiz';

    final int totalQuestions =
        int.tryParse(result['totalQuestions']?.toString() ?? '0') ?? 0;

    final int correctAnswers =
        int.tryParse(result['correctAnswers']?.toString() ?? '0') ?? 0;

    final int wrongAnswers =
        int.tryParse(result['wrongAnswers']?.toString() ?? '0') ?? 0;

    final int score = int.tryParse(result['score']?.toString() ?? '0') ?? 0;

    final double percentage =
        double.tryParse(result['percentage']?.toString() ?? '0') ?? 0;

    final String dateTime = result['dateTime']?.toString() ?? '';

    final Color scoreColor = getScoreColor(percentage);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TOP ROW
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.quiz, color: scoreColor, size: 28),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.isEmpty ? 'Quiz' : topic,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              formatDate(dateTime),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    deleteResult(key);
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==================================================
            // SCORE
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scoreColor.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Score', style: TextStyle(color: Colors.grey)),

                      const SizedBox(height: 4),

                      Text(
                        '$score / $totalQuestions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Percentage',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ANSWER STATISTICS
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    icon: Icons.check_circle,
                    label: 'Correct',
                    value: correctAnswers.toString(),
                    color: Colors.green,
                  ),
                ),

                Expanded(
                  child: _statItem(
                    icon: Icons.cancel,
                    label: 'Wrong',
                    value: wrongAnswers.toString(),
                    color: Colors.red,
                  ),
                ),

                Expanded(
                  child: _statItem(
                    icon: Icons.quiz,
                    label: 'Questions',
                    value: totalQuestions.toString(),
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT ITEM
  // ============================================================

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 2),

        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ============================================================
  // EMPTY HISTORY
  // ============================================================

  Widget buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 60, color: Colors.indigo),
            ),

            const SizedBox(height: 25),

            const Text(
              'No Quiz History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Complete an AI quiz and your '
              'result will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.quiz),
              label: const Text('Take a Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Clear History',
              icon: const Icon(Icons.delete_sweep),
              onPressed: clearAllHistory,
            ),
        ],
      ),

      body: history.isEmpty
          ? buildEmptyHistory()
          : RefreshIndicator(
              onRefresh: () async {
                loadHistory();
              },
              child: ListView(
                padding: const EdgeInsets.all(15),
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.analytics,
                              size: 30,
                              color: Colors.indigo,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Quiz Results',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  '${history.length} quiz${history.length == 1 ? '' : 'zes'} completed',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // HISTORY LIST
                  // ==================================================
                  ...history.map((result) => buildHistoryCard(result)),
                ],
              ),
            ),
    );
  }
}
