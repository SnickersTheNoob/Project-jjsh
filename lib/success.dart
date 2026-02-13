import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:io';
import 'widgets/floating_hearts.dart';

class SuccessScreen extends StatefulWidget {
  final String name;
  final File? image;

  const SuccessScreen({Key? key, required this.name, this.image})
      : super(key: key);

  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _glowController;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _replayConfetti() {
    _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingHearts()), // animated background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [Colors.red, Colors.pink, Colors.yellow],
                ),
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _glow.value,
                      child: Text(
                        "Yay ${widget.name} said YES 💖",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                if (widget.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(widget.image!, height: 200),
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _replayConfetti,
                  child: const Text("Replay Celebration 🎉"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}