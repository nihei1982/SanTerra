import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/game_theme_config.dart';
import '../util/asset_guard.dart';

/// BGM / SE playback with missing-asset guards and theme-aware BGM paths.
class SoundManager extends ChangeNotifier {
  SoundManager(this._prefs, {this.enableAudio = true});

  static const _bgmKey = 'santerra_bgm_on';
  static const _seKey = 'santerra_se_on';
  static const _bgmVolume = 0.62;
  static const _seVolume = 0.22;

  final SharedPreferences _prefs;
  final bool enableAudio;

  AudioPlayer? _bgm;
  List<AudioPlayer>? _sePool;
  int _seIndex = 0;

  bool _bgmOn = true;
  bool _seOn = true;
  String? _currentBgm;
  bool _bgmPaused = false;
  bool _playersReady = false;
  bool _suspended = false;
  Future<void>? _ensurePlayersFuture;

  static final AudioContext _mixContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  bool get bgmOn => _bgmOn;
  bool get seOn => _seOn;

  void setSuspended(bool value) {
    _suspended = value;
  }

  Future<void> init() async {
    _bgmOn = _prefs.getBool(_bgmKey) ?? true;
    _seOn = _prefs.getBool(_seKey) ?? true;
    if (!enableAudio) {
      return;
    }
    await _ensurePlayers();
  }

  Future<void> _ensurePlayers() async {
    if (!enableAudio || _playersReady) {
      return;
    }
    _ensurePlayersFuture ??= _createPlayers();
    await _ensurePlayersFuture;
  }

  Future<void> _createPlayers() async {
    await AudioPlayer.global.setAudioContext(_mixContext);
    final bgm = AudioPlayer();
    await bgm.setAudioContext(_mixContext);
    await bgm.setReleaseMode(ReleaseMode.loop);
    await bgm.setVolume(_bgmVolume);
    _bgm = bgm;

    final pool = <AudioPlayer>[];
    for (var i = 0; i < 4; i++) {
      final se = AudioPlayer();
      await se.setAudioContext(_mixContext);
      await se.setReleaseMode(ReleaseMode.stop);
      await se.setVolume(_seVolume);
      pool.add(se);
    }
    _sePool = pool;
    _playersReady = true;
  }

  Future<void> setBgmOn(bool value) async {
    _bgmOn = value;
    await _prefs.setBool(_bgmKey, value);
    if (!value) {
      await _bgm?.stop();
      _currentBgm = null;
      _bgmPaused = false;
    }
    notifyListeners();
  }

  Future<void> setSeOn(bool value) async {
    _seOn = value;
    await _prefs.setBool(_seKey, value);
    notifyListeners();
  }

  Future<void> playBgm(GameThemeConfig theme) async {
    if (!enableAudio || _suspended) {
      return;
    }
    final source = AssetGuard.playableAudioSource(theme.bgmAsset);
    if (!_bgmOn || source == null) {
      await _bgm?.stop();
      _currentBgm = null;
      return;
    }
    if (_currentBgm == source && !_bgmPaused) {
      return;
    }
    try {
      await _ensurePlayers();
      await _bgm?.setAudioContext(_mixContext);
      await _bgm?.stop();
      await _bgm?.setVolume(_bgmVolume);
      await _bgm?.play(AssetSource(source));
      _currentBgm = source;
      _bgmPaused = false;
    } catch (_) {
      _currentBgm = null;
    }
  }

  Future<void> pauseAll() async {
    if (!enableAudio) {
      return;
    }
    try {
      _bgmPaused = true;
      await _bgm?.stop();
      if (_sePool != null) {
        for (final player in _sePool!) {
          await player.stop();
        }
      }
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!enableAudio || !_bgmOn || _currentBgm == null) {
      return;
    }
    try {
      await _bgm?.resume();
      _bgmPaused = false;
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgm?.stop();
    } catch (_) {}
    _currentBgm = null;
    _bgmPaused = false;
  }

  Future<void> playSe(String? path) async {
    if (!enableAudio || _suspended) {
      return;
    }
    final source = AssetGuard.playableAudioSource(path);
    if (!_seOn || source == null) {
      return;
    }
    try {
      await _ensurePlayers();
      final pool = _sePool;
      if (pool == null || pool.isEmpty) {
        return;
      }
      final player = pool[_seIndex];
      _seIndex = (_seIndex + 1) % pool.length;
      await player.stop();
      await player.setAudioContext(_mixContext);
      await player.setVolume(_seVolume);
      await player.play(AssetSource(source));
    } catch (_) {}
  }

  Future<void> disposePlayers() async {
    await _bgm?.dispose();
    if (_sePool != null) {
      for (final player in _sePool!) {
        await player.dispose();
      }
    }
    _bgm = null;
    _sePool = null;
    _playersReady = false;
    _suspended = false;
    _ensurePlayersFuture = null;
  }
}
