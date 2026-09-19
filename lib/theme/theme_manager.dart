import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_theme_config.dart';

class ThemeManager extends ChangeNotifier {
  ThemeManager(this._prefs) {
    final stored = _prefs.getString(_key);
    _id = GameThemeId.values.firstWhere(
      (id) => id.name == stored,
      orElse: () => GameThemeId.atelier,
    );
  }

  static const _key = 'santerra_theme_id';

  final SharedPreferences _prefs;
  late GameThemeId _id;

  GameThemeId get id => _id;

  GameThemeConfig get config => GameThemeConfig.of(_id);

  Future<void> setTheme(GameThemeId id) async {
    if (_id == id) {
      return;
    }
    _id = id;
    await _prefs.setString(_key, id.name);
    notifyListeners();
  }
}
