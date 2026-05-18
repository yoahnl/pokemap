import '../battle_effect.dart';
import '../battle_effect_scope.dart';

/// Passive PSDK `ItemBurnt` marker.
final class ItemBurntEffect extends BattleEffect {
  const ItemBurntEffect({
    required BattleEffectScope scope,
    int? remainingTurns,
  }) : super(
          id: 'item_burnt',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ItemBurntEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
