import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

typedef HeldItemDamageCondition = bool Function(
  BattleItemDamageModifierContext context,
);

typedef HeldItemStatCondition = bool Function(PsdkBattleCombatant battler);

final class HeldItemModifierEffect extends BattleItemEffect {
  const HeldItemModifierEffect({
    required String itemId,
    required BattleEffectScope scope,
    this.basePowerMultiplier = 1,
    this.finalDamageMultiplier = 1,
    this.statMultipliers = const <String, double>{},
    HeldItemDamageCondition? damageCondition,
    HeldItemStatCondition? statCondition,
  })  : _damageCondition = damageCondition,
        _statCondition = statCondition,
        super(itemId: itemId, scope: scope);

  final double basePowerMultiplier;
  final double finalDamageMultiplier;
  final Map<String, double> statMultipliers;
  final HeldItemDamageCondition? _damageCondition;
  final HeldItemStatCondition? _statCondition;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double damageBasePowerMultiplier(BattleItemDamageModifierContext context) {
    if (!_canApplyTo(context.user) ||
        !(_damageCondition?.call(context) ?? true)) {
      return 1;
    }
    return basePowerMultiplier;
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    if (!_canApplyTo(context.user) ||
        !(_damageCondition?.call(context) ?? true)) {
      return 1;
    }
    return finalDamageMultiplier;
  }

  @override
  double statMultiplier(PsdkBattleCombatant battler, String stat) {
    if (!_canApplyTo(battler) || !(_statCondition?.call(battler) ?? true)) {
      return 1;
    }
    return statMultipliers[stat] ?? 1;
  }

  bool _canApplyTo(PsdkBattleCombatant battler) {
    return battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed;
  }
}

final class GemItemEffect extends BattleItemEffect {
  const GemItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.moveType,
  }) : super(itemId: itemId, scope: scope);

  final String moveType;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    return _canUseGem(context) ? 1.3 : 1;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.user != owner ||
        context.target == owner ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final user = context.state.battlerAt(owner);
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed ||
        context.move.type.toLowerCase() != moveType ||
        context.move.power <= 0 ||
        context.move.battleEngineMethod == 's_pledge') {
      return null;
    }
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: consumed.state,
      rng: consumed.rng,
      events: consumed.events,
    );
  }

  bool _canUseGem(BattleItemDamageModifierContext context) {
    return context.user.heldItemId == itemId &&
        !context.user.itemConsumed &&
        !context.user.itemEffectsSuppressed &&
        context.moveType == moveType &&
        context.move.power > 0 &&
        context.move.battleEngineMethod != 's_pledge';
  }
}

final class LifeOrbEffect extends BattleItemEffect {
  const LifeOrbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'life_orb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LifeOrbEffect(scope: scope);
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    if (context.user.heldItemId != itemId ||
        context.user.itemConsumed ||
        context.user.itemEffectsSuppressed ||
        context.move.power <= 0) {
      return 1;
    }
    return 1.3;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.user != owner ||
        context.target == owner ||
        context.damage <= 0) {
      return null;
    }
    final user = context.state.battlerAt(owner);
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed ||
        user.isFainted ||
        user.abilityId == 'magic_guard') {
      return null;
    }

    final amount = (user.maxHp ~/ 10).clamp(1, user.currentHp).toInt();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'item:life_orb',
      rawDamage: amount,
    );
    if (!damaged.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: damaged.state,
      rng: damaged.rng,
      events: <PsdkBattleEvent>[...damaged.events],
    );
  }
}
