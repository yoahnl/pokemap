import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class LoadedDiceEffect extends BattleItemEffect {
  const LoadedDiceEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'loaded_dice', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LoadedDiceEffect(scope: scope);
  }

  @override
  int? minimumHitCount(BattleMoveDefinition move) {
    return switch (move.battleEngineMethod) {
      's_multi_hit' || 's_water_shuriken' => 4,
      _ => null,
    };
  }
}
