import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../effect/battle_effect.dart';
import '../effect/battle_effect_scope.dart';
import 'battle_transform_state.dart';

final class PsdkBattleTransformService {
  const PsdkBattleTransformService();

  bool canTransform(PsdkBattleCombatant user) {
    return !user.transformState.isTransformed;
  }

  bool canCopy(PsdkBattleCombatant target) {
    return !target.transformState.isTransformed &&
        !target.effects.contains('substitute');
  }

  PsdkBattleCombatant transform({
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
    required PsdkBattleSlotRef userSlot,
  }) {
    return user.copyWith(
      speciesId: target.speciesId,
      displayName: target.displayName,
      types: target.types,
      stats: target.stats,
      abilityId: target.abilityId,
      statStages: target.statStages,
      currentWeightKg: target.currentWeightKg,
      moves: _transformMoves(target.moves),
      transformState: PsdkBattleTransformState(
        transformedFromSpeciesId:
            user.transformState.transformedFromSpeciesId ?? user.speciesId,
        illusionSpeciesId: user.transformState.illusionSpeciesId,
        illusionDisplayName: user.transformState.illusionDisplayName,
      ),
      effects: user.effects.addEffect(
        GenericBattleEffect(
          id: 'transform',
          scope: BattlerBattleEffectScope(userSlot),
        ),
      ),
    );
  }

  List<PsdkBattleMoveData> _transformMoves(List<PsdkBattleMoveData> moves) {
    if (moves.isEmpty) {
      return const <PsdkBattleMoveData>[];
    }
    return moves
        .map(
          (move) => move.copyWith(
            pp: 5,
            currentPp: 5,
          ),
        )
        .toList(growable: false);
  }
}
