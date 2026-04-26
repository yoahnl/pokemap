import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_transform_state.dart';
import '../../effect/battle_effect.dart';
import '../../effect/battle_effect_scope.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

/// Ports Pokemon SDK's `s_transform` move family.
///
/// PSDK copies the target's visible battle form, battle stats, ability, stat
/// stages and moveset, while keeping the user's HP and level. The copied moves
/// each receive 5 PP for the transformed battler.
final class TransformMoveBehavior
    implements BattleMoveBehavior, BattleMoveUserPreventionBehavior {
  const TransformMoveBehavior();

  @override
  String get battleEngineMethod => 's_transform';

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (!user.transformState.isTransformed) {
      return null;
    }
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final target = prepared.state.battlerAt(targetSlot);
    if (!_canCopy(target)) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: targetSlot,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final user = prepared.state.battlerAt(context.user);
    final transformed = _transformUser(
      user: user,
      target: target,
      userSlot: context.user,
    );

    return BattleMoveBehaviorResolution(
      state: prepared.state.replaceBattler(context.user, transformed),
      rng: prepared.rng,
      events: prepared.events,
    );
  }

  bool _canCopy(PsdkBattleCombatant target) {
    return !target.effects.contains('substitute');
  }

  PsdkBattleCombatant _transformUser({
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
