import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/ability/ability_effect.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';
import 'battle_stat_change_handler.dart';

final class BattleDamageHandler {
  const BattleDamageHandler();

  BattleHandlerResult applyDamage({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
    required int rawDamage,
    PsdkBattleMoveCategory? moveCategory,
    BattleMoveDefinition? move,
    bool criticalHit = false,
    bool isFinalHit = true,
  }) {
    final targetBattler = context.state.battlerAt(target);
    final moveDefinition = move ??
        _damageMoveDefinition(
          moveId: moveId,
          category: moveCategory,
        );
    final abilityBypassed = _userBypassesAbilityPrevention(
      context.state.battlerAt(context.user),
    );
    final prevention = targetBattler.effects.dispatchDamagePrevention(
      BattleEffectDamagePreventionContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        owner: target,
        user: context.user,
        target: target,
        move: moveDefinition,
        damage: rawDamage,
      ),
      where: (effect) {
        if (effect is! BattleAbilityEffect) {
          return true;
        }
        return !targetBattler.effects.contains('ability_suppressed') &&
            !abilityBypassed;
      },
    );
    if (prevention != null && prevention.prevented) {
      return BattleHandlerResult(
        state: prevention.state,
        rng: prevention.rng,
        events: prevention.events,
        applied: prevention.applied,
        reason: prevention.reason.jsonName,
        amount: prevention.amount,
      );
    }

    final incomingDamage = rawDamage.clamp(0, targetBattler.currentHp).toInt();
    final damage = targetBattler.effects.contains('endure') &&
            incomingDamage >= targetBattler.currentHp
        ? (targetBattler.currentHp - 1)
            .clamp(0, targetBattler.currentHp)
            .toInt()
        : incomingDamage;
    if (damage <= 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_damage',
      );
    }

    final remainingHp = targetBattler.currentHp - damage;
    final nextTarget = targetBattler
        .recordDamage(
          turn: context.turn,
          source: context.user,
          moveId: moveId,
          damage: damage,
          remainingHp: remainingHp,
          moveCategory: moveCategory,
        )
        .copyWith(currentHp: remainingHp);

    final damagedState = context.state.replaceBattler(target, nextTarget);
    final damageEvent = PsdkBattleDamageEvent(
      user: context.user,
      target: target,
      moveId: moveId,
      damage: damage,
      remainingHp: nextTarget.currentHp,
    );
    final rageResult = _applyRageCounterIfNeeded(
      context: context,
      state: damagedState,
      target: target,
    );
    final postDamageResult = _dispatchPostDamageEffects(
      context: context,
      state: rageResult.state,
      rng: rageResult.rng,
      target: target,
      move: moveDefinition,
      damage: damage,
      criticalHit: criticalHit,
      isFinalHit: isFinalHit,
    );

    return BattleHandlerResult(
      state: postDamageResult.state,
      rng: postDamageResult.rng,
      amount: damage,
      events: <PsdkBattleEvent>[
        damageEvent,
        ...rageResult.events,
        ...postDamageResult.events,
      ],
    );
  }

  BattleEffectPostDamageResult _dispatchPostDamageEffects({
    required BattleHandlerContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required int damage,
    required bool criticalHit,
    required bool isFinalHit,
  }) {
    var nextState = state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;

    final owners = <PsdkBattleSlotRef>[
      target,
      if (context.user != target) context.user,
      for (final owner in nextState.alliesOf(target))
        if (owner != context.user && _observesAllyPostDamage(nextState, owner))
          owner,
    ];
    for (final owner in owners) {
      final result = nextState.battlerAt(owner).effects.dispatchPostDamage(
            BattleEffectPostDamageContext(
              state: nextState,
              rng: nextRng,
              turn: context.turn,
              owner: owner,
              user: context.user,
              target: target,
              move: move,
              damage: damage,
              targetFainted: nextState.battlerAt(target).isFainted,
              criticalHit: criticalHit,
              canFlee: context.canFlee,
              userActionOrder: context.actionOrder,
              targetActionOrder: context.targetActionOrder,
              isFinalHit: isFinalHit,
            ),
          );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      applied = applied || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectPostDamageResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: applied,
    );
  }

  BattleHandlerResult _applyRageCounterIfNeeded({
    required BattleHandlerContext context,
    required PsdkBattleState state,
    required PsdkBattleSlotRef target,
  }) {
    if (context.user.bank == target.bank) {
      return BattleHandlerResult(state: state, rng: context.rng);
    }

    final targetBattler = state.battlerAt(target);
    if (!targetBattler.effects.contains('rage')) {
      return BattleHandlerResult(state: state, rng: context.rng);
    }

    return const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: target,
      stat: 'attack',
      stages: 1,
    );
  }
}

bool _observesAllyPostDamage(
  PsdkBattleState state,
  PsdkBattleSlotRef owner,
) {
  return state.battlerAt(owner).abilityEffects.any(
        (effect) => effect.affectsAlliesPostDamage,
      );
}

const _abilityPreventionBypassAbilityIds = <String>{
  'mold_breaker',
  'teravolt',
  'turboblaze',
};

bool _userBypassesAbilityPrevention(PsdkBattleCombatant user) {
  if (user.effects.contains('ability_suppressed')) {
    return false;
  }
  final abilityId = user.abilityId?.trim().toLowerCase();
  return abilityId != null &&
      _abilityPreventionBypassAbilityIds.contains(abilityId);
}

BattleMoveDefinition _damageMoveDefinition({
  required String moveId,
  PsdkBattleMoveCategory? category,
}) {
  return BattleMoveDefinition(
    id: moveId,
    dbSymbol: moveId,
    name: moveId,
    type: 'normal',
    category: category ?? PsdkBattleMoveCategory.physical,
    power: 0,
    accuracy: 100,
    pp: 1,
    priority: 0,
    battleEngineMethod: 's_direct_damage',
    target: PsdkBattleMoveTarget.adjacentFoe,
    flags: const BattleMoveFlags(protectable: false),
  );
}
