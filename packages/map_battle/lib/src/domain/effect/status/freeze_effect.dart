import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'status_effect_registry.dart';

final class FreezeEffect extends BattleMajorStatusEffect {
  const FreezeEffect({
    required BattleEffectScope scope,
  }) : super(id: 'freeze', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.freeze;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FreezeEffect(scope: scope);
  }
}
