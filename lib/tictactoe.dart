import 'dart:async';
import 'dart:math';
import 'dart:ui'; // for ImageFilter.blur
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'services/stats_service.dart';
import 'services/music_service.dart';
import 'download_helper.dart';

enum Difficulty { easy, medium, hard }

class TicTacToeScreen extends StatefulWidget {
  final String name;
  const TicTacToeScreen({Key? key, required this.name}) : super(key: key);

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  // 0 = empty, 1 = human (X), -1 = Damian (O)
  final List<int> _board = List<int>.filled(9, 0);
  bool _humanTurn = true;
  bool _gameOver = false;
  String _status = "Your move";
  Difficulty _difficulty = Difficulty.medium;
  final Random _rand = Random();
  bool _introShown = false;

  // confetti
  late ConfettiController _confettiController;

  // stats
  final StatsService _stats = StatsService();
  int _wins = 0, _losses = 0, _draws = 0, _winsQualified = 0;

  // winning line highlight
  List<int>? _winningLine;

  // Bundled prize asset path (use prize.jpg from assets/)
  String? _prizeAssetPath;

  // Whether prize has been claimed (unblur thumbnail only after successful download)
  bool _prizeClaimed = false;

  // Music control
  bool _isMusicPlaying = false;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadStats();
    // Observe music playing state
    _playingSub = MusicService().playingStream.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isMusicPlaying = playing;
      });
    }, onError: (_) {
      // ignore stream errors
    });

    // Attempt to locate bundled prize as soon as screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryUseBundledPrize();
      if (!_introShown) {
        _introShown = true;
        _showJoinPopup();
      }
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    await _stats.init();
    setState(() {
      _wins = _stats.wins;
      _losses = _stats.losses;
      _draws = _stats.draws;
      _winsQualified = _stats.winsMediumOrHard;
    });
  }

  void _toggleMusic() async {
    try {
      if (_isMusicPlaying) {
        await MusicService().stop();
      } else {
        await MusicService().play();
      }
      // playingStream subscription will update _isMusicPlaying
    } catch (e) {
      // ignore: avoid_print
      print('Music toggle failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to toggle music')));
    }
  }

  void _showJoinPopup() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Play Tic‑Tac‑Toe"),
          content: const Text(
            "Beat Damian and you win a surprise prize!\n\n"
            "Note: Easy is practice only — wins on Easy do NOT qualify for the prize.\n"
            "You must win at Medium or Hard to earn the prize. Good luck!",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Start background music in response to a user gesture to satisfy browser autoplay policies.
                try {
                  await MusicService().play();
                } catch (_) {
                  // ignore any play errors
                }
                Navigator.of(ctx).pop();
              },
              child: const Text("Play"),
            ),
          ],
        );
      },
    );
  }

  /// Try to use a bundled asset as prize. Looks for a single canonical filename.
  Future<void> _tryUseBundledPrize() async {
    const candidate = 'assets/prize.jpg';
    try {
      await rootBundle.load(candidate);
      setState(() {
        _prizeAssetPath = candidate;
      });
    } catch (_) {
      setState(() {
        _prizeAssetPath = null;
      });
    }
  }

  // Web-first save: try browser download helper; on non-web this returns null (no-op).
  Future<String?> _savePrizeToDownloads() async {
    if (_prizeAssetPath == null) return null;
    try {
      final data = await rootBundle.load(_prizeAssetPath!);
      final bytes = data.buffer.asUint8List();

      final now = DateTime.now();
      final filename =
          'prize_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}.jpg';

      // Web: use helper which attempts anchor download and falls back to opening a tab.
      if (kIsWeb) {
        final ok = await saveBytesAsFile(bytes, filename);
        if (ok) return 'downloaded';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download blocked — opened image in a new tab or blocked by browser.')),
        );
        return null;
      }

      // Non-web: not implemented in this build. Return null so caller can fallback or show error.
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save prize image')),
      );
      // ignore: avoid_print
      print('Failed to save prize image: $e');
      return null;
    }
  }

  void _resetBoard({bool humanStarts = true}) {
    for (var i = 0; i < 9; i++) _board[i] = 0;
    _humanTurn = humanStarts;
    _gameOver = false;
    _status = _humanTurn ? "Your move" : "Damian is thinking...";
    _winningLine = null;
    setState(() {});
    if (!_humanTurn) _aiMoveWithDelay();
  }

  void _playerMove(int index) {
    if (_gameOver || !_humanTurn || _board[index] != 0) return;
    setState(() {
      _board[index] = 1;
      _humanTurn = false;
      _status = "Damian is thinking...";
    });
    _checkEndOrContinue();
  }

  Future<void> _aiMoveWithDelay() async {
    if (_gameOver) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _aiMove();
  }

  void _aiMove() {
    if (_gameOver) return;
    int move;
    switch (_difficulty) {
      case Difficulty.easy:
        move = _randomMove();
        break;
      case Difficulty.medium:
        move = _mediumMove();
        break;
      case Difficulty.hard:
        move = _minimaxMove();
        break;
    }
    if (move >= 0) {
      setState(() {
        _board[move] = -1;
        _humanTurn = true;
        _status = "Your move";
      });
    }
    _checkEndOrContinue();
  }

  int _randomMove() {
    final empties = <int>[];
    for (var i = 0; i < 9; i++) if (_board[i] == 0) empties.add(i);
    if (empties.isEmpty) return -1;
    return empties[_rand.nextInt(empties.length)];
  }

  int _mediumMove() {
    // 1) Win if possible (Damian = -1)
    for (var i = 0; i < 9; i++) {
      if (_board[i] == 0) {
        _board[i] = -1;
        if (_winner(_board) == -1) {
          _board[i] = 0;
          return i;
        }
        _board[i] = 0;
      }
    }
    // 2) Block human win
    for (var i = 0; i < 9; i++) {
      if (_board[i] == 0) {
        _board[i] = 1;
        if (_winner(_board) == 1) {
          _board[i] = 0;
          return i;
        }
        _board[i] = 0;
      }
    }
    // 3) Prefer center, corners, then random
    if (_board[4] == 0) return 4;
    final corners = [0, 2, 6, 8].where((i) => _board[i] == 0).toList();
    if (corners.isNotEmpty) return corners[_rand.nextInt(corners.length)];
    return _randomMove();
  }

  int _minimaxMove() {
    var bestScore = -9999;
    var bestMove = -1;
    for (var i = 0; i < 9; i++) {
      if (_board[i] == 0) {
        _board[i] = -1;
        final score = _minimax(_board, 0, true);
        _board[i] = 0;
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int _minimax(List<int> board, int depth, bool isHumanTurn) {
    final winner = _winner(board);
    if (winner != 0) {
      if (winner == -1) return 10 - depth; // Damian win => positive for AI
      if (winner == 1) return depth - 10; // Human win => negative for AI
    }
    if (!board.contains(0)) return 0; // draw

    if (!isHumanTurn) {
      // human's turn (minimizer)
      var best = 9999;
      for (var i = 0; i < 9; i++) {
        if (board[i] == 0) {
          board[i] = 1;
          final score = _minimax(board, depth + 1, true);
          board[i] = 0;
          best = min(best, score);
        }
      }
      return best;
    } else {
      // Damian's turn (maximizer)
      var best = -9999;
      for (var i = 0; i < 9; i++) {
        if (board[i] == 0) {
          board[i] = -1;
          final score = _minimax(board, depth + 1, false);
          board[i] = 0;
          best = max(best, score);
        }
      }
      return best;
    }
  }

  int _winner(List<int> b) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var line in lines) {
      final a = b[line[0]], c = b[line[1]], d = b[line[2]];
      if (a != 0 && a == c && a == d) {
        _winningLine = List<int>.from(line);
        return a;
      }
    }
    _winningLine = null;
    return 0;
  }

  void _checkEndOrContinue() {
    final w = _winner(_board);
    if (w != 0) {
      _gameOver = true;
      if (w == 1) {
        _status = "You win! 🎉";
        _confettiController.play();
        MusicService().playEffect('assets/sounds/victory.mp3');
        _stats.incrementWin(mediumOrHard: _difficulty != Difficulty.easy);
        _loadStats();
        // DO NOT auto-claim the prize here. Keep the thumbnail blurred until downloaded.
        _showEndDialog(playerWon: true);
      } else {
        _status = "Damian wins 😢";
        MusicService().playEffect('assets/sounds/alert.mp3');
        _stats.incrementLoss();
        _loadStats();
        _showEndDialog(playerWon: false);
      }
      setState(() {});
      return;
    }
    if (!_board.contains(0)) {
      _gameOver = true;
      _status = "Draw";
      _stats.incrementDraw();
      _loadStats();
      _showEndDialog(draw: true);
      setState(() {});
      return;
    }
    if (!_humanTurn) _aiMoveWithDelay();
  }

  Future<void> _showEndDialog({bool draw = false, bool playerWon = false}) async {
    String title;
    String content;

    if (draw) {
      title = "Draw";
      content = "It's a tie — so close!";
    } else if (playerWon) {
      // Player beat Damian
      if (_difficulty == Difficulty.easy) {
        title = "You won!";
        content = "Nice job, but Easy wins don't qualify for the prize. Try Medium or Hard for the prize.";
      } else {
        title = "You beat Damian! 🎉";
        content = "Congratulations — you beat Damian on ${_difficulty.name.toUpperCase()} and earned the surprise prize!";
      }
    } else {
      // Damian won
      title = "Damian won";
      content = "Damian beat you this time. Try again — beat Medium or Hard to win the prize.";
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final qualifies = playerWon &&
            (_difficulty == Difficulty.medium || _difficulty == Difficulty.hard) &&
            _prizeAssetPath != null;
        if (qualifies) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(_prizeAssetPath!, height: 200, fit: BoxFit.cover)),
                const SizedBox(height: 12),
                Text(content),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text("Download"),
                onPressed: () async {
                  final path = await _savePrizeToDownloads();
                  if (path != null) {
                    // Mark prize claimed only after a successful save
                    setState(() {
                      _prizeClaimed = true;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved: $path")));
                    // Offer to move to memories (next)
                    showDialog<void>(
                      context: context,
                      builder: (ctx2) {
                        return AlertDialog(
                          title: const Text("Prize saved"),
                          content: const Text("Would you like to view the memories next?"),
                          actions: [
                            TextButton(
                              child: const Text("Go to Next"),
                              onPressed: () {
                                Navigator.of(ctx2).pop();
                                Navigator.of(context).pushNamed('/gallery', arguments: {'name': widget.name});
                              },
                            ),
                            TextButton(
                              child: const Text("Close"),
                              onPressed: () => Navigator.of(ctx2).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save prize image")));
                  }
                },
              ),
              TextButton(
                child: const Text("Play again"),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _resetBoard(humanStarts: true);
                },
              ),
              TextButton(
                child: const Text("Main menu"),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text("Play again"),
              onPressed: () {
                Navigator.of(ctx).pop();
                _resetBoard(humanStarts: true);
              },
            ),
            TextButton(
              child: const Text("Main menu"),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).maybePop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCell(int i) {
    final v = _board[i];
    final label = v == 1 ? 'X' : v == -1 ? 'O' : '';
    final color = v == 1 ? Colors.pink : v == -1 ? Colors.purple : Colors.grey.shade300;
    final isWinning = _winningLine?.contains(i) ?? false;

    return GestureDetector(
      onTap: () => _playerMove(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isWinning ? Colors.yellow.shade100 : Colors.white,
          border: Border.all(color: isWinning ? Colors.orange : Colors.pink.shade100, width: isWinning ? 3 : 1),
          boxShadow: isWinning ? [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 8, spreadRadius: 2)] : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: label.isEmpty
                ? const SizedBox.shrink(key: ValueKey('empty'))
                : Text(label, key: ValueKey<String?>(label + i.toString()), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    final boardSize = min(size, 520.0) * 0.9;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tic Tac Toe ✖︎◯"),
        actions: [
          IconButton(
            tooltip: _isMusicPlaying ? 'Mute music' : 'Play music',
            icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off),
            onPressed: _toggleMusic,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text("Opponent: Damian — Good luck, ${widget.name}!", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text("Difficulty:"),
                  const SizedBox(width: 12),
                  DropdownButton<Difficulty>(
                    value: _difficulty,
                    items: const [
                      DropdownMenuItem(value: Difficulty.easy, child: Text("Easy")),
                      DropdownMenuItem(value: Difficulty.medium, child: Text("Medium")),
                      DropdownMenuItem(value: Difficulty.hard, child: Text("Hard")),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _difficulty = v;
                      });
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _resetBoard(humanStarts: true),
                    child: const Text("Reset"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _resetBoard(humanStarts: false),
                    child: const Text("Damian starts"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Center(
                  child: Container(
                    width: boardSize,
                    height: boardSize,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 9,
                      itemBuilder: (_, i) => _buildCell(i),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      maxBlastForce: 25,
                      minBlastForce: 8,
                      emissionFrequency: 0.02,
                      colors: const [Colors.pink, Colors.red, Colors.purple, Colors.yellow],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stats panel (shows bundled prize thumbnail if available)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Wins: $_wins"),
                      Text("Qualified wins (M+H): $_winsQualified"),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Losses: $_losses"),
                      Text("Draws: $_draws"),
                    ],
                  ),
                  const SizedBox(width: 16),
                  if (_prizeAssetPath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _prizeClaimed
                            ? Image.asset(_prizeAssetPath!, width: 56, height: 56, fit: BoxFit.cover)
                            : ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                                child: Image.asset(_prizeAssetPath!, width: 56, height: 56, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      await _stats.reset();
                      await _loadStats();
                      // Reset claimed state when stats are reset so thumbnail is blurred again
                      setState(() {
                        _prizeClaimed = false;
                      });
                    },
                    child: const Text("Reset Stats"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("How to play"),
                    content: const Text("Tap a cell to place X. First to align three in a row wins. Choose difficulty for Damian."),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close"))],
                  ),
                );
              },
              child: const Text("How to play"),
            ),
          ],
        ),
      ),
    );
  }
}