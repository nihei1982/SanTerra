import 'package:flutter_test/flutter_test.dart';
import 'package:santerra/game/score_manager.dart';

void main() {
  test('score is eliminated grains times chain index', () {
    expect(ScoreManager.pointsFor(40, 1), 40);
    expect(ScoreManager.pointsFor(40, 3), 120);
    expect(ScoreManager.pointsFor(0, 2), 0);
    expect(ScoreManager.pointsFor(10, 0), 0);
  });
}
