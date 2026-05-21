import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_item_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/berry_item_effect.dart';
import '../item/item_effect_registry.dart';
import 'ability_effect.dart';

const String unburdenActiveEffectId = 'unburden_active';

final class UnburdenEffect extends BattleAbilityEffect {
  const UnburdenEffect({required BattleEffectScope scope})
      : super(abilityId: 'unburden', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return UnburdenEffect(scope: scope);
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    if (context.stat != 'speed' || context.battler.abilityId != abilityId) {
      return 1;
    }
    if (context.battler.effects.contains(unburdenActiveEffectId) ||
        context.battler.effects.contains('item_stolen') ||
        context.battler.effects.contains('item_burnt')) {
      return 2;
    }
    return 1;
  }

  @override
  BattleEffectItemChangeResult? onPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    if (!isOwnedBy(context.target)) {
      return null;
    }
    final battler = context.state.battlerAt(context.target);
    if (battler.abilityId != abilityId) {
      return null;
    }

    final shouldEnable =
        context.previousItemId != null && context.nextItemId == null;
    final nextEffects = shouldEnable
        ? battler.effects.add(unburdenActiveEffectId)
        : battler.effects.remove(unburdenActiveEffectId);
    if (identical(nextEffects, battler.effects)) {
      return null;
    }
    return BattleEffectItemChangeResult(
      state: context.state.updateBattler(
        context.target,
        (current) => current.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    final nextEffects = battler.effects.remove(unburdenActiveEffectId);
    if (identical(nextEffects, battler.effects)) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: context.state.updateBattler(
        context.owner,
        (current) => current.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }
}

final class HarvestEffect extends BattleAbilityEffect {
  const HarvestEffect({required BattleEffectScope scope})
      : super(abilityId: 'harvest', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HarvestEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    final consumedItemId = battler.consumedItemId;
    if (battler.abilityId != abilityId ||
        battler.isFainted ||
        battler.heldItemId != null ||
        !battler.itemConsumed ||
        consumedItemId == null ||
        !isPsdkBerryItemId(consumedItemId)) {
      return null;
    }

    final sunny = _globalSunny(context);
    final chance = sunny
        ? null
        : context.rng.generic.nextChance(numerator: 1, denominator: 2);
    final nextRng = chance == null
        ? context.rng
        : context.rng.copyWith(generic: chance.next);
    if (chance != null && !chance.didOccur) {
      return BattleEffectEndTurnResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }

    final restored = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: nextRng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      heldItemId: consumedItemId,
    );
    final berryResult =
        restored.state.battlerAt(context.owner).effects.dispatchEndTurn(
              BattleEffectEndTurnContext(
                state: restored.state,
                rng: restored.rng,
                turn: context.turn,
                owner: context.owner,
              ),
              where: (effect) => effect is BerryItemEffect,
            );
    return BattleEffectEndTurnResult(
      state: berryResult.state,
      rng: berryResult.rng,
      events: <PsdkBattleEvent>[
        ...restored.events,
        ...berryResult.events,
      ],
      applied: true,
    );
  }
}

final class RipenEffect extends BattleAbilityEffect {
  const RipenEffect({required BattleEffectScope scope})
      : super(abilityId: 'ripen', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RipenEffect(scope: scope);
  }
}

final class CheekPouchEffect extends BattleAbilityEffect {
  const CheekPouchEffect({required BattleEffectScope scope})
      : super(abilityId: 'cheek_pouch', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CheekPouchEffect(scope: scope);
  }

  @override
  BattleEffectItemChangeResult? onPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    if (!isOwnedBy(context.target) ||
        context.reason != 'consumed' ||
        context.consumedItemId == null ||
        !isPsdkBerryItemId(context.consumedItemId!)) {
      return null;
    }
    final battler = context.state.battlerAt(context.target);
    if (battler.abilityId != abilityId ||
        battler.isFainted ||
        battler.effects.contains('heal_block')) {
      return null;
    }

    final healed = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.target,
      ),
      target: context.target,
      amount: battler.maxHp ~/ 3,
    );
    if (!healed.applied) {
      return null;
    }
    final current = healed.state.battlerAt(context.target);
    return BattleEffectItemChangeResult(
      state: healed.state,
      rng: healed.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: context.target,
          target: context.target,
          moveId: 'ability:cheek_pouch',
          amount: healed.amount,
          remainingHp: current.currentHp,
        ),
      ],
    );
  }
}

final class CudChewEffect extends BattleAbilityEffect {
  const CudChewEffect({required BattleEffectScope scope})
      : super(abilityId: 'cud_chew', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CudChewEffect(scope: scope);
  }

  @override
  BattleEffectItemChangeResult? onPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    if (!isOwnedBy(context.target) ||
        context.reason != 'consumed' ||
        context.consumedItemId == null ||
        !isPsdkBerryItemId(context.consumedItemId!)) {
      return null;
    }

    final battler = context.state.battlerAt(context.target);
    if (battler.abilityId != abilityId || battler.isFainted) {
      return null;
    }

    final nextEffects = battler.effects.addEffect(
      CudChewPendingEffect(
        scope: BattlerBattleEffectScope(context.target),
        berryItemId: context.consumedItemId!,
        remainingTurns: 2,
      ),
    );
    return BattleEffectItemChangeResult(
      state: context.state.updateBattler(
        context.target,
        (current) => current.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }
}

final class CudChewPendingEffect extends BattleEffect {
  const CudChewPendingEffect({
    required BattleEffectScope scope,
    required this.berryItemId,
    required int remainingTurns,
  }) : super(
          id: 'cud_chew_pending',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final String berryItemId;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CudChewPendingEffect(
      scope: scope,
      berryItemId: berryItemId,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = switch (scope) {
      BattlerBattleEffectScope(:final slot) => slot,
      _ => null,
    };
    if (owner == null || owner != context.owner) {
      return null;
    }

    final turns = remainingTurns ?? 0;
    if (turns > 1) {
      return _replaceSelf(context, turns - 1);
    }

    final withoutPending = context.state.updateBattler(
      owner,
      (battler) => battler.copyWith(
        effects: battler.effects.remove(id),
      ),
    );
    final berryEffect = ItemEffectRegistry().create(berryItemId, owner: owner);
    final berryResult = berryEffect is BerryItemEffect
        ? berryEffect.forceExecute(
            state: withoutPending,
            rng: context.rng,
            turn: context.turn,
            owner: owner,
          )
        : null;
    return BattleEffectEndTurnResult(
      state: berryResult?.state ?? withoutPending,
      rng: berryResult?.rng ?? context.rng,
      events: <PsdkBattleEvent>[
        ...?berryResult?.events,
        PsdkBattleEffectEvent.removed(
          turn: context.turn,
          target: owner,
          effectId: id,
          remainingTurns: 0,
          reason: 'cud_chew',
        ),
      ],
    );
  }

  BattleEffectEndTurnResult _replaceSelf(
    BattleEffectEndTurnContext context,
    int nextTurns,
  ) {
    final owner = context.owner;
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        owner,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(copyWithRemainingTurns(nextTurns)),
        ),
      ),
      rng: context.rng,
      applied: true,
    );
  }
}

bool _globalSunny(BattleEffectEndTurnContext context) {
  if (context.state.weatherEffectsSuppressed) {
    return false;
  }
  final field = context.state.field;
  return field.isWeatherActive(PsdkBattleWeatherId.sunny) ||
      field.isWeatherActive(PsdkBattleWeatherId.hardsun);
}
