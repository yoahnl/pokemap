import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/item_effect.dart';

final class BindEffect extends BattleEffect {
  const BindEffect({
    required BattleEffectScope scope,
    required this.origin,
    int remainingTurns = 4,
  }) : super(
          id: PsdkBattleEffectIds.bind,
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final PsdkBattleSlotRef origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BindEffect(
      scope: scope,
      origin: origin,
      remainingTurns: remainingTurns,
    );
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    final originBattler = context.state.combatants[origin];
    if (originBattler == null || originBattler.isFainted) {
      return null;
    }
    return PsdkBattleEffectIds.bind;
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final target = context.owner;
    final targetBattler = context.state.battlerAt(target);
    final originBattler = context.state.combatants[origin];
    if (originBattler == null || originBattler.isFainted) {
      final cleared = context.state.updateBattler(
        target,
        (battler) => battler.copyWith(effects: battler.effects.remove(id)),
      );
      return BattleEffectEndTurnResult(state: cleared, rng: context.rng);
    }
    if (targetBattler.isFainted || targetBattler.abilityId == 'magic_guard') {
      return _tickCounter(context);
    }

    final hpFactor = _bindResidualDamageDivisor(
      state: context.state,
      originSlot: origin,
      origin: originBattler,
      target: targetBattler,
    );
    final damage =
        (targetBattler.maxHp ~/ hpFactor).clamp(1, targetBattler.currentHp);
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: origin,
      ),
      target: target,
      moveId: 'effect:bind',
      rawDamage: damage,
    );
    final ticked = _tickCounter(
      BattleEffectEndTurnContext(
        state: damaged.state,
        rng: damaged.rng,
        turn: context.turn,
        owner: context.owner,
      ),
    );
    if (ticked == null) {
      return BattleEffectEndTurnResult(
        state: damaged.state,
        rng: damaged.rng,
        events: damaged.events,
      );
    }

    return BattleEffectEndTurnResult(
      state: ticked.state,
      rng: ticked.rng,
      events: <PsdkBattleEvent>[
        ...damaged.events,
        ...ticked.events,
      ],
    );
  }

  BattleEffectEndTurnResult? _tickCounter(
    BattleEffectEndTurnContext context,
  ) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextEffects = turns <= 1
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(turns - 1));
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }
}

int _bindResidualDamageDivisor({
  required PsdkBattleState state,
  required PsdkBattleSlotRef originSlot,
  required PsdkBattleCombatant origin,
  required PsdkBattleCombatant target,
}) {
  const defaultDivisor = 8;
  for (final effect in state.activeItemEffectsAt(originSlot)) {
    final divisor = effect.bindResidualDamageDivisor(
      BattleItemBindResidualContext(
        origin: origin,
        target: target,
        defaultDivisor: defaultDivisor,
      ),
    );
    if (divisor != null) {
      return divisor;
    }
  }
  return defaultDivisor;
}
