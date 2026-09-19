import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/game_controller.dart';
import '../../models/sand_kind.dart';
import '../../models/sand_model.dart';
import '../../theme/game_theme_config.dart';
import '../../util/asset_guard.dart';
import '../../util/cell_noise.dart';

/// Playfield renderer: themed paper, piled sand, peek-through grain noise, drop guide.
class FieldPainter extends CustomPainter {
  FieldPainter({
    required this.controller,
    this.canvasImage,
  });

  final GameController controller;
  final ui.Image? canvasImage;

  @override
  void paint(Canvas canvas, Size size) {
    final physics = controller.physics;
    final cols = physics.cols;
    final visibleRows = controller.visibleRows;
    final cellW = size.width / cols;
    final cellH = size.height / visibleRows;
    final scroll = controller.scrollY;
    final theme = controller.theme;

    _paintBackdrop(canvas, size, theme);

    for (var wy = 0; wy < physics.rows; wy++) {
      final screenY = wy - scroll;
      if (screenY < -1 || screenY > visibleRows) {
        continue;
      }
      for (var x = 0; x < cols; x++) {
        final i = physics.index(x, wy);
        final value = physics.cells[i];
        if (value == 0) {
          continue;
        }
        _paintGrain(
          canvas,
          x,
          wy,
          screenY,
          cellW,
          cellH,
          value,
          controller.clearingCells.contains(i),
        );
      }
    }

    final falling = controller.falling;
    if (falling != null) {
      _paintCluster(canvas, falling, cellW, cellH, 1, scroll);
    }

    _paintKillLine(canvas, size, cellH, scroll);

    controller.worm?.paint(
      canvas,
      cellW: cellW,
      cellH: cellH,
      scroll: scroll,
    );

    if (controller.phase == PlayPhase.aiming && controller.aimCellX != null) {
      _paintGuide(canvas, size, cellW, cellH, scroll);
    }
  }

  void _paintKillLine(Canvas canvas, Size size, double cellH, double scroll) {
    final y = 2.5 - scroll * cellH;
    if (y < -6 || y > size.height + 6) {
      return;
    }
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0x88FF1744)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    final dash = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(min(x + 10, size.width), y), dash);
      x += 16;
    }
  }

  void _paintBackdrop(Canvas canvas, Size size, GameThemeConfig theme) {
    final rect = Offset.zero & size;
    if (canvasImage != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: canvasImage!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.canvasGradient,
          ).createShader(rect),
      );
    }

    final line = Paint()
      ..color = theme.paperLine
      ..strokeWidth = 1;
    for (var i = 1; i < 12; i++) {
      final y = size.height * (i / 12);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (var s = 0; s < 180; s++) {
      final nx = cellNoise(s, 3, 11);
      final ny = cellNoise(s, 7, 19);
      canvas.drawCircle(
        Offset(nx * size.width, ny * size.height),
        0.6 + cellNoise(s, 9, 4) * 1.4,
        Paint()..color = theme.paperLine.withValues(alpha: 0.18),
      );
    }
  }

  void _paintGrain(
    Canvas canvas,
    int x,
    int worldY,
    double screenY,
    double cellW,
    double cellH,
    int value,
    bool clearing,
  ) {
    final kind = SandKind.fromCell(value);
    if (kind == null) {
      return;
    }
    if (!controller.settings.sparkle) {
      var color = kind.color;
      if (clearing) {
        final flash = 0.45 + 0.45 * sin(controller.clearT * 22);
        color = Color.lerp(color, Colors.white, flash)!;
      }
      _fillCell(canvas, x, screenY, cellW, cellH, color);
      return;
    }
    final physics = controller.physics;
    final seed = controller.sparkleSeed;
    final n = cellNoise(x, worldY, seed);
    var thickness = 0;
    for (var ty = worldY; ty < physics.rows && physics.getCell(x, ty) == value; ty++) {
      thickness++;
      if (thickness > 6) {
        break;
      }
    }
    final belowKind = SandKind.fromCell(physics.getCell(x, worldY + 1));
    final edge = _isEdge(x, worldY, value);

    if (!clearing && thickness <= 2 && n < 0.16) {
      if (belowKind != null && belowKind != kind) {
        _fillCell(canvas, x, screenY, cellW, cellH, _vary(belowKind.color, n, 0.08));
      }
      if (n < 0.08) {
        return;
      }
    }

    var color = _vary(kind.color, n, 0.12);
    if (clearing) {
      final flash = 0.45 + 0.45 * sin(controller.clearT * 22);
      color = Color.lerp(color, Colors.white, flash)!;
    }
    _fillCell(canvas, x, screenY, cellW, cellH, color);

    if (belowKind != null && belowKind != kind && (edge || thickness <= 3)) {
      if (n < 0.34) {
        final speckle = Paint()..color = belowKind.color.withValues(alpha: 0.85);
        canvas.drawCircle(
          Offset((x + 0.25 + n * 0.5) * cellW, (screenY + 0.3 + (1 - n) * 0.4) * cellH),
          max(0.6, min(cellW, cellH) * 0.28),
          speckle,
        );
      }
    } else if (edge && n < 0.2) {
      canvas.drawCircle(
        Offset((x + n) * cellW, (screenY + cellNoise(x, worldY, seed + 3)) * cellH),
        0.7,
        Paint()..color = controller.theme.canvasColor.withValues(alpha: 0.55),
      );
    }
  }

  bool _isEdge(int x, int y, int value) {
    final physics = controller.physics;
    for (final d in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      if (physics.getCell(x + d.$1, y + d.$2) != value) {
        return true;
      }
    }
    return false;
  }

  void _fillCell(
    Canvas canvas,
    int x,
    double y,
    double cellW,
    double cellH,
    Color color,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.4, cellH + 0.4),
      Paint()..color = color,
    );
  }

  Color _vary(Color color, double n, double amount) {
    final d = (n - 0.5) * amount;
    return Color.from(
      alpha: color.a,
      red: (color.r + d).clamp(0.0, 1.0),
      green: (color.g + d * 0.86).clamp(0.0, 1.0),
      blue: (color.b + d * 0.7).clamp(0.0, 1.0),
    );
  }

  void _paintCluster(
    Canvas canvas,
    FallingCluster cluster,
    double cellW,
    double cellH,
    double opacity,
    double scroll,
  ) {
    final paint = Paint()
      ..color = cluster.model.kind.color.withValues(alpha: opacity);
    for (final offset in cluster.model.offsets) {
      final gx = cluster.x + offset.x;
      final gy = cluster.y + offset.y - scroll;
      canvas.drawRect(
        Rect.fromLTWH(gx * cellW, gy * cellH, cellW + 0.3, cellH + 0.3),
        paint,
      );
    }
  }

  void _paintGuide(
    Canvas canvas,
    Size size,
    double cellW,
    double cellH,
    double scroll,
  ) {
    final x = controller.aimCellX!;
    final px = x * cellW;
    final cancel = controller.pointerInCancelZone;
    final color = cancel ? const Color(0xFFB71C1C) : controller.theme.frameAccent;
    final dash = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(px, y), Offset(px, min(y + 7, size.height)), dash);
      y += 12;
    }

    final ghost = FallingCluster(model: controller.nextPiece, x: x, y: 1.5);
    _paintCluster(canvas, ghost, cellW, cellH, cancel ? 0.2 : 0.55, scroll);

    if (cancel) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'CANCEL',
          style: TextStyle(
            color: Color(0xFFB71C1C),
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, 10));
    }
  }

  @override
  bool shouldRepaint(covariant FieldPainter oldDelegate) => true;
}

Future<ui.Image?> loadOptionalImage(String? path) async {
  if (!AssetGuard.exists(path) || path == null) {
    return null;
  }
  try {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}
