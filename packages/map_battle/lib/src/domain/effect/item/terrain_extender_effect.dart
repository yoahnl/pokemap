import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class TerrainExtenderEffect extends BattleItemEffect {
  const TerrainExtenderEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'terrain_extender', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TerrainExtenderEffect(scope: scope);
  }

  @override
  int? terrainDuration(String dbSymbol) => 8;
}
