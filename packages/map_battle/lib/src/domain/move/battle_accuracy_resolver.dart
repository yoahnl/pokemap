import '../battle/battle_slot.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/item/item_effect.dart';
import '../rng/battle_rng_streams.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import 'battle_move_execution.dart';

final class BattleAccuracyResolver {
  const BattleAccuracyResolver();

  BattleAccuracyResult resolve({
    required BattleMoveProcedureExecution execution,
    required List<BattlePositionRef> targets,
  }) {
    if (_bypassAccuracy(execution, targets)) {
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
      if (roll.value <= _effectiveAccuracy(execution, target)) {
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

  bool _bypassAccuracy(
    BattleMoveProcedureExecution execution,
    List<BattlePositionRef> targets,
  ) {
    if (execution.move.accuracy <= 0) {
      return true;
    }
    if (_snowBypassesBlizzardAccuracy(execution)) {
      return true;
    }
    for (final target in targets) {
      final context = BattleAbilityMoveContext(
        state: execution.context.state,
        user: execution.psdkUser,
        target: PsdkBattleSlotRef(bank: target.bank, position: target.position),
        move: execution.move,
      );
      if (execution.context.state.activeAbilityEffects().any(
            (effect) => effect.bypassesAccuracy(context),
          )) {
        return true;
      }
    }
    return false;
  }

  bool _snowBypassesBlizzardAccuracy(BattleMoveProcedureExecution execution) {
    if (execution.move.dbSymbol != 'blizzard') {
      return false;
    }
    final state = execution.context.state;
    return state.isWeatherEffectActive(PsdkBattleWeatherId.hail) ||
        state.isWeatherEffectActive(PsdkBattleWeatherId.snow);
  }

  int _effectiveAccuracy(
    BattleMoveProcedureExecution execution,
    BattlePositionRef targetRef,
  ) {
    final user = execution.context.state.battlerAt(execution.psdkUser);
    final target = execution.context.state.battlerAt(
      PsdkBattleSlotRef(bank: targetRef.bank, position: targetRef.position),
    );
    final context = BattleItemAccuracyContext(
      user: user,
      target: target,
      move: execution.move,
    );
    var multiplier = 1.0;
    for (final effect in user.activeItemEffects) {
      multiplier *= effect.accuracyMultiplier(context);
    }
    for (final effect in target.activeItemEffects) {
      multiplier *= effect.accuracyMultiplier(context);
    }
    final adjusted = (execution.move.accuracy * multiplier).floor();
    return adjusted.clamp(1, 100).toInt();
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
