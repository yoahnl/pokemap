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
export 'src/application/story_flags_manager.dart' show StoryFlagsManager;
export 'src/application/scenario_conditions.dart' show ScenarioConditions;
export 'src/application/runtime_story_branching.dart'
    show RuntimeStoryBranching;
export 'src/application/scenario_runtime/scenario_runtime_models.dart'
    show
        ScenarioRuntimeSourceType,
        ScenarioRuntimeSourceEvent,
        ScenarioRuntimeEffectType,
        ScenarioRuntimeEffect,
        ScenarioRuntimeExecutionStatus,
        ScenarioRuntimeExecutionResult,
        ScenarioRuntimeExecutionContext,
        ScenarioRuntimeOpenDialogue,
        ScenarioRuntimeRunScript,
        ScenarioRuntimeShowMessage;
export 'src/application/scenario_runtime/scenario_runtime_executor.dart'
    show
        ScenarioRuntimeExecutor,
        kScenarioSourceMapEnter,
        kScenarioSourceTriggerEnter,
        kScenarioSourceEntityInteract,
        kScenarioSourceOutcome,
        kScenarioActionRunScript,
        kScenarioActionOpenDialogue,
        kScenarioActionShowMessage,
        kScenarioActionSetFlag,
        kScenarioActionClearFlag,
        kScenarioActionEmitOutcome,
        scenarioOutcomeFlagName;
export 'src/application/scripted_entity_movement_models.dart'
    show
        ScriptedEntityMovementState,
        ScriptedEntityMovementStatus,
        ScriptedEntityPatrolRoute;
export 'src/application/scripted_entity_movement_controller.dart'
    show
        ScriptedEntityMovementController,
        ScriptedMovementCellBlocked,
        ScriptedEntityStepStarter,
        ScriptedEntityStepInProgressReader,
        ScriptedEntityPositionCommitted;
export 'src/application/cutscene_runtime_models.dart'
    show
        RuntimeCutsceneAsset,
        RuntimeCutsceneStep,
        CutsceneDialogueStep,
        CutsceneMoveNpcToStep,
        CutsceneWaitStep,
        CutsceneFaceNpcStep,
        CutsceneEmitOutcomeStep,
        CutsceneSetFlagStep,
        CutsceneClearFlagStep,
        CutsceneRunnerState,
        CutsceneRuntimeStatus;
export 'src/application/cutscene_runtime_runner.dart'
    show
        CutsceneRuntimeContext,
        CutsceneRuntimeRunner,
        CutsceneOpenDialogue,
        CutsceneMoveNpcTo,
        CutsceneReadNpcMovementStatus,
        CutsceneFaceNpc,
        CutsceneEmitOutcome,
        CutsceneSetFlag,
        CutsceneClearFlag;

// Save/Load system exports
export 'domain/repositories/game_save_repository.dart'
    show GameSaveRepository, GameSaveException;
export 'src/infrastructure/file_game_save_repository.dart'
    show FileGameSaveRepository;
export 'src/application/save_game_use_case.dart' show SaveGameUseCase;
export 'src/application/load_game_use_case.dart' show LoadGameUseCase;
