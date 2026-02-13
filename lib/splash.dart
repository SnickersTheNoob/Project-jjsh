import 'dart:async';

import 'package:flutter/material.dart';
import 'widgets/floating_hearts.dart';
import 'services/music_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;
  final double _playVolume = 0.85;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start music (service was initialized in main).
    MusicService().play(volume: _playVolume);

    // Schedule navigation with a cancellable Timer and guarded checks.
    _navTimer = Timer(const Duration(seconds: 4), () async {
      // fade out before navigating
      await MusicService().fadeTo(0.0, const Duration(milliseconds: 400));

      // ensure widget still mounted before using context
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/form');

      // if still mounted (or app still running), restore music level
      await MusicService().fadeTo(_playVolume, const Duration(milliseconds: 400));
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startNow() async {
    // Cancel scheduled nav to avoid duplicate navigation
    _navTimer?.cancel();

    // fade and navigate, but guard after awaits
    await MusicService().fadeTo(0.0, const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/form');
    await MusicService().fadeTo(_playVolume, const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingHearts()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _glow.value,
                      child: const Icon(Icons.favorite,
                          color: Colors.redAccent, size: 120),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  "Damian’s Valentine 💖",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.redAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _startNow,
                  child: const Text("Start the Magic ✨"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}