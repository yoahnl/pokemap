/// Public barrel for the parallel Pokemon SDK battle foundation.
///
/// This barrel is exported from `map_battle.dart` so tests, tools, and future
/// adapters can exercise the PSDK lane without importing legacy `BattleSession`
/// internals. The implementation stays split by responsibility below to avoid
/// recreating another monolithic battle file.
library psdk_battle;

export '../domain/move/battle_move_prevention.dart'
    show
        BattleMoveAccuracyHook,
        BattleMoveAccuracyHookContext,
        BattleMoveFailureContext,
        BattleMoveFailureHook,
        BattleMoveFailureReason,
        BattleMoveFailureReasonJson,
        BattleMoveProcedureHooks,
        BattleMoveUserPreventionContext,
        BattleMoveUserPreventionHook,
        BattleMoveUserPreventionResult;
export 'application/psdk_battle_engine.dart';
export 'application/psdk_battle_move_behavior.dart';
export 'domain/psdk_battle_combatant.dart';
export 'domain/psdk_battle_field.dart';
export 'domain/psdk_battle_move.dart';
export 'domain/psdk_battle_outcome.dart';
export 'domain/psdk_battle_rng.dart';
export 'domain/psdk_battle_setup.dart';
export 'domain/psdk_battle_slots.dart';
export 'domain/psdk_battle_state.dart';
export 'domain/psdk_battle_timeline.dart';
