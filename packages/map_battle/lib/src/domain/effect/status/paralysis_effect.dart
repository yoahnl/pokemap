import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'status_effect_registry.dart';

final class ParalysisEffect extends BattleMajorStatusEffect {
  const ParalysisEffect({
    required BattleEffectScope scope,
  }) : super(id: 'paralysis', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.paralysis;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ParalysisEffect(scope: scope);
  }
}
