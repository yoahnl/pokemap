import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/item_effect.dart';

final class LeechSeedEffect extends BattleEffect {
  const LeechSeedEffect({
    required BattleEffectScope scope,
    required this.source,
  }) : super(
          id: 'leech_seed',
          scope: scope,
        );

  final PsdkBattleSlotRef source;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LeechSeedEffect(scope: scope, source: source);
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return LeechSeedEffect(
      scope: BattlerBattleEffectScope(context.target),
      source: source,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final target = context.owner;
    final targetBattler = context.state.battlerAt(target);
    final sourceBattler = context.state.battlerAt(source);
    if (targetBattler.isFainted ||
        sourceBattler.isFainted ||
        targetBattler.abilityId == 'magic_guard') {
      return null;
    }

    final damage =
        (targetBattler.maxHp ~/ 8).clamp(1, targetBattler.currentHp).toInt();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: source,
      ),
      target: target,
      moveId: 'effect:leech_seed',
      rawDamage: damage,
    );
    if (!damaged.applied) {
      return null;
    }

    final healAmount = _itemAdjustedHealAmount(
      sourceBattler: sourceBattler,
      targetBattler: targetBattler,
      healAmount: damaged.amount,
    );

    if (targetBattler.abilityId == 'liquid_ooze') {
      if (sourceBattler.abilityId == 'magic_guard') {
        return BattleEffectEndTurnResult(
          state: damaged.state,
          rng: damaged.rng,
          events: damaged.events,
        );
      }

      final punished = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: damaged.state,
          rng: damaged.rng,
          turn: context.turn,
          user: target,
        ),
        target: source,
        moveId: 'effect:leech_seed',
        rawDamage: healAmount,
      );
      return BattleEffectEndTurnResult(
        state: punished.state,
        rng: punished.rng,
        events: <PsdkBattleEvent>[
          ...damaged.events,
          ...punished.events,
        ],
      );
    }

    final healed = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: damaged.state,
        rng: damaged.rng,
        turn: context.turn,
        user: source,
      ),
      target: source,
      amount: healAmount,
    );
    final events = <PsdkBattleEvent>[...damaged.events];
    if (healed.applied) {
      final healedSource = healed.state.battlerAt(source);
      events.add(
        PsdkBattleHealEvent(
          user: source,
          target: source,
          moveId: 'effect:leech_seed',
          amount: healed.amount,
          remainingHp: healedSource.currentHp,
        ),
      );
    }

    return BattleEffectEndTurnResult(
      state: healed.state,
      rng: healed.rng,
      events: events,
    );
  }
}

int _itemAdjustedHealAmount({
  required PsdkBattleCombatant sourceBattler,
  required PsdkBattleCombatant targetBattler,
  required int healAmount,
}) {
  var multiplier = 1.0;
  for (final effect in sourceBattler.activeItemEffects) {
    multiplier *= effect.drainHealMultiplier(
      BattleItemDrainModifierContext(
        user: sourceBattler,
        target: targetBattler,
        move: null,
        baseHealAmount: healAmount,
      ),
    );
  }
  final adjusted = (healAmount * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}
