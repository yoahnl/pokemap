import '../domain/battle/battle_context.dart';
import '../domain/battle/battle_setup.dart';
import '../domain/ai/psdk_battle_ai.dart';
import '../domain/decision/battle_decision.dart';
import '../psdk/application/psdk_battle_move_behavior.dart';
import '../psdk/domain/psdk_battle_setup.dart';
import 'battle_engine.dart';
import 'battle_turn_runner.dart';

/// Small facade around [BattleEngine] for callers that still think in sessions.
///
/// This is not the old immutable `BattleSession`. It exists as a migration
/// bridge so runtime integration can depend on a stable object while later lots
/// move more PSDK concepts into domain/application files.
final class BattleSessionFacade {
  BattleSessionFacade({
    required BattleEngine engine,
  }) : _engine = engine;

  factory BattleSessionFacade.fromSetup({
    required BattleEngineSetup setup,
    PsdkBattleMoveBehaviorRegistry? moveBehaviorRegistry,
    PsdkBattleAi? opponentAi,
  }) {
    return BattleSessionFacade(
      engine: BattleEngine(
        setup: setup,
        moveBehaviorRegistry: moveBehaviorRegistry,
        opponentAi: opponentAi,
      ),
    );
  }

  factory BattleSessionFacade.fromPsdkSetup({
    required PsdkBattleSetup setup,
    PsdkBattleMoveBehaviorRegistry? moveBehaviorRegistry,
    PsdkBattleAi? opponentAi,
  }) {
    return BattleSessionFacade(
      engine: BattleEngine.fromPsdk(
        setup: setup,
        moveBehaviorRegistry: moveBehaviorRegistry,
        opponentAi: opponentAi,
      ),
    );
  }

  final BattleEngine _engine;

  BattlePublicState get state => _engine.snapshot();
  BattleEngineDecisionRequest get decisionRequest => _engine.currentRequest;

  BattleEngineTurnResult submit(BattleDecision decision) {
    return _engine.submit(decision);
  }
}
