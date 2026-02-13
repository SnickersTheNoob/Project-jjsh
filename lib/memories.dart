// Updated memories screen: sync hearts/large hearts pulse to music positionStream (BPM-based simple beat)

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/music_service.dart';

class MemoriesScreen extends StatefulWidget {
  final String name;
  const MemoriesScreen({Key? key, required this.name}) : super(key: key);

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _Heart {
  double x;
  double y;
  double size;
  double speed;
  double sway;
  double phase;
  Color color;
  _Heart({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.color,
  });
}

class _MemoriesScreenState extends State<MemoriesScreen> with TickerProviderStateMixin {
  final List<String> _images = const [
    'assets/memory1.jpg',
    'assets/memory2.png',
    'assets/memory3.jpg',
  ];
  static const String _bearGif = 'assets/bear.gif';

  int _current = 0;
  Timer? _autoTimer;

  late final AnimationController _colorController;
  late final Animation<Color?> _colorAnimation;

  late final AnimationController _gifPulseController;
  late final Animation<double> _gifPulse;

  late final AnimationController _heartsTicker;
  final List<_Heart> _hearts = [];
  final Random _rand = Random();
  double _screenHeight = 800;
  double _screenWidth = 400;

  Uint8List? _bearBytes;
  bool _bearLoadFailed = false;

  // beat-related
  double _beatSeconds = 0.0; // playback time in seconds
  double _beatScale = 1.0; // 1.0..1.x derived from beat
  StreamSubscription<Duration>? _posSub;
  // If you know the song BPM, set it here for tighter sync.
  // You can tweak this (default 72).
  final double _bpm = 72.0;

  static const String _speechFull =
      "You're the best girl I've met, wish I could spend a lot of time with you. "
      "No matter what I'll stay with you and not go away. I really wish it would turn out well and hope you will see this. "
      "Love you Laura and, if you really reached this — this is the valentine gift 👀💖";

  static const Duration _displayDuration = Duration(seconds: 4);
  static const Duration _transitionDuration = Duration(milliseconds: 800);
  static const double _endScale = 1.06;

  bool _expanded = false;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _colorAnimation = ColorTween(begin: Colors.pinkAccent, end: Colors.purpleAccent)
        .animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));

    _gifPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _gifPulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _gifPulseController, curve: Curves.easeInOut),
    );

    _heartsTicker = AnimationController(vsync: this, duration: const Duration(seconds: 1000))
      ..addListener(_onTick)
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final path in _images) {
        precacheImage(AssetImage(path), context);
      }
      _loadBearGifBytes();
      _ensureHeartsInitialized();
    });

    // subscribe to music position stream for beat sync
    _posSub = MusicService().positionStream.listen((pos) {
      if (!mounted) return;
      _beatSeconds = pos.inMilliseconds / 1000.0;
      // derive a simple beat scale from playback time and BPM
      final phase = (2 * pi * _bpm * _beatSeconds) / 60.0;
      // beatOsc ranges -1..1; map to 0..1
      final beatOsc = (sin(phase) + 1.0) * 0.5;
      // scale roughly 1.0 .. 1.18 (adjust multiplier)
      _beatScale = 1.0 + (0.18 * beatOsc);
      // We don't call setState here each position event (very frequent).
      // Instead rely on hearts ticker which reads _beatScale on tick.
    }, onError: (_) {
      // ignore errors; leave _beatScale default
    });

    _startAutoAdvance();
  }

  Future<void> _loadBearGifBytes() async {
    try {
      final data = await rootBundle.load(_bearGif);
      if (!mounted) return;
      setState(() {
        _bearBytes = data.buffer.asUint8List();
        _bearLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bearBytes = null;
        _bearLoadFailed = true;
      });
    }
  }

  _Heart _randomHeart({bool initial = false}) {
    final size = 12 + _rand.nextDouble() * 28;
    final speed = 30 + _rand.nextDouble() * 80;
    final sway = 8 + _rand.nextDouble() * 20;
    final x = _rand.nextDouble();
    final y = initial ? (_rand.nextDouble() * _screenHeight) : (-size - _rand.nextDouble() * 200);
    final hue = 330 + _rand.nextDouble() * 40;
    final color = HSVColor.fromAHSV(1.0, hue, 0.7, 0.95).toColor();
    final phase = _rand.nextDouble() * pi * 2;
    return _Heart(x: x, y: y, size: size, speed: speed, sway: sway, phase: phase, color: color);
  }

  void _ensureHeartsInitialized() {
    if (_hearts.isNotEmpty) return;
    const count = 20;
    for (var i = 0; i < count; i++) {
      _hearts.add(_randomHeart(initial: true));
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;
    if (dt <= 0) return;
    var needsSet = false;
    // modify global speed multiplier from beatScale; keep small influence
    final globalMul = 1.0 + ((_beatScale - 1.0) * 0.6);
    for (final h in _hearts) {
      h.y += h.speed * dt * globalMul;
      final t = now.millisecondsSinceEpoch / 1000.0;
      final swayOffset = sin(t + h.phase) * h.sway;
      h.x += swayOffset * 0.01 * globalMul;
      if (h.x < 0) h.x = 0;
      if (h.x > 1) h.x = 1;
      if (h.y > _screenHeight + h.size) {
        final newH = _randomHeart(initial: false);
        h.x = newH.x;
        h.y = newH.y;
        h.size = newH.size;
        h.speed = newH.speed;
        h.sway = newH.sway;
        h.phase = newH.phase;
        h.color = newH.color;
      }
      needsSet = true;
    }
    if (needsSet && mounted) setState(() {});
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_displayDuration, (_) {
      if (!mounted) return;
      setState(() => _current = (_current + 1) % _images.length);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _colorController.dispose();
    _gifPulseController.dispose();
    _heartsTicker.dispose();
    _posSub?.cancel();
    super.dispose();
  }

  String get _speechShort {
    final whoever = widget.name.isNotEmpty ? widget.name : 'Laura';
    return "You're the best, $whoever. I hope we can spend more time together. Love you 💖";
  }

  Widget _buildAnimatedImage(double height) {
    return AnimatedSwitcher(
      duration: _transitionDuration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: offsetAnim, child: fade);
      },
      child: SizedBox(
        key: ValueKey<int>(_current),
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _endScale),
            duration: _displayDuration + _transitionDuration,
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, origin: const Offset(0, 0), child: child);
            },
            child: Image.asset(
              _images[_current],
              fit: BoxFit.contain,
              alignment: Alignment.center,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }

  void _openGifViewer() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: _bearBytes != null
                  ? Image.memory(_bearBytes!, fit: BoxFit.contain, gaplessPlayback: true)
                  : _bearLoadFailed
                      ? const Center(child: Text('GIF unavailable', style: TextStyle(color: Colors.white)))
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartsLayer() {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(builder: (context, constraints) {
          _screenHeight = constraints.maxHeight;
          _screenWidth = constraints.maxWidth;
          _ensureHeartsInitialized();
          final children = <Widget>[];
          for (final h in _hearts) {
            final left = (h.x * _screenWidth) - (h.size / 2);
            final top = h.y - (h.size / 2);
            children.add(Positioned(
              left: left.clamp(-50.0, _screenWidth + 50.0),
              top: top,
              child: Opacity(
                opacity: 0.85,
                child: Transform.rotate(
                  angle: sin((h.phase + DateTime.now().millisecondsSinceEpoch / 800)) * 0.2,
                  child: SizedBox(
                    width: h.size,
                    height: h.size,
                    child: Icon(Icons.favorite, color: h.color.withOpacity(0.95), size: h.size),
                  ),
                ),
              ),
            ));
          }
          return Stack(children: children);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.55;

    // big hearts scale is based on beatScale so they "pulse" with music
    final bigHeartScale = _beatScale;

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(title: Text('Memories of ${widget.name}')),
      body: Stack(
        children: [
          _buildHeartsLayer(),

          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) {
                    final baseColor = _colorAnimation.value ?? Colors.pinkAccent;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: bigHeartScale * 1.8,
                          child: Opacity(opacity: 0.06, child: Icon(Icons.favorite, size: 420, color: baseColor)),
                        ),
                        Transform.scale(
                          scale: bigHeartScale * 1.1,
                          child: Opacity(opacity: 0.04, child: Icon(Icons.favorite, size: 300, color: baseColor)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 12),
              Expanded(child: Center(child: _buildAnimatedImage(height))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Text('${_current + 1} / ${_images.length}'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        _autoTimer?.cancel();
                        setState(() {
                          _current = (_current - 1 + _images.length) % _images.length;
                        });
                        _startAutoAdvance();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        _autoTimer?.cancel();
                        setState(() {
                          _current = (_current + 1) % _images.length;
                        });
                        _startAutoAdvance();
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
                  ],
                ),
              ),
            ],
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _colorAnimation,
                          builder: (context, child) {
                            return Text(
                              _expanded ? _speechFull : _speechShort,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _colorAnimation.value ?? Colors.pinkAccent,
                                fontSize: 16,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black.withOpacity(0.4), offset: const Offset(0, 1), blurRadius: 2)],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => setState(() => _expanded = !_expanded), child: Text(_expanded ? 'Less' : 'Read more')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 20,
            bottom: 96,
            child: GestureDetector(
              onTap: _openGifViewer,
              child: ScaleTransition(
                scale: _gifPulse,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8)], color: Colors.white),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _bearBytes != null
                        ? Image.memory(_bearBytes!, fit: BoxFit.cover, gaplessPlayback: true)
                        : _bearLoadFailed
                            ? const Center(child: Icon(Icons.broken_image, color: Colors.red))
                            : const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator())),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}