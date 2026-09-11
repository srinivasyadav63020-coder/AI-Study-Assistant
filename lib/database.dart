import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  // ============================================================
  // HIVE BOX NAMES
  // ============================================================

  static const String notesBoxName = 'notesBox';
  static const String plannerBoxName = 'plannerBox';
  static const String quizHistoryBoxName = 'quizHistoryBox';

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(notesBoxName)) {
      await Hive.openBox(notesBoxName);
    }

    if (!Hive.isBoxOpen(plannerBoxName)) {
      await Hive.openBox(plannerBoxName);
    }

    if (!Hive.isBoxOpen(quizHistoryBoxName)) {
      await Hive.openBox(quizHistoryBoxName);
    }
  }

  // ============================================================
  // NOTES DATABASE
  // ============================================================

  static Box get notesBox {
    return Hive.box(notesBoxName);
  }

  static Future<void> addNote({
    required String title,
    required String content,
  }) async {
    final DateTime now = DateTime.now();

    await notesBox.add({
      'title': title,
      'content': content,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getNotes() {
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < notesBox.length; i++) {
      final dynamic value = notesBox.getAt(i);

      if (value is Map) {
        result.add({
          'key': notesBox.keyAt(i),
          'title': value['title'] ?? '',
          'content': value['content'] ?? '',
          'createdAt': value['createdAt'] ?? '',
          'updatedAt': value['updatedAt'] ?? '',
        });
      }
    }

    return result;
  }

  static Future<void> updateNote({
    required dynamic key,
    required String title,
    required String content,
  }) async {
    final dynamic oldNote = notesBox.get(key);

    String createdAt = DateTime.now().toIso8601String();

    if (oldNote is Map && oldNote['createdAt'] != null) {
      createdAt = oldNote['createdAt'].toString();
    }

    await notesBox.put(key, {
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteNote(dynamic key) async {
    await notesBox.delete(key);
  }

  // ============================================================
  // PLANNER DATABASE
  // ============================================================

  static Box get plannerBox {
    return Hive.box(plannerBoxName);
  }

  static Future<void> addPlannerTask({
    required String subject,
    required String topic,
    required String priority,
  }) async {
    final DateTime now = DateTime.now();

    await plannerBox.add({
      'subject': subject,
      'topic': topic,
      'priority': priority,
      'completed': false,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getPlannerTasks() {
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < plannerBox.length; i++) {
      final dynamic value = plannerBox.getAt(i);

      if (value is Map) {
        result.add({
          'key': plannerBox.keyAt(i),
          'subject': value['subject'] ?? '',
          'topic': value['topic'] ?? '',
          'priority': value['priority'] ?? 'Medium',
          'completed': value['completed'] ?? false,
          'createdAt': value['createdAt'] ?? '',
          'updatedAt': value['updatedAt'] ?? '',
        });
      }
    }

    return result;
  }

  static Future<void> updatePlannerTask({
    required dynamic key,
    required String subject,
    required String topic,
    required String priority,
    required bool completed,
  }) async {
    final dynamic oldTask = plannerBox.get(key);

    String createdAt = DateTime.now().toIso8601String();

    if (oldTask is Map && oldTask['createdAt'] != null) {
      createdAt = oldTask['createdAt'].toString();
    }

    await plannerBox.put(key, {
      'subject': subject,
      'topic': topic,
      'priority': priority,
      'completed': completed,
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deletePlannerTask(dynamic key) async {
    await plannerBox.delete(key);
  }

  static Future<void> deleteOldPlannerTasks({int days = 90}) async {
    final DateTime limit = DateTime.now().subtract(Duration(days: days));

    final List<dynamic> keysToDelete = [];

    for (int i = 0; i < plannerBox.length; i++) {
      final dynamic key = plannerBox.keyAt(i);
      final dynamic value = plannerBox.getAt(i);

      if (value is Map) {
        final String createdAt = value['createdAt']?.toString() ?? '';

        if (createdAt.isNotEmpty) {
          try {
            final DateTime date = DateTime.parse(createdAt);

            if (date.isBefore(limit)) {
              keysToDelete.add(key);
            }
          } catch (_) {
            // Ignore invalid dates.
          }
        }
      }
    }

    for (final dynamic key in keysToDelete) {
      await plannerBox.delete(key);
    }
  }

  // ============================================================
  // QUIZ HISTORY DATABASE
  // ============================================================

  static Box get quizHistoryBox {
    return Hive.box(quizHistoryBoxName);
  }

  // ============================================================
  // SAVE QUIZ RESULT
  // ============================================================

  static Future<void> saveQuizResult({
    required String topic,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required int score,
  }) async {
    final DateTime now = DateTime.now();

    final double percentage = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions) * 100;

    await quizHistoryBox.add({
      'topic': topic,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'score': score,
      'percentage': percentage,
      'dateTime': now.toIso8601String(),
    });
  }

  // ============================================================
  // GET QUIZ HISTORY
  // NEWEST RESULT FIRST
  // ============================================================

  static List<Map<String, dynamic>> getQuizHistory() {
    final List<Map<String, dynamic>> result = [];

    // Start from the newest Hive entry.
    for (int i = quizHistoryBox.length - 1; i >= 0; i--) {
      final dynamic value = quizHistoryBox.getAt(i);

      if (value is Map) {
        result.add({
          'key': quizHistoryBox.keyAt(i),
          'topic': value['topic'] ?? '',
          'totalQuestions': value['totalQuestions'] ?? 0,
          'correctAnswers': value['correctAnswers'] ?? 0,
          'wrongAnswers': value['wrongAnswers'] ?? 0,
          'score': value['score'] ?? 0,
          'percentage': value['percentage'] ?? 0,
          'dateTime': value['dateTime'] ?? '',
        });
      }
    }

    return result;
  }

  // ============================================================
  // DELETE ONE QUIZ HISTORY
  // ============================================================

  static Future<void> deleteQuizHistory(dynamic key) async {
    await quizHistoryBox.delete(key);
  }

  // ============================================================
  // CLEAR ALL QUIZ HISTORY
  // ============================================================

  static Future<void> clearQuizHistory() async {
    await quizHistoryBox.clear();
  }

  // ============================================================
  // DELETE OLD QUIZ HISTORY
  // Optional: keeps history for a selected number of days.
  // Default = 90 days.
  // ============================================================

  static Future<void> deleteOldQuizHistory({int days = 90}) async {
    final DateTime limit = DateTime.now().subtract(Duration(days: days));

    final List<dynamic> keysToDelete = [];

    for (int i = 0; i < quizHistoryBox.length; i++) {
      final dynamic key = quizHistoryBox.keyAt(i);

      final dynamic value = quizHistoryBox.getAt(i);

      if (value is Map) {
        final String dateTime = value['dateTime']?.toString() ?? '';

        if (dateTime.isNotEmpty) {
          try {
            final DateTime date = DateTime.parse(dateTime);

            if (date.isBefore(limit)) {
              keysToDelete.add(key);
            }
          } catch (_) {
            // Ignore invalid dates.
          }
        }
      }
    }

    for (final dynamic key in keysToDelete) {
      await quizHistoryBox.delete(key);
    }
  }
}
