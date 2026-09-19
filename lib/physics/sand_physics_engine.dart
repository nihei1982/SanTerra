import 'dart:math';
import 'dart:typed_data';

import '../models/sand_kind.dart';
import '../models/sand_model.dart';

/// Cellular falling-sand engine: gravity, piling, walls, and angle-of-repose slides.
class SandPhysicsEngine {
  SandPhysicsEngine({
    this.cols = 80,
    int rows = 112,
    int? seed,
  })  : baseRows = rows,
        _rows = rows,
        _cells = Uint8List(cols * rows),
        _rng = Random(seed);

  final int cols;
  final int baseRows;

  /// Rows appended when Infinity mode approaches the mouth of the pot.
  static const int expandChunk = 16;
  static const int maxExtraRows = 480;

  int _rows;
  Uint8List _cells;
  final Random _rng;

  int get rows => _rows;

  int get extraDepth => _rows - baseRows;

  /// Maximum extra height a column may keep over a neighbor (~45° repose).
  static const int reposeMaxDrop = 1;

  Uint8List get cells => _cells;

  int index(int x, int y) => y * cols + x;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < cols && y < rows;

  int getCell(int x, int y) {
    if (!inBounds(x, y)) {
      return -1;
    }
    return _cells[index(x, y)];
  }

  void setCell(int x, int y, int value) {
    if (!inBounds(x, y)) {
      return;
    }
    _cells[index(x, y)] = value;
  }

  bool isEmpty(int x, int y) => getCell(x, y) == 0;

  bool isSolid(int x, int y) {
    if (y >= rows) {
      return true;
    }
    if (!inBounds(x, y)) {
      return x < 0 || x >= cols;
    }
    return _cells[index(x, y)] != 0;
  }

  void clear() {
    if (_rows != baseRows) {
      _rows = baseRows;
      _cells = Uint8List(cols * baseRows);
    } else {
      _cells.fillRange(0, _cells.length, 0);
    }
  }

  void fillFrom(List<int> values) {
    if (values.length != _cells.length) {
      throw ArgumentError('Grid size mismatch');
    }
    for (var i = 0; i < values.length; i++) {
      _cells[i] = values[i];
    }
  }

  int countSand() {
    var n = 0;
    for (final v in _cells) {
      if (v != 0) {
        n++;
      }
    }
    return n;
  }

  /// Game over / deepen when settled sand occupies the topmost row (canvas edge).
  int get topOutRows => 1;

  int get expandTriggerRows => max(2, (baseRows * 0.08).ceil());

  int get shrinkClearance => expandTriggerRows + 2;

  /// True when settled sand has reached or crossed the kill line from below.
  bool hasReachedTop() {
    final limit = topOutRows;
    for (var y = 0; y < limit; y++) {
      for (var x = 0; x < cols; x++) {
        if (_cells[index(x, y)] != 0) {
          return true;
        }
      }
    }
    return false;
  }

  bool isNearCeiling() {
    final limit = min(_rows, expandTriggerRows);
    for (var y = 0; y < limit; y++) {
      for (var x = 0; x < cols; x++) {
        if (_cells[index(x, y)] != 0) {
          return true;
        }
      }
    }
    return false;
  }

  int emptyRowsFromTop() {
    for (var y = 0; y < _rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (_cells[index(x, y)] != 0) {
          return y;
        }
      }
    }
    return _rows;
  }

  /// Deepens the pot by appending empty rows at the floor. Gravity will pull sand down.
  int expandBottom([int? count]) {
    final add = count ?? expandChunk;
    if (add <= 0 || extraDepth >= maxExtraRows) {
      return 0;
    }
    final clamped = min(add, maxExtraRows - extraDepth);
    final next = Uint8List(cols * (_rows + clamped));
    next.setRange(0, _cells.length, _cells);
    _cells = next;
    _rows += clamped;
    return clamped;
  }

  /// Removes empty rows at the mouth so extra depth returns toward [baseRows].
  int shrinkEmptyTop() {
    if (extraDepth <= 0) {
      return 0;
    }
    final empty = emptyRowsFromTop();
    final removable = min(empty - shrinkClearance, extraDepth);
    if (removable <= 0) {
      return 0;
    }
    final newRows = _rows - removable;
    final next = Uint8List(cols * newRows);
    next.setRange(0, next.length, _cells.sublist(removable * cols));
    _cells = next;
    _rows = newRows;
    return removable;
  }

  /// Height of a packed column measured from the floor, assuming gravity has run.
  int columnHeight(int x) {
    if (x < 0 || x >= cols) {
      return 0;
    }
    for (var y = 0; y < rows; y++) {
      if (_cells[index(x, y)] != 0) {
        return rows - y;
      }
    }
    return 0;
  }

  int peakY(int x) => rows - columnHeight(x);

  /// One gravity + diagonal-slide pass. Returns whether any grain moved.
  bool stepGravity() {
    var moved = false;
    for (var y = rows - 2; y >= 0; y--) {
      final leftToRight = _rng.nextBool();
      if (leftToRight) {
        for (var x = 0; x < cols; x++) {
          if (_moveGrain(x, y)) {
            moved = true;
          }
        }
      } else {
        for (var x = cols - 1; x >= 0; x--) {
          if (_moveGrain(x, y)) {
            moved = true;
          }
        }
      }
    }
    return moved;
  }

  /// Avalanche pass that flattens slopes steeper than the repose angle.
  bool stepRepose() {
    var moved = false;
    final order = List<int>.generate(cols, (i) => i);
    order.shuffle(_rng);
    for (final x in order) {
      final h = columnHeight(x);
      if (h == 0) {
        continue;
      }
      final leftH = x > 0 ? columnHeight(x - 1) : h;
      final rightH = x < cols - 1 ? columnHeight(x + 1) : h;
      final leftDrop = h - leftH;
      final rightDrop = h - rightH;
      var dir = 0;
      if (leftDrop > reposeMaxDrop && rightDrop > reposeMaxDrop) {
        dir = leftDrop == rightDrop
            ? (_rng.nextBool() ? -1 : 1)
            : (leftDrop > rightDrop ? -1 : 1);
      } else if (leftDrop > reposeMaxDrop) {
        dir = -1;
      } else if (rightDrop > reposeMaxDrop) {
        dir = 1;
      }
      if (dir == 0) {
        continue;
      }
      final nx = x + dir;
      if (nx < 0 || nx >= cols) {
        continue;
      }
      final fromY = peakY(x);
      final toY = peakY(nx) - 1;
      if (fromY < 0 || fromY >= rows) {
        continue;
      }
      if (toY < 0 || toY >= rows) {
        continue;
      }
      if (_cells[index(nx, toY)] != 0) {
        continue;
      }
      _cells[index(nx, toY)] = _cells[index(x, fromY)];
      _cells[index(x, fromY)] = 0;
      moved = true;
    }
    return moved;
  }

  /// Spreads peaks into valleys until the surface is as level as a discrete grid allows.
  bool stepFlatten({int moves = 16}) {
    var moved = stepGravity();
    for (var i = 0; i < moves; i++) {
      if (!_flattenOnce()) {
        break;
      }
      moved = true;
    }
    return moved;
  }

  bool _flattenOnce() {
    final heights = List<int>.generate(cols, columnHeight);
    var maxH = 0;
    var minH = rows;
    for (final h in heights) {
      if (h > maxH) {
        maxH = h;
      }
      if (h < minH) {
        minH = h;
      }
    }
    if (maxH - minH <= 1) {
      return false;
    }
    final peaks = <int>[];
    for (var x = 0; x < cols; x++) {
      if (heights[x] != maxH) {
        continue;
      }
      final leftLower = x > 0 && heights[x - 1] < heights[x];
      final rightLower = x < cols - 1 && heights[x + 1] < heights[x];
      if (leftLower || rightLower) {
        peaks.add(x);
      }
    }
    if (peaks.isEmpty) {
      return false;
    }
    final x = peaks[_rng.nextInt(peaks.length)];
    final leftH = x > 0 ? heights[x - 1] : heights[x];
    final rightH = x < cols - 1 ? heights[x + 1] : heights[x];
    var dir = 0;
    if (leftH < heights[x] && rightH < heights[x]) {
      dir = leftH == rightH ? (_rng.nextBool() ? -1 : 1) : (leftH < rightH ? -1 : 1);
    } else if (leftH < heights[x]) {
      dir = -1;
    } else {
      dir = 1;
    }
    final nx = x + dir;
    if (nx < 0 || nx >= cols) {
      return false;
    }
    final fromY = peakY(x);
    final toY = peakY(nx) - 1;
    if (fromY < 0 || fromY >= rows || toY < 0 || toY >= rows) {
      return false;
    }
    if (_cells[index(nx, toY)] != 0) {
      return false;
    }
    _cells[index(nx, toY)] = _cells[index(x, fromY)];
    _cells[index(x, fromY)] = 0;
    return true;
  }

  bool step() {
    final gravity = stepGravity();
    final repose = stepRepose();
    return gravity || repose;
  }

  /// Runs [maxSteps] or until the field is still. Returns remaining motion.
  bool stepMany(int maxSteps) {
    var moved = false;
    for (var i = 0; i < maxSteps; i++) {
      if (!step()) {
        return moved;
      }
      moved = true;
    }
    return true;
  }

  /// Writes a landed cluster into the grid. Overflow grains search nearby empty cells.
  int stampCluster(FallingCluster cluster) {
    var placed = 0;
    final kind = cluster.model.kind.cellValue;
    final grains = [...cluster.model.offsets]..shuffle(_rng);
    for (final offset in grains) {
      var x = (cluster.x + offset.x).round();
      var y = (cluster.y + offset.y).floor();
      x = x.clamp(0, cols - 1);
      y = y.clamp(0, rows - 1);
      if (_placeNear(x, y, kind)) {
        placed++;
      }
    }
    return placed;
  }

  bool _placeNear(int x, int y, int kind) {
    if (_tryPlace(x, y, kind)) {
      return true;
    }
    for (var radius = 1; radius <= 8; radius++) {
      for (var dy = 0; dy <= radius; dy++) {
        for (var dx = -radius; dx <= radius; dx++) {
          if (_tryPlace(x + dx, y + dy, kind)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _tryPlace(int x, int y, int kind) {
    if (!inBounds(x, y) || _cells[index(x, y)] != 0) {
      return false;
    }
    _cells[index(x, y)] = kind;
    return true;
  }

  bool _moveGrain(int x, int y) {
    final value = _cells[index(x, y)];
    if (value == 0) {
      return false;
    }
    if (isEmpty(x, y + 1)) {
      _swap(x, y, x, y + 1);
      return true;
    }
    final downLeft = x > 0 && isEmpty(x - 1, y + 1);
    final downRight = x < cols - 1 && isEmpty(x + 1, y + 1);
    if (downLeft && downRight) {
      if (_rng.nextBool()) {
        _swap(x, y, x - 1, y + 1);
      } else {
        _swap(x, y, x + 1, y + 1);
      }
      return true;
    }
    if (downLeft) {
      _swap(x, y, x - 1, y + 1);
      return true;
    }
    if (downRight) {
      _swap(x, y, x + 1, y + 1);
      return true;
    }
    return false;
  }

  void _swap(int ax, int ay, int bx, int by) {
    final a = index(ax, ay);
    final b = index(bx, by);
    final tmp = _cells[a];
    _cells[a] = _cells[b];
    _cells[b] = tmp;
  }

  SandKind? kindAt(int x, int y) => SandKind.fromCell(getCell(x, y));
}
