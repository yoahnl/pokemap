import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class EndureEffect extends BattleEffect {
  const EndureEffect({
    required BattleEffectScope scope,
  }) : super(
          id: PsdkBattleEffectIds.endure,
          scope: scope,
          remainingTurns: 0,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return EndureEffect(scope: scope);
  }
}
