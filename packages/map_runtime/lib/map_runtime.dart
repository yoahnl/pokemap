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
export 'src/application/npc_runtime_presence.dart'
    show isNpcRuntimePresentOnMap;
export 'src/application/runtime_battle_move_bridge.dart'
    show RuntimeBattleMoveBridge;
export 'src/application/runtime_battle_move_bridge_diagnostics.dart'
    show RuntimeBattleMoveBridgeDiagnostics;
export 'src/application/runtime_battle_setup_exception.dart'
    show RuntimeBattleSetupException;
export 'src/application/load_runtime_map_bundle.dart' show loadRuntimeMapBundle;
export 'src/application/runtime_map_bundle.dart' show RuntimeMapBundle;
export 'src/application/world_rules/runtime_world_rule_projection_hook.dart'
    show RuntimeWorldRuleProjectionHook, RuntimeWorldRuleProjectionState;
export 'src/presentation/flame/playable_map_game.dart' show PlayableMapGame;
export 'src/presentation/flutter/battle_command_overlay_snapshot.dart'
    show
        BattleCommandOverlayMode,
        BattleCommandOverlayEntryKind,
        BattleCommandOverlayEntryTone,
        BattleCommandOverlayEntry,
        BattleCommandOverlayHudSnapshot,
        BattleCommandOverlaySnapshot;
export 'src/presentation/flutter/battle_mobile_command_overlay.dart'
    show BattleMobileCommandOverlay;
export 'src/presentation/flame/runtime_input_event.dart'
    show RuntimeInputControl, RuntimeInputEvent, RuntimeInputEventPhase;
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
export 'src/application/scene_runtime/scene_event_runtime_hook.dart'
    show SceneEventRuntimeHook;
export 'src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart'
    show
        SceneBattleRuntimeBattleRequest,
        SceneBattleRuntimeLauncher,
        SceneBattleRuntimeOutcomeAdapter;
export 'src/application/scene_runtime/scene_battle_runtime_outcome_result.dart'
    show
        SceneBattleRuntimeOutcomeErrorCode,
        SceneBattleRuntimeOutcomePort,
        SceneBattleRuntimeOutcomeResult,
        SceneBattleRuntimeOutcomeStatus;
export 'src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart'
    show
        SceneDialogueRuntimeAwaitableAdapter,
        SceneDialogueRuntimeDialogueRequest,
        SceneDialogueRuntimeLauncher;
export 'src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart'
    show
        SceneDialogueRuntimeAwaitableErrorCode,
        SceneDialogueRuntimeAwaitableResult,
        SceneDialogueRuntimeAwaitableStatus;
export 'src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart'
    show
        SceneCinematicRuntimeAwaitableAdapter,
        SceneCinematicRuntimePlayer,
        SceneCinematicRuntimeRequest,
        SceneCinematicRuntimeNoVisualPlayer;
export 'src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart'
    show
        SceneCinematicRuntimeAwaitableErrorCode,
        SceneCinematicRuntimeAwaitableResult,
        SceneCinematicRuntimeAwaitableStatus;
export 'src/application/scene_runtime/scene_consequence_runtime_writer.dart'
    show SceneConsequenceRuntimeWriter;
export 'src/application/scene_runtime/scene_consequence_runtime_write_result.dart'
    show
        SceneConsequenceRuntimeWriteErrorCode,
        SceneConsequenceRuntimeWriteResult,
        SceneConsequenceRuntimeWriteStatus;
export 'src/application/scene_runtime/scene_runtime_host_callbacks.dart'
    show SceneRuntimeHostCallbacks;
export 'src/application/scene_runtime/scene_runtime_hook_result.dart'
    show
        SceneEventRuntimeHookErrorCode,
        SceneEventRuntimeHookResult,
        SceneEventRuntimeHookStatus;
export 'src/application/scenario_runtime/scenario_runtime_models.dart'
    show
        ScenarioRuntimeSourceType,
        ScenarioRuntimeSourceEvent,
        ScenarioRuntimeEffectType,
        ScenarioRuntimeEffect,
        ScenarioRuntimeExecutionStatus,
        ScenarioRuntimeExecutionResult,
        ScenarioRuntimeExecutionContext,
        ScenarioRuntimeShouldSkipScenario,
        ScenarioRuntimeOpenDialogue,
        ScenarioRuntimeRunScript,
        ScenarioRuntimeShowMessage,
        ScenarioRuntimeMoveCharacter,
        ScenarioRuntimeFollowCharacter,
        ScenarioRuntimeFaceCharacter,
        ScenarioRuntimeTransitionMap;
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
        kScenarioActionMoveCharacter,
        kScenarioActionFollowCharacter,
        kScenarioActionFaceCharacter,
        kScenarioActionTransitionMap,
        kScenarioActionSetFlag,
        kScenarioActionClearFlag,
        kScenarioActionEmitOutcome,
        kScenarioActionStartTrainerBattle,
        kScenarioActionGivePokemon,
        kScenarioActionGiveItem,
        kScenarioActionCompleteStep,
        kScenarioActionFlowMerge,
        kScenarioActionAuthoringPlaceholder,
        scenarioOutcomeFlagName;
export 'src/application/scenario_runtime/scenario_battle_outcome_flags.dart'
    show
        kBattleOutcomeFlagPrefix,
        kBattleOutcomeSuffixVictory,
        kBattleOutcomeSuffixDefeat,
        kBattleOutcomeSuffixFlee,
        kBattleOutcomeSuffixCaptured,
        scenarioBattleOutcomeFlagName;
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
        ScriptedEntityStepValidation,
        ScriptedEntityPositionCommitted;
export 'src/application/npc_overworld_movement_defaults.dart'
    show resolveNpcDefaultPatrolRoute;
export 'src/application/scripted_npc_anchor_passability.dart'
    show
        ScriptedNpcAnchorPassabilityResult,
        evaluateScriptedNpcAnchorPassability;
export 'src/application/cutscene_runtime_models.dart'
    show
        RuntimeCutsceneAsset,
        RuntimeCutsceneStep,
        CutsceneChoiceOption,
        CutsceneChoiceRequest,
        CutsceneChoiceResult,
        CutsceneDialogueStep,
        CutsceneChoiceStep,
        CutsceneLabelStep,
        CutsceneGotoStep,
        CutsceneGotoIfChoiceStep,
        CutsceneGotoIfFlagStep,
        CutsceneGotoIfOutcomeStep,
        CutsceneMoveNpcToStep,
        CutsceneWaitStep,
        CutsceneWaitUntilDialogueClosedStep,
        CutsceneWaitUntilNpcMoveCompletedStep,
        CutsceneFaceNpcStep,
        CutsceneEmitOutcomeStep,
        CutsceneWaitUntilFlagStep,
        CutsceneWaitUntilOutcomeStep,
        CutsceneSetFlagStep,
        CutsceneClearFlagStep,
        CutsceneCallStep,
        CutsceneRunnerState,
        CutsceneRuntimeStatus;
export 'src/application/cutscene_runtime_runner.dart'
    show
        CutsceneRuntimeContext,
        CutsceneRuntimeRunner,
        CutsceneOpenDialogue,
        CutsceneIsDialogueOpen,
        CutsceneRequestChoice,
        CutsceneResolveById,
        CutsceneMoveNpcTo,
        CutsceneReadNpcMovementStatus,
        CutsceneFaceNpc,
        CutsceneEmitOutcome,
        CutsceneSetFlag,
        CutsceneClearFlag,
        CutsceneIsFlagSet,
        CutsceneIsOutcomeSet;

// Save/Load system exports
export 'domain/repositories/game_save_repository.dart'
    show GameSaveRepository, GameSaveException;
export 'src/infrastructure/file_game_save_repository.dart'
    show FileGameSaveRepository;
export 'src/application/save_game_use_case.dart' show SaveGameUseCase;
export 'src/application/load_game_use_case.dart' show LoadGameUseCase;
