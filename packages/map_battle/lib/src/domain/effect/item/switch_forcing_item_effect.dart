import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../handler/battle_switch_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class EjectButtonEffect extends BattleItemEffect {
  const EjectButtonEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'eject_button', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.user == owner ||
        context.targetFainted ||
        _sheerForceAlreadyActivated(context)) {
      return null;
    }
    final holder = context.state.battlerAt(owner);
    if (!_canUseHeldItem(holder, itemId) ||
        holder.switching ||
        !const BattleSwitchHandler().hasAvailableReplacement(
          state: context.state,
          target: owner,
        )) {
      return null;
    }

    final switching = const BattleSwitchHandler().markSwitching(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: owner,
      switching: true,
    );
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: switching.state,
        rng: switching.rng,
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
}

final class RedCardEffect extends BattleItemEffect {
  const RedCardEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'red_card', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.user == owner ||
        context.targetFainted ||
        _sheerForceAlreadyActivated(context)) {
      return null;
    }
    final holder = context.state.battlerAt(owner);
    final attacker = context.state.battlerAt(context.user);
    if (!_canUseHeldItem(holder, itemId) ||
        attacker.switching ||
        !const BattleSwitchHandler().hasAvailableReplacement(
          state: context.state,
          target: context.user,
        )) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    if (_normalizedAbilityId(attacker) != 'guard_dog') {
      final switching = const BattleSwitchHandler().markSwitching(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: owner,
        ),
        target: context.user,
        switching: true,
      );
      nextState = switching.state;
      nextRng = switching.rng;
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: nextState,
        rng: nextRng,
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
}

bool _canUseHeldItem(PsdkBattleCombatant battler, String itemId) {
  return !battler.isFainted &&
      battler.heldItemId == itemId &&
      !battler.itemConsumed &&
      !battler.itemEffectsSuppressed;
}

bool _sheerForceAlreadyActivated(BattleEffectPostDamageContext context) {
  final attacker = context.state.battlerAt(context.user);
  if (_normalizedAbilityId(attacker) != 'sheer_force' ||
      attacker.effects.contains('ability_suppressed') ||
      context.move.category == PsdkBattleMoveCategory.status) {
    return false;
  }
  if (context.move.statuses.any(
        (status) => status.majorStatus != null || status.volatileStatus != null,
      ) ||
      context.move.effectChance != null) {
    return true;
  }
  if (context.move.stageMods.isEmpty) {
    return false;
  }
  final onlyPositive = context.move.stageMods.every((mod) => mod.stages > 0);
  final onlyNegative = context.move.stageMods.every((mod) => mod.stages < 0);
  return switch (context.move.target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => onlyPositive,
    _ => onlyNegative,
  };
}

String? _normalizedAbilityId(PsdkBattleCombatant battler) {
  return battler.abilityId?.trim().toLowerCase();
}
