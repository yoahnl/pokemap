library map_gameplay;

export 'src/battle_reward.dart'
    show
        BattleRewardSourceKind,
        BattleExperienceGrant,
        BattleRewardItemGrant,
        BattleReward;
export 'src/pokemon_experience_curve.dart' show PokemonExperienceCurve;
export 'src/pokemon_stat_calculator.dart'
    show
        PokemonNatureStatPolicy,
        PokemonNatureStat,
        PokemonNatureEffect,
        canonicalPokemonNatureIds,
        canonicalPokemonNatureEffect,
        PokemonOpponentStatProfile,
        PokemonBaseStats,
        PokemonCalculatedStats,
        PokemonStatCalculator;
export 'src/pokemon_evolution_service.dart'
    show
        PokemonEvolutionTriggerKind,
        PokemonEvolutionTrigger,
        PokemonEvolutionConditionKind,
        PokemonEvolutionCondition,
        PokemonEvolutionCandidate,
        PokemonEvolutionResult,
        PokemonEvolutionService,
        PokemonEvolutionItemUseFailure,
        PokemonEvolutionItemUseResult,
        PokemonEvolutionItemOperations;
export 'src/pokemon_move_machine_service.dart'
    show
        PokemonMoveMachineCandidate,
        PokemonMoveMachineDecision,
        LearnPokemonMoveMachineDecision,
        ReplacePokemonMoveMachineDecision,
        DeclinePokemonMoveMachineDecision,
        PokemonMoveMachineUseStatus,
        PokemonMoveMachineUseFailure,
        PokemonMoveMachineUseResult,
        PokemonMoveMachineService;
export 'src/battle_progression_result.dart'
    show
        PokemonMoveLearningCandidate,
        BattleMoveLearningOpportunity,
        BattleMoveLearningPhase,
        PendingBattleMoveLearning,
        BattleMoveLearningDecision,
        LearnBattleMoveLearningDecision,
        ReplaceBattleMoveLearningDecision,
        DeclineBattleMoveLearningDecision,
        BattleMoveLearningChangeKind,
        BattleMoveLearningChange,
        BattleEvolutionOpportunity,
        PendingBattleEvolution,
        BattleEvolutionDecision,
        AcceptBattleEvolutionDecision,
        RefuseBattleEvolutionDecision,
        BattleEvolutionChangeKind,
        BattleEvolutionChange,
        BattlePokemonProgressionChange,
        BattleProgressionResult;
export 'src/battle_progression_service.dart'
    show
        BattleProgressionOutcomeKind,
        BattleProgressionDefeatedOpponent,
        BattleProgressionPartySlotMetadata,
        BattleProgressionContext,
        BattleProgressionService;
export 'src/battle_progression_authoring_service.dart';
export 'src/direction.dart' show Direction, DirectionX, EntityFacingX;
export 'src/gameplay_exceptions.dart' show GameplaySpawnResolutionException;
export 'src/player_spawn_resolver.dart' show resolveInitialPlayerSpawn;
export 'src/gameplay_intent.dart'
    show GameplayIntent, MoveIntent, InteractIntent;
export 'src/movement_block_reason.dart' show GameplayMovementBlockReason;
export 'src/gameplay_player_state.dart' show GameplayPlayerState;
export 'src/gameplay_encounter.dart'
    show
        defaultEncounterChancePerStep,
        GameplayEncounterPolicy,
        GameplayEncounterCheckStatus,
        GameplayEncounter,
        GameplayEncounterCheckResult,
        checkEncounterAtPlayerPosition;
export 'src/gameplay_connection.dart' show resolveConnectedMapTargetPos;
export 'src/gameplay_hazard.dart' show GameplayHazardEffect;
export 'src/gameplay_movement_effect.dart'
    show GameplayMovementEffect, GameplayMovementEffectKind;
export 'src/grid_pathfinder.dart'
    show GridCellPassability, GridPathfindingResult, GridPathfinder;
export 'src/gameplay_step.dart' show stepGameplayWorld;
export 'src/gameplay_step_result.dart'
    show
        GameplayStepResult,
        Moved,
        Blocked,
        WarpTriggered,
        ConnectionTriggered,
        TriggeredWarp,
        TriggeredConnection,
        NothingToInteract,
        NpcInteracted,
        SignInteracted,
        ItemInteracted,
        EntityInteracted,
        PlacedElementInteracted,
        MapEventInteracted;
export 'src/gameplay_world_state.dart'
    show
        GameplayWorldState,
        NpcMapPresencePredicate,
        MapEntityPresencePredicate;
export 'src/surf_evaluation.dart'
    show
        SurfAttemptEvaluation,
        NotWater,
        AlreadySurfing,
        MissingSurfCapablePokemon,
        SurfNotUnlocked,
        CanPromptSurf,
        evaluateSurfAttempt,
        partyHasUsableFieldMove;

// Line of Sight detection
export 'src/los_detection.dart' show checkLineOfSight;

// Script system exports
export 'src/script_condition_evaluator.dart'
    show ScriptConditionEvaluator, ScriptEvaluationContext;
export 'src/shop_state_resolver.dart' show ResolvedShopState, ShopStateResolver;
export 'src/shop_state_resolution_validator.dart'
    show ShopStateResolutionScenario, ShopStateResolutionValidator;
export 'src/event_page_resolver.dart' show EventPageResolver;
export 'src/game_state_mutations.dart'
    show
        CaptureDestinationKind,
        CaptureDestinationFailure,
        CaptureDestinationResult,
        ShopPurchaseFailure,
        ShopPurchaseResult,
        ShopSaleFailure,
        ShopSaleResult,
        GameStateMutations;
export 'src/player_storage_operations.dart';
export 'src/sandbox_player_state.dart';
export 'src/player_item_effects.dart';
export 'src/items/bag_operation_result.dart';
export 'src/items/bag_operations.dart';
export 'src/items/item_catalog_snapshot.dart';
export 'src/items/item_capability_resolver.dart';
export 'src/items/mvp_item_catalog.dart';
export 'src/items/player_item_use_service.dart';
export 'src/player_defeat_recovery.dart';
export 'src/runtime_map_projection.dart'
    show
        RuntimeMapLocation,
        RuntimeMapLocationStatus,
        projectRuntimeMapLocations;
export 'src/new_game_state_builder.dart'
    show
        createNewGameState,
        createNewGameStateFromMap,
        createNewGameStateFromProject,
        applyPlayerIdentityDialogueVariables,
        playerNameScriptVariable,
        playerAvatarScriptVariable,
        playerPronounSetScriptVariable,
        playerSubjectPronounScriptVariable,
        playerObjectPronounScriptVariable,
        playerPossessivePronounScriptVariable,
        playerReflexivePronounScriptVariable;
export 'src/narrative_event_dispatch_planner.dart'
    show NarrativeEventDispatchPlanner;
export 'src/narrative_trigger_enter_fronts.dart'
    show
        NarrativeTriggerEnterFrontResolution,
        resolveNarrativeTriggerEnterFronts;
export 'src/narrative_event_state_transactions.dart'
    show
        NarrativeEventStateTransaction,
        NarrativeEventStateTransactionDecision,
        NarrativeEventStateTransactionCommit,
        NarrativeEventStateTransactionRollback,
        NarrativeEventStateTransactionCallback,
        NarrativeEventAfterCommitCallback,
        NarrativeEventStateTransactions;
export 'src/narrative_event_execution_coordinator.dart'
    show
        NarrativeEventActivity,
        NarrativeEventActivityPort,
        NoopNarrativeEventActivityPort,
        NarrativeSceneExecutionRequest,
        NarrativeSceneExecutionCallback,
        NarrativeSceneExecutionResult,
        NarrativeSceneExecutionCompleted,
        NarrativeSceneExecutionFailed,
        NarrativeSceneExecutionCancelled,
        NarrativeEventExecutionFailureKind,
        NarrativeEventExecutionFailure,
        NarrativeEventExecutionResult,
        NarrativeEventExecutionNoMatch,
        NarrativeEventExecutionClaimedButIneligible,
        NarrativeEventExecutionSucceeded,
        NarrativeEventExecutionFailed,
        NarrativeEventExecutionCancelled,
        NarrativeExecutionIdFactory,
        NarrativeCorrelationIdFactory,
        NarrativeDeliveryIdFactory,
        NarrativeEventExecutionCoordinator;
export 'src/narrative_outcome_outbox_processor.dart'
    show
        NarrativeOutcomeOutboxSnapshot,
        GameStateNarrativeOutcomeOutboxSnapshot,
        NarrativeOutcomeOutboxSnapshotFactory,
        NarrativeOutcomeDispatchRequest,
        NarrativeOutcomeDispatcher,
        NarrativeOutcomeDispatchResult,
        NarrativeOutcomeDispatchDelivered,
        NarrativeOutcomeDispatchInfrastructureFailureBeforePlanning,
        NarrativeOutcomeDispatchTerminalFailure,
        NarrativeOutcomeTerminalReason,
        NarrativeOutcomeOutboxProcessResult,
        NarrativeOutcomeOutboxEmpty,
        NarrativeOutcomeOutboxBusy,
        NarrativeOutcomeOutboxDelivered,
        NarrativeOutcomeOutboxRetryScheduled,
        NarrativeOutcomeOutboxTerminalized,
        NarrativeOutcomeOutboxDataInconsistency,
        NarrativeOutcomeOutboxProcessor;
export 'src/validation/narrative_physical_reachability_validator.dart'
    show
        NarrativePhysicalReachabilityVerdict,
        NarrativePhysicalSourceStatus,
        NarrativePhysicalIssueCode,
        NarrativePhysicalReachabilityIssue,
        NarrativePhysicalSourceResult,
        NarrativePhysicalReachabilityReport,
        validateNarrativePhysicalReachability;
