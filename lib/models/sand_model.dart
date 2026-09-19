import 'dart:math';

import 'sand_amount.dart';
import 'sand_kind.dart';

/// One queued / falling sand piece: color, volume, and grain footprint.
class SandModel {
  SandModel({
    required this.kind,
    required this.amount,
    required List<Point<int>> offsets,
  }) : offsets = List<Point<int>>.unmodifiable(offsets);

  final SandKind kind;
  final SandAmount amount;
  final List<Point<int>> offsets;

  int get grainCount => offsets.length;

  static SandModel random(
    Random rng, {
    int colorCount = 4,
    int sizeTypes = 4,
  }) {
    final colors = SandKind.palette(colorCount);
    final sizes = SandAmount.values.take(sizeTypes.clamp(1, SandAmount.values.length)).toList();
    return generate(
      colors[rng.nextInt(colors.length)],
      sizes[rng.nextInt(sizes.length)],
      rng,
    );
  }

  static SandModel generate(SandKind kind, SandAmount amount, Random rng) {
    return SandModel(
      kind: kind,
      amount: amount,
      offsets: buildClusterOffsets(amount.grainCount, rng),
    );
  }

  /// Organic disk of grains used both for dropping and the NEXT preview.
  static List<Point<int>> buildClusterOffsets(int count, Random rng) {
    if (count <= 0) {
      return const [];
    }
    final radius = sqrt(count / pi) * 1.2;
    final rCeil = max(1, radius.ceil());
    final candidates = <Point<int>>[];
    for (var dy = -rCeil; dy <= rCeil; dy++) {
      for (var dx = -rCeil; dx <= rCeil; dx++) {
        final dist = sqrt(dx * dx + dy * dy);
        if (dist <= radius + rng.nextDouble() * 0.45) {
          candidates.add(Point(dx, dy));
        }
      }
    }
    candidates.shuffle(rng);
    if (candidates.length >= count) {
      return candidates.take(count).toList(growable: false);
    }
    final used = candidates.toSet();
    var guard = 0;
    while (used.length < count && guard < count * 12) {
      guard++;
      final p = Point(rng.nextInt(rCeil * 2 + 1) - rCeil, rng.nextInt(rCeil * 2 + 1) - rCeil);
      used.add(p);
    }
    return used.take(count).toList(growable: false);
  }
}

/// A cluster currently falling through the playfield (cell-space coordinates).
class FallingCluster {
  FallingCluster({
    required this.model,
    required this.x,
    required this.y,
  });

  final SandModel model;
  double x;
  double y;
  double vy = 0;
}
