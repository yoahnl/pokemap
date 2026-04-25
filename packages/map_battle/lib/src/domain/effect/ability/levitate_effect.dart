import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class LevitateEffect extends BattleAbilityEffect {
  const LevitateEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'levitate', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LevitateEffect(scope: scope);
  }

  @override
  bool? groundedOverride(PsdkBattleCombatant battler) => false;
}
