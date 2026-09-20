import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/game_theme_config.dart';

/// Decorative frame around the playfield (wood/glass atelier, moonlit desert night).
class FramePainter extends CustomPainter {
  FramePainter({required this.theme, this.frameImage});

  final GameThemeConfig theme;
  final ui.Image? frameImage;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(outer.deflate(2), const Radius.circular(18));

    final innerHole = RRect.fromRectAndRadius(
      outer.deflate(18),
      const Radius.circular(8),
    );
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(rrect)
      ..addRRect(innerHole);

    if (frameImage != null) {
      canvas.save();
      canvas.clipPath(ring);
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
    canvas.drawPath(ring, Paint()..color = theme.frameOuter);

    canvas.save();
    canvas.clipPath(ring);
    if (theme.id == GameThemeId.atelier) {
      _atelier(canvas, size, rrect);
    } else {
      _resort(canvas, size, rrect);
    }
    canvas.restore();
  }

  void _atelier(Canvas canvas, Size size, RRect rrect) {
    final grain = Paint()
      ..color = theme.woodGrain
      ..strokeWidth = 1.1;
    for (var i = 0; i < 10; i++) {
      final y = 8.0 + i * (size.height - 16) / 10;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y + sin(i) * 1.4), grain);
    }
    final inner = rrect.deflate(9);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = theme.frameInner.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..color = theme.frameAccent.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawRRect(
      inner.deflate(2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.04),
          ],
        ).createShader(inner.outerRect),
    );
  }

  void _resort(Canvas canvas, Size size, RRect rrect) {
    final inner = rrect.deflate(10);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = theme.frameInner.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..color = theme.frameAccent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    final starFill = Paint()..color = theme.frameAccent.withValues(alpha: 0.9);
    final starLine = Paint()
      ..color = theme.frameAccent.withValues(alpha: 0.9)
      ..strokeWidth = 1.1;
    void spark(Offset c) {
      canvas.drawCircle(c, 2.2, starFill);
      canvas.drawLine(c.translate(-5, 0), c.translate(5, 0), starLine);
      canvas.drawLine(c.translate(0, -5), c.translate(0, 5), starLine);
    }
    spark(const Offset(16, 16));
    spark(Offset(size.width - 16, 16));
    spark(Offset(16, size.height - 16));
    spark(Offset(size.width - 16, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) {
    return oldDelegate.theme.id != theme.id || oldDelegate.frameImage != frameImage;
  }
}

class WorldBackdrop extends StatefulWidget {
  const WorldBackdrop({super.key, required this.theme, this.worldImage});

  final GameThemeConfig theme;
  final ui.Image? worldImage;

  @override
  State<WorldBackdrop> createState() => _WorldBackdropState();
}

class _WorldBackdropState extends State<WorldBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsed = elapsed;
      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WorldBackgroundPainter(
        widget.theme,
        widget.worldImage,
        _elapsed.inMilliseconds / 1000.0,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class WorldBackgroundPainter extends CustomPainter {
  WorldBackgroundPainter(this.theme, [this.worldImage, this.time = 0]);

  final GameThemeConfig theme;
  final ui.Image? worldImage;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (worldImage != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: worldImage!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
      return;
    }
    if (theme.id == GameThemeId.atelier) {
      _paintAtelier(canvas, size);
    } else {
      _paintNightDesert(canvas, size);
    }
  }

  void _paintAtelier(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC8DCE8), Color(0xFFB5D0E4), Color(0xFFC3D8E8)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.075),
      Paint()..color = const Color(0xFFD2E4EE),
    );

    void cloud(Offset c, double s) {
      final p = Paint()..color = const Color(0x66FFFFFF);
      canvas.drawOval(Rect.fromCenter(center: c, width: s * 2.2, height: s), p);
      canvas.drawOval(Rect.fromCenter(center: c.translate(-s * 0.7, s * 0.08), width: s * 1.3, height: s * 0.75), p);
      canvas.drawOval(Rect.fromCenter(center: c.translate(s * 0.7, s * 0.1), width: s * 1.2, height: s * 0.7), p);
    }

    cloud(Offset(w * 0.12, h * 0.11), w * 0.055);
    cloud(Offset(w * 0.88, h * 0.16), w * 0.05);
    cloud(Offset(w * 0.08, h * 0.48), w * 0.045);
    cloud(Offset(w * 0.92, h * 0.42), w * 0.04);

    final win = Rect.fromLTWH(w * 0.27, h * 0.11, w * 0.46, h * 0.40);
    canvas.drawRect(
      win.inflate(18),
      Paint()
        ..color = const Color(0x55FFF8DC)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(win.inflate(8), const Radius.circular(4)),
      Paint()..color = const Color(0xFFE8EEF2),
    );
    canvas.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF4), Color(0xFFFFF3C8), Color(0xFFE8F0F8)],
        ).createShader(win),
    );
    final pane = Paint()
      ..color = const Color(0xFFB7C4CE)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), pane);
    canvas.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), pane);
    canvas.drawLine(Offset(win.left, win.top + win.height / 3), Offset(win.right, win.top + win.height / 3), pane..strokeWidth = 1.6);

    final ray = Paint()..color = Color.fromRGBO(255, 248, 220, 0.10 + 0.04 * sin(time * 0.7));
    for (var i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(win.center.dx + (i - 2) * 8, win.bottom)
        ..lineTo(w * (0.18 + i * 0.16), h)
        ..lineTo(w * (0.28 + i * 0.16), h)
        ..close();
      canvas.drawPath(path, ray);
    }

    final rodY = win.top - 10;
    canvas.drawLine(
      Offset(win.left - w * 0.14, rodY),
      Offset(win.right + w * 0.14, rodY),
      Paint()
        ..color = const Color(0xFFC4A882)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    void curtain(Rect r, {bool left = true}) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)),
        Paint()
          ..shader = LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [Color(0xFFFFFCF8), Color(0xFFEDE6DC), Color(0xFFFFF8F2)],
          ).createShader(r),
      );
      final fold = Paint()
        ..color = const Color(0x22C4B8A8)
        ..strokeWidth = 1.2;
      for (var i = 1; i < 5; i++) {
        final x = r.left + r.width * (i / 5);
        canvas.drawLine(Offset(x, r.top + 6), Offset(x + (left ? 3 : -3), r.bottom - 6), fold);
      }
    }

    curtain(Rect.fromLTWH(win.left - w * 0.16, rodY, w * 0.17, h * 0.58));
    curtain(Rect.fromLTWH(win.right - w * 0.01, rodY, w * 0.17, h * 0.58), left: false);

    canvas.drawRect(Rect.fromLTWH(0, h * 0.70, w, h * 0.30), Paint()..color = const Color(0xFFE8E4DC));
    final rug = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.52, h * 0.90), width: w * 0.92, height: h * 0.22));
    canvas.save();
    canvas.clipPath(rug);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD8E8D4), Color(0xFFF3E4C4), Color(0xFFE8D0DC), Color(0xFFD4E4F2)],
        ).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.22)),
    );
    canvas.restore();

    final wood = Paint()..color = const Color(0xFFE6D3B0);
    final chair = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.58, w * 0.28, h * 0.22),
      const Radius.circular(16),
    );
    canvas.drawRRect(chair, Paint()..color = const Color(0xFFE2D0B8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.09, h * 0.61, w * 0.22, h * 0.10), const Radius.circular(10)),
      Paint()..color = const Color(0xFFD4C2AA),
    );

    final table = Rect.fromLTWH(w * 0.34, h * 0.68, w * 0.46, h * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(table, const Radius.circular(4)), wood);
    canvas.drawRect(Rect.fromLTWH(table.left + 8, table.bottom, 10, h * 0.08), wood);
    canvas.drawRect(Rect.fromLTWH(table.right - 18, table.bottom, 10, h * 0.08), wood);

    final robotC = Offset(table.left + table.width * 0.28, table.top - 6);
    canvas.drawCircle(robotC.translate(0, -16), 11, Paint()..color = const Color(0xFF9EC4DC));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: robotC, width: 22, height: 26), const Radius.circular(6)),
      Paint()..color = const Color(0xFF8BB7D4),
    );
    canvas.drawCircle(robotC.translate(-4, -17), 2.2, Paint()..color = const Color(0xFF4A3F36));
    canvas.drawCircle(robotC.translate(4, -17), 2.2, Paint()..color = const Color(0xFF4A3F36));
    canvas.drawLine(
      robotC.translate(0, -26),
      robotC.translate(0, -34),
      Paint()
        ..color = const Color(0xFF7A6A5A)
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(robotC.translate(0, -35), 2.4, Paint()..color = const Color(0xFFE8A0A0));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(table.left + table.width * 0.55, table.top - 22, 16, 16), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE8D08A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(table.left + table.width * 0.62, table.top - 30, 14, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFFD4E4C8),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.78, h * 0.62, w * 0.16, h * 0.14), const Radius.circular(4)),
      Paint()..color = const Color(0xFFDCC8A4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.86, h * 0.58), width: w * 0.12, height: h * 0.10),
      Paint()..color = const Color(0xFF7CB08A),
    );

    canvas.drawCircle(
      Offset(w * 0.82, h * 0.22),
      16,
      Paint()
        ..color = const Color(0xFFE8DCC8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (var i = 0; i < 18; i++) {
      final nx = _hash(i, 5);
      final ny = _hash(i, 13);
      final x = win.left + nx * win.width;
      final y = win.bottom + ny * (h * 0.35);
      final tw = 0.25 + 0.75 * (0.5 + 0.5 * sin(time * 1.6 + i));
      canvas.drawCircle(
        Offset(x, y),
        1.1 + tw,
        Paint()..color = Color.fromRGBO(255, 252, 230, (0.15 + 0.35 * tw).clamp(0.0, 1.0)),
      );
    }
  }

  void _paintNightDesert(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050B22),
            Color(0xFF0A1848),
            Color(0xFF163A78),
            Color(0xFF2A5088),
            Color(0xFF3A5A7A),
          ],
          stops: [0.0, 0.28, 0.52, 0.68, 1.0],
        ).createShader(rect),
    );

    _paintStars(canvas, size);
    _paintMoon(canvas, size);
    _paintDunes(canvas, size);
  }

  void _paintStars(Canvas canvas, Size size) {
    final duneTop = size.height * 0.58;
    for (var i = 0; i < 160; i++) {
      final nx = _hash(i, 3);
      final ny = _hash(i, 11);
      final x = nx * size.width;
      final y = ny * duneTop;
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * sin(time * (1.4 + nx * 2.2) + i));
      final r = 0.5 + _hash(i, 19) * 1.5;
      canvas.drawCircle(
        Offset(x, y),
        r * (0.7 + 0.5 * twinkle),
        Paint()..color = Color.fromRGBO(255, 252, 240, (0.25 + 0.75 * twinkle).clamp(0.0, 1.0)),
      );
    }
  }

  void _paintMoon(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.28, size.height * 0.17);
    final r = min(size.width, size.height) * 0.14;
    canvas.drawCircle(
      c,
      r * 1.55,
      Paint()
        ..color = const Color(0x44FFF4C2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF3EEC2));
    canvas.drawCircle(c.translate(-r * 0.18, -r * 0.12), r * 0.92, Paint()..color = const Color(0x22FFFFFF));
    final crater = Paint()..color = const Color(0x33B8A56A);
    canvas.drawOval(Rect.fromCenter(center: c.translate(-r * 0.22, r * 0.08), width: r * 0.38, height: r * 0.28), crater);
    canvas.drawOval(Rect.fromCenter(center: c.translate(r * 0.28, -r * 0.18), width: r * 0.22, height: r * 0.18), crater);
    canvas.drawOval(Rect.fromCenter(center: c.translate(r * 0.08, r * 0.32), width: r * 0.3, height: r * 0.22), crater);
    canvas.drawOval(Rect.fromCenter(center: c.translate(-r * 0.05, -r * 0.32), width: r * 0.16, height: r * 0.12), crater);
  }

  void _paintDunes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final back = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.22, h * 0.56, w * 0.42, h * 0.60)
      ..quadraticBezierTo(w * 0.62, h * 0.66, w * 0.82, h * 0.61)
      ..lineTo(w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFE8B45A), Color(0xFFC9842E), Color(0xFFA86A22)],
        ).createShader(back.getBounds()),
    );

    _paintCamels(canvas, Offset(w * 0.30, h * 0.575), min(w, h) * 0.028);

    final mid = Path()
      ..moveTo(w * 0.18, h)
      ..quadraticBezierTo(w * 0.55, h * 0.60, w, h * 0.70)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      mid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFFD49A3C), Color(0xFFB57528), Color(0xFF8E5A1C)],
        ).createShader(mid.getBounds()),
    );

    final front = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.38, h * 0.78, w, h * 0.90)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFFC48432));

    final ridge = Paint()
      ..color = const Color(0x66F6D27A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final ridgePath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.22, h * 0.56, w * 0.42, h * 0.60)
      ..quadraticBezierTo(w * 0.62, h * 0.66, w * 0.82, h * 0.61);
    canvas.drawPath(ridgePath, ridge);
  }

  void _paintCamels(Canvas canvas, Offset origin, double s) {
    final paint = Paint()..color = const Color(0xFF1A1208);
    void camel(Offset o, {bool flip = false}) {
      canvas.save();
      canvas.translate(o.dx, o.dy);
      if (flip) {
        canvas.scale(-1, 1);
      }
      final body = Path()
        ..moveTo(-2.2 * s, 0)
        ..quadraticBezierTo(-1.6 * s, -2.4 * s, -0.4 * s, -2.1 * s)
        ..quadraticBezierTo(0.5 * s, -3.4 * s, 1.5 * s, -2.0 * s)
        ..quadraticBezierTo(2.4 * s, -0.4 * s, 2.6 * s, 0.6 * s)
        ..lineTo(2.1 * s, 0.6 * s)
        ..lineTo(1.9 * s, 2.4 * s)
        ..lineTo(1.4 * s, 2.4 * s)
        ..lineTo(1.3 * s, 0.5 * s)
        ..lineTo(0.2 * s, 0.5 * s)
        ..lineTo(0.15 * s, 2.5 * s)
        ..lineTo(-0.35 * s, 2.5 * s)
        ..lineTo(-0.4 * s, 0.5 * s)
        ..lineTo(-1.3 * s, 0.5 * s)
        ..lineTo(-1.45 * s, 2.3 * s)
        ..lineTo(-2.0 * s, 2.3 * s)
        ..lineTo(-1.9 * s, 0.4 * s)
        ..close();
      canvas.drawPath(body, paint);
      final neck = Path()
        ..moveTo(1.6 * s, -1.8 * s)
        ..quadraticBezierTo(2.5 * s, -3.2 * s, 3.1 * s, -2.6 * s)
        ..quadraticBezierTo(3.4 * s, -2.3 * s, 3.0 * s, -2.1 * s)
        ..quadraticBezierTo(2.4 * s, -2.4 * s, 1.8 * s, -1.2 * s)
        ..close();
      canvas.drawPath(neck, paint);
      canvas.restore();
    }

    camel(origin);
    camel(origin.translate(s * 4.2, s * 0.35));
  }

  double _hash(int i, int salt) {
    final n = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return n - n.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant WorldBackgroundPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id ||
        oldDelegate.worldImage != worldImage ||
        (oldDelegate.time - time).abs() > 0.016;
  }
}
