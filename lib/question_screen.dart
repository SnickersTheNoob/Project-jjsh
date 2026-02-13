import 'package:flutter/material.dart';

class QuestionScreen extends StatefulWidget {
  final String name;
  const QuestionScreen({Key? key, required this.name}) : super(key: key);

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final List<String> _questions = [
    "Do you love surprises? 💖",
    "Do you enjoy confetti parties? 🎉",
    "Do you believe in love at first sight? 💘",
    "Will you be my Valentine? 🌹",
  ];

  final TextEditingController _answerController = TextEditingController();
  final Map<int, String> _answers = {};

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  // Simple sentiment helpers using word boundaries to avoid false matches.
  bool _isPositive(String text) {
    final lower = text.toLowerCase();
    final positivePattern = RegExp(r"\b(yes|yep|yeah|sure|of course|definitely|absolutely|i do|i will)\b");
    return positivePattern.hasMatch(lower);
  }

  bool _isNegative(String text) {
    final lower = text.toLowerCase();
    final negativePattern = RegExp(r"\b(no|nah|nope|not really|i don't|i do not|i won't)\b");
    return negativePattern.hasMatch(lower);
  }

  Future<void> _openAnswerSheet(BuildContext context, int index) async {
    _answerController.text = ''; // start fresh for each question

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _questions[index],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.pink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Type your answer (or write 'Yes' / 'No')",
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Quick Yes
                        Navigator.of(ctx).pop('Yes');
                      },
                      child: const Text("Yes 💖"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Quick No
                        Navigator.of(ctx).pop('No');
                      },
                      child: const Text("No 💔"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _answerController.text.trim();
                  if (text.isEmpty) {
                    // if empty, treat as no answer and ask to confirm
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text("Please type an answer or use Yes/No buttons")),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop(text);
                },
                child: const Text("Submit Custom Answer"),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    final answer = (result ?? '').trim();
    if (answer.isEmpty) return;

    await _showReplyForAnswer(index, answer);
  }

  Future<void> _showReplyForAnswer(int index, String answer) async {
    final question = _questions[index];
    final isPos = _isPositive(answer);
    final isNeg = _isNegative(answer);

    // Save the answer
    _answers[index] = answer;

    String title;
    String body;

    if (isPos && !isNeg) {
      title = "Yay! 💖";
      body = "You answered \"$answer\" to:\n\n\"$question\"\n\nWe're so happy!";
    } else if (isNeg && !isPos) {
      title = "Oh... 💔";
      body = "You answered \"$answer\" to:\n\n\"$question\"\n\nThat's sad, but thank you for being honest.";
    } else {
      title = "Thanks!";
      body = "You answered \"$answer\" to:\n\n\"$question\"\n\nThanks for sharing — that means a lot.";
    }

    // Show reply dialog
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _proceedAfterAnswer(index, isPos, isNeg, answer);
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void _proceedAfterAnswer(int index, bool isPos, bool isNeg, String answer) {
    final lastIndex = _questions.length - 1;

    // If final question -> go to maze (positive/neutral) or abort (negative)
    if (index == lastIndex) {
      if (isNeg && !isPos) {
        Navigator.pushNamed(context, '/abort');
        return;
      }
      // go to maze next; maze will lead to success when finished
      Navigator.pushNamed(context, '/maze', arguments: {'name': widget.name});
      return;
    }

    // Non-final question: save answer (already saved) and open next question sheet so user answers all.
    final nextIndex = index + 1;
    // Friendly feedback then open next question automatically
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Answer saved. Next question...")),
    );

    // Open the next question after a short delay so the snackbar shows
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _openAnswerSheet(context, nextIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Valentine Questions 💌")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final answered = _answers.containsKey(index);
          return Card(
            elevation: 4,
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(
                _questions[index],
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.pink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: answered ? Text("Answer: ${_answers[index]}") : null,
              trailing: ElevatedButton(
                onPressed: () => _openAnswerSheet(context, index),
                child: Text(index == _questions.length - 1 ? "Answer 💘" : "Answer ✨"),
              ),
            ),
          );
        },
      ),
    );
  }
}