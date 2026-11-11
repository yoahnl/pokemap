library;

export 'src/runtime/scene_runtime_plan.dart';
export 'src/runtime/scene_runtime_plan_builder.dart';
export 'src/runtime/scene_runtime_executor.dart';
export 'src/runtime/scene_runtime_dry_run_preview.dart';
export 'src/runtime/scene_execution_context.dart';
export 'src/runtime/scene_structured_interaction_port.dart';

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
        NarrativeEventStateTransactions,
        NarrativeEventStateCheckpointOwner;
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
export 'src/narrative_parallel_scheduler.dart';
