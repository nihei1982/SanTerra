import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../audio/sound_manager.dart';
import '../models/sand_model.dart';
import '../physics/field_manager.dart';
import '../physics/sand_physics_engine.dart';
import '../theme/game_theme_config.dart';
import '../theme/theme_manager.dart';
import 'game_mode.dart';
import 'score_manager.dart';
import 'settings_manager.dart';

enum PlayPhase { idle, aiming, falling, settling, clearing, quaking, paused, gameOver }

/// Owns the run loop, input lock, chain reactions, pause/lifecycle, and scoring.
class GameController extends ChangeNotifier with WidgetsBindingObserver {
  GameController({
    required this.themeManager,
    required this.sound,
    required this.score,
    required this.settings,
    this.mode = GameMode.normal,
    SandPhysicsEngine? engine,
    int? seed,
  })  : physics = engine ?? SandPhysicsEngine(seed: seed),
        field = FieldManager(),
        _rng = Random(seed) {
    nextPiece = _rollPiece();
  }

  final ThemeManager themeManager;
  final SoundManager sound;
  final ScoreManager score;
  final SettingsManager settings;
  final GameMode mode;
  final SandPhysicsEngine physics;
  final FieldManager field;
  final Random _rng;

  GameThemeConfig get theme => themeManager.config;

  PlayPhase phase = PlayPhase.idle;
  PlayPhase _phaseBeforePause = PlayPhase.idle;

  late SandModel nextPiece;
  FallingCluster? falling;
  double? aimCellX;
  Offset? pointerLocal;
  bool pointerInCancelZone = false;

  final Set<int> clearingCells = {};
  double clearT = 0;
  int chainCount = 0;
  int lastClearPoints = 0;
  String? banner;
  double bannerT = 0;
  int sparkleSeed = 1;
  double _sparkleAcc = 0;
  int _stillFrames = 0;
  double _slideCooldown = 0;
  Duration _lastElapsed = Duration.zero;
  bool _bound = false;
  double scrollY = 0;
  int dropCount = 0;
  bool _quakeArmed = false;
  double quakeT = 0;
  static const quakeDuration = 1.0;

  double get quakeGauge {
    if (!settings.earthquake) {
      return 0;
    }
    if (_quakeArmed || phase == PlayPhase.quaking) {
      return 1;
    }
    return (dropCount % SettingsManager.quakeEveryDrops) /
        SettingsManager.quakeEveryDrops;
  }

  Offset get shakeOffset {
    if (phase != PlayPhase.quaking) {
      return Offset.zero;
    }
    final mag = 12.0;
    return Offset(sin(quakeT * 92) * mag, cos(quakeT * 78) * mag * 0.75);
  }

  int get visibleRows => physics.baseRows;

  double get maxScrollY => max(0, physics.rows - visibleRows).toDouble();

  bool get canScroll => mode == GameMode.infinity && maxScrollY > 0.5;

  bool get isInfinity => mode == GameMode.infinity;

  bool get isBusy =>
      phase == PlayPhase.falling ||
      phase == PlayPhase.settling ||
      phase == PlayPhase.clearing ||
      phase == PlayPhase.quaking;

  bool get acceptsInput =>
      phase == PlayPhase.idle || phase == PlayPhase.aiming;

  bool get showPauseOverlay => phase == PlayPhase.paused;

  bool get showGameOverOverlay => phase == PlayPhase.gameOver;

  void bindLifecycle() {
    if (_bound) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _bound = true;
  }

  @override
  void dispose() {
    if (_bound) {
      WidgetsBinding.instance.removeObserver(this);
      _bound = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (phase == PlayPhase.gameOver) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      pauseGame(fromLifecycle: true);
    }
  }

  Future<void> startSession() async {
    score.resetCurrent();
    physics.clear();
    clearingCells.clear();
    falling = null;
    aimCellX = null;
    pointerLocal = null;
    pointerInCancelZone = false;
    chainCount = 0;
    lastClearPoints = 0;
    banner = null;
    scrollY = 0;
    dropCount = 0;
    _quakeArmed = false;
    quakeT = 0;
    nextPiece = _rollPiece();
    phase = PlayPhase.idle;
    unawaited(sound.playBgm(theme));
    notifyListeners();
  }

  void tick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    var dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) {
      return;
    }
    dt = min(dt, 1 / 20);

    if (phase == PlayPhase.paused || phase == PlayPhase.gameOver) {
      return;
    }
    if (phase == PlayPhase.quaking) {
      quakeT += dt;
    }

    _sparkleAcc += dt;
    if (_sparkleAcc > 0.08) {
      _sparkleAcc = 0;
      sparkleSeed++;
    }
    if (_slideCooldown > 0) {
      _slideCooldown -= dt;
    }
    if (banner != null) {
      bannerT -= dt;
      if (bannerT <= 0) {
        banner = null;
      }
    }

    final simulating = phase == PlayPhase.falling ||
        phase == PlayPhase.settling ||
        phase == PlayPhase.clearing ||
        phase == PlayPhase.quaking;

    switch (phase) {
      case PlayPhase.falling:
        _tickFalling(dt);
      case PlayPhase.settling:
        _tickSettling();
      case PlayPhase.clearing:
        _tickClearing(dt);
      case PlayPhase.quaking:
        _tickQuake();
      default:
        break;
    }
    if (simulating || banner != null) {
      notifyListeners();
    }
  }

  void setScrollY(double value) {
    final next = value.clamp(0, maxScrollY).toDouble();
    if ((next - scrollY).abs() < 0.001) {
      return;
    }
    scrollY = next;
    notifyListeners();
  }

  void scrollByCells(double delta) => setScrollY(scrollY + delta);

  void beginAim(Offset local, Size canvasSize, {required bool inCancelZone}) {
    if (!acceptsInput) {
      return;
    }
    if (isInfinity && scrollY > 0.2) {
      setScrollY(0);
    }
    phase = PlayPhase.aiming;
    pointerLocal = local;
    pointerInCancelZone = inCancelZone;
    aimCellX = _localToCellX(local.dx, canvasSize.width);
    notifyListeners();
  }

  void updateAim(Offset local, Size canvasSize, {required bool inCancelZone}) {
    if (phase != PlayPhase.aiming) {
      return;
    }
    pointerLocal = local;
    pointerInCancelZone = inCancelZone;
    aimCellX = _localToCellX(local.dx, canvasSize.width);
    notifyListeners();
  }

  void cancelAim() {
    if (phase == PlayPhase.aiming) {
      _cancelAim();
    }
  }

  void releaseAim() {
    if (phase != PlayPhase.aiming) {
      return;
    }
    if (pointerInCancelZone || aimCellX == null) {
      _cancelAim();
      return;
    }
    falling = FallingCluster(
      model: nextPiece,
      x: aimCellX!,
      y: 1.2,
    );
    dropCount++;
    if (settings.earthquake && dropCount % SettingsManager.quakeEveryDrops == 0) {
      _quakeArmed = true;
    }
    nextPiece = _rollPiece();
    aimCellX = null;
    pointerLocal = null;
    pointerInCancelZone = false;
    chainCount = 0;
    lastClearPoints = 0;
    phase = PlayPhase.falling;
    notifyListeners();
  }

  void pauseGame({bool fromLifecycle = false}) {
    if (phase == PlayPhase.paused || phase == PlayPhase.gameOver) {
      if (fromLifecycle) {
        unawaited(sound.pauseAll());
      }
      return;
    }
    if (phase == PlayPhase.aiming) {
      aimCellX = null;
      pointerLocal = null;
      pointerInCancelZone = false;
      _phaseBeforePause = PlayPhase.idle;
    } else {
      _phaseBeforePause = phase;
    }
    phase = PlayPhase.paused;
    unawaited(sound.pauseAll());
    notifyListeners();
  }

  void resumeGame() {
    if (phase != PlayPhase.paused) {
      return;
    }
    phase = _phaseBeforePause == PlayPhase.paused
        ? PlayPhase.idle
        : _phaseBeforePause;
    unawaited(sound.playBgm(theme));
    notifyListeners();
  }

  Future<void> restartGame() async {
    await startSession();
  }

  void _cancelAim() {
    phase = PlayPhase.idle;
    aimCellX = null;
    pointerLocal = null;
    pointerInCancelZone = false;
    notifyListeners();
  }

  void _tickFalling(double dt) {
    final cluster = falling;
    if (cluster == null) {
      phase = PlayPhase.settling;
      return;
    }
    const gravity = 240.0;
    cluster.vy = min(cluster.vy + gravity * dt, 90);
    var remaining = cluster.vy * dt;
    while (remaining > 0) {
      final step = min(0.35, remaining);
      remaining -= step;
      cluster.y += step;
      if (_clusterHits(cluster)) {
        cluster.y -= step;
        physics.stampCluster(cluster);
        falling = null;
        unawaited(sound.playSe(theme.seSandDrop));
        phase = PlayPhase.settling;
        _stillFrames = 0;
        return;
      }
    }
  }

  bool _clusterHits(FallingCluster cluster) {
    for (final offset in cluster.model.offsets) {
      final gx = (cluster.x + offset.x).round().clamp(0, physics.cols - 1);
      final gy = (cluster.y + offset.y).floor();
      if (gy >= physics.rows - 1) {
        return true;
      }
      if (gy >= 0 && physics.isSolid(gx, gy + 1)) {
        return true;
      }
    }
    return false;
  }

  void _tickSettling() {
    final before = physics.countSand();
    final moved = physics.stepMany(3);
    if (moved && _slideCooldown <= 0 && physics.countSand() == before) {
      unawaited(sound.playSe(theme.seSandSlide));
      _slideCooldown = 0.22;
    }
    if (moved) {
      _stillFrames = 0;
      return;
    }
    _stillFrames++;
    if (_stillFrames < 2) {
      return;
    }
    _onFullySettled();
  }

  void _onFullySettled() {
    final spanning = field.findSpanningGroups(physics);
    if (spanning.isNotEmpty) {
      _beginClear(spanning);
      return;
    }
    chainCount = 0;
    if (_quakeArmed) {
      _startQuake();
      return;
    }
    _finishIdleOrFail();
  }

  void _startQuake() {
    _quakeArmed = false;
    quakeT = 0;
    banner = 'EARTHQUAKE';
    bannerT = 1.0;
    phase = PlayPhase.quaking;
    unawaited(sound.playSe(theme.seSandSlide));
  }

  void _tickQuake() {
    physics.stepFlatten(moves: 280);
    if (quakeT >= quakeDuration) {
      quakeT = 0;
      _onFullySettled();
    }
  }

  void _finishIdleOrFail() {
    if (isInfinity) {
      if (physics.isNearCeiling() && physics.extraDepth < SandPhysicsEngine.maxExtraRows) {
        physics.expandBottom();
        _stillFrames = 0;
        phase = PlayPhase.settling;
        return;
      }
      if (physics.extraDepth > 0) {
        physics.shrinkEmptyTop();
        setScrollY(scrollY);
      }
      phase = PlayPhase.idle;
      return;
    }
    if (field.hasReachedTop(physics)) {
      phase = PlayPhase.gameOver;
      unawaited(score.persistHighScore());
      unawaited(sound.pauseAll());
      return;
    }
    phase = PlayPhase.idle;
  }

  void _beginClear(List<ConnectedGroup> spanning) {
    chainCount += 1;
    clearingCells
      ..clear()
      ..addAll([
        for (final group in spanning)
          for (final cell in group.cells)
            physics.index(cell.$1, cell.$2),
      ]);
    lastClearPoints = ScoreManager.pointsFor(clearingCells.length, chainCount);
    score.add(lastClearPoints);
    clearT = 0;
    phase = PlayPhase.clearing;
    unawaited(sound.playSe(theme.seClear));
    if (chainCount >= 2) {
      banner = 'CHAIN $chainCount';
      bannerT = 1.1;
      unawaited(sound.playSe(theme.seChain));
    }
  }

  void _tickClearing(double dt) {
    clearT += dt;
    if (clearT < 0.38) {
      return;
    }
    for (final i in clearingCells) {
      physics.cells[i] = 0;
    }
    clearingCells.clear();
    _stillFrames = 0;
    phase = PlayPhase.settling;
  }

  double _localToCellX(double localX, double width) {
    if (width <= 0) {
      return physics.cols / 2;
    }
    final cell = localX / width * physics.cols;
    return cell.clamp(2, physics.cols - 3);
  }

  SandModel _rollPiece() {
    return SandModel.random(
      _rng,
      colorCount: settings.colorCount,
      sizeTypes: settings.sizeTypes,
    );
  }
}
