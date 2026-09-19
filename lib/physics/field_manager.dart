import '../models/sand_kind.dart';
import 'sand_physics_engine.dart';

/// A connected same-color region on the field (8-way, including winding shapes).
class ConnectedGroup {
  ConnectedGroup({
    required this.kind,
    required this.cells,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.fieldCols,
    required this.fieldRows,
  });

  final SandKind kind;
  final List<(int, int)> cells;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  final int fieldCols;
  final int fieldRows;

  int get area => cells.length;

  bool get spansHorizontal => minX <= 0 && maxX >= fieldCols - 1;

  bool get spansVertical => minY <= 0 && maxY >= fieldRows - 1;

  bool get spans => spansHorizontal || spansVertical;
}

/// Connectivity, spanning elimination, chain control, and top-out checks.
class FieldManager {
  static const _neighbors8 = <(int, int)>[
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];

  List<ConnectedGroup> findGroups(SandPhysicsEngine engine) {
    final cols = engine.cols;
    final rows = engine.rows;
    final visited = List<bool>.filled(cols * rows, false);
    final groups = <ConnectedGroup>[];

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final start = engine.index(x, y);
        if (visited[start]) {
          continue;
        }
        final value = engine.cells[start];
        final kind = SandKind.fromCell(value);
        if (kind == null) {
          visited[start] = true;
          continue;
        }
        groups.add(_flood(engine, x, y, kind, visited));
      }
    }
    return groups;
  }

  List<ConnectedGroup> findSpanningGroups(SandPhysicsEngine engine) {
    return findGroups(engine).where((g) => g.spans).toList(growable: false);
  }

  int clearGroups(SandPhysicsEngine engine, List<ConnectedGroup> groups) {
    var removed = 0;
    for (final group in groups) {
      for (final (x, y) in group.cells) {
        if (engine.getCell(x, y) != 0) {
          engine.setCell(x, y, 0);
          removed++;
        }
      }
    }
    return removed;
  }

  bool hasReachedTop(SandPhysicsEngine engine) {
    return engine.hasReachedTop();
  }

  ConnectedGroup _flood(
    SandPhysicsEngine engine,
    int startX,
    int startY,
    SandKind kind,
    List<bool> visited,
  ) {
    final cols = engine.cols;
    final rows = engine.rows;
    final stack = <(int, int)>[(startX, startY)];
    final cells = <(int, int)>[];
    var minX = startX;
    var maxX = startX;
    var minY = startY;
    var maxY = startY;
    final target = kind.cellValue;

    while (stack.isNotEmpty) {
      final (x, y) = stack.removeLast();
      if (!engine.inBounds(x, y)) {
        continue;
      }
      final i = engine.index(x, y);
      if (visited[i] || engine.cells[i] != target) {
        continue;
      }
      visited[i] = true;
      cells.add((x, y));
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
      for (final (dx, dy) in _neighbors8) {
        stack.add((x + dx, y + dy));
      }
    }

    return ConnectedGroup(
      kind: kind,
      cells: cells,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      fieldCols: cols,
      fieldRows: rows,
    );
  }
}
