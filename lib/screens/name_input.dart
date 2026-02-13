import 'package:flutter/material.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({Key? key}) : super(key: key);

  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submitName() {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name 💔")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/questions',
      arguments: {'name': _controller.text}, // ✅ always pass name
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(title: const Text("Enter Name 💌")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Who is your Valentine? 💖",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type a name...",
                prefixIcon: const Icon(Icons.favorite, color: Colors.red),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitName,
              child: const Text("Continue 💘"),
            ),
          ],
        ),
      ),
    );
  }
}