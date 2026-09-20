import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio/sound_manager.dart';
import 'game/score_manager.dart';
import 'game/settings_manager.dart';
import 'theme/theme_manager.dart';
import 'ui/title_scene.dart';

class SanTerraApp extends StatefulWidget {
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
  State<SanTerraApp> createState() => _SanTerraAppState();
}

class _SanTerraAppState extends State<SanTerraApp> with WidgetsBindingObserver {
  final _navKey = GlobalKey<NavigatorState>();
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.sound.setSuspended(false);
        if (mounted && !_foreground) {
          setState(() => _foreground = true);
        }
        _resumeTitleBgm();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.sound.setSuspended(true);
        unawaited(widget.sound.pauseAll());
        if (mounted && _foreground) {
          setState(() => _foreground = false);
        }
    }
  }

  void _resumeTitleBgm() {
    final nav = _navKey.currentState;
    if (nav == null || nav.canPop()) {
      return;
    }
    unawaited(widget.sound.playBgm(widget.themeManager.config));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: widget.themeManager),
        ChangeNotifierProvider<SoundManager>.value(value: widget.sound),
        ChangeNotifierProvider<ScoreManager>.value(value: widget.score),
        ChangeNotifierProvider<SettingsManager>.value(value: widget.settings),
      ],
      child: TickerMode(
        enabled: _foreground,
        child: ListenableBuilder(
          listenable: widget.themeManager,
          builder: (context, _) {
            final theme = widget.themeManager.config;
            return MaterialApp(
              navigatorKey: _navKey,
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
      ),
    );
  }
}
