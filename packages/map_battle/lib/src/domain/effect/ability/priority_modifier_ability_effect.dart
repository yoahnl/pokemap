import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class PranksterAbilityEffect extends BattleAbilityEffect {
  const PranksterAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'prankster', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PranksterAbilityEffect(scope: scope);
  }

  @override
  int movePriorityModifier(BattleAbilityMovePriorityContext context) {
    if (!isOwnedBy(context.user) ||
        context.move.category != PsdkBattleMoveCategory.status) {
      return 0;
    }
    return 1;
  }
}

final class TriageAbilityEffect extends BattleAbilityEffect {
  const TriageAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'triage', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TriageAbilityEffect(scope: scope);
  }

  @override
  int movePriorityModifier(BattleAbilityMovePriorityContext context) {
    if (!isOwnedBy(context.user) || !_isHealingMove(context.move)) {
      return 0;
    }
    return 3;
  }
}

bool _isHealingMove(PsdkBattleMoveData move) {
  return move.heal ||
      _knownHealingMoveMethods.contains(move.battleEngineMethod) ||
      _knownHealingMoveIds.contains(move.dbSymbol) ||
      _knownHealingMoveIds.contains(move.id);
}

const _knownHealingMoveMethods = <String>{
  's_floral_healing',
  's_heal',
  's_heal_weather',
  's_healing_wish',
  's_jungle_healing',
  's_lunar_dance',
  's_purify',
  's_rest',
  's_roost',
  's_wish',
};

const _knownHealingMoveIds = <String>{
  'floral_healing',
  'heal_order',
  'healing_wish',
  'jungle_healing',
  'life_dew',
  'lunar_dance',
  'milk_drink',
  'moonlight',
  'morning_sun',
  'purify',
  'recover',
  'rest',
  'roost',
  'shore_up',
  'slack_off',
  'soft_boiled',
  'strength_sap',
  'synthesis',
  'wish',
};
