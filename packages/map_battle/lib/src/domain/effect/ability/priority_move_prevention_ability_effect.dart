import '../../../psdk/domain/psdk_battle_move.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class PriorityMovePreventionAbilityEffect extends BattleAbilityEffect {
  const PriorityMovePreventionAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    this.requiresProtectable = true,
    this.restrictToSingleTargetOrPerishSong = false,
  }) : super(abilityId: abilityId, scope: scope);

  final bool requiresProtectable;
  final bool restrictToSingleTargetOrPerishSong;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PriorityMovePreventionAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      requiresProtectable: requiresProtectable,
      restrictToSingleTargetOrPerishSong: restrictToSingleTargetOrPerishSong,
    );
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (context.move.priority <= 0) {
      return null;
    }
    if (requiresProtectable && !context.move.flags.protectable) {
      return null;
    }
    if (context.user.bank == context.target.bank) {
      return null;
    }
    if (restrictToSingleTargetOrPerishSong &&
        !_isSingleTargetOrPerishSong(context.move.target, context.move.id)) {
      return null;
    }
    if (!_protects(context.target.bank)) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  bool _protects(int targetBank) {
    final scope = this.scope;
    return switch (scope) {
      BankBattleEffectScope(:final bank) => bank == targetBank,
      BattlerBattleEffectScope(:final slot) => slot.bank == targetBank,
      _ => true,
    };
  }
}

bool _isSingleTargetOrPerishSong(PsdkBattleMoveTarget target, String moveId) {
  if (moveId == 'perish_song') {
    return true;
  }
  return switch (target) {
    PsdkBattleMoveTarget.adjacentAlly ||
    PsdkBattleMoveTarget.adjacentAllyOrSelf ||
    PsdkBattleMoveTarget.adjacentFoe ||
    PsdkBattleMoveTarget.anyFoe ||
    PsdkBattleMoveTarget.randomFoe ||
    PsdkBattleMoveTarget.self ||
    PsdkBattleMoveTarget.user =>
      true,
    _ => false,
  };
}
