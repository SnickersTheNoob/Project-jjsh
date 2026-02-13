import 'package:flutter/material.dart';
import 'dart:math';

class FloatingHearts extends StatefulWidget {
  const FloatingHearts({Key? key}) : super(key: key);

  @override
  _FloatingHeartsState createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildHeart(double progress) {
    final double startX = _random.nextDouble() * MediaQuery.of(context).size.width;
    final double y = MediaQuery.of(context).size.height * (1 - progress);
    final double size = 20 + _random.nextDouble() * 30;
    final Color color = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.orange
    ][_random.nextInt(4)];

    return Positioned(
      left: startX,
      top: y,
      child: Icon(Icons.favorite, color: color, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Stack(
          children: List.generate(15, (index) => _buildHeart((progress + index / 15) % 1)),
        );
      },
    );
  }
}