import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sand_amount.dart';
import '../models/sand_kind.dart';

class SettingsManager extends ChangeNotifier {
  SettingsManager(this._prefs) {
    colorCount = (_prefs.getInt(_colorKey) ?? defaultColorCount).clamp(minColorCount, maxColorCount);
    sizeTypes = (_prefs.getInt(_sizeKey) ?? defaultSizeTypes).clamp(minSizeTypes, maxSizeTypes);
    earthquake = _prefs.getBool(_quakeKey) ?? false;
  }

  static const defaultColorCount = 4;
  static const minColorCount = 3;
  static const maxColorCount = 8;
  static const defaultSizeTypes = 4;
  static const minSizeTypes = 1;
  static const maxSizeTypes = 4;
  static const quakeEveryDrops = 10;

  static const _colorKey = 'santerra_color_count';
  static const _sizeKey = 'santerra_size_types';
  static const _quakeKey = 'santerra_earthquake';

  final SharedPreferences _prefs;

  late int colorCount;
  late int sizeTypes;
  late bool earthquake;

  List<SandKind> get activeColors => SandKind.palette(colorCount);

  List<SandAmount> get activeSizes =>
      SandAmount.values.take(sizeTypes.clamp(minSizeTypes, maxSizeTypes)).toList(growable: false);

  String get sizeSummary => activeSizes.map((s) => s.label).join(' / ');

  Future<void> setColorCount(int value) async {
    final next = value.clamp(minColorCount, maxColorCount);
    if (next == colorCount) {
      return;
    }
    colorCount = next;
    await _prefs.setInt(_colorKey, colorCount);
    notifyListeners();
  }

  Future<void> setSizeTypes(int value) async {
    final next = value.clamp(minSizeTypes, maxSizeTypes);
    if (next == sizeTypes) {
      return;
    }
    sizeTypes = next;
    await _prefs.setInt(_sizeKey, sizeTypes);
    notifyListeners();
  }

  Future<void> setEarthquake(bool value) async {
    if (earthquake == value) {
      return;
    }
    earthquake = value;
    await _prefs.setBool(_quakeKey, earthquake);
    notifyListeners();
  }
}
