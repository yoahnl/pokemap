import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class SoundproofEffect extends BattleAbilityEffect {
  const SoundproofEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'soundproof', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SoundproofEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!context.move.flags.sound) {
      return null;
    }

    final scope = this.scope;
    if (scope is BattlerBattleEffectScope) {
      final owner = scope.slot;
      if (owner.bank != context.target.bank ||
          owner.position != context.target.position) {
        return null;
      }
    }

    return BattleMoveFailureReason.immunity;
  }
}
