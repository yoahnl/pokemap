import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class StockpileEffect extends BattleEffect {
  const StockpileEffect({
    required BattleEffectScope scope,
    this.stockpile = 0,
    this.defenseBonus = 0,
    this.specialDefenseBonus = 0,
  }) : super(
          id: 'stockpile',
          scope: scope,
        );

  final int stockpile;
  final int defenseBonus;
  final int specialDefenseBonus;

  bool get increasable => stockpile < maximum;

  bool get usable => stockpile > 0;

  int get maximum => 3;

  StockpileEffect increase({
    int amount = 1,
    int defenseDelta = 0,
    int specialDefenseDelta = 0,
  }) {
    return StockpileEffect(
      scope: scope,
      stockpile: (stockpile + amount).clamp(0, maximum),
      defenseBonus: defenseBonus + defenseDelta,
      specialDefenseBonus: specialDefenseBonus + specialDefenseDelta,
    );
  }

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StockpileEffect(
      scope: scope,
      stockpile: stockpile,
      defenseBonus: defenseBonus,
      specialDefenseBonus: specialDefenseBonus,
    );
  }
}
