import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:santerra/models/sand_amount.dart';
import 'package:santerra/models/sand_kind.dart';
import 'package:santerra/models/sand_model.dart';

void main() {
  test('random pieces stay within the selected color count', () {
    final rng = Random(3);
    final seen = <SandKind>{};
    for (var i = 0; i < 80; i++) {
      seen.add(SandModel.random(rng, colorCount: 3, sizeTypes: 4).kind);
    }
    expect(seen, everyElement(isIn(SandKind.palette(3))));
    expect(seen.length, 3);
  });

  test('one size type uses only the smallest sand', () {
    final rng = Random(4);
    for (var i = 0; i < 20; i++) {
      expect(
        SandModel.random(rng, colorCount: 4, sizeTypes: 1).amount,
        SandAmount.s,
      );
    }
  });

  test('two size types add M on top of S', () {
    final rng = Random(5);
    final seen = <SandAmount>{};
    for (var i = 0; i < 60; i++) {
      seen.add(SandModel.random(rng, colorCount: 4, sizeTypes: 2).amount);
    }
    expect(seen, equals({SandAmount.s, SandAmount.m}));
  });
}
