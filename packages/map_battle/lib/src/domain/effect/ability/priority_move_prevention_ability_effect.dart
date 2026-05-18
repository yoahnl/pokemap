import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class PriorityMovePreventionAbilityEffect extends BattleAbilityEffect {
  const PriorityMovePreventionAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PriorityMovePreventionAbilityEffect(
      abilityId: abilityId,
      scope: scope,
    );
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (context.move.priority <= 0 || !context.move.flags.protectable) {
      return null;
    }
    if (context.user.bank == context.target.bank) {
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
