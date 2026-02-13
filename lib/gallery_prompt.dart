import 'package:flutter/material.dart';
import 'success.dart';
import 'abort.dart';

class GalleryPromptScreen extends StatefulWidget {
  final String name;
  const GalleryPromptScreen({Key? key, required this.name}) : super(key: key);

  @override
  _GalleryPromptScreenState createState() => _GalleryPromptScreenState();
}

class _GalleryPromptScreenState extends State<GalleryPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _float = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continueToSuccess() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessScreen(
          name: widget.name,
          image: null, // no gallery image
        ),
      ),
    );
  }

  void _abort() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AbortScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative framed placeholder instead of actual gallery image
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 320,
                  height: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.pink, width: 6),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.28),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.pink.shade50,
                      child: const Center(
                        child: Icon(Icons.photo, size: 64, color: Colors.pinkAccent),
                      ),
                    ),
                  ),
                ),
                // Animated hearts / favorites
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: Transform.translate(
                        offset: Offset(0, _float.value),
                        child: const Icon(Icons.favorite, color: Colors.red, size: 40),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 34,
                  right: 46,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulse.value,
                        child: Transform.translate(
                          offset: Offset(0, -_float.value),
                          child: const Icon(Icons.favorite, color: Colors.pink, size: 30),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 76,
                  right: 26,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulse.value,
                        child: Transform.translate(
                          offset: Offset(_float.value, 0),
                          child: const Icon(Icons.favorite, color: Colors.purple, size: 25),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              "Let's celebrate 🎉",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36.0),
              child: Text(
                "I removed the gallery prompt. Tap Continue to go to the celebration screen.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  child: const Text("Continue to Celebration 🎉"),
                  onPressed: _continueToSuccess,
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _abort,
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}