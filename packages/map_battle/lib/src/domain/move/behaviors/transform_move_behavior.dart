import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_transform_service.dart';
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

  static const PsdkBattleTransformService _transformService =
      PsdkBattleTransformService();

  @override
  String get battleEngineMethod => 's_transform';

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_transformService.canTransform(user)) {
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
    if (!_transformService.canCopy(target)) {
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
    final transformed = _transformService.transform(
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
}
