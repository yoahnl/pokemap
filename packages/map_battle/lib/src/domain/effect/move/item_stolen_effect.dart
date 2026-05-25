import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `ItemStolen` marker.
///
/// The marker keeps item-loss dependent hooks such as Unburden active while the
/// battler has no item. It clears once the holder receives a replacement item.
final class ItemStolenEffect extends BattleEffect {
  const ItemStolenEffect({
    required BattleEffectScope scope,
    int? remainingTurns,
  }) : super(
          id: 'item_stolen',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ItemStolenEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectItemChangeResult? onPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    if (!_appliesTo(context.owner) ||
        context.target != context.owner ||
        context.nextItemId == null) {
      return null;
    }
    return BattleEffectItemChangeResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.remove(id),
        ),
      ),
      rng: context.rng,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == owner;
  }
}
