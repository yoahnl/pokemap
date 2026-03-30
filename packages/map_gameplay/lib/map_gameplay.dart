library map_gameplay;

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
        PathAnimationSignalKind,
        PathAnimationSignal,
        NothingToInteract,
        NpcInteracted,
        SignInteracted,
        ItemInteracted,
        EntityInteracted,
        PlacedElementInteracted;
export 'src/gameplay_world_state.dart' show GameplayWorldState;
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

// Script system exports
export 'src/script_condition_evaluator.dart'
    show ScriptConditionEvaluator, ScriptEvaluationContext;
export 'src/event_page_resolver.dart' show EventPageResolver;
export 'src/game_state_mutations.dart' show GameStateMutations;
