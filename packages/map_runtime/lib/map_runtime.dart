library map_runtime;

export 'src/application/battle_start_request.dart'
    show
        RuntimeBattleKind,
        RuntimeBattleSourceKind,
        OverworldReturnContext,
        BattleStartRequest,
        WildBattleStartRequest,
        TrainerBattleStartRequest;
export 'src/application/encounter_to_battle_request.dart'
    show buildBattleStartRequestFromEncounter;
export 'src/application/trainer_battle_request.dart'
    show buildTrainerBattleRequestFromNpc;
export 'src/application/load_runtime_map_bundle.dart' show loadRuntimeMapBundle;
export 'src/application/runtime_map_bundle.dart' show RuntimeMapBundle;
export 'src/presentation/flame/playable_map_game.dart' show PlayableMapGame;
export 'src/presentation/flame/runtime_map_game.dart' show RuntimeMapGame;

// Script system exports
export 'src/application/script_runtime_state.dart'
    show
        ScriptExecutionState,
        ScriptSuspendReason,
        ScriptCommandResult,
        ScriptCommandResultCompleted,
        ScriptCommandResultSuspended,
        ScriptCommandResultJumpToNode,
        ScriptCommandResultTerminated,
        ScriptCommandResultError,
        ScriptExecutionContext;
export 'src/application/script_runtime_controller.dart'
    show ScriptRuntimeController;
export 'src/application/script_command_executor.dart'
    show ScriptCommandExecutor;

// Save/Load system exports
export 'domain/repositories/game_save_repository.dart'
    show GameSaveRepository, GameSaveException;
export 'src/infrastructure/file_game_save_repository.dart'
    show FileGameSaveRepository;
export 'src/application/save_game_use_case.dart' show SaveGameUseCase;
export 'src/application/load_game_use_case.dart' show LoadGameUseCase;
