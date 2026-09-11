import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _controller = TextEditingController();

  final AIService _aiService = AIService();

  // ============================================================
  // CHAT MESSAGES
  // ============================================================

  final List<Map<String, String>> messages = [
    {
      'sender': 'ai',
      'message':
          'Hello! 👋 I am your AI Study Assistant.\n\n'
          'Ask me anything about your studies, '
          'programming, exams, websites and more.',
    },
  ];

  bool isLoading = false;

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    final String question = _controller.text.trim();

    if (question.isEmpty || isLoading) {
      return;
    }

    setState(() {
      messages.add({'sender': 'user', 'message': question});

      isLoading = true;
    });

    _controller.clear();

    try {
      final String answer = await _aiService.askAI(question);

      if (!mounted) return;

      setState(() {
        messages.add({'sender': 'ai', 'message': answer});

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'sender': 'ai',
          'message':
              'Sorry, I could not connect to the AI.\n\n'
              'Error: $e',
        });

        isLoading = false;
      });
    }
  }

  // ============================================================
  // COPY ANSWER
  // ============================================================

  Future<void> copyAnswer(String answer) async {
    await Clipboard.setData(ClipboardData(text: answer));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer copied successfully! 📋'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // VERIFIED OFFICIAL WEBSITES
  // ============================================================

  String? getVerifiedWebsite(String text) {
    final String lower = text.toLowerCase();

    // RRB Chandigarh
    if (lower.contains('rrbcdg.gov.in')) {
      return 'https://www.rrbcdg.gov.in/';
    }

    // Python
    if (lower.contains('python.org')) {
      return 'https://www.python.org/';
    }

    // Flutter
    if (lower.contains('flutter.dev')) {
      return 'https://flutter.dev/';
    }

    // Dart
    if (lower.contains('dart.dev')) {
      return 'https://dart.dev/';
    }

    // GitHub
    if (lower.contains('github.com')) {
      return 'https://github.com/';
    }

    // MDN
    if (lower.contains('developer.mozilla.org')) {
      return 'https://developer.mozilla.org/';
    }

    // Java
    if (lower.contains('java.com')) {
      return 'https://www.java.com/';
    }

    // Oracle
    if (lower.contains('oracle.com')) {
      return 'https://www.oracle.com/';
    }

    // Stack Overflow
    if (lower.contains('stackoverflow.com')) {
      return 'https://stackoverflow.com/';
    }

    // W3C
    if (lower.contains('w3.org')) {
      return 'https://www.w3.org/';
    }

    return null;
  }

  // ============================================================
  // CLEAN URL
  // ============================================================

  String cleanUrl(String url) {
    String result = url.trim();

    // Remove Markdown characters.
    result = result
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('*', '')
        .replaceAll('"', '')
        .replaceAll("'", '');

    // Remove punctuation accidentally attached to URL.
    while (result.endsWith('.') ||
        result.endsWith(',') ||
        result.endsWith(';') ||
        result.endsWith(':')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  // ============================================================
  // OPEN WEBSITE
  // ============================================================

  Future<void> openWebsite(String url) async {
    try {
      String cleanedUrl = cleanUrl(url);

      // Check known official websites.
      final String? verifiedUrl = getVerifiedWebsite(cleanedUrl);

      if (verifiedUrl != null) {
        cleanedUrl = verifiedUrl;
      }

      final Uri uri = Uri.parse(cleanedUrl);

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        throw Exception('Invalid URL scheme');
      }

      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the website.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This website link is invalid.')),
      );
    }
  }

  // ============================================================
  // BUILD MESSAGE
  // ============================================================

  Widget buildMessage(String text, bool isUser) {
    final RegExp urlRegex = RegExp(
      r'https?://[^\s<>\[\]]+',
      caseSensitive: false,
    );

    final Iterable<RegExpMatch> matches = urlRegex.allMatches(text);

    // ==========================================================
    // NO URL
    // ==========================================================

    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isUser ? Colors.white : Colors.black87,
        ),
      );
    }

    // ==========================================================
    // URL FOUND
    // ==========================================================

    final List<InlineSpan> spans = [];

    int currentIndex = 0;

    for (final match in matches) {
      // Text before URL.
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      String url = match.group(0)!;

      url = cleanUrl(url);

      final String? verifiedUrl = getVerifiedWebsite(url);

      final String finalUrl = verifiedUrl ?? url;

      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.indigo,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              openWebsite(finalUrl);
            },
        ),
      );

      currentIndex = match.end;
    }

    // Text after URL.
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isUser ? Colors.white : Colors.black87,
        ),
        children: spans,
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
          'AI Tutor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ======================================================
          // CHAT
          // ======================================================

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                final bool isUser = message['sender'] == 'user';

                final String messageText = message['message'] ?? '';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),

                    padding: const EdgeInsets.all(15),

                    constraints: const BoxConstraints(maxWidth: 700),

                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo : Colors.grey.shade200,

                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // AI / USER MESSAGE
                        buildMessage(messageText, isUser),

                        // COPY BUTTON
                        if (!isUser) ...[
                          const SizedBox(height: 10),

                          const Divider(),

                          const SizedBox(height: 4),

                          OutlinedButton.icon(
                            onPressed: () {
                              copyAnswer(messageText);
                            },

                            icon: const Icon(Icons.copy, size: 18),

                            label: const Text('Copy Answer'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ======================================================
          // LOADING
          // ======================================================
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 8),

              child: Align(
                alignment: Alignment.centerLeft,

                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),

                    SizedBox(width: 10),

                    Text(
                      'AI is thinking...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // INPUT
          // ======================================================
          Container(
            padding: const EdgeInsets.all(10),

            decoration: const BoxDecoration(color: Colors.white),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,

                    enabled: !isLoading,

                    textInputAction: TextInputAction.send,

                    decoration: InputDecoration(
                      hintText: 'Ask something...',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),

                    onSubmitted: (_) {
                      sendMessage();
                    },
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(
                  backgroundColor: Colors.indigo,

                  child: IconButton(
                    onPressed: isLoading ? null : sendMessage,

                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
