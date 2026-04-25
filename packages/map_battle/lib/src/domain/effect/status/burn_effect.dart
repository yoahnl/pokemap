import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'status_effect_registry.dart';

final class BurnEffect extends BattleMajorStatusEffect {
  const BurnEffect({
    required BattleEffectScope scope,
  }) : super(id: 'burn', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.burn;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BurnEffect(scope: scope);
  }
}
