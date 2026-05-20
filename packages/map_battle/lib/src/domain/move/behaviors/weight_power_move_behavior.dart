import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _WeightPowerKind {
  lowKick,
  heavySlam,
}

/// Ports PSDK moves whose base power is determined by battler weight.
///
/// The formulas intentionally consume the combatant's battle snapshot rather
/// than reaching into species data. That keeps the battle engine pure and lets
/// runtime/editor import layers decide later how base/current weights are
/// hydrated. PSDK's ability fallback around modified weights remains outside
/// this slice, so these methods stay `partial`.
final class WeightPowerMoveBehavior implements BattleMoveBehavior {
  const WeightPowerMoveBehavior.lowKick()
      : battleEngineMethod = 's_low_kick',
        _kind = _WeightPowerKind.lowKick;

  const WeightPowerMoveBehavior.heavySlam()
      : battleEngineMethod = 's_heavy_slam',
        _kind = _WeightPowerKind.heavySlam;

  @override
  final String battleEngineMethod;
  final _WeightPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final heavySlamMinimizeBonus = _kind == _WeightPowerKind.heavySlam &&
        context.state.battlerAt(context.target).effects.contains('minimize');
    final prepared = prepareBattleMove(
      context,
      forceAccuracyBypass: heavySlamMinimizeBonus,
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = switch (_kind) {
      _WeightPowerKind.lowKick => _lowKickPower(target),
      _WeightPowerKind.heavySlam => _heavySlamPower(
          user,
          target,
          heavySlamMinimizeBonus: heavySlamMinimizeBonus,
        ),
    };

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        field: prepared.state.field,
        state: prepared.state,
        userSlot: context.user,
        targetSlot: targetSlot,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _lowKickPower(PsdkBattleCombatant target) {
    final targetWeight = target.currentWeightKg;
    const maximumWeights = <double>[10, 25, 50, 100, 200];
    final index = maximumWeights.indexWhere((weight) => targetWeight < weight);
    return 20 + 20 * (index == -1 ? maximumWeights.length : index);
  }

  int _heavySlamPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target, {
    required bool heavySlamMinimizeBonus,
  }) {
    final weightPercent = target.currentWeightKg / user.currentWeightKg;
    const minimumWeightPercent = <double>[0.5, 0.3334, 0.25, 0.20];
    final index =
        minimumWeightPercent.indexWhere((weight) => weightPercent > weight);
    final basePower =
        40 + 20 * (index == -1 ? minimumWeightPercent.length : index);
    return heavySlamMinimizeBonus ? basePower * 2 : basePower;
  }
}
