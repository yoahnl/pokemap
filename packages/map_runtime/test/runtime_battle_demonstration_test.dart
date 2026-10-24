import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_battle_demonstration.dart';

void main() {
  test('demonstration capture guarantee covers the minimum catch rate at full health', () {
    for (var catchRate = 1; catchRate <= 255; catchRate++) {
      for (var seed = 0; seed < 100; seed++) {
        final capture = const BattleCaptureFormula().attempt(
          targetCurrentHp: 100,
          targetMaxHp: 100,
          catchRate: catchRate,
          ballId: 'ball',
          ballRateNumerator: guaranteedDemonstrationBallRateNumerator,
          ballRateDenominator: 1,
          status: BattleCaptureStatus.none,
          rng: BattleSeededRng(state: seed),
        );
        expect(capture.caught, true, reason: 'catchRate=$catchRate seed=$seed');
        expect(capture.shakes, 4);
      }
    }
  });
}
