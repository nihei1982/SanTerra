import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:santerra/game/sandworm.dart';
import 'package:santerra/models/sand_kind.dart';
import 'package:santerra/physics/field_manager.dart';
import 'package:santerra/physics/sand_physics_engine.dart';

void main() {
  late SandPhysicsEngine engine;
  late FieldManager field;

  setUp(() {
    engine = SandPhysicsEngine(cols: 10, rows: 8, seed: 7);
    field = FieldManager();
  });

  test('gravity drops a grain onto the floor', () {
    engine.setCell(4, 0, SandKind.red.cellValue);
    var guard = 0;
    while (engine.stepGravity() && guard < 40) {
      guard++;
    }
    expect(engine.getCell(4, 7), SandKind.red.cellValue);
    expect(engine.getCell(4, 0), 0);
  });

  test('walls keep sand inside the field', () {
    engine.setCell(0, 3, SandKind.blue.cellValue);
    engine.setCell(9, 3, SandKind.blue.cellValue);
    for (var i = 0; i < 30; i++) {
      engine.step();
    }
    expect(engine.countSand(), 2);
    for (var y = 0; y < engine.rows; y++) {
      for (var x = 0; x < engine.cols; x++) {
        if (engine.getCell(x, y) != 0) {
          expect(x, inInclusiveRange(0, 9));
        }
      }
    }
  });

  test('repose flattens a pillar toward a 45-degree pile', () {
    for (var y = 2; y < 8; y++) {
      engine.setCell(5, y, SandKind.yellow.cellValue);
    }
    for (var i = 0; i < 80; i++) {
      engine.step();
    }
    for (var x = 1; x < 9; x++) {
      final delta = (engine.columnHeight(x) - engine.columnHeight(x + 1)).abs();
      expect(delta, lessThanOrEqualTo(SandPhysicsEngine.reposeMaxDrop + 1));
    }
  });

  test('same color touching cells merge into one group', () {
    engine.setCell(1, 7, SandKind.red.cellValue);
    engine.setCell(2, 7, SandKind.red.cellValue);
    engine.setCell(2, 6, SandKind.red.cellValue);
    final groups = field.findGroups(engine);
    expect(groups, hasLength(1));
    expect(groups.single.area, 3);
  });

  test('horizontal span from left wall to right wall clears', () {
    for (var x = 0; x < 10; x++) {
      engine.setCell(x, 6, SandKind.green.cellValue);
    }
    final spanning = field.findSpanningGroups(engine);
    expect(spanning, hasLength(1));
    expect(spanning.single.spansHorizontal, isTrue);
    expect(field.clearGroups(engine, spanning), 10);
    expect(engine.countSand(), 0);
  });

  test('vertical span from top to bottom clears', () {
    for (var y = 0; y < 8; y++) {
      engine.setCell(3, y, SandKind.blue.cellValue);
    }
    final spanning = field.findSpanningGroups(engine);
    expect(spanning.single.spansVertical, isTrue);
  });

  test('diagonal winding connection still counts as one spanning group', () {
    var x = 0;
    var y = 7;
    while (x < 10) {
      engine.setCell(x, y, SandKind.red.cellValue);
      x++;
      if (x < 10) {
        y = (y == 7) ? 6 : 7;
        engine.setCell(x, y, SandKind.red.cellValue);
        x++;
      }
    }
    final group = field.findGroups(engine).single;
    expect(group.spansHorizontal, isTrue);
  });

  test('a short same-color run does not span', () {
    engine.setCell(0, 7, SandKind.red.cellValue);
    engine.setCell(1, 7, SandKind.red.cellValue);
    engine.setCell(2, 7, SandKind.red.cellValue);
    expect(field.findSpanningGroups(engine), isEmpty);
  });

  test('different colors do not connect', () {
    engine.setCell(0, 7, SandKind.red.cellValue);
    engine.setCell(1, 7, SandKind.blue.cellValue);
    expect(field.findGroups(engine), hasLength(2));
  });

  test('game over when piled sand reaches the kill line', () {
    expect(field.hasReachedTop(engine), isFalse);
    engine.setCell(4, 7, SandKind.red.cellValue);
    expect(field.hasReachedTop(engine), isFalse);
    engine.setCell(3, engine.topOutRows, SandKind.green.cellValue);
    expect(field.hasReachedTop(engine), isFalse);
    engine.setCell(3, engine.topOutRows - 1, SandKind.blue.cellValue);
    expect(field.hasReachedTop(engine), isTrue);
  });

  test('sand above a cleared gap falls down', () {
    for (var x = 0; x < 10; x++) {
      engine.setCell(x, 7, SandKind.red.cellValue);
    }
    engine.setCell(4, 6, SandKind.blue.cellValue);
    field.clearGroups(engine, field.findSpanningGroups(engine));
    expect(engine.getCell(4, 6), SandKind.blue.cellValue);
    var guard = 0;
    while (engine.step() && guard < 40) {
      guard++;
    }
    expect(engine.getCell(4, 7), SandKind.blue.cellValue);
    expect(engine.getCell(4, 6), 0);
  });

  test('infinity pot deepens then gravity lowers the pile', () {
    engine.setCell(2, 0, SandKind.red.cellValue);
    expect(engine.isNearCeiling(), isTrue);
    expect(engine.expandBottom(4), 4);
    expect(engine.rows, 12);
    expect(engine.extraDepth, 4);
    var guard = 0;
    while (engine.step() && guard < 50) {
      guard++;
    }
    expect(engine.countSand(), 1);
    expect(engine.isNearCeiling(), isFalse);
    expect(engine.emptyRowsFromTop(), greaterThan(6));
  });

  test('infinity pot shrinks back when sand is low', () {
    engine.setCell(1, 7, SandKind.blue.cellValue);
    engine.expandBottom(4);
    var guard = 0;
    while (engine.step() && guard < 50) {
      guard++;
    }
    expect(engine.rows, 12);
    final removed = engine.shrinkEmptyTop();
    expect(removed, greaterThan(0));
    expect(engine.rows, lessThan(12));
    expect(engine.countSand(), 1);
  });

  test('clear resets extra depth', () {
    engine.expandBottom(8);
    expect(engine.rows, 16);
    engine.clear();
    expect(engine.rows, 8);
    expect(engine.countSand(), 0);
  });

  test('earthquake flatten levels a tall pillar', () {
    for (var y = 2; y < 8; y++) {
      engine.setCell(4, y, SandKind.red.cellValue);
    }
    final before = engine.columnHeight(4);
    expect(before, greaterThan(3));
    var guard = 0;
    while (engine.stepFlatten(moves: 24) && guard < 80) {
      guard++;
    }
    var minH = 8;
    var maxH = 0;
    for (var x = 0; x < 10; x++) {
      final h = engine.columnHeight(x);
      if (h < minH) {
        minH = h;
      }
      if (h > maxH) {
        maxH = h;
      }
    }
    expect(maxH - minH, lessThanOrEqualTo(1));
    expect(maxH, lessThan(before));
  });

  test('sandworm stir mixes layers vertically without losing grains', () {
    for (var y = 4; y < 6; y++) {
      for (var x = 0; x < 10; x++) {
        engine.setCell(x, y, SandKind.blue.cellValue);
      }
    }
    for (var y = 6; y < 8; y++) {
      for (var x = 0; x < 10; x++) {
        engine.setCell(x, y, SandKind.red.cellValue);
      }
    }
    final before = engine.countSand();
    final body = <(int, int)>[
      for (var y = 3; y < 8; y++) (5, y),
    ];
    engine.stepWormStir(body, dirX: 0, dirY: 1);
    expect(engine.countSand(), before);

    var redRaised = false;
    var blueLowered = false;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 10; x++) {
        final v = engine.getCell(x, y);
        if (v == SandKind.red.cellValue && y <= 5) {
          redRaised = true;
        }
        if (v == SandKind.blue.cellValue && y >= 6) {
          blueLowered = true;
        }
      }
    }
    expect(redRaised || blueLowered, isTrue);
  });

  test('sandworm stays inside the sand after emerging', () {
    for (var y = 3; y < 8; y++) {
      for (var x = 0; x < 10; x++) {
        engine.setCell(x, y, SandKind.red.cellValue);
      }
    }
    final rng = Random(3);
    final worm = SandwormActor.spawn(engine, rng);
    expect(
      worm.head.dx < 1 ||
          worm.head.dx > engine.cols - 1 ||
          worm.head.dy >= engine.rows - 0.5,
      isTrue,
    );

    for (var i = 0; i < 50; i++) {
      worm.tick(1 / 60, engine, rng);
    }
    expect(worm.stage, SandwormStage.roam);
    final hx = worm.head.dx.round().clamp(0, engine.cols - 1);
    final hy = worm.head.dy.round().clamp(0, engine.rows - 1);
    expect(hy, greaterThanOrEqualTo(engine.peakY(hx)));
    expect(
      engine.getCell(hx, hy) != 0 ||
          engine.getCell(hx, min(engine.rows - 1, hy + 1)) != 0,
      isTrue,
    );
  });
}
