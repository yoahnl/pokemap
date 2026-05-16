/// Battle engine for Pokémon-like RPG combat.
///
/// Pure Dart package, independent of Flutter/Flame.
/// Deterministic, testable, and minimal.
///
/// ## Usage
///
/// ```dart
/// // 1. Create setup
/// final setup = BattleSetup(
///   playerPokemon: BattleCombatantData(
///     speciesId: 'pikachu',
///     level: 5,
///     maxHp: 20,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   enemyPokemon: BattleCombatantData(
///     speciesId: 'lapras',
///     level: 5,
///     maxHp: 25,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   isTrainerBattle: true,
///   trainerId: 'gym_leader_1',
/// );
///
/// // 2. Create session
/// final session = createBattleSession(setup);
///
/// // 3. Read the explicit decision request
/// final request = session.decisionRequest;
/// final choices = request.allowedChoices; // compatibility helper
///
/// // 4. Apply choice
/// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
///
/// // 5. Check if finished
/// if (newSession.state.isFinished) {
///   final outcome = newSession.state.outcome!;
///   if (outcome.isVictory) {
///     // Mark trainer as defeated
///   }
/// }
/// ```
library map_battle;

export 'src/battle_setup.dart';
export 'src/battle_decision.dart';
export 'src/battle_session.dart';
export 'src/battle_state.dart';
export 'src/battle_topology.dart';
export 'src/battle_field.dart';
export 'src/battle_spikes.dart';
export 'src/battle_stealth_rock.dart';
export 'src/battle_status.dart';
export 'src/battle_volatile.dart';
export 'src/battle_switch.dart';
export 'src/battle_stats.dart';
export 'src/battle_typing.dart';
export 'src/battle_type_chart.dart';
export 'src/battle_rng.dart';
export 'src/battle_action.dart';
export 'src/battle_move.dart';
export 'src/battle_opponent_policy.dart';
export 'src/battle_resolution.dart';
export 'src/application/battle_engine.dart' show BattleEngine;
export 'src/application/battle_session_facade.dart' show BattleSessionFacade;
export 'src/application/battle_turn_runner.dart' show BattleEngineTurnResult;
export 'src/domain/battle/battle_context.dart' show BattlePublicState;
export 'src/domain/battle/battle_outcome.dart'
    show BattleEngineOutcome, BattleEngineOutcomeKind;
export 'src/domain/battle/battle_setup.dart' show BattleEngineSetup;
export 'src/domain/battle/battle_stats.dart'
    show BattleComputedStats, BattleStat, BattleStatStageSet, BattleTypes;
export 'src/domain/battle/battle_battler.dart'
    show BattleBattler, BattleBattlerHistory, BattleEffectStack;
export 'src/domain/battle/battle_slot.dart' show BattlePositionRef, BattleSlot;
export 'src/domain/battle/battle_party.dart' show BattleParty;
export 'src/domain/battle/battle_bank.dart' show BattleBank;
export 'src/domain/battle/battle_topology.dart' show BattleTopology;
export 'src/domain/action/battle_action.dart'
    show
        PsdkBattleAction,
        PsdkBattleActionKind,
        PsdkBattleFightAction,
        PsdkBattleNoAction,
        PsdkBattleSwitchAction;
export 'src/domain/action/battle_action_decision_mapper.dart'
    show PsdkBattleActionDecisionMapper;
export 'src/domain/action/battle_action_ordering.dart'
    show PsdkBattleActionOrdering;
export 'src/domain/action/battle_action_queue.dart' show PsdkBattleActionQueue;
export 'src/domain/handler/battle_ability_change_handler.dart'
    show BattleAbilityChangeHandler;
export 'src/domain/handler/battle_battle_end_handler.dart'
    show BattleBattleEndHandler;
export 'src/domain/handler/battle_damage_handler.dart' show BattleDamageHandler;
export 'src/domain/handler/battle_end_turn_handler.dart'
    show BattleEndTurnHandler;
export 'src/domain/handler/battle_handler_context.dart'
    show BattleHandlerContext;
export 'src/domain/handler/battle_handler_result.dart' show BattleHandlerResult;
export 'src/domain/handler/battle_heal_handler.dart' show BattleHealHandler;
export 'src/domain/handler/battle_item_change_handler.dart'
    show BattleItemChangeHandler;
export 'src/domain/handler/battle_stat_change_handler.dart'
    show BattleStatChangeHandler;
export 'src/domain/handler/battle_status_change_handler.dart'
    show BattleStatusChangeHandler;
export 'src/domain/handler/battle_switch_handler.dart' show BattleSwitchHandler;
export 'src/domain/handler/battle_terrain_change_handler.dart'
    show BattleTerrainChangeHandler;
export 'src/domain/handler/battle_weather_change_handler.dart'
    show BattleWeatherChangeHandler;
export 'src/domain/move/battle_move_data.dart'
    show BattleMoveDefinition, BattleMoveFlags, BattleStageMod;
export 'src/domain/move/battle_move_instance.dart' show BattleMoveInstance;
export 'src/domain/move/battle_move_behavior.dart'
    show
        BattleMoveBehavior,
        BattleMoveBehaviorContext,
        BattleMoveBehaviorResolution,
        BattleMoveBehaviorResolver,
        BattleMoveUserPreventionBehavior,
        CallbackBattleMoveBehavior;
export 'src/domain/move/battle_move_execution.dart'
    show BattleMoveProcedureExecution;
export 'src/domain/move/battle_move_history_recorder.dart'
    show BattleMoveHistoryRecorder;
export 'src/domain/move/battle_move_immunity_resolver.dart'
    show BattleMoveImmunityResolver;
export 'src/domain/move/battle_move_prevention.dart'
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
export 'src/domain/move/battle_move_remapper.dart'
    show
        BattleMoveRemapContext,
        BattleMoveRemapper,
        BattleMoveRemapResult,
        NoopBattleMoveRemapper;
export 'src/domain/move/battle_target_resolver.dart' show BattleTargetResolver;
export 'src/domain/move/battle_accuracy_resolver.dart'
    show BattleAccuracyResolver, BattleAccuracyResult;
export 'src/domain/move/battle_move_critical_resolver.dart'
    show BattleMoveCriticalResolver, BattleMoveCriticalResult;
export 'src/domain/move/battle_move_damage_calculator.dart'
    show
        BattleMoveDamageCalculator,
        BattleMoveDamageContext,
        BattleMoveDamageOverrides,
        BattleMoveDamageResult,
        BattleMoveStatResolver;
export 'src/domain/move/battle_move_procedure.dart'
    show
        BattleMoveProcedure,
        BattleMoveProcedureResult,
        BattleMoveTargetPrecheck,
        BattleMoveTargetPrecheckResult;
export 'src/domain/move/battle_move_registry.dart'
    show BattleMoveRegistry, UnsupportedBattleMoveBehavior;
export 'src/domain/move/psdk_battle_move_request.dart'
    show PsdkBattleMoveRequest;
export 'src/domain/move/psdk_battle_move_executor.dart'
    show PsdkBattleMoveExecutor;
export 'src/domain/move/battle_move_secondary_effect_resolver.dart'
    show BattleMoveSecondaryEffectResolver, BattleMoveSecondaryEffectResult;
export 'src/domain/move/battle_move_type_processor.dart'
    show BattleMoveTypeProcessor, BattleTypeEffectivenessResult;
export 'src/data/static_basic_move_registry.dart'
    show createStaticBasicMoveRegistry;
export 'src/data/generated/psdk_move_registry_manifest.dart'
    show
        psdkMoveRegistryManifest,
        PsdkMoveRegistryManifestEntry,
        PsdkPortStatus,
        PsdkMoveDependency;
export 'src/domain/decision/battle_decision.dart'
    show
        BattleDecision,
        BattleEngineDecisionRequest,
        BattleEngineDecisionRequestKind,
        BattleFightDecision,
        BattleMoveDecisionOption,
        BattleSwitchDecision;
export 'src/domain/timeline/battle_timeline.dart' show BattleTimeline;
export 'src/domain/timeline/battle_timeline_builder.dart'
    show BattleTimelineBuilder;
export 'src/domain/timeline/battle_timeline_event.dart'
    show
        BattleAbilityTriggeredTimelineEvent,
        BattleActionEndedTimelineEvent,
        BattleActionStartedTimelineEvent,
        BattleAnimationCueTimelineEvent,
        BattleCaptureAttemptTimelineEvent,
        BattleDamageTimelineEvent,
        BattleDecisionRequestedTimelineEvent,
        BattleEffectTimelineEvent,
        BattleEndedTimelineEvent,
        BattleFleeAttemptTimelineEvent,
        BattleHealTimelineEvent,
        BattleItemTimelineEvent,
        BattleMoveDeclaredTimelineEvent,
        BattleMoveFailedTimelineEvent,
        BattleMoveImmuneTimelineEvent,
        BattleMoveMissedTimelineEvent,
        BattleMoveProcedureStage,
        BattleMoveProcedureTraceEvent,
        BattleMovePpSpentTimelineEvent,
        BattleStatStageChangeTimelineEvent,
        BattleStatusChangeTimelineEvent,
        BattleStatusCureTimelineEvent,
        BattleSwitchInTimelineEvent,
        BattleSwitchOutTimelineEvent,
        BattleTerrainChangedTimelineEvent,
        BattleTimelineEvent,
        BattleTurnEndedTimelineEvent,
        BattleTurnStartedTimelineEvent,
        BattleWeatherChangedTimelineEvent;
export 'src/domain/rng/battle_seeded_rng.dart'
    show BattleRngChanceRoll, BattleRngStream, BattleRngStreamRoll;
export 'src/domain/rng/battle_rng_streams.dart'
    show BattleRngSeeds, BattleRngStreamKind, BattleRngStreams;
export 'src/psdk/psdk_battle.dart';
