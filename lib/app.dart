import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio/sound_manager.dart';
import 'game/score_manager.dart';
import 'game/settings_manager.dart';
import 'theme/theme_manager.dart';
import 'ui/title_scene.dart';

class SanTerraApp extends StatelessWidget {
  const SanTerraApp({
    super.key,
    required this.themeManager,
    required this.sound,
    required this.score,
    required this.settings,
  });

  final ThemeManager themeManager;
  final SoundManager sound;
  final ScoreManager score;
  final SettingsManager settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
        ChangeNotifierProvider<SoundManager>.value(value: sound),
        ChangeNotifierProvider<ScoreManager>.value(value: score),
        ChangeNotifierProvider<SettingsManager>.value(value: settings),
      ],
      child: ListenableBuilder(
        listenable: themeManager,
        builder: (context, _) {
          final theme = themeManager.config;
          return MaterialApp(
            title: 'SanTerra',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: theme.buttonFill,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const TitleScene(),
          );
        },
      ),
    );
  }
}
