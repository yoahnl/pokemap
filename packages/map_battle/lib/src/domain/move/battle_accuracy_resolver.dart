import '../battle/battle_slot.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_execution.dart';

final class BattleAccuracyResolver {
  const BattleAccuracyResolver();

  BattleAccuracyResult resolve({
    required BattleMoveProcedureExecution execution,
    required List<BattlePositionRef> targets,
  }) {
    if (_bypassAccuracy(execution)) {
      return BattleAccuracyResult(
        rng: execution.context.rng,
        hitTargets: targets,
        missedTargets: const <BattlePositionRef>[],
        bypassed: true,
      );
    }

    var rng = execution.context.rng;
    final hitTargets = <BattlePositionRef>[];
    final missedTargets = <BattlePositionRef>[];
    for (final target in targets) {
      final roll = rng.moveAccuracy.nextPercent();
      rng = rng.copyWith(moveAccuracy: roll.next);
      if (roll.value <= execution.move.accuracy) {
        hitTargets.add(target);
      } else {
        missedTargets.add(target);
      }
    }

    return BattleAccuracyResult(
      rng: rng,
      hitTargets: hitTargets,
      missedTargets: missedTargets,
      bypassed: false,
    );
  }

  bool _bypassAccuracy(BattleMoveProcedureExecution execution) {
    return execution.move.accuracy <= 0 || execution.move.accuracy >= 100;
  }
}

final class BattleAccuracyResult {
  BattleAccuracyResult({
    required this.rng,
    required List<BattlePositionRef> hitTargets,
    required List<BattlePositionRef> missedTargets,
    required this.bypassed,
  })  : hitTargets = List<BattlePositionRef>.unmodifiable(hitTargets),
        missedTargets = List<BattlePositionRef>.unmodifiable(missedTargets);

  final BattleRngStreams rng;
  final List<BattlePositionRef> hitTargets;
  final List<BattlePositionRef> missedTargets;
  final bool bypassed;
}
