import 'package:flutter/material.dart';

/// Sand pigments. The first four are the default set; settings can enable up to eight.
enum SandKind {
  red(Color(0xFFFF3333)),
  blue(Color(0xFF3366FF)),
  green(Color(0xFF33CC33)),
  yellow(Color(0xFFFFCC00)),
  orange(Color(0xFFFF8800)),
  purple(Color(0xFFAA44FF)),
  cyan(Color(0xFF22DDDD)),
  pink(Color(0xFFFF66AA));

  const SandKind(this.color);

  final Color color;

  /// Grid cell value. 0 is reserved for empty.
  int get cellValue => index + 1;

  static SandKind? fromCell(int value) {
    if (value <= 0 || value > SandKind.values.length) {
      return null;
    }
    return SandKind.values[value - 1];
  }

  static List<SandKind> palette(int colorCount) {
    final n = colorCount.clamp(3, SandKind.values.length);
    return SandKind.values.take(n).toList(growable: false);
  }
}
