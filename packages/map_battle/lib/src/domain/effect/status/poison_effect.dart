import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'status_effect_registry.dart';

final class PoisonEffect extends BattleMajorStatusEffect {
  const PoisonEffect({
    required BattleEffectScope scope,
  }) : super(id: 'poison', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.poison;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PoisonEffect(scope: scope);
  }
}
