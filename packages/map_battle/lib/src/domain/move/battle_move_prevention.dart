import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_slot.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_data.dart';

enum BattleMoveFailureReason {
  userFainted,
  noTarget,
  unusableByUser,
  accuracy,
  immunity,
  pp,
  protected,
  terrain,
  weather,
}

extension BattleMoveFailureReasonJson on BattleMoveFailureReason {
  String get jsonName {
    return switch (this) {
      BattleMoveFailureReason.userFainted => 'user_fainted',
      BattleMoveFailureReason.noTarget => 'no_target',
      BattleMoveFailureReason.unusableByUser => 'unusable_by_user',
      BattleMoveFailureReason.accuracy => 'accuracy',
      BattleMoveFailureReason.immunity => 'immunity',
      BattleMoveFailureReason.pp => 'pp',
      BattleMoveFailureReason.protected => 'protected',
      BattleMoveFailureReason.terrain => 'terrain',
      BattleMoveFailureReason.weather => 'weather',
    };
  }
}

typedef BattleMoveUserPreventionHook = BattleMoveUserPreventionResult? Function(
    BattleMoveUserPreventionContext context);

typedef BattleMoveFailureHook = void Function(
  BattleMoveFailureContext context,
);

typedef BattleMoveAccuracyHook = void Function(
  BattleMoveAccuracyHookContext context,
);

/// Extensible no-op hook bundle for the PSDK-style move procedure.
///
/// The hooks are intentionally observational except for user prevention. Later
/// lots can swap these callbacks for richer effect handlers without changing
/// the public engine entry points added in this migration slice.
final class BattleMoveProcedureHooks {
  BattleMoveProcedureHooks({
    List<BattleMoveUserPreventionHook> userPreventionHooks =
        const <BattleMoveUserPreventionHook>[],
    List<BattleMoveFailureHook> failureHooks = const <BattleMoveFailureHook>[],
    List<BattleMoveAccuracyHook> preAccuracyHooks =
        const <BattleMoveAccuracyHook>[],
    List<BattleMoveAccuracyHook> postAccuracyHooks =
        const <BattleMoveAccuracyHook>[],
    List<BattleMoveAccuracyHook> postAccuracyMoveHooks =
        const <BattleMoveAccuracyHook>[],
  })  : userPreventionHooks = List<BattleMoveUserPreventionHook>.unmodifiable(
          userPreventionHooks,
        ),
        failureHooks = List<BattleMoveFailureHook>.unmodifiable(failureHooks),
        preAccuracyHooks =
            List<BattleMoveAccuracyHook>.unmodifiable(preAccuracyHooks),
        postAccuracyHooks =
            List<BattleMoveAccuracyHook>.unmodifiable(postAccuracyHooks),
        postAccuracyMoveHooks =
            List<BattleMoveAccuracyHook>.unmodifiable(postAccuracyMoveHooks);

  const BattleMoveProcedureHooks.empty()
      : userPreventionHooks = const <BattleMoveUserPreventionHook>[],
        failureHooks = const <BattleMoveFailureHook>[],
        preAccuracyHooks = const <BattleMoveAccuracyHook>[],
        postAccuracyHooks = const <BattleMoveAccuracyHook>[],
        postAccuracyMoveHooks = const <BattleMoveAccuracyHook>[];

  static const BattleMoveProcedureHooks none = BattleMoveProcedureHooks.empty();

  final List<BattleMoveUserPreventionHook> userPreventionHooks;
  final List<BattleMoveFailureHook> failureHooks;
  final List<BattleMoveAccuracyHook> preAccuracyHooks;
  final List<BattleMoveAccuracyHook> postAccuracyHooks;
  final List<BattleMoveAccuracyHook> postAccuracyMoveHooks;

  BattleMoveUserPreventionResult? preventUser(
    BattleMoveUserPreventionContext context,
  ) {
    for (final hook in userPreventionHooks) {
      final result = hook(context);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  void notifyFailure(BattleMoveFailureContext context) {
    for (final hook in failureHooks) {
      hook(context);
    }
  }

  void notifyPreAccuracy(BattleMoveAccuracyHookContext context) {
    for (final hook in preAccuracyHooks) {
      hook(context);
    }
  }

  void notifyPostAccuracy(BattleMoveAccuracyHookContext context) {
    for (final hook in postAccuracyHooks) {
      hook(context);
    }
  }

  void notifyPostAccuracyMove(BattleMoveAccuracyHookContext context) {
    for (final hook in postAccuracyMoveHooks) {
      hook(context);
    }
  }
}

final class BattleMoveUserPreventionResult {
  const BattleMoveUserPreventionResult({
    required this.reason,
    this.message,
  });

  final BattleMoveFailureReason reason;
  final String? message;
}

final class BattleMoveSelectionPreventionResult {
  const BattleMoveSelectionPreventionResult({
    required this.reason,
    this.message,
  });

  final BattleMoveFailureReason reason;
  final String? message;
}

final class BattleMoveSelectionPreventionContext {
  const BattleMoveSelectionPreventionContext({
    required this.state,
    required this.user,
    required this.target,
    required this.move,
  });

  final PsdkBattleState state;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition move;
}

final class BattleMoveUserPreventionContext {
  const BattleMoveUserPreventionContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    required this.target,
    required this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final BattlePositionRef user;
  final BattlePositionRef target;
  final BattleMoveDefinition move;
}

final class BattleMoveFailureContext {
  BattleMoveFailureContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    this.target,
    required this.move,
    required this.reason,
    List<BattlePositionRef> targets = const <BattlePositionRef>[],
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final BattlePositionRef user;
  final BattlePositionRef? target;
  final BattleMoveDefinition move;
  final BattleMoveFailureReason reason;
  final List<BattlePositionRef> targets;
}

final class BattleMoveAccuracyHookContext {
  BattleMoveAccuracyHookContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    this.requestedTarget,
    required this.move,
    required List<BattlePositionRef> targets,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final BattlePositionRef user;
  final BattlePositionRef? requestedTarget;
  final BattleMoveDefinition move;
  final List<BattlePositionRef> targets;
}
