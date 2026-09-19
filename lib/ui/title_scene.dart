import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sound_manager.dart';
import '../game/game_mode.dart';
import '../game/score_manager.dart';
import '../game/settings_manager.dart';
import '../theme/game_theme_config.dart';
import '../theme/theme_manager.dart';
import 'game_scene.dart';
import 'painters/field_painter.dart';
import 'painters/frame_painter.dart';
import 'settings_scene.dart';

class TitleScene extends StatefulWidget {
  const TitleScene({super.key});

  @override
  State<TitleScene> createState() => _TitleSceneState();
}

class _TitleSceneState extends State<TitleScene> {
  ui.Image? _worldImage;
  GameThemeId? _loadedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final theme = context.read<ThemeManager>().config;
      context.read<SoundManager>().playBgm(theme);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWorld(context.read<ThemeManager>().config);
  }

  Future<void> _loadWorld(GameThemeConfig theme) async {
    if (_loadedFor == theme.id) {
      return;
    }
    _loadedFor = theme.id;
    final image = await loadOptionalImage(theme.worldImageAsset);
    if (!mounted) {
      return;
    }
    setState(() => _worldImage = image);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final sound = context.watch<SoundManager>();
    final score = context.watch<ScoreManager>();
    final theme = themeManager.config;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: WorldBackgroundPainter(theme, _worldImage),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScene(),
                          ),
                        );
                      },
                      color: theme.buttonText,
                      icon: const Icon(Icons.settings),
                      tooltip: 'SETTINGS',
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'SanTerra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.buttonText,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '砂の物理パズル',
                          style: TextStyle(
                            color: theme.buttonText.withValues(alpha: 0.9),
                            fontSize: 16,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${score.mode.label}  HIGH SCORE  ${score.highScore}',
                          style: TextStyle(
                            color: theme.buttonText.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                            builder: (_) => GameScene(
                              themeManager: themeManager,
                              sound: sound,
                              score: score,
                              mode: score.mode,
                              settings: context.read<SettingsManager>(),
                            ),
                            ),
                          );
                          if (context.mounted) {
                            await sound.playBgm(themeManager.config);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.buttonFill,
                          foregroundColor: theme.buttonText,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        child: const Text('START'),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'MODE',
                            style: TextStyle(
                              color: theme.buttonText.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeCard(
                                mode: GameMode.normal,
                                selected: score.mode == GameMode.normal,
                                theme: theme,
                                onTap: () => score.setMode(GameMode.normal),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModeCard(
                                mode: GameMode.infinity,
                                selected: score.mode == GameMode.infinity,
                                theme: theme,
                                onTap: () => score.setMode(GameMode.infinity),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'THEME',
                            style: TextStyle(
                              color: theme.buttonText.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ThemeCard(
                                config: GameThemeConfig.atelier,
                                selected: theme.id == GameThemeId.atelier,
                                onTap: () async {
                                  await themeManager.setTheme(GameThemeId.atelier);
                                  if (context.mounted) {
                                    await sound.playBgm(GameThemeConfig.atelier);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ThemeCard(
                                config: GameThemeConfig.resort,
                                selected: theme.id == GameThemeId.resort,
                                onTap: () async {
                                  await themeManager.setTheme(GameThemeId.resort);
                                  if (context.mounted) {
                                    await sound.playBgm(GameThemeConfig.resort);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _SoundToggle(
                          label: 'BGM',
                          value: sound.bgmOn,
                          theme: theme,
                          onChanged: (v) async {
                            await sound.setBgmOn(v);
                            if (v && context.mounted) {
                              await sound.playBgm(themeManager.config);
                            }
                          },
                        ),
                        _SoundToggle(
                          label: 'SE',
                          value: sound.seOn,
                          theme: theme,
                          onChanged: sound.setSeOn,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final GameMode mode;
  final bool selected;
  final GameThemeConfig theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.uiPanel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? theme.frameAccent : theme.uiPanelBorder,
              width: selected ? 2.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode.label,
                style: TextStyle(
                  color: theme.uiText,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mode.description,
                style: TextStyle(color: theme.uiMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.config,
    required this.selected,
    required this.onTap,
  });

  final GameThemeConfig config;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: config.uiPanel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? config.frameAccent : config.uiPanelBorder,
              width: selected ? 2.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: config.canvasGradient),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                config.displayName,
                style: TextStyle(
                  color: config.uiText,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                config.tagline,
                style: TextStyle(color: config.uiMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle({
    required this.label,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final GameThemeConfig theme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        label,
        style: TextStyle(
          color: theme.buttonText,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.all(theme.frameAccent),
    );
  }
}
