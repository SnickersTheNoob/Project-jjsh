import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  StatsService._internal();
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;

  SharedPreferences? _prefs;

  static const _kWins = 'ttt_wins';
  static const _kLosses = 'ttt_losses';
  static const _kDraws = 'ttt_draws';
  static const _kWinsMediumOrHard = 'ttt_wins_medium_hard';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  int get wins => _prefs?.getInt(_kWins) ?? 0;
  int get losses => _prefs?.getInt(_kLosses) ?? 0;
  int get draws => _prefs?.getInt(_kDraws) ?? 0;
  int get winsMediumOrHard => _prefs?.getInt(_kWinsMediumOrHard) ?? 0;

  Future<void> incrementWin({required bool mediumOrHard}) async {
    await init();
    final w = wins + 1;
    await _prefs!.setInt(_kWins, w);
    if (mediumOrHard) {
      final wm = winsMediumOrHard + 1;
      await _prefs!.setInt(_kWinsMediumOrHard, wm);
    }
  }

  Future<void> incrementLoss() async {
    await init();
    final l = losses + 1;
    await _prefs!.setInt(_kLosses, l);
  }

  Future<void> incrementDraw() async {
    await init();
    final d = draws + 1;
    await _prefs!.setInt(_kDraws, d);
  }

  Future<void> reset() async {
    await init();
    await _prefs!.remove(_kWins);
    await _prefs!.remove(_kLosses);
    await _prefs!.remove(_kDraws);
    await _prefs!.remove(_kWinsMediumOrHard);
  }
}