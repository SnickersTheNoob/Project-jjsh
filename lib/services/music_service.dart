// music_service.dart — added `playFromStart` to restart background music.

import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';

class MusicService {
  MusicService._internal();
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;

  final AudioPlayer _bgPlayer = AudioPlayer();
  double _currentVolume = 1.0;
  Timer? _fadeTimer;

  // Reusable players for short effects (preloaded)
  final Map<String, AudioPlayer> _effectPlayers = {};

  // Optional list of effect assets to preload
  final List<String> _effectsToPreload = [
    'assets/sounds/step.mp3',
    'assets/sounds/alert.mp3',
    'assets/sounds/victory.mp3',
  ];

  /// Initialize background music and preload effects.
  /// Call after `WidgetsFlutterBinding.ensureInitialized()` (e.g. in main()).
  Future<void> init() async {
    try {
      // small delay can help ensure plugin registration on desktop
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await Future.delayed(const Duration(milliseconds: 120));
      }

      // background music (safe if asset missing)
      try {
        await _bgPlayer.setAsset('assets/romantic.mp3');
        _bgPlayer.setLoopMode(LoopMode.one);
        await _bgPlayer.setVolume(_currentVolume);
      } catch (e) {
        // ignore: avoid_print
        print('MusicService: background asset load failed: $e');
      }

      // preload effect players (fail safely if asset missing)
      for (final asset in _effectsToPreload) {
        try {
          final player = AudioPlayer();
          await player.setAsset(asset);
          _effectPlayers[asset] = player;
        } catch (e) {
          // ignore missing assets or platform-specific issues
          // ignore: avoid_print
          print('MusicService: failed to preload $asset: $e');
          try {
            await _effectPlayers.remove(asset)?.dispose();
          } catch (_) {}
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('MusicService.init non-fatal error: $e\n$st');
    }
  }

  Future<void> play({double volume = 0.9}) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    try {
      await _bgPlayer.setVolume(_currentVolume);
      await _bgPlayer.play();
    } catch (e) {
      // ignore: avoid_print
      print('MusicService.play error: $e');
    }
  }

  /// Seek to start and play from the beginning.
  Future<void> playFromStart({double volume = 0.9}) async {
    try {
      _currentVolume = volume.clamp(0.0, 1.0);
      await _bgPlayer.setVolume(_currentVolume);
      await _bgPlayer.seek(Duration.zero);
      await _bgPlayer.play();
    } catch (e) {
      // ignore: avoid_print
      print('MusicService.playFromStart error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _bgPlayer.stop();
    } catch (e) {
      // ignore: avoid_print
      print('MusicService.stop error: $e');
    }
  }

  Future<void> fadeTo(double target, Duration duration) async {
    _fadeTimer?.cancel();
    final start = _currentVolume;
    final end = target.clamp(0.0, 1.0);
    if (duration.inMilliseconds <= 0) {
      _currentVolume = end;
      await _bgPlayer.setVolume(_currentVolume);
      return;
    }

    final int steps = (duration.inMilliseconds / 20).ceil().clamp(1, 1000);
    final double stepDelta = (end - start) / steps;
    int step = 0;

    final completer = Completer<void>();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      step++;
      _currentVolume = (start + stepDelta * step).clamp(0.0, 1.0);
      try {
        await _bgPlayer.setVolume(_currentVolume);
      } catch (_) {}
      if (step >= steps) {
        timer.cancel();
        _fadeTimer = null;
        completer.complete();
      }
    });

    return completer.future;
  }

  Future<void> fadeOutAndStop(Duration duration) async {
    await fadeTo(0.0, duration);
    await stop();
  }

  /// Play a short one-shot effect. Reuses preloaded players if available.
  Future<void> playEffect(String asset) async {
    try {
      // If we have a preloaded player, reuse it.
      if (_effectPlayers.containsKey(asset)) {
        final player = _effectPlayers[asset]!;
        try {
          await player.seek(Duration.zero);
          await player.play();
          return;
        } catch (e) {
          // fallthrough to create-on-demand
          // ignore: avoid_print
          print('MusicService.playEffect reuse error: $e');
        }
      }

      // Create a short-lived player as fallback.
      final player = AudioPlayer();
      await player.setAsset(asset);
      await player.play();
      player.playerStateStream.firstWhere(
        (ps) => ps.processingState == ProcessingState.completed || !ps.playing,
      ).then((_) => player.dispose());
    } catch (e) {
      // ignore: avoid_print
      print('MusicService.playEffect error: $e');
    }
  }

  /// Dispose everything (call when app terminates if needed).
  Future<void> dispose() async {
    _fadeTimer?.cancel();
    try {
      await _bgPlayer.dispose();
    } catch (_) {}
    for (final p in _effectPlayers.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _effectPlayers.clear();
  }

  // --- Expose background player streams for UI sync ---

  /// Stream of the current playback position (Duration).
  Stream<Duration> get positionStream => _bgPlayer.positionStream;

  /// Stream that emits true/false while background player is playing.
  Stream<bool> get playingStream => _bgPlayer.playingStream;
}