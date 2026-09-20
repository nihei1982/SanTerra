import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'audio/sound_manager.dart';
import 'game/score_manager.dart';
import 'game/settings_manager.dart';
import 'l10n/locale_manager.dart';
import 'theme/theme_manager.dart';
import 'util/asset_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AssetGuard.load();
  final prefs = await SharedPreferences.getInstance();
  final themeManager = ThemeManager(prefs);
  final sound = SoundManager(prefs);
  await sound.init();
  final score = ScoreManager(prefs);
  await score.load();
  final settings = SettingsManager(prefs);
  final localeManager = LocaleManager(prefs);
  runApp(
    SanTerraApp(
      themeManager: themeManager,
      sound: sound,
      score: score,
      settings: settings,
      localeManager: localeManager,
    ),
  );
}
