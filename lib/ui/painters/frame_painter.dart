import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/game_theme_config.dart';

/// Decorative frame around the playfield (wood/glass atelier, driftwood/coral resort).
class FramePainter extends CustomPainter {
  FramePainter({required this.theme, this.frameImage});

  final GameThemeConfig theme;
  final ui.Image? frameImage;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(outer.deflate(2), const Radius.circular(18));

    if (frameImage != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      paintImage(
        canvas: canvas,
        rect: outer,
        image: frameImage!,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.low,
      );
      canvas.restore();
      return;
    }

    canvas.drawRRect(rrect, Paint()..color = theme.frameOuter);

    if (theme.id == GameThemeId.atelier) {
      _atelier(canvas, size, rrect);
    } else {
      _resort(canvas, size, rrect);
    }
  }

  void _atelier(Canvas canvas, Size size, RRect rrect) {
    final grain = Paint()
      ..color = theme.woodGrain
      ..strokeWidth = 1.2;
    for (var i = 0; i < 14; i++) {
      final y = 8.0 + i * (size.height - 16) / 14;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y + sin(i) * 2), grain);
    }
    final inner = rrect.deflate(9);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = theme.frameInner.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..color = theme.frameAccent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // glass highlight
    canvas.drawRRect(
      inner.deflate(2),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.02),
          ],
        ).createShader(inner.outerRect),
    );
  }

  void _resort(Canvas canvas, Size size, RRect rrect) {
    final inner = rrect.deflate(10);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = theme.frameInner.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final coral = Paint()
      ..color = theme.frameAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    _branch(canvas, Offset(18, 22), coral);
    _branch(canvas, Offset(size.width - 22, 26), coral);
    _branch(canvas, Offset(22, size.height - 28), coral);
    _branch(canvas, Offset(size.width - 24, size.height - 24), coral);
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _branch(Canvas canvas, Offset origin, Paint paint) {
    canvas.drawArc(Rect.fromCircle(center: origin, radius: 10), 0.2, 2.4, false, paint);
    canvas.drawArc(Rect.fromCircle(center: origin.translate(6, 4), radius: 7), 1.2, 2.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) {
    return oldDelegate.theme.id != theme.id || oldDelegate.frameImage != frameImage;
  }
}

class WorldBackgroundPainter extends CustomPainter {
  WorldBackgroundPainter(this.theme, [this.worldImage]);

  final GameThemeConfig theme;
  final ui.Image? worldImage;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (worldImage != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: worldImage!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
      return;
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.worldGradient,
        ).createShader(rect),
    );
    if (theme.id == GameThemeId.atelier) {
      final grain = Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 2;
      for (var i = 0; i < 22; i++) {
        final y = size.height * (i / 22) + sin(i * 1.7) * 4;
        canvas.drawLine(Offset(0, y), Offset(size.width, y + 6), grain);
      }
    } else {
      final wave = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (var w = 0; w < 5; w++) {
        final path = Path();
        final base = size.height * (0.35 + w * 0.12);
        path.moveTo(0, base);
        for (var x = 0.0; x <= size.width; x += 12) {
          path.lineTo(x, base + sin((x / 40) + w) * 10);
        }
        canvas.drawPath(path, wave);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WorldBackgroundPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id;
  }
}
