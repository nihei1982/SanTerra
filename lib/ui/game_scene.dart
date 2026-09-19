import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/sound_manager.dart';
import '../game/game_controller.dart';
import '../game/game_mode.dart';
import '../game/score_manager.dart';
import '../game/settings_manager.dart';
import '../theme/theme_manager.dart';
import 'game_canvas_widget.dart';
import 'overlays/game_dialogs.dart';
import 'painters/field_painter.dart';
import 'painters/frame_painter.dart';
import 'settings_scene.dart';
import 'widgets/next_preview.dart';

class GameScene extends StatefulWidget {
  const GameScene({
    super.key,
    required this.themeManager,
    required this.sound,
    required this.score,
    required this.mode,
    required this.settings,
  });

  final ThemeManager themeManager;
  final SoundManager sound;
  final ScoreManager score;
  final GameMode mode;
  final SettingsManager settings;

  @override
  State<GameScene> createState() => _GameSceneState();
}

class _GameSceneState extends State<GameScene> with SingleTickerProviderStateMixin {
  late final GameController _controller;
  late final Ticker _ticker;
  ui.Image? _worldImage;
  ui.Image? _canvasImage;
  ui.Image? _frameImage;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      themeManager: widget.themeManager,
      sound: widget.sound,
      score: widget.score,
      settings: widget.settings,
      mode: widget.mode,
    )..bindLifecycle();
    _ticker = createTicker(_controller.tick)..start();
    _controller.startSession();
    _controller.addListener(_onTick);
    _loadThemeImages();
  }

  Future<void> _loadThemeImages() async {
    final theme = widget.themeManager.config;
    final world = await loadOptionalImage(theme.worldImageAsset);
    final canvas = await loadOptionalImage(theme.canvasImageAsset);
    final frame = await loadOptionalImage(theme.frameImageAsset);
    if (!mounted) {
      return;
    }
    setState(() {
      _worldImage = world;
      _canvasImage = canvas;
      _frameImage = frame;
    });
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _controller.theme;
    final media = MediaQuery.of(context);
    final cancelY = media.size.height * 0.10;

    return Scaffold(
      body: Transform.translate(
        offset: _controller.shakeOffset,
        child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: WorldBackgroundPainter(theme, _worldImage),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      NextPreview(piece: _controller.nextPiece, theme: theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _controller.mode.label,
                              style: TextStyle(
                                color: theme.buttonText.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            Text(
                              'SCORE',
                              style: TextStyle(
                                color: theme.buttonText.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            Text(
                              '${widget.score.current}',
                              style: TextStyle(
                                color: theme.buttonText,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'HI  ${widget.score.highScore}',
                              style: TextStyle(
                                color: theme.buttonText.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            if (_controller.isInfinity &&
                                _controller.physics.extraDepth > 0)
                              Text(
                                'DEPTH +${_controller.physics.extraDepth}',
                                style: TextStyle(
                                  color: theme.frameAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.settings.earthquake) ...[
                        _QuakeGauge(
                          progress: _controller.quakeGauge,
                          shaking: _controller.phase == PlayPhase.quaking,
                          pulse: _controller.quakeT,
                        ),
                        const SizedBox(width: 10),
                      ],
                      IconButton.filled(
                        onPressed: _controller.phase == PlayPhase.gameOver
                            ? null
                            : () => _controller.pauseGame(),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.buttonFill,
                          foregroundColor: theme.buttonText,
                        ),
                        icon: const Icon(Icons.pause),
                        tooltip: 'PAUSE',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: CustomPaint(
                      painter: FramePainter(theme: theme, frameImage: _frameImage),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GameCanvasWidget(
                            controller: _controller,
                            cancelThresholdGlobalY: cancelY,
                            canvasImage: _canvasImage,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_controller.phase == PlayPhase.aiming)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cancelY,
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x14B71C1C).withValues(
                    alpha: _controller.pointerInCancelZone ? 0.22 : 0.08,
                  ),
                ),
              ),
            ),
          if (_controller.banner != null)
            Center(
              child: IgnorePointer(
                child: Text(
                  _controller.banner!,
                  style: TextStyle(
                    color: theme.buttonText,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          if (_controller.lastClearPoints > 0 &&
              _controller.phase == PlayPhase.clearing)
            Positioned(
              top: media.size.height * 0.22,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  '+${_controller.lastClearPoints}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.frameAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
              ),
            ),
          if (_controller.showPauseOverlay)
            PauseOverlay(
              theme: theme,
              onResume: _controller.resumeGame,
              onRestart: () => _controller.restartGame(),
              onSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScene(),
                  ),
                );
              },
              onTitle: () => Navigator.of(context).pop(),
            ),
          if (_controller.showGameOverOverlay)
            GameOverOverlay(
              theme: theme,
              score: widget.score.current,
              highScore: widget.score.highScore,
              onRetry: () => _controller.restartGame(),
              onTitle: () => Navigator.of(context).pop(),
            ),
        ],
        ),
      ),
    );
  }
}

class _QuakeGauge extends StatelessWidget {
  const _QuakeGauge({
    required this.progress,
    required this.shaking,
    required this.pulse,
  });

  final double progress;
  final bool shaking;
  final double pulse;

  Color get _fillColor {
    if (shaking) {
      final flash = (sin(pulse * 24) + 1) / 2;
      return Color.lerp(const Color(0xFF8E0000), const Color(0xFFFF1744), flash)!;
    }
    final t = progress.clamp(0.0, 1.0);
    if (t < 0.5) {
      return Color.lerp(const Color(0xFF1E88E5), const Color(0xFFFF6D00), t * 2)!;
    }
    return Color.lerp(const Color(0xFFFF6D00), const Color(0xFFE53935), (t - 0.5) * 2)!;
  }

  @override
  Widget build(BuildContext context) {
    final color = _fillColor;
    const barHeight = 18.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'QUAKE',
          style: TextStyle(
            color: color.withValues(alpha: 0.95),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          height: barHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barHeight / 2),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                const ColoredBox(
                  color: Color(0x66000000),
                  child: SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: color),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    border: Border.all(color: Colors.white24, width: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
