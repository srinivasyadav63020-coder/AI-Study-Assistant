import 'dart:convert';

import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'database.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController topicController = TextEditingController();

  // ============================================================
  // AI SERVICE
  // ============================================================

  final AIService aiService = AIService();

  // ============================================================
  // QUIZ DATA
  // ============================================================

  List<Map<String, dynamic>> questions = [];

  List<int?> selectedAnswers = [];

  int currentQuestion = 0;

  int score = 0;

  bool isLoading = false;

  bool quizStarted = false;

  bool quizFinished = false;

  String difficulty = 'Medium';

  int numberOfQuestions = 5;

  String currentTopic = '';

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    topicController.dispose();
    super.dispose();
  }

  // ============================================================
  // GENERATE QUIZ
  // ============================================================

  Future<void> generateQuiz() async {
    final String topic = topicController.text.trim();

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject or topic.')),
      );

      return;
    }

    setState(() {
      isLoading = true;
      questions = [];
      selectedAnswers = [];
      currentQuestion = 0;
      score = 0;
      quizStarted = false;
      quizFinished = false;
      currentTopic = topic;
    });

    final String prompt =
        '''
Create a multiple-choice quiz for a college student.

Topic: $topic

Difficulty: $difficulty

Number of questions: $numberOfQuestions

IMPORTANT:
Return ONLY a valid JSON array.
Do not write any introduction.
Do not write any conclusion.
Do not use Markdown.
Do not use ```json.
Do not use code fences.

Use EXACTLY this JSON format:

[
  {
    "question": "Question text",
    "options": [
      "Option A",
      "Option B",
      "Option C",
      "Option D"
    ],
    "answer": 0,
    "explanation": "Short explanation"
  }
]

RULES:

1. Generate exactly $numberOfQuestions questions.

2. Every question must have exactly 4 options.

3. The answer field must contain only:
0, 1, 2, or 3.

4. 0 means Option A.
5. 1 means Option B.
6. 2 means Option C.
7. 3 means Option D.

8. Questions must be factually correct.

9. Avoid duplicate questions.

10. Questions should be suitable for college students.

11. Give a short explanation for every answer.

12. Do not put any text outside the JSON array.
''';

    try {
      final String response = await aiService.askAI(prompt);

      if (!mounted) {
        return;
      }

      final List<Map<String, dynamic>> parsedQuestions = parseQuizResponse(
        response,
      );

      if (parsedQuestions.isEmpty) {
        setState(() {
          isLoading = false;
        });

        _showError(
          'Could not create the quiz.\n'
          'The AI returned an invalid quiz format.\n'
          'Please try again.',
        );

        return;
      }

      // If AI returned more questions than requested,
      // use only the requested number.
      final List<Map<String, dynamic>> finalQuestions =
          parsedQuestions.length > numberOfQuestions
          ? parsedQuestions.sublist(0, numberOfQuestions)
          : parsedQuestions;

      setState(() {
        questions = finalQuestions;

        selectedAnswers = List<int?>.filled(finalQuestions.length, null);

        currentQuestion = 0;

        score = 0;

        isLoading = false;

        quizStarted = true;

        quizFinished = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      _showError('Quiz generation failed.\n$e');
    }
  }

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  // ============================================================
  // PARSE AI RESPONSE
  // ============================================================

  List<Map<String, dynamic>> parseQuizResponse(String response) {
    try {
      String cleaned = response.trim();

      if (cleaned.isEmpty) {
        return [];
      }

      // --------------------------------------------------------
      // Remove Markdown code fences
      // --------------------------------------------------------

      cleaned = cleaned
          .replaceAll('```json', '')
          .replaceAll('```JSON', '')
          .replaceAll('```', '')
          .trim();

      // --------------------------------------------------------
      // Find the JSON array
      // --------------------------------------------------------

      final int start = cleaned.indexOf('[');

      final int end = cleaned.lastIndexOf(']');

      if (start == -1 || end == -1 || end <= start) {
        return [];
      }

      cleaned = cleaned.substring(start, end + 1).trim();

      // --------------------------------------------------------
      // Decode JSON
      // --------------------------------------------------------

      dynamic decoded = jsonDecode(cleaned);

      // Sometimes the AI returns the JSON array as a String.
      if (decoded is String) {
        final String nested = decoded.trim();

        if (nested.startsWith('[') && nested.endsWith(']')) {
          decoded = jsonDecode(nested);
        }
      }

      if (decoded is! List) {
        return [];
      }

      final List<Map<String, dynamic>> result = [];

      // --------------------------------------------------------
      // Validate every question
      // --------------------------------------------------------

      for (final dynamic item in decoded) {
        if (item is! Map) {
          continue;
        }

        final String question = item['question']?.toString().trim() ?? '';

        final dynamic optionsData = item['options'];

        int answer = -1;

        final dynamic answerData = item['answer'];

        if (answerData is int) {
          answer = answerData;
        } else {
          answer = int.tryParse(answerData?.toString() ?? '') ?? -1;
        }

        final String explanation = item['explanation']?.toString().trim() ?? '';

        // ------------------------------------------------------
        // Validate question
        // ------------------------------------------------------

        if (question.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // Validate options
        // ------------------------------------------------------

        if (optionsData is! List) {
          continue;
        }

        if (optionsData.length != 4) {
          continue;
        }

        final List<String> options = [];

        for (final dynamic option in optionsData) {
          final String optionText = option.toString().trim();

          if (optionText.isEmpty) {
            continue;
          }

          options.add(optionText);
        }

        if (options.length != 4) {
          continue;
        }

        // ------------------------------------------------------
        // Validate answer
        // ------------------------------------------------------

        if (answer < 0 || answer > 3) {
          continue;
        }

        // ------------------------------------------------------
        // Add valid question
        // ------------------------------------------------------

        result.add({
          'question': question,
          'options': options,
          'answer': answer,
          'explanation': explanation,
        });
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // SELECT ANSWER
  // ============================================================

  void selectAnswer(int answerIndex) {
    if (quizFinished) {
      return;
    }

    setState(() {
      selectedAnswers[currentQuestion] = answerIndex;
    });
  }

  // ============================================================
  // NEXT QUESTION
  // ============================================================

  void nextQuestion() {
    if (selectedAnswers[currentQuestion] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer first.')),
      );

      return;
    }

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      finishQuiz();
    }
  }

  // ============================================================
  // PREVIOUS QUESTION
  // ============================================================

  void previousQuestion() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
      });
    }
  }

  // ============================================================
  // FINISH QUIZ
  // ============================================================

  Future<void> finishQuiz() async {
    int finalScore = 0;

    for (int i = 0; i < questions.length; i++) {
      final int? selected = selectedAnswers[i];

      final int correct = int.tryParse(questions[i]['answer'].toString()) ?? -1;

      if (selected != null && selected == correct) {
        finalScore++;
      }
    }

    setState(() {
      score = finalScore;
      quizFinished = true;
    });

    // ==========================================================
    // SAVE QUIZ RESULT TO HIVE
    // ==========================================================

    try {
      await DatabaseService.saveQuizResult(
        topic: currentTopic,
        totalQuestions: questions.length,
        correctAnswers: finalScore,
        wrongAnswers: questions.length - finalScore,
        score: finalScore,
      );
    } catch (e) {
      debugPrint('Could not save quiz result: $e');
    }
  }

  // ============================================================
  // RESTART QUIZ
  // ============================================================

  void restartQuiz() {
    setState(() {
      questions = [];
      selectedAnswers = [];
      currentQuestion = 0;
      score = 0;
      quizStarted = false;
      quizFinished = false;
      currentTopic = '';
    });

    topicController.clear();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Quiz Generator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? buildLoading()
          : quizFinished
          ? buildResultScreen()
          : quizStarted
          ? buildQuizScreen()
          : buildSetupScreen(),
    );
  }

  // ============================================================
  // SETUP SCREEN
  // ============================================================

  Widget buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.quiz, size: 70, color: Colors.indigo),

          const SizedBox(height: 15),

          const Text(
            'Create an AI Quiz',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter a topic and let AI create '
            'a quiz for your preparation.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 30),

          // ==================================================
          // TOPIC
          // ==================================================
          TextField(
            controller: topicController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Subject / Topic',
              hintText: 'Example: DBMS Normalization',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // DIFFICULTY
          // ==================================================
          const Text(
            'Difficulty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'Easy',
                  label: Text('Easy'),
                  icon: Icon(Icons.sentiment_satisfied),
                ),
                ButtonSegment<String>(
                  value: 'Medium',
                  label: Text('Medium'),
                  icon: Icon(Icons.sentiment_neutral),
                ),
                ButtonSegment<String>(
                  value: 'Hard',
                  label: Text('Hard'),
                  icon: Icon(Icons.local_fire_department),
                ),
              ],
              selected: {difficulty},
              onSelectionChanged: (Set<String> value) {
                setState(() {
                  difficulty = value.first;
                });
              },
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // NUMBER OF QUESTIONS
          // ==================================================
          const Text(
            'Number of Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 5, label: Text('5')),
                ButtonSegment<int>(value: 10, label: Text('10')),
                ButtonSegment<int>(value: 15, label: Text('15')),
              ],
              selected: {numberOfQuestions},
              onSelectionChanged: (Set<int> value) {
                setState(() {
                  numberOfQuestions = value.first;
                });
              },
            ),
          ),

          const SizedBox(height: 35),

          // ==================================================
          // GENERATE BUTTON
          // ==================================================
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : generateQuiz,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Generate Quiz',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI will create multiple-choice '
                      'questions with explanations '
                      'based on your selected topic.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),

            const SizedBox(height: 25),

            const Text(
              'Generating your quiz...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              '$difficulty • '
              '$numberOfQuestions questions',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),

            const Text(
              'AI is preparing questions for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUIZ SCREEN
  // ============================================================

  Widget buildQuizScreen() {
    final Map<String, dynamic> question = questions[currentQuestion];

    final String questionText = question['question'].toString();

    final List<dynamic> options = question['options'] as List<dynamic>;

    final int? selected = selectedAnswers[currentQuestion];

    return Column(
      children: [
        // ======================================================
        // PROGRESS
        // ======================================================

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question '
                    '${currentQuestion + 1}'
                    ' / ${questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Text(
                    difficulty,
                    style: TextStyle(
                      color: getDifficultyColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: (currentQuestion + 1) / questions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),

        // ======================================================
        // QUESTION + OPTIONS
        // ======================================================
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      questionText,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Choose your answer:',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ...List.generate(options.length, (index) {
                  final bool isSelected = selected == index;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        selectAnswer(index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.indigo
                                    : Colors.indigo.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.indigo,
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Text(
                                options[index].toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),

                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.indigo,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ======================================================
        // NAVIGATION BUTTONS
        // ======================================================
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black12)],
          ),
          child: Row(
            children: [
              if (currentQuestion > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                ),

              if (currentQuestion > 0) const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: nextQuestion,
                  icon: Icon(
                    currentQuestion == questions.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    currentQuestion == questions.length - 1
                        ? 'Finish Quiz'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULT SCREEN
  // ============================================================

  Widget buildResultScreen() {
    final int total = questions.length;

    final double percentage = total == 0 ? 0 : (score / total) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 90, color: Colors.amber),

          const SizedBox(height: 15),

          const Text(
            'Quiz Completed!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            currentTopic,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Text(
                    '$score / $total',
                    style: const TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    getResultMessage(percentage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // REVIEW
          // ==================================================
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Answer Review',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          ...List.generate(questions.length, (index) {
            return buildReviewCard(index);
          }),

          const SizedBox(height: 20),

          // ==================================================
          // NEW QUIZ
          // ==================================================
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: restartQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Create New Quiz',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  Widget buildReviewCard(int index) {
    final Map<String, dynamic> question = questions[index];

    final List<dynamic> options = question['options'] as List<dynamic>;

    final int correctAnswer = int.tryParse(question['answer'].toString()) ?? -1;

    final int? selectedAnswer = selectedAnswers[index];

    final bool correct = selectedAnswer == correctAnswer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? Colors.green : Colors.red,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    '${index + 1}. '
                    '${question['question']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Your answer: '
              '${selectedAnswer == null ? 'Not answered' : options[selectedAnswer]}',
              style: TextStyle(color: correct ? Colors.green : Colors.red),
            ),

            const SizedBox(height: 5),

            Text(
              'Correct answer: '
              '${correctAnswer >= 0 && correctAnswer < options.length ? options[correctAnswer] : 'Unavailable'}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (question['explanation'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),

              Text(
                'Explanation: '
                '${question['explanation']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULT MESSAGE
  // ============================================================

  String getResultMessage(double percentage) {
    if (percentage >= 90) {
      return 'Excellent! You have a very strong understanding. 🎉';
    }

    if (percentage >= 75) {
      return 'Great job! Keep practicing to reach an even higher score. 👏';
    }

    if (percentage >= 50) {
      return 'Good attempt. Review the incorrect answers and practice again. 💪';
    }

    return 'Keep learning! Review the topic and try another quiz. 📚';
  }

  // ============================================================
  // DIFFICULTY COLOR
  // ============================================================

  Color getDifficultyColor() {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;

      case 'Hard':
        return Colors.red;

      case 'Medium':
      default:
        return Colors.orange;
    }
  }
}
