import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

const Set<String> _dampBlockedMethods = <String>{
  's_explosion',
  's_misty_explosion',
  's_mind_blown',
  's_chloroblast',
  's_steel_beam',
};

final class DampEffect extends BattleAbilityEffect {
  const DampEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'damp', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DampEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionUser(
    BattleAbilityMoveContext context,
  ) {
    if (_dampBlockedMethods.contains(context.move.battleEngineMethod)) {
      return BattleMoveFailureReason.unusableByUser;
    }
    return null;
  }
}
