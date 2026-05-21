import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import 'ability_effect.dart';

enum ItemStealAbilityMode {
  stealFromAttacker,
  stealFromTarget,
}

final class ItemStealAbilityEffect extends BattleAbilityEffect {
  const ItemStealAbilityEffect({
    required super.abilityId,
    required super.scope,
    required this.mode,
  });

  final ItemStealAbilityMode mode;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ItemStealAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      mode: mode,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        !isOwnedBy(context.owner) ||
        context.damage <= 0 ||
        context.user == context.target ||
        context.state.battlerAt(owner).effects.contains('ability_suppressed')) {
      return null;
    }

    return switch (mode) {
      ItemStealAbilityMode.stealFromAttacker =>
        _resolvePickpocket(context, owner),
      ItemStealAbilityMode.stealFromTarget => _resolveMagician(context, owner),
    };
  }

  BattleEffectPostDamageResult? _resolvePickpocket(
    BattleEffectPostDamageContext context,
    PsdkBattleSlotRef owner,
  ) {
    if (owner != context.target ||
        context.targetFainted ||
        !context.move.flags.contact) {
      return null;
    }

    final holder = context.state.battlerAt(owner);
    final attacker = context.state.battlerAt(context.user);
    if (holder.heldItemId != null ||
        attacker.isFainted ||
        attacker.heldItemId == null) {
      return null;
    }

    return _transferItem(
      context: context,
      from: context.user,
      to: owner,
      itemId: attacker.heldItemId!,
    );
  }

  BattleEffectPostDamageResult? _resolveMagician(
    BattleEffectPostDamageContext context,
    PsdkBattleSlotRef owner,
  ) {
    if (owner != context.user) {
      return null;
    }

    final thief = context.state.battlerAt(owner);
    final target = context.state.battlerAt(context.target);
    if (thief.isFainted ||
        thief.heldItemId != null ||
        target.heldItemId == null ||
        _isInertDamage(context.move)) {
      return null;
    }

    return _transferItem(
      context: context,
      from: context.target,
      to: owner,
      itemId: target.heldItemId!,
    );
  }

  BattleEffectPostDamageResult _transferItem({
    required BattleEffectPostDamageContext context,
    required PsdkBattleSlotRef from,
    required PsdkBattleSlotRef to,
    required String itemId,
  }) {
    final removed = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: to,
      ),
      target: from,
      heldItemId: null,
    );
    final stolen = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: removed.state,
        rng: removed.rng,
        turn: context.turn,
        user: to,
      ),
      target: to,
      heldItemId: itemId,
    );
    return BattleEffectPostDamageResult(
      state: stolen.state,
      rng: stolen.rng,
      events: <PsdkBattleEvent>[
        ...removed.events,
        ...stolen.events,
      ],
    );
  }
}

bool _isInertDamage(BattleMoveDefinition move) {
  return move.id.startsWith('item:') || move.id.startsWith('ability:');
}
