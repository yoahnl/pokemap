import '../../../psdk/domain/psdk_battle_move.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class ParentalBondEffect extends BattleAbilityEffect {
  const ParentalBondEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'parental_bond', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ParentalBondEffect(scope: scope);
  }

  static bool canApplyFollowUp({
    required BattleMoveDefinition move,
    required bool alreadyFollowUp,
  }) {
    return !alreadyFollowUp &&
        move.category != PsdkBattleMoveCategory.status &&
        move.power > 0 &&
        !_excludedMethods.contains(_normalizedId(move.battleEngineMethod));
  }
}

const _excludedMethods = <String>{
  's_solar_beam',
  's_2turns',
  's_endeavor',
  's_ohko',
  's_fling',
  's_explosion',
  's_final_gambit',
  's_uproar',
  's_rollout',
  's_ice_ball',
  's_relic_sound',
  's_electro_shot',
};

String _normalizedId(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_');
}
