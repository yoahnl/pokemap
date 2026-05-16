import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';

/// Stores the first-turn state of a Pokemon SDK two-turn move.
///
/// PSDK does not let the battler freely pick a different move while waiting to
/// release moves such as Fly or Dig. The charged move id and original target
/// give the action mapper enough information to replay the release turn without
/// hardcoding that rule in every individual two-turn move implementation.
final class TwoTurnChargeEffect extends BattleEffect {
  const TwoTurnChargeEffect({
    required BattleEffectScope scope,
    required this.chargedMoveId,
    required this.chargedTarget,
    int? remainingTurns,
  }) : super(
          id: PsdkBattleEffectIds.twoTurnCharge,
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final String chargedMoveId;
  final PsdkBattleSlotRef chargedTarget;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TwoTurnChargeEffect(
      scope: scope,
      chargedMoveId: chargedMoveId,
      chargedTarget: chargedTarget,
      remainingTurns: remainingTurns,
    );
  }
}
