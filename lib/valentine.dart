import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ValentineScreen extends StatefulWidget {
  const ValentineScreen({Key? key}) : super(key: key);

  @override
  _ValentineScreenState createState() => _ValentineScreenState();
}

class _ValentineScreenState extends State<ValentineScreen> {
  final TextEditingController _nameController = TextEditingController();
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oops 💔, name can’t be empty!")),
      );
      return;
    }
    _confetti.play();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamed(
        context,
        '/questions', // ✅ go to questions first
        arguments: {
          'name': _nameController.text,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.red, Colors.pink, Colors.yellow],
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Enter your Valentine’s name 💘",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Type a name...",
                    prefixIcon: const Icon(Icons.favorite, color: Colors.red),
                    filled: true,
                    fillColor: Colors.pink.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text("Celebrate Love ✨"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}