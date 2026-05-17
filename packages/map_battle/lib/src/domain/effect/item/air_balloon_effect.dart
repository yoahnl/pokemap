import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class AirBalloonEffect extends BattleItemEffect {
  const AirBalloonEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'air_balloon', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AirBalloonEffect(scope: scope);
  }

  @override
  bool? groundedOverride(PsdkBattleCombatant battler) {
    return battler.itemConsumed ? null : false;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.damage <= 0 ||
        context.user == owner ||
        _isInertDirectDamage(context.move.id)) {
      return null;
    }

    final target = context.state.battlerAt(owner);
    if (target.heldItemId != itemId ||
        target.itemConsumed ||
        target.itemEffectsSuppressed) {
      return null;
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
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
      applied: true,
    );
  }
}

bool _isInertDirectDamage(String moveId) {
  return moveId.startsWith('item:') || moveId.startsWith('status:');
}
