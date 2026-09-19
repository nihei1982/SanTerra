import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_mode.dart';

class ScoreManager extends ChangeNotifier {
  ScoreManager(this._prefs);

  static const highScoreKey = 'santerra_high_score';
  static const infinityHighScoreKey = 'santerra_high_score_infinity';
  static const modeKey = 'santerra_game_mode';

  final SharedPreferences _prefs;
  GameMode mode = GameMode.normal;
  int current = 0;
  int highScore = 0;

  Future<void> load() async {
    final stored = _prefs.getString(modeKey);
    mode = GameMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => GameMode.normal,
    );
    highScore = _highScoreFor(mode);
    notifyListeners();
  }

  int _highScoreFor(GameMode value) {
    if (value == GameMode.infinity) {
      return _prefs.getInt(infinityHighScoreKey) ?? 0;
    }
    return _prefs.getInt(highScoreKey) ?? 0;
  }

  Future<void> setMode(GameMode value) async {
    if (mode == value) {
      highScore = _highScoreFor(value);
      notifyListeners();
      return;
    }
    mode = value;
    highScore = _highScoreFor(value);
    await _prefs.setString(modeKey, value.name);
    notifyListeners();
  }

  String get _activeKey =>
      mode == GameMode.infinity ? infinityHighScoreKey : highScoreKey;

  static int pointsFor(int eliminatedGrains, int chainIndex) {
    if (eliminatedGrains <= 0 || chainIndex <= 0) {
      return 0;
    }
    return eliminatedGrains * chainIndex;
  }

  void resetCurrent() {
    current = 0;
    notifyListeners();
  }

  void add(int points) {
    if (points <= 0) {
      return;
    }
    current += points;
    if (current > highScore) {
      highScore = current;
      _prefs.setInt(_activeKey, highScore);
    }
    notifyListeners();
  }

  Future<void> persistHighScore() async {
    if (current > highScore) {
      highScore = current;
    }
    await _prefs.setInt(_activeKey, highScore);
    notifyListeners();
  }
}
