import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sound_manager.dart';
import '../game/game_mode.dart';
import '../game/score_manager.dart';
import '../game/settings_manager.dart';
import '../l10n/app_strings_scope.dart';
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
    final s = context.strings;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          WorldBackdrop(theme: theme, worldImage: _worldImage),
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
                      color: theme.uiText,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.uiPanel,
                      ),
                      icon: const Icon(Icons.settings),
                      tooltip: s.settings,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        _Headline(
                          'SanTerra',
                          theme: theme,
                          fontSize: 48,
                          letterSpacing: 1.5,
                        ),
                        const SizedBox(height: 6),
                        _Headline(
                          s.tagline,
                          theme: theme,
                          fontSize: 16,
                          letterSpacing: 4,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(height: 10),
                        _Headline(
                          s.highScoreLine(score.mode.label, score.highScore),
                          theme: theme,
                          fontSize: 14,
                          letterSpacing: 0.6,
                          weight: FontWeight.w700,
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
                        child: Text(s.start),
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
                          child: _Headline(
                            s.mode,
                            theme: theme,
                            fontSize: 12,
                            letterSpacing: 2,
                            weight: FontWeight.w800,
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
                                description: s.modeDescription(GameMode.normal),
                                onTap: () => score.setMode(GameMode.normal),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModeCard(
                                mode: GameMode.infinity,
                                selected: score.mode == GameMode.infinity,
                                theme: theme,
                                description: s.modeDescription(GameMode.infinity),
                                onTap: () => score.setMode(GameMode.infinity),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _Headline(
                            s.theme,
                            theme: theme,
                            fontSize: 12,
                            letterSpacing: 2,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ThemeCard(
                                config: GameThemeConfig.atelier,
                                selected: theme.id == GameThemeId.atelier,
                                name: s.themeName(GameThemeId.atelier),
                                tagline: s.themeTagline(GameThemeId.atelier),
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
                                name: s.themeName(GameThemeId.resort),
                                tagline: s.themeTagline(GameThemeId.resort),
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
                          label: s.bgm,
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
                          label: s.se,
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

class _Headline extends StatelessWidget {
  const _Headline(
    this.text, {
    required this.theme,
    required this.fontSize,
    this.letterSpacing = 0,
    this.weight = FontWeight.w900,
  });

  final String text;
  final GameThemeConfig theme;
  final double fontSize;
  final double letterSpacing;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final fill = theme.uiText;
    final outline = theme.id == GameThemeId.atelier
        ? const Color(0xF2FFFFFF)
        : const Color(0xE6081228);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize > 30 ? 8 : 4.5
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: fill),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.theme,
    required this.description,
    required this.onTap,
  });

  final GameMode mode;
  final bool selected;
  final GameThemeConfig theme;
  final String description;
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
                description,
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
    required this.name,
    required this.tagline,
    required this.onTap,
  });

  final GameThemeConfig config;
  final bool selected;
  final String name;
  final String tagline;
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
                name,
                style: TextStyle(
                  color: config.uiText,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                tagline,
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme.uiText,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.all(theme.frameAccent),
        ),
      ],
    );
  }
}
