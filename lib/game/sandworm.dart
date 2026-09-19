import 'dart:math';

import 'package:flutter/material.dart';

import '../physics/sand_physics_engine.dart';

enum SandwormStage { emerge, roam, retreat }

enum SandwormEdge { left, right, bottom }

/// Stretched earthworm that burrows inside the pile. It can enter from any
/// sand edge (left, right, or floor), mix along a long path, then leave
/// through another edge without breaking the surface.
class SandwormActor {
  SandwormActor._(
    this.segments,
    this.heading,
    this._rows,
    this._cols,
    this.entry,
    this.exit,
  );

  static const segmentCount = 26;
  static const spacing = 1.45;
  static const duration = 2.0;

  static const _bodyLight = Color(0xFFF0D28A);
  static const _bodyMid = Color(0xFFE2B45A);
  static const _bodyDark = Color(0xFFC9843C);
  static const _crack = Color(0xFFB06A30);
  static const _mouthPink = Color(0xFFE8A8B0);
  static const _mouthBrown = Color(0xFF8B4A2B);
  static const _tooth = Color(0xFFF6E6C4);

  final List<Offset> segments;
  Offset heading;
  final int _rows;
  final int _cols;
  final SandwormEdge entry;
  final SandwormEdge exit;
  double t = 0;
  double _omega = 0;
  SandwormStage stage = SandwormStage.emerge;

  Offset get head => segments.first;

  Offset get _inward => switch (entry) {
        SandwormEdge.left => const Offset(1, 0.12),
        SandwormEdge.right => const Offset(-1, 0.12),
        SandwormEdge.bottom => const Offset(0, -1),
      };

  Offset get _outward => switch (exit) {
        SandwormEdge.left => const Offset(-1, 0.08),
        SandwormEdge.right => const Offset(1, 0.08),
        SandwormEdge.bottom => const Offset(0, 1),
      };

  bool get finished {
    if (t >= duration) {
      return true;
    }
    if (stage != SandwormStage.retreat) {
      return false;
    }
    return switch (exit) {
      SandwormEdge.left => head.dx < -3,
      SandwormEdge.right => head.dx > _cols + 3,
      SandwormEdge.bottom => head.dy > _rows + 2 && segments.last.dy > _rows,
    };
  }

  factory SandwormActor.spawn(SandPhysicsEngine physics, Random rng) {
    final left = <Offset>[];
    final right = <Offset>[];
    final bottom = <Offset>[];
    for (var y = 0; y < physics.rows; y++) {
      int? minX;
      int? maxX;
      for (var x = 0; x < physics.cols; x++) {
        if (physics.getCell(x, y) == 0) {
          continue;
        }
        minX ??= x;
        maxX = x;
      }
      if (minX == null || maxX == null) {
        continue;
      }
      left.add(Offset(minX - 2.8, y + 0.5));
      right.add(Offset(maxX + 2.8, y + 0.5));
    }
    for (var x = 0; x < physics.cols; x++) {
      if (physics.columnHeight(x) > 0) {
        bottom.add(Offset(x + 0.5, physics.rows + 2.2));
      }
    }

    SandwormEdge edgeOf(List<Offset> pts, SandwormEdge value) => value;
    final types = <SandwormEdge>[
      if (left.isNotEmpty) edgeOf(left, SandwormEdge.left),
      if (right.isNotEmpty) edgeOf(right, SandwormEdge.right),
      if (bottom.isNotEmpty) edgeOf(bottom, SandwormEdge.bottom),
    ];
    final entry = types.isEmpty
        ? SandwormEdge.bottom
        : types[rng.nextInt(types.length)];
    final exits = <SandwormEdge>[
      if (entry != SandwormEdge.left && left.isNotEmpty) SandwormEdge.left,
      if (entry != SandwormEdge.right && right.isNotEmpty) SandwormEdge.right,
      if (bottom.isNotEmpty) SandwormEdge.bottom,
    ];
    SandwormEdge exit;
    if (entry == SandwormEdge.left && right.isNotEmpty && rng.nextDouble() < 0.72) {
      exit = SandwormEdge.right;
    } else if (entry == SandwormEdge.right && left.isNotEmpty && rng.nextDouble() < 0.72) {
      exit = SandwormEdge.left;
    } else if (exits.isEmpty) {
      exit = SandwormEdge.bottom;
    } else {
      exit = exits[rng.nextInt(exits.length)];
    }

    List<Offset> pointsFor(SandwormEdge edge) => switch (edge) {
          SandwormEdge.left => left,
          SandwormEdge.right => right,
          SandwormEdge.bottom => bottom,
        };
    final pts = pointsFor(entry);
    final head = pts.isEmpty
        ? Offset(physics.cols / 2, physics.rows + 2)
        : pts[rng.nextInt(pts.length)];
    var heading = switch (entry) {
      SandwormEdge.left => Offset(1, (rng.nextDouble() - 0.5) * 0.35),
      SandwormEdge.right => Offset(-1, (rng.nextDouble() - 0.5) * 0.35),
      SandwormEdge.bottom => Offset((rng.nextDouble() - 0.5) * 0.55, -1),
    };
    final len = heading.distance;
    heading = heading / (len == 0 ? 1 : len);
    final segments = List<Offset>.generate(
      segmentCount,
      (i) => head - heading * (i * spacing),
    );
    return SandwormActor._(
      segments,
      heading,
      physics.rows,
      physics.cols,
      entry,
      exit,
    );
  }

  void tick(double dt, SandPhysicsEngine physics, Random rng) {
    t += dt;
    final u = (t / duration).clamp(0.0, 1.0);
    if (u < 0.12) {
      stage = SandwormStage.emerge;
    } else if (u < 0.78) {
      stage = SandwormStage.roam;
    } else {
      stage = SandwormStage.retreat;
    }

    _omega += (rng.nextDouble() - 0.5) * 18 * dt;
    _omega *= 0.92;
    if (stage == SandwormStage.roam && rng.nextDouble() < 0.06) {
      _omega += (rng.nextDouble() - 0.5) * 5;
    }

    var angle = atan2(heading.dy, heading.dx) + _omega * dt;
    if (stage == SandwormStage.emerge) {
      angle = atan2(_inward.dy, _inward.dx);
    } else if (stage == SandwormStage.retreat) {
      angle = atan2(_outward.dy, _outward.dx);
    }
    heading = Offset(cos(angle), sin(angle));
    final speed = switch (stage) {
      SandwormStage.emerge => 58.0,
      SandwormStage.roam => 64 + 12 * sin(t * 7),
      SandwormStage.retreat => 86.0,
    };
    final dist = speed * dt;
    var next = _stepInSand(physics, rng, dist) ?? (segments.first + heading * dist);
    if (stage == SandwormStage.roam) {
      next = _keepUnderSurface(next, physics);
      next = Offset(
        next.dx.clamp(0.4, physics.cols - 0.4),
        next.dy,
      );
    } else {
      next = Offset(next.dx, next.dy);
    }
    heading = _safeHeading(segments.first, next);

    var prev = next;
    for (var i = 0; i < segments.length; i++) {
      if (i == 0) {
        segments[i] = next;
      } else {
        final delta = prev - segments[i];
        final d = delta.distance;
        if (d > 0.001) {
          segments[i] = prev - delta / d * spacing;
        }
      }
      prev = segments[i];
    }
    for (var i = 0; i < segments.length; i++) {
      segments[i] = _burySegment(segments[i], physics);
    }
  }

  Offset _burySegment(Offset p, SandPhysicsEngine physics) {
    if (p.dx < 0 || p.dx > physics.cols || p.dy >= physics.rows - 0.15) {
      return p;
    }
    final x = p.dx.clamp(0.4, physics.cols - 0.6);
    final xi = x.round().clamp(0, physics.cols - 1);
    final top = physics.peakY(xi);
    var y = p.dy;
    if (y < top + 1.5) {
      y = min(physics.rows - 1.2, top + 2.2);
    }
    return Offset(x, y);
  }

  Offset _safeHeading(Offset from, Offset to) {
    final d = to - from;
    final n = d.distance;
    if (n < 0.001) {
      return heading;
    }
    return d / n;
  }

  Offset _keepUnderSurface(Offset p, SandPhysicsEngine physics) {
    final x = p.dx.round().clamp(0, physics.cols - 1);
    final top = physics.peakY(x);
    final minY = min(physics.rows - 1.2, top + 2.0);
    if (p.dy < minY) {
      return Offset(p.dx, minY);
    }
    return p;
  }

  Offset? _stepInSand(SandPhysicsEngine physics, Random rng, double dist) {
    final origin = segments.first;
    Offset? best;
    var bestScore = -1e9;
    for (var k = 0; k < 14; k++) {
      final jitter = k == 0 ? 0.0 : (rng.nextDouble() - 0.5) * pi;
      final a = atan2(heading.dy, heading.dx) + jitter;
      final h = Offset(cos(a), sin(a));
      final p = origin + h * dist;
      if (!_allowed(p, physics)) {
        continue;
      }
      var score = rng.nextDouble() * 0.25;
      if (stage == SandwormStage.emerge) {
        score += h.dx * _inward.dx + h.dy * _inward.dy * 2.2;
      } else if (stage == SandwormStage.retreat) {
        score += h.dx * _outward.dx * 3.4 + h.dy * _outward.dy * 3.4;
      } else {
        final x = p.dx.round().clamp(0, physics.cols - 1);
        final depth = p.dy - physics.peakY(x);
        if (depth < 3) {
          score -= 4;
        }
        score += (depth.clamp(0, 12)) * 0.06;
        score += h.dx * _outward.dx * 1.6 + h.dy * _outward.dy * 1.1;
      }
      if (score > bestScore) {
        bestScore = score;
        best = p;
        heading = h;
      }
    }
    if (best != null) {
      return best;
    }
    final bias = stage == SandwormStage.retreat
        ? _outward
        : stage == SandwormStage.emerge
            ? _inward
            : _outward;
    final n = bias.distance;
    final dir = n < 0.001 ? heading : bias / n;
    return origin + dir * dist;
  }

  bool _inSandBand(Offset p, SandPhysicsEngine physics) {
    final x = p.dx.round().clamp(0, physics.cols - 1);
    if (physics.columnHeight(x) <= 0) {
      return false;
    }
    final top = physics.peakY(x);
    return p.dy >= top + 1 && p.dy < physics.rows + 6;
  }

  bool _allowed(Offset p, SandPhysicsEngine physics) {
    if (p.dy < 0) {
      return false;
    }
    final offLeft = p.dx < 0.4;
    final offRight = p.dx > physics.cols - 0.4;
    final offBottom = p.dy >= physics.rows - 0.4;
    if (offLeft || offRight || offBottom) {
      if (stage == SandwormStage.roam) {
        return false;
      }
      if (stage == SandwormStage.emerge) {
        if (entry == SandwormEdge.left && offLeft) {
          return _inSandBand(p, physics);
        }
        if (entry == SandwormEdge.right && offRight) {
          return _inSandBand(p, physics);
        }
        if (entry == SandwormEdge.bottom && offBottom) {
          return _inSandBand(p, physics);
        }
        return false;
      }
      if (exit == SandwormEdge.left && offLeft) {
        return true;
      }
      if (exit == SandwormEdge.right && offRight) {
        return true;
      }
      if (exit == SandwormEdge.bottom && offBottom) {
        return true;
      }
      return false;
    }
    final x = p.dx.round().clamp(0, physics.cols - 1);
    final y = p.dy.round().clamp(0, physics.rows - 1);
    final top = physics.peakY(x);
    if (y < top + 1) {
      return false;
    }
    if (physics.getCell(x, y) != 0) {
      return true;
    }
    for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, 1)]) {
      if (physics.getCell(x + d.$1, y + d.$2) != 0) {
        return true;
      }
    }
    return false;
  }

  List<Offset> get undulated {
    final out = <Offset>[];
    for (var i = 0; i < segments.length; i++) {
      final p = segments[i];
      final next = i + 1 < segments.length ? segments[i + 1] : p - heading;
      final tangent = p - next;
      final len = tangent.distance;
      final perp = len < 0.001
          ? Offset(-heading.dy, heading.dx)
          : Offset(-tangent.dy / len, tangent.dx / len);
      final wave = sin(i * 0.62 + t * 12) * 0.32;
      out.add(p + perp * wave);
    }
    return out;
  }

  void paint(Canvas canvas, {required double cellW, required double cellH, required double scroll}) {
    Offset toScreen(Offset p) => Offset(p.dx * cellW, (p.dy - scroll) * cellH);

    final pts = undulated.map(toScreen).toList(growable: false);
    if (pts.length < 2) {
      return;
    }

    final headW = 3.15 * cellW;
    final tailW = 1.15 * cellW;
    final halfW = <double>[
      for (var i = 0; i < pts.length; i++)
        headW + (tailW - headW) * (i / (pts.length - 1)),
    ];

    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final prev = i == 0 ? pts[i] : pts[i - 1];
      final next = i == pts.length - 1 ? pts[i] : pts[i + 1];
      var tx = next.dx - prev.dx;
      var ty = next.dy - prev.dy;
      final len = sqrt(tx * tx + ty * ty);
      if (len < 0.001) {
        tx = heading.dx;
        ty = heading.dy;
      } else {
        tx /= len;
        ty /= len;
      }
      final nx = -ty * halfW[i];
      final ny = tx * halfW[i];
      left.add(Offset(pts[i].dx + nx, pts[i].dy + ny));
      right.add(Offset(pts[i].dx - nx, pts[i].dy - ny));
    }

    final body = Path()..addPolygon([...left, ...right.reversed], true);
    final shadow = body.shift(Offset(0, cellH * 0.55));
    canvas.drawPath(shadow, Paint()..color = _bodyDark.withValues(alpha: 0.45));
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [_bodyLight, _bodyMid, _bodyDark],
        ).createShader(body.getBounds()),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0x66000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final crack = Paint()
      ..color = _crack
      ..strokeWidth = max(1.4, cellW * 0.28)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 2; i < pts.length - 2; i += 2) {
      final p = pts[i];
      final n = pts[min(i + 1, pts.length - 1)];
      final mid = Offset((p.dx + n.dx) / 2, (p.dy + n.dy) / 2);
      final zig = Offset(-(n.dy - p.dy), n.dx - p.dx);
      final zlen = zig.distance;
      final off = zlen < 0.001 ? Offset.zero : zig / zlen * halfW[i] * 0.45;
      final path = Path()
        ..moveTo(p.dx - off.dx * 0.15, p.dy - off.dy * 0.15)
        ..lineTo(mid.dx + off.dx, mid.dy + off.dy)
        ..lineTo(n.dx - off.dx * 0.1, n.dy - off.dy * 0.1);
      canvas.drawPath(path, crack);
    }

    _paintMouth(canvas, pts.first, cellW, cellH);
  }

  void _paintMouth(Canvas canvas, Offset head, double cellW, double cellH) {
    final r = max(cellW, cellH) * 3.45;
    final angle = atan2(heading.dy, heading.dx);
    final center = head + Offset(cos(angle), sin(angle)) * r * 0.15;

    canvas.drawCircle(center, r * 1.05, Paint()..color = _bodyLight);

    for (var i = 0; i < 8; i++) {
      final a = angle + i * pi / 4;
      final petal = center + Offset(cos(a), sin(a)) * r * 0.62;
      canvas.drawCircle(petal, r * 0.34, Paint()..color = _mouthPink);
    }

    canvas.drawCircle(center, r * 0.72, Paint()..color = _mouthBrown);

    for (var i = 0; i < 8; i++) {
      final a = angle + i * pi / 4 + pi / 8;
      final tooth = center + Offset(cos(a), sin(a)) * r * 0.38;
      canvas.save();
      canvas.translate(tooth.dx, tooth.dy);
      canvas.rotate(a + pi / 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 0.28, height: r * 0.48),
        Paint()..color = _tooth,
      );
      canvas.restore();
    }
  }
}
