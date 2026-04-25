import '../../application/battle_engine.dart';
import '../../domain/decision/battle_decision.dart';
import '../../domain/move/battle_move_prevention.dart';
import '../domain/psdk_battle_outcome.dart';
import '../domain/psdk_battle_setup.dart';
import '../domain/psdk_battle_state.dart';
import '../domain/psdk_battle_timeline.dart';
import 'psdk_battle_move_behavior.dart';

class PsdkBattleDecision {
  const PsdkBattleDecision.fight({
    required this.moveSlot,
  });

  final int moveSlot;
}

class PsdkBattleTurnResult {
  const PsdkBattleTurnResult({
    required this.state,
    required this.timeline,
    required this.outcome,
  });

  final PsdkBattleState state;
  final PsdkBattleTimeline timeline;
  final PsdkBattleOutcome? outcome;
}

class PsdkBattleEngine {
  PsdkBattleEngine({
    required PsdkBattleSetup setup,
    PsdkBattleMoveBehaviorRegistry? registry,
    BattleMoveProcedureHooks moveProcedureHooks = BattleMoveProcedureHooks.none,
  }) : _engine = BattleEngine.fromPsdk(
          setup: setup,
          moveBehaviorRegistry: registry,
          moveProcedureHooks: moveProcedureHooks,
        );

  final BattleEngine _engine;

  PsdkBattleState get state => _engine.snapshot().psdkState;

  /// Resolves one complete singles turn.
  ///
  /// The method mutates this small engine instance on purpose: the PSDK lane is
  /// a CLI/smoke-test foundation rather than the immutable legacy session API.
  /// Keeping mutability local avoids pretending the old and new engines share
  /// lifecycle guarantees before the migration bridge exists.
  PsdkBattleTurnResult submit(PsdkBattleDecision decision) {
    final result = _engine.submit(
      BattleDecision.fight(moveSlot: decision.moveSlot),
    );
    return PsdkBattleTurnResult(
      state: result.state.psdkState,
      timeline: result.timeline.psdkTimeline,
      outcome: result.outcome?.psdkOutcome,
    );
  }
}
