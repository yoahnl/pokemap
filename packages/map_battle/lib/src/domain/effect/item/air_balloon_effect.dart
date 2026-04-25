import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../battle_effect.dart';
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
}
