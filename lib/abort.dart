import 'package:flutter/material.dart';

class AbortScreen extends StatefulWidget {
  const AbortScreen({Key? key}) : super(key: key);

  @override
  _AbortScreenState createState() => _AbortScreenState();
}

class _AbortScreenState extends State<AbortScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retry() {
    Navigator.pushReplacementNamed(context, '/form');
  }

  void _exit() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulse.value,
                  child: const Icon(
                    Icons.heart_broken,
                    color: Colors.redAccent,
                    size: 120,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "Oh no 💔\nLove denied...",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _retry,
              child: const Text("Try Again 💖"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text("Exit 💔"),
            ),
          ],
        ),
      ),
    );
  }
}