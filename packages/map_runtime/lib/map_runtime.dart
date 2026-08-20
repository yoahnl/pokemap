library;

export 'package:map_core/map_core.dart'
    show
        PlayerPronounSet,
        ProjectMenuLabelsProfile,
        ProjectSemanticThemeProfile,
        ProjectTypographyRole;
export 'package:map_authoring/map_authoring.dart'
    show
        ArtifactAssertion,
        ArtifactKind,
        AuthoringArtifactManifest,
        AuthoringArtifactRef,
        AuthoringJobArtifact,
        AuthoringJobCancellation,
        AuthoringJobEvent,
        AuthoringJobPort,
        AuthoringJobRequest,
        AuthoringJobSnapshot,
        AuthoringJobState,
        PlaytestCommand,
        PlaytestCommandResult,
        PlaytestEvent,
        PlaytestPort,
        PlaytestReceipt,
        PlaytestSession,
        PlaytestSessionState,
        PlaytestSnapshot,
        PlaytestStartRequest,
        PlaytestStateChange,
        PlaytestStateDiff;
export 'src/player/runtime_project_typography_loader.dart'
    show
        FlutterRuntimeFontRegistrar,
        RuntimeFontRegistrar,
        RuntimeLoadedFontRole,
        RuntimeLoadedTypography,
        RuntimeProjectFontRequest,
        RuntimeProjectTypographyLoader;
export 'src/player/runtime_title_music_controller.dart'
    show RuntimeTitleMusicController;
export 'src/player/runtime_splash_jingle_controller.dart'
    show RuntimeSplashJingleController, runtimePremiumSplashJingleAsset;
export 'src/player/runtime_audio_mixer.dart'
    show
        RuntimeAudioBus,
        RuntimeAudioMix,
        RuntimeAudioMixer,
        RuntimeAudioRoute,
        RuntimeAudioRouteBus,
        RuntimeAudioVolumeSetter;
export 'src/player/runtime_presentation_audio_controller.dart'
    show
        FlameRuntimePresentationAudioDriver,
        RuntimePresentationAudioController,
        RuntimePresentationAudioDriver,
        RuntimePresentationAudioFailure;
export 'src/player/runtime_presentation_media_playback_controller.dart'
    show
        RuntimePresentationMediaPlaybackController,
        RuntimePresentationMediaPlaybackDiagnosticCodes,
        RuntimePresentationMediaPlaybackSnapshot,
        RuntimePresentationMediaPlaybackStatus,
        RuntimePresentationMediaUriResolver,
        RuntimePresentationVideoAudioMode,
        RuntimePresentationVideoPlaybackDriver;
export 'src/player/runtime_presentation_execution_controller.dart'
    show
        RuntimePresentationCancellationReason,
        RuntimePresentationExecutionController,
        RuntimePresentationExecutionPhase,
        RuntimePresentationExecutionResult,
        RuntimePresentationExecutionSnapshot,
        RuntimePresentationExecutionTerminal,
        RuntimePresentationExecutionTerminalSink,
        RuntimePresentationRunToken;
export 'src/player/runtime_presentation_scene_playback_controller.dart';
export 'src/player/runtime_intro_sequence_controller.dart'
    show
        RuntimeIntroPhase,
        RuntimeIntroReducedMotionBehavior,
        RuntimeIntroSequenceController;
export 'src/player/runtime_initial_map_preloader.dart';
export 'src/player/runtime_startup_models.dart'
    show
        RuntimeStartupPhase,
        RuntimeStartupAction,
        RuntimeStartupCommandStatus,
        RuntimeStartupCommand,
        RuntimeStartupCommandResult,
        RuntimeStartupPreparationStage,
        RuntimeStartupDiagnostic,
        RuntimeStartupFailure,
        RuntimeHostSplashBranding,
        RuntimeResolvedAsset,
        RuntimeStartupPresentationAsset,
        RuntimeStartupPresentationMetadata,
        RuntimeStartupResolvedPresentation,
        RuntimeStartupSnapshot;
export 'src/player/runtime_presentation_media_selection.dart'
    show
        RuntimePresentationOrientation,
        RuntimeSelectedPresentationVideo,
        selectRuntimePresentationVideo;
export 'src/player/runtime_startup_preparation.dart'
    show
        runtimeStartupPreparationWeights,
        RuntimeStartupClock,
        RuntimeStartupScheduledDelay,
        RuntimeStartupSchedulingClock,
        SystemRuntimeStartupClock,
        RuntimeStartupTimelineGate,
        RuntimeStartupPreparationStepStatus,
        RuntimeStartupPreparationStepResult,
        RuntimeStartupPreparationOperation,
        RuntimeStartupPreparationSnapshot,
        RuntimeStartupPreparationStatus,
        RuntimeStartupPreparationResult,
        RuntimeStartupPreparation;
export 'src/player/runtime_startup_bootstrap.dart'
    show
        RuntimeStartupBootstrapStage,
        runtimeStartupBootstrapWeights,
        RuntimeStartupBootstrapStageSink,
        RuntimeStartupBootstrapPort,
        RuntimeStartupBootstrapResult,
        RuntimeStartupBootstrapException,
        RuntimeStartupPreparedGraph,
        RuntimeStartupBootstrapCoordinator;
export 'src/player/runtime_startup_coordinator.dart'
    show
        RuntimeStartupPreparationPort,
        RuntimePresentationAssetResolver,
        RuntimeStartupCoordinator;

export 'src/application/scene_runtime/narrative_command_runtime_capability_evidence.dart'
    show buildMapRuntimeNarrativeCommandConsumerAttestation;
export 'src/application/dialogue_portrait_resolver.dart'
    show
        DialoguePortraitResolutionCode,
        DialoguePortraitResolutionDiagnostic,
        ResolvedDialoguePortrait,
        DialoguePortraitLookup,
        DialoguePortraitResolver;
export 'src/application/character_animation_source_resolver.dart'
    show
        CharacterAnimationSourceDiagnosticCode,
        CharacterAnimationSourceDiagnostic,
        ResolvedCharacterAnimationFrameSource,
        CharacterAnimationSourceResolver,
        CharacterAnimationSourcePreloadPlan,
        characterAnimationRuntimeImageId,
        buildCharacterAnimationSourcePreloadPlan;
export 'src/application/character_custom_animation_runtime_controller.dart'
    show
        CharacterCustomAnimationRuntimeStatus,
        CharacterCustomAnimationRuntimeDiagnosticCode,
        CharacterCustomAnimationRuntimeResult,
        CharacterCustomAnimationRuntimeActor,
        CharacterCustomAnimationRuntimeActorLookup,
        CharacterCustomAnimationRuntimeController;
export 'src/presentation/flame/narrative_command_player_surface_capability_evidence.dart'
    show buildMapRuntimeNarrativeCommandPlayerSurfaceAttestation;
export 'src/application/narrative_runtime_smoke_evidence.dart'
    show buildNarrativeRuntimeSmokeEvidence;
export 'src/application/player_service_runtime_controller.dart'
    show
        RuntimePlayerServiceRecoveryCaps,
        PlayerServiceRequest,
        PlayerServiceShopRequest,
        PlayerServicePcRequest,
        PlayerServiceHealRequest,
        PlayerServiceHostResult,
        PlayerServiceOverlayHost,
        PlayerServiceRuntimeStatus,
        PlayerServiceRuntimeResult,
        PlayerServiceGameStateReader,
        PlayerServiceStateTransaction,
        PlayerServiceInputLockSetter,
        PlayerServiceRecoveryCapsLoader,
        PlayerServiceRuntimeController,
        loadRuntimePlayerServiceRecoveryCaps;

export 'src/application/battle_start_request.dart'
    show
        RuntimeBattleKind,
        RuntimeBattleSourceKind,
        OverworldReturnContext,
        BattleStartRequest,
        WildBattleStartRequest,
        TrainerBattleStartRequest,
        StaticBattleStartRequest;
export 'src/application/encounter_to_battle_request.dart'
    show buildBattleStartRequestFromEncounter;
export 'src/application/trainer_battle_request.dart'
    show buildTrainerBattleRequestFromNpc;
export 'src/application/runtime_trainer_lifecycle_policy.dart'
    show
        RuntimeTrainerInteractionDisposition,
        RuntimeTrainerInteractionPlan,
        RuntimeTrainerPostBattleResult,
        resolveRuntimeTrainerInteractionPlan,
        resolveRuntimeTrainerPostBattleDialogue;
export 'src/application/npc_runtime_presence.dart'
    show isNpcRuntimePresentOnMap;
export 'src/application/runtime_battle_move_bridge.dart'
    show RuntimeBattleMoveBridge;
export 'src/application/runtime_battle_move_bridge_diagnostics.dart'
    show RuntimeBattleMoveBridgeDiagnostics;
export 'src/application/runtime_battle_setup_exception.dart'
    show RuntimeBattleSetupException;
export 'src/application/runtime_item_catalog_loader.dart'
    show RuntimeItemCatalogLoader;
export 'src/application/runtime_move_machine_loader.dart'
    show
        RuntimeMoveMachineKind,
        RuntimeMoveMachineDefinition,
        RuntimeMoveMachineLoader;
export 'src/application/runtime_battle_bag_hp_heal_item_apply.dart'
    show RuntimeBattleItemApplyResult, tryApplyRuntimeBattleItemUse;
export 'src/application/runtime_battle_outcome_apply.dart'
    show
        RuntimeActiveBattleContext,
        RuntimeBattleCaptureAttemptReceipt,
        RuntimeBattleCaptureAttemptSubmission,
        submitRuntimeBattleCaptureAttempt,
        commitRuntimeBattleCaptureAttemptReceipt,
        applyRuntimeBattleOutcomeToGameState;
export 'src/application/runtime_battle_authoring_capability_truth.dart'
    show
        RuntimeBattleAuthoringSupportStatus,
        RuntimeBattleAuthoringCapability,
        RuntimeBattleAuthoringCapabilityTruth;
export 'src/application/runtime_playtest_port.dart';
export 'src/application/runtime_failure_taxonomy.dart';
export 'src/application/runtime_battle_progression_context_mapper.dart'
    show RuntimeBattleProgressionContextMapper;
export 'src/application/runtime_battle_reward_resolver.dart'
    show
        RuntimePostBattleSpeciesLoader,
        RuntimePostBattleMoveLearningLoader,
        RuntimePostBattleEvolutionLoader,
        RuntimePostBattleResolutionErrorCode,
        RuntimePostBattleResolutionException,
        RuntimeBattleRewardResolution,
        RuntimeBattleRewardResolver;
export 'src/application/runtime_post_battle_decision_coordinator.dart'
    show
        RuntimePostBattleRewardResolutionLoader,
        RuntimePostBattlePlayerPokemonHydrator,
        RuntimePostBattleMessageKind,
        RuntimePostBattleMessage,
        RuntimePostBattleCoordinatorFailureCode,
        RuntimePostBattleCoordinatorFailure,
        RuntimePostBattleCoordinatorResult,
        RuntimePostBattleTransaction,
        RuntimePostBattleDecisionCoordinator;
export 'src/application/runtime_player_pokemon_progression_hydrator.dart'
    show
        RuntimePlayerPokemonProgressionHydrationException,
        RuntimePlayerPokemonProgressionCatalogs,
        RuntimePlayerPokemonProgressionCatalogLoader,
        runtimeSupportedPokemonGrowthRateIds,
        hydrateRuntimePlayerPokemon,
        hydrateRuntimePlayerPokemonProgression,
        loadRuntimePlayerPokemonProgressionCatalogs;
export 'src/application/runtime_player_pokemon_grant.dart'
    show applyRuntimePlayerPokemonGrant, transactRuntimePlayerPokemonGrant;
export 'src/application/runtime_pokemon_species_loader.dart'
    show RuntimePokemonSpeciesNotFoundException;
export 'src/application/load_runtime_map_bundle.dart'
    show
        RuntimeMapBundleLoadProfile,
        RuntimeMapBundleLoadProfileSink,
        RuntimeMapBundleLoadProgressSink,
        RuntimeMapBundleLoadStage,
        loadRuntimeMapBundle,
        loadProjectManifestFromFile,
        loadMapDataFromFile;
export 'src/application/authoring_preview/runtime_authoring_map_render_adapter.dart'
    show RuntimeAuthoringMapRenderAdapter;
export 'src/application/runtime_map_bundle.dart' show RuntimeMapBundle;
export 'src/application/map_activation.dart'
    show MapActivationReason, MapActivation;
export 'src/application/map_enter_production_dispatch_bridge.dart'
    show
        MapEnterProductionDispatchResult,
        MapEnterProductionDispatchLegacyFallback,
        MapEnterProductionDispatchDuplicate,
        MapEnterProductionDispatchNoFallback,
        MapEnterProductionDispatchV2Handled,
        MapEnterProductionDispatchClaimedIneligible,
        MapEnterProductionDispatchStale,
        MapEnterProductionDispatchAuthorityBlocked,
        MapEnterProductionDispatchFailed,
        MapEnterProductionDispatchBridge;
export 'src/application/narrative_spatial_production_dispatch_bridge.dart'
    show
        NarrativeSpatialProductionDispatchResult,
        NarrativeSpatialProductionDispatchLegacyFallback,
        NarrativeSpatialProductionDispatchDuplicate,
        NarrativeSpatialProductionDispatchNoFallback,
        NarrativeSpatialProductionDispatchV2Handled,
        NarrativeSpatialProductionDispatchClaimedIneligible,
        NarrativeSpatialProductionDispatchStale,
        NarrativeSpatialProductionDispatchAuthorityBlocked,
        NarrativeSpatialProductionDispatchFailed,
        NarrativeSpatialAuthorityPreparation,
        NarrativeSpatialLegacyFallback,
        NarrativeSpatialProductionDispatchBridge;
export 'src/border/border_runtime_asset_collection.dart'
    show
        BorderRuntimeFrameRequest,
        BorderRuntimeSnapshotRequest,
        BorderRuntimeAssetCollection;
export 'src/border/border_runtime_preparation.dart'
    show BorderRuntimePreparation;
export 'src/border/border_runtime_readiness.dart'
    show BorderRuntimeReadinessException, prepareBorderRuntimeBundle;
export 'src/application/world_rules/runtime_world_rule_projection_hook.dart'
    show RuntimeWorldRuleProjectionHook, RuntimeWorldRuleProjectionState;
export 'src/presentation/flame/playable_map_game.dart' show PlayableMapGame;
export 'src/presentation/flame/post_battle_progression_overlay_component.dart'
    show PostBattleProgressionOverlayComponent;
export 'src/presentation/flame/flame_cinematic_runtime_playback_sink.dart'
    show
        FlameCinematicRuntimeActorHandle,
        FlameCinematicCharacterAnimationActorHandle,
        FlameCinematicRuntimeHost,
        FlameCinematicRuntimePlaybackSink;
export 'src/presentation/flame/flame_cinematic_media_playback_adapter.dart'
    show
        FlameCinematicAudioDriver,
        FlameAudioCinematicRuntimeDriver,
        FlameCinematicMediaPlaybackAdapter,
        FlameCinematicMediaPathResolver;
export 'src/presentation/flame/flame_cinematic_fx_playback_adapter.dart'
    show FlameCinematicFxHost, FlameCinematicFxPlaybackAdapter;
export 'src/presentation/flutter/battle_command_overlay_snapshot.dart'
    show
        BattleCommandOverlayMode,
        BattlePresentationPhase,
        BattleCommandOverlayEntryKind,
        BattleCommandOverlayEntryTone,
        BattleCommandOverlayEntry,
        BattleCommandOverlayHudSnapshot,
        BattleCommandOverlaySnapshot,
        BattlePresentationCommand,
        BattleSelectEntryCommand,
        BattleBackCommand,
        BattlePresentationCommandRejection,
        BattlePresentationCommandValidation,
        validateBattlePresentationCommand;
export 'src/presentation/flutter/battle_mobile_command_overlay.dart'
    show
        BattleMobileCommandOverlay,
        BattleMobileItemIcon,
        BattleMobileItemIconBytesLoader;
export 'src/presentation/flutter/dialogue_presentation_snapshot.dart'
    show
        DialoguePresentationMode,
        DialoguePresentationChoice,
        DialoguePresentationSnapshot,
        DialoguePresentationCommand,
        DialogueAdvanceCommand,
        DialogueSelectChoiceCommand,
        splitDialogueSpeakerLine,
        DialoguePresentationCommandRejection,
        DialoguePresentationCommandValidation,
        validateDialoguePresentationCommand;
export 'src/presentation/flutter/runtime_notification_snapshot.dart'
    show RuntimeNotificationTone, RuntimeNotificationSnapshot;
export 'src/presentation/flutter/post_battle_presentation_snapshot.dart'
    show
        PostBattlePresentationChoice,
        PostBattlePresentationSnapshot,
        PostBattlePresentationCommand,
        PostBattleAdvanceCommand,
        PostBattleSelectDecisionCommand,
        PostBattlePresentationCommandRejection,
        PostBattlePresentationCommandValidation,
        validatePostBattlePresentationCommand;
export 'src/presentation/flame/runtime_input_event.dart'
    show RuntimeInputControl, RuntimeInputEvent, RuntimeInputEventPhase;
export 'src/presentation/flame/runtime_input_key_bindings.dart'
    show runtimeInputControlFromLogicalKey, runtimeInputEventFromKeyEvent;
export 'src/presentation/flame/runtime_input_authority.dart'
    show
        RuntimeInputContext,
        RuntimeExternalInputLock,
        RuntimeInputAuthoritySnapshot;
export 'src/presentation/flame/dialogue_text_speed.dart'
    show RuntimeDialogueTextSpeed;
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
export 'src/application/scene_runtime/cinematic_runtime_playback_controller.dart'
    show
        CinematicRuntimePlaybackController,
        CinematicRuntimePlaybackSink,
        CinematicRuntimeStepCompletionPolicy,
        CinematicRuntimeAsyncRestorationSink,
        CinematicRuntimeSinkPreflightResult,
        CinematicRuntimeStepContext,
        CinematicRuntimeTermination;
export 'src/application/scene_runtime/cinematic_runtime_preview_adapter.dart'
    show CinematicRuntimePreview, CinematicRuntimePreviewAdapter;
export 'src/application/scene_runtime/cinematic_media_playback_port.dart'
    show
        CinematicRuntimeMediaPlaybackPort,
        cinematicMediaCommandForStep,
        cinematicMediaEndCommandForStep;
export 'src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart'
    show
        SceneCinematicRuntimeAwaitableErrorCode,
        SceneCinematicRuntimeAwaitableResult,
        SceneCinematicRuntimeAwaitableStatus;
export 'src/application/scene_runtime/scene_presentation_cinematic_runtime_awaitable_adapter.dart'
    show
        RuntimePresentationSceneLaunch,
        RuntimePresentationScenePlayer,
        ScenePresentationCinematicRuntimeAwaitableAdapter,
        ScenePresentationCinematicRuntimeDiagnosticCodes,
        ScenePresentationInteractionCue,
        ScenePresentationInteractionCueHandler,
        ScenePresentationCinematicRuntimePlayer,
        ScenePresentationCinematicRuntimeRequest;
export 'src/application/scene_runtime/scene_presentation_cinematic_runtime_awaitable_result.dart'
    show
        ScenePresentationCinematicRuntimeAwaitableErrorCode,
        ScenePresentationCinematicRuntimeAwaitableResult,
        ScenePresentationCinematicRuntimeAwaitableStatus;
export 'src/application/scene_runtime/scene_consequence_runtime_writer.dart'
    show SceneConsequenceRuntimeWriter;
export 'src/application/scene_runtime/narrative_game_completion_runtime_coordinator.dart'
    show
        GameCompletionRequestEmitter,
        NarrativeGameCompletionRuntimeCoordinator;
export 'src/application/scene_runtime/scene_finish_game_runtime_mapper.dart'
    show SceneFinishGameRuntimeMapper;
export 'src/application/scene_runtime/scene_game_completion_metadata.dart'
    show
        gameStateAllowsPostGameContinue,
        sceneGameCompletionEndingMetadataKey,
        sceneGameCompletionPostGamePolicyMetadataKey;
export 'src/application/scene_runtime/scene_npc_state_metadata.dart'
    show sceneNpcPresenceMetadataKey, sceneNpcPresenceOverride;
export 'src/application/scene_runtime/scene_interactive_command_runtime_executor.dart'
    show SceneInteractiveCommandHandler, SceneInteractiveCommandRuntimeExecutor;
export 'src/application/scene_runtime/scene_consequence_runtime_write_result.dart'
    show
        SceneConsequenceRuntimeWriteErrorCode,
        SceneConsequenceRuntimeWriteResult,
        SceneConsequenceRuntimeWriteStatus;
export 'src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart'
    show evaluateCanonicalNarrativeFactSceneCondition;
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
// Save/Load system exports
export 'domain/repositories/game_save_repository.dart'
    show GameSaveRepository, GameSaveException;
export 'src/infrastructure/file_game_save_repository.dart'
    show FileGameSaveRepository;
export 'src/infrastructure/game_save_load_diagnostics.dart'
    show describeGameSaveLoadFailure;
export 'src/infrastructure/project_tileset_visual_resolution.dart'
    show resolveRuntimeProjectTilesetVisual;
export 'src/infrastructure/game_save_codec_executor.dart'
    show
        GameSaveCodecDiagnostics,
        GameSaveCodecExecutor,
        GameSaveCodecWorkerRunner;
export 'src/application/save_game_use_case.dart' show SaveGameUseCase;
export 'src/application/load_game_use_case.dart' show LoadGameUseCase;

// Player session shell contracts. These DTOs intentionally expose no Flame
// component, widget, package path or Hub storage implementation.
export 'src/session/game_session_contract.dart';
export 'src/session/game_session_controller.dart' show GameSessionController;
export 'src/session/in_process_game_session_adapter.dart';
export 'src/session/playable_map_game_session_runtime.dart';
export 'src/session/player_input.dart';
export 'src/player/runtime_player_host.dart';
export 'src/player/runtime_new_game_flow.dart';
export 'src/player/runtime_player_coordinator.dart';
export 'src/player/runtime_input_lock_manager.dart';
export 'src/player/runtime_player_input.dart';
export 'src/player/runtime_player_models.dart';
export 'src/player/runtime_title_menu_policy.dart';
export 'src/player/runtime_player_pause_data.dart';
export 'src/player/runtime_pokemon_summary.dart';
export 'src/player/runtime_player_pause_data_builder.dart'
    show RuntimePlayerPauseDataBuilder;
export 'src/player/runtime_world_service_models.dart';
