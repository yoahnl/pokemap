import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class StatusImmunityEffect extends BattleAbilityEffect {
  StatusImmunityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required Set<PsdkBattleMajorStatus> preventedStatuses,
  })  : _preventedStatuses = Set<PsdkBattleMajorStatus>.unmodifiable(
          preventedStatuses,
        ),
        super(abilityId: abilityId, scope: scope);

  final Set<PsdkBattleMajorStatus> _preventedStatuses;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatusImmunityEffect(
      abilityId: abilityId,
      scope: scope,
      preventedStatuses: _preventedStatuses,
    );
  }

  @override
  bool preventsStatus(BattleAbilityStatusContext context) {
    return _preventedStatuses.contains(context.status);
  }
}
