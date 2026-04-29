import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _BasicDamageSpecializationKind {
  fangs,
  falseSwipe,
  fullCrit,
}

/// Ports small PSDK `Basic` descendants that only specialize damage inputs.
///
/// `FalseSwipe` remains partial until Substitute exists in the PSDK combatant
/// effects. `FullCrit` is a direct port of Ruby's `critical_rate = 100`.
final class BasicDamageSpecializationMoveBehavior
    implements BattleMoveBehavior {
  const BasicDamageSpecializationMoveBehavior.fangs()
      : battleEngineMethod = 's_a_fang',
        _kind = _BasicDamageSpecializationKind.fangs;

  const BasicDamageSpecializationMoveBehavior.falseSwipe()
      : battleEngineMethod = 's_false_swipe',
        _kind = _BasicDamageSpecializationKind.falseSwipe;

  const BasicDamageSpecializationMoveBehavior.fullCrit()
      : battleEngineMethod = 's_full_crit',
        _kind = _BasicDamageSpecializationKind.fullCrit;

  @override
  final String battleEngineMethod;
  final _BasicDamageSpecializationKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final move = _damageMove(context.move);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: move,
        rng: prepared.rng,
      ),
    );
    final damage = _damageAmount(
      calculatedDamage: damageResult.damage,
      targetCurrentHp: target.currentHp,
    );
    if (damage <= 0) {
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
      amount: damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: move,
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

  BattleMoveDefinition _damageMove(BattleMoveDefinition move) {
    return switch (_kind) {
      _BasicDamageSpecializationKind.fangs => move,
      _BasicDamageSpecializationKind.falseSwipe => move,
      _BasicDamageSpecializationKind.fullCrit => _moveWithCriticalRate(
          move,
          criticalRate: 100,
        ),
    };
  }

  int _damageAmount({
    required int calculatedDamage,
    required int targetCurrentHp,
  }) {
    return switch (_kind) {
      _BasicDamageSpecializationKind.fangs => calculatedDamage,
      _BasicDamageSpecializationKind.falseSwipe =>
        calculatedDamage >= targetCurrentHp
            ? targetCurrentHp - 1
            : calculatedDamage,
      _BasicDamageSpecializationKind.fullCrit => calculatedDamage,
    };
  }
}

BattleMoveDefinition _moveWithCriticalRate(
  BattleMoveDefinition move, {
  required int criticalRate,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: move.power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
