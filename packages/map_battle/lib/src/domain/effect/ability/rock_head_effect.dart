import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

const Set<String> _rockHeadExcludedMoves = <String>{
  'struggle',
  'shadow_rush',
  'shadow_end',
};

final class RockHeadEffect extends BattleAbilityEffect {
  const RockHeadEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'rock_head', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RockHeadEffect(scope: scope);
  }

  @override
  bool preventsRecoil(BattleAbilityMoveContext context) {
    return isOwnedBy(context.user) &&
        !_rockHeadExcludedMoves.contains(context.move.dbSymbol);
  }
}
