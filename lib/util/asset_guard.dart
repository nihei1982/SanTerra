import 'package:flutter/services.dart';

/// Looks up bundled assets so missing BGM/SE/images never crash the game.
class AssetGuard {
  AssetGuard._();

  static Set<String> _assets = {};
  static bool _loaded = false;

  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
    } catch (_) {
      _assets = {};
    }
    _loaded = true;
  }

  static bool exists(String? path) {
    if (path == null || path.isEmpty || !_loaded) {
      return false;
    }
    if (_assets.contains(path)) {
      return true;
    }
    // audioplayers AssetSource is relative to the assets folder.
    if (_assets.contains('assets/$path')) {
      return true;
    }
    return false;
  }

  static String? playableAudioSource(String? path) {
    if (!exists(path) || path == null) {
      return null;
    }
    if (path.startsWith('assets/')) {
      return path.substring('assets/'.length);
    }
    return path;
  }
}
