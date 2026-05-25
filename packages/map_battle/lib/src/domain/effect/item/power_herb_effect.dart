import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class PowerHerbEffect extends BattleItemEffect {
  const PowerHerbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'power_herb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  bool twoTurnShortcut(BattleMoveDefinition move) {
    if (move.dbSymbol == 'sky_drop' || move.id == 'sky_drop') {
      return false;
    }
    return move.battleEngineMethod == 's_2turns' || move.charge;
  }
}
