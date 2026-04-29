import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/flinch_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _ActionGatedKind {
  fakeOut,
  snore,
  suckerPunch,
}

/// Ports small PSDK move-specific user gates that are checked before PP.
///
/// The Sucker Punch slice is intentionally local-singles scoped because the
/// current clean move context does not yet expose the full ordered action queue.
final class ActionGatedMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const ActionGatedMoveBehavior.fakeOut()
      : battleEngineMethod = 's_fake_out',
        _kind = _ActionGatedKind.fakeOut;

  const ActionGatedMoveBehavior.snore()
      : battleEngineMethod = 's_snore',
        _kind = _ActionGatedKind.snore;

  const ActionGatedMoveBehavior.suckerPunch()
      : battleEngineMethod = 's_sucker_punch',
        _kind = _ActionGatedKind.suckerPunch;

  @override
  final String battleEngineMethod;
  final _ActionGatedKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    final target = context.state.battlerAt(context.target);
    return switch (_kind) {
      _ActionGatedKind.fakeOut => _canUseFakeOut(user)
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
      _ActionGatedKind.snore => _canUseSnore(user)
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
      _ActionGatedKind.suckerPunch => _canUseSuckerPunch(
          target: target,
          turn: context.turn,
        )
            ? null
            : const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              ),
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
      );
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    final flinched = _kind == _ActionGatedKind.fakeOut
        ? secondary.state.updateBattler(
            targetSlot,
            (battler) => battler.copyWith(
              effects: battler.effects.addEffect(
                FlinchEffect(scope: BattlerBattleEffectScope(targetSlot)),
              ),
            ),
          )
        : secondary.state;

    return BattleMoveBehaviorResolution(
      state: flinched,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  bool _canUseFakeOut(PsdkBattleCombatant user) {
    return user.battleTurnCount <= 1 && !user.effects.contains('instruct');
  }

  bool _canUseSnore(PsdkBattleCombatant user) {
    return user.majorStatus == PsdkBattleMajorStatus.sleep ||
        user.abilityId == 'comatose';
  }

  bool _canUseSuckerPunch({
    required PsdkBattleCombatant target,
    required int turn,
  }) {
    if (target.moveHistory.attempts.any((entry) => entry.turn == turn)) {
      return false;
    }
    if (target.moves.isEmpty) {
      return false;
    }
    return target.moves.first.category != PsdkBattleMoveCategory.status;
  }
}
