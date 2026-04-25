import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _DirectHpMoveKind {
  endeavor,
  finalGambit,
}

/// Ports PSDK moves that assign HP loss directly instead of using the normal
/// damage formula.
///
/// This behavior deliberately reuses the shared procedure before HP changes so
/// accuracy, Protect and type-immunity stay aligned with other PSDK move
/// families. It does not attempt to model text messages or later faint-process
/// callbacks, which is why Final Gambit remains partial in the matrix.
final class DirectHpMoveBehavior implements BattleMoveUserPreventionBehavior {
  const DirectHpMoveBehavior.endeavor()
      : battleEngineMethod = 's_endeavor',
        _kind = _DirectHpMoveKind.endeavor;

  const DirectHpMoveBehavior.finalGambit()
      : battleEngineMethod = 's_final_gambit',
        _kind = _DirectHpMoveKind.finalGambit;

  @override
  final String battleEngineMethod;
  final _DirectHpMoveKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    if (_kind != _DirectHpMoveKind.endeavor) {
      return null;
    }

    final userHp = context.state.battlerAt(context.user).currentHp;
    final targetHp = context.state.battlerAt(context.target).currentHp;
    if (userHp < targetHp) {
      return null;
    }

    // Ruby PSDK implements this in `move_usable_by_user`, before PP spending
    // and before the usage animation. Exposing it through the behavior-level
    // prevention seam keeps that timing exact for the clean engine runner.
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _DirectHpMoveKind.endeavor => _resolveEndeavor(
          context: context,
          prepared: prepared,
        ),
      _DirectHpMoveKind.finalGambit => _resolveFinalGambit(
          context: context,
          prepared: prepared,
        ),
    };
  }

  BattleMoveBehaviorResolution _resolveEndeavor({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final target = prepared.psdkTargets.single;
    final userHp = prepared.state.battlerAt(context.user).currentHp;
    final targetHp = prepared.state.battlerAt(target).currentHp;
    final amount = targetHp - userHp;
    if (amount <= 0) {
      return prepared.toResolution();
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: target,
      moveId: context.move.id,
      rng: prepared.rng,
      turn: context.turn,
      amount: amount,
    );

    return BattleMoveBehaviorResolution(
      state: applied.state,
      rng: applied.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveFinalGambit({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final hpDealt = prepared.state.battlerAt(context.user).currentHp;
    var nextState = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    // PSDK first removes the user's current HP, then applies that captured
    // amount to every actual target. Keeping the original amount protects the
    // move from accidentally dealing zero after the self-KO mutation.
    final selfDamage = applyDirectDamage(
      state: nextState,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: hpDealt,
    );
    nextState = selfDamage.state;
    rng = selfDamage.rng;
    if (selfDamage.event != null) {
      events.add(selfDamage.event!);
    }

    for (final target in prepared.psdkTargets) {
      final targetDamage = applyDirectDamage(
        state: nextState,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: hpDealt,
      );
      nextState = targetDamage.state;
      rng = targetDamage.rng;
      if (targetDamage.event != null) {
        events.add(targetDamage.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: prevention.reason.jsonName,
        ),
      ],
      successful: false,
    );
  }
}
