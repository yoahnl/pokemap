import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class WeatherRockEffect extends BattleItemEffect {
  const WeatherRockEffect({
    required super.itemId,
    required BattleEffectScope scope,
    required Iterable<String> moveDbSymbols,
  })  : moveDbSymbols = moveDbSymbols,
        super(scope: scope);

  final Iterable<String> moveDbSymbols;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WeatherRockEffect(
      itemId: itemId,
      scope: scope,
      moveDbSymbols: moveDbSymbols,
    );
  }

  @override
  int? weatherDuration(String dbSymbol) {
    return moveDbSymbols.contains(dbSymbol) ? 8 : null;
  }
}
