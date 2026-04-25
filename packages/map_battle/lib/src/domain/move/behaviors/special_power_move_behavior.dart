import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _SpecialPowerKind {
  acrobatics,
  storedPower,
}

/// Ports PSDK damage moves whose main rule is a local base-power override.
///
/// These behaviors still use the shared PSDK move procedure for target,
/// accuracy, Protect and immunity handling. Only the `real_base_power` style
/// calculation is specialized here.
final class SpecialPowerMoveBehavior implements BattleMoveBehavior {
  const SpecialPowerMoveBehavior.acrobatics()
      : battleEngineMethod = 's_acrobatics',
        _kind = _SpecialPowerKind.acrobatics;

  const SpecialPowerMoveBehavior.storedPower()
      : battleEngineMethod = 's_stored_power',
        _kind = _SpecialPowerKind.storedPower;

  @override
  final String battleEngineMethod;
  final _SpecialPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = switch (_kind) {
      _SpecialPowerKind.acrobatics =>
        _acrobaticsPower(context.move.power, user),
      _SpecialPowerKind.storedPower =>
        _storedPower(context.move.power, context.move.dbSymbol, user, target),
    };
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
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
}

int _acrobaticsPower(int movePower, PsdkBattleCombatant user) {
  if (user.heldItemId == null || user.itemConsumed) {
    return movePower * 2;
  }
  return movePower;
}

int _storedPower(
  int movePower,
  String dbSymbol,
  PsdkBattleCombatant user,
  PsdkBattleCombatant target,
) {
  if (dbSymbol == 'punishment') {
    final count = _positiveStageCount(target).clamp(0, 7).toInt();
    return 60 + (20 * count);
  }
  return movePower + (20 * _positiveStageCount(user));
}

int _positiveStageCount(PsdkBattleCombatant battler) {
  return battler.statStages.values.values
      .where((stage) => stage > 0)
      .fold<int>(0, (sum, stage) => sum + stage);
}
