import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

typedef PrepareNarrativeEventBuilderV2Session
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);
typedef NarrativeEventBuilderV2IdGeneratorFactory = NarrativeEventIdGenerator
    Function();

/// Editor state that must be clean before a registry transaction starts.
///
/// Event V2 writes replace `project.json` through the journaled persistence
/// gateway. Starting that transaction while the editor owns newer in-memory
/// map/project bytes would make either side silently stale.
final class NarrativeEventBuilderV2WriteEnvironment {
  const NarrativeEventBuilderV2WriteEnvironment({
    required this.mapDirty,
    required this.projectDirty,
    required this.saving,
  });

  const NarrativeEventBuilderV2WriteEnvironment.clean()
      : mapDirty = false,
        projectDirty = false,
        saving = false;

  final bool mapDirty;
  final bool projectDirty;
  final bool saving;
}

enum NarrativeEventBuilderV2WriteStatus {
  blocked,
  committed,
  noOp,
  conflict,
  recoveryRequired,
  rejected,
  failed,
}

/// Product-facing result of one atomic Event-owned mutation.
///
/// The result deliberately keeps the authoring and persistence evidence so
/// tests and recovery UI can explain a failure without pretending that a
/// rejected draft reached disk.
final class NarrativeEventBuilderV2WriteResult {
  const NarrativeEventBuilderV2WriteResult({
    required this.status,
    required this.code,
    required this.message,
    this.eventId,
    this.authoringResult,
    this.persistenceResult,
  });

  final NarrativeEventBuilderV2WriteStatus status;
  final String code;
  final String message;
  final String? eventId;
  final NarrativeEventAuthoringResult? authoringResult;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;

  bool get succeeded =>
      status == NarrativeEventBuilderV2WriteStatus.committed ||
      status == NarrativeEventBuilderV2WriteStatus.noOp;
}

enum NarrativeEventBuilderV2CreationStep {
  draft,
  scene,
  reusePolicy,
  publication,
  reload,
}

/// Complete no-code creation intent.
///
/// A null source is the explicit “Décider plus tard” path. Such a record stays
/// a non-publishable draft; the workflow never invents a map or physical owner.
final class NarrativeEventBuilderV2CreationRequest {
  const NarrativeEventBuilderV2CreationRequest({
    required this.name,
    this.source,
    this.sceneId,
    this.reusePolicy,
    required this.publish,
  });

  final String name;
  final NarrativeEventSourceRef? source;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final bool publish;
}

/// Result of the ordered creation workflow.
///
/// [hasDurableDraft] is intentionally separate from [succeeded]: a later
/// conflict can leave a useful draft committed by the first transaction.
final class NarrativeEventBuilderV2CreationResult {
  const NarrativeEventBuilderV2CreationResult({
    required this.status,
    required this.code,
    required this.message,
    required this.eventId,
    required this.hasDurableDraft,
    required this.failedStep,
    required this.initialRegistry,
    required this.finalRegistry,
    required this.finalRecord,
    required this.writes,
  });

  final NarrativeEventBuilderV2WriteStatus status;
  final String code;
  final String message;
  final String? eventId;
  final bool hasDurableDraft;
  final NarrativeEventBuilderV2CreationStep? failedStep;
  final NarrativeEventRegistry? initialRegistry;
  final NarrativeEventRegistry? finalRegistry;
  final NarrativeEventRecord? finalRecord;
  final List<NarrativeEventBuilderV2WriteResult> writes;

  bool get succeeded =>
      failedStep == null &&
      (status == NarrativeEventBuilderV2WriteStatus.committed ||
          status == NarrativeEventBuilderV2WriteStatus.noOp);
}

/// Attested editor detail that the project list intentionally does not carry.
///
/// Raw identities remain internal dropdown values; visible widgets use only
/// the human labels carried by the catalog entries.
final class NarrativeEventBuilderV2EditorSnapshot {
  NarrativeEventBuilderV2EditorSnapshot({
    required this.projectRevision,
    required this.record,
    required List<NarrativeSpatialEventSourceOption> spatialSources,
    required List<NarrativeOutcomeEventSourceOption> outcomeSources,
    required List<NarrativeEventProjectSceneEntry> scenes,
    required List<NarrativeEventProjectFactEntry> facts,
    required List<NarrativeEventProjectEventEntry> events,
  })  : spatialSources = List.unmodifiable(spatialSources),
        outcomeSources = List.unmodifiable(outcomeSources),
        scenes = List.unmodifiable(scenes),
        facts = List.unmodifiable(facts),
        events = List.unmodifiable(events);

  final String projectRevision;
  final NarrativeEventRecord? record;
  final List<NarrativeSpatialEventSourceOption> spatialSources;
  final List<NarrativeOutcomeEventSourceOption> outcomeSources;
  final List<NarrativeEventProjectSceneEntry> scenes;
  final List<NarrativeEventProjectFactEntry> facts;
  final List<NarrativeEventProjectEventEntry> events;

  List<NarrativeEventCondition> get conditions =>
      record?.draftOrNull?.conditions ??
      record?.definitionOrNull?.conditions ??
      const [];

  NarrativeEventConditionExpression get conditionExpression =>
      record?.draftOrNull?.conditionExpression ??
      record?.definitionOrNull?.conditionExpression ??
      NarrativeEventConditionExpression.all(const []);

  NarrativeEventResetPolicy get resetPolicy =>
      record?.draftOrNull?.resetPolicy ??
      record?.definitionOrNull?.resetPolicy ??
      const NarrativeEventResetPolicy.never();
}

/// Thin H3/H4 coordinator over the existing core authoring operations and the
/// Phase E journaled registry writer.
///
/// It owns no registry algorithm and performs no map mutation. Every command
/// prepares a fresh attested session, applies exactly one core mutation, then
/// persists it with compare-and-swap semantics through the existing gateway.
final class NarrativeEventBuilderV2UseCase {
  NarrativeEventBuilderV2UseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventBuilderV2Session? prepareSession,
    NarrativeEventBuilderV2IdGeneratorFactory? idGeneratorFactory,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _idGeneratorFactory =
            idGeneratorFactory ?? NarrativeEventIdGenerator.new,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventBuilderV2Session _prepareSession;
  final NarrativeEventBuilderV2IdGeneratorFactory _idGeneratorFactory;
  final String Function() _operationIdFactory;

  Future<NarrativeEventBuilderV2EditorSnapshot> loadEditorSnapshot({
    required String projectPath,
    String? eventId,
  }) async {
    final session = await _prepareSession(projectPath);
    final catalog = session.context.catalog;
    return NarrativeEventBuilderV2EditorSnapshot(
      projectRevision: session.projectRevision,
      record: eventId == null
          ? null
          : _findRecord(session.context.registryOrNull, eventId),
      // NSC-41 keeps broken and legacy physical owners visible to authoring.
      // Mutations still accept only catalog-selectable identities; the UI uses
      // each option's reference state instead of pretending missing sources do
      // not exist.
      spatialSources: catalog.spatialSources.options,
      outcomeSources: catalog.outcomeSources.selectableOptions,
      scenes: [
        for (final entry in catalog.scenes)
          if (entry.buildable) entry
      ],
      facts: catalog.facts,
      events: [
        for (final entry in catalog.events)
          if (!entry.proposed && entry.applicableReferenceTarget) entry,
      ],
    );
  }

  /// Executes a read-only preview against a fresh attested project snapshot.
  ///
  /// The use case does no eligibility work: core builds the controlled
  /// GameState and delegates the decision to the production dispatch authority.
  Future<NarrativeEventSimulationReport> simulate({
    required String projectPath,
    required NarrativeEventSimulationInput input,
  }) async {
    final session = await _prepareSession(projectPath);
    final registry = session.context.registryOrNull;
    return simulateNarrativeEventDispatch(
      registryResult: session.context.registryState,
      projectCatalog: session.context.catalog,
      facts: session.manifest.facts,
      input: input,
      // An unclaimed dual-read registry is runtime-ready with its structural
      // index. Claimed legacy cohorts still fail closed here until the exact
      // runtime evidence is available instead of being guessed by the editor.
      legacyClaimIndex: registry?.mode == EventSystemMode.dualRead
          ? buildValidatedLegacyClaimIndex(registry!)
          : null,
    );
  }

  /// Persists each authoring step independently and reloads the attested
  /// session between steps. This matches the one-mutation journal contract and
  /// makes a partial failure recoverable instead of rolling back good bytes.
  Future<NarrativeEventBuilderV2CreationResult> create({
    required String projectPath,
    required NarrativeEventBuilderV2CreationRequest request,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) async {
    final writes = <NarrativeEventBuilderV2WriteResult>[];
    final draftWrite = await createDraft(
      projectPath: projectPath,
      name: request.name,
      source: request.source,
      environment: environment,
    );
    writes.add(draftWrite);
    final eventId = draftWrite.eventId;
    final initialRegistry = draftWrite.authoringResult?.previousRegistry;
    if (!draftWrite.succeeded || eventId == null) {
      return _creationFailure(
        write: draftWrite,
        eventId: eventId,
        failedStep: NarrativeEventBuilderV2CreationStep.draft,
        hasDurableDraft: false,
        initialRegistry: initialRegistry,
        writes: writes,
      );
    }

    Future<NarrativeEventBuilderV2CreationResult?> runStep(
      NarrativeEventBuilderV2CreationStep step,
      Future<NarrativeEventBuilderV2WriteResult> Function() action,
    ) async {
      final write = await action();
      writes.add(write);
      if (write.succeeded) return null;
      final snapshot = await _reloadRecord(projectPath, eventId);
      return _creationFailure(
        write: write,
        eventId: eventId,
        failedStep: step,
        hasDurableDraft: true,
        initialRegistry: initialRegistry,
        finalRegistry: snapshot.registry,
        finalRecord: snapshot.record,
        writes: writes,
      );
    }

    final sceneId = request.sceneId;
    if (sceneId != null) {
      final failure = await runStep(
        NarrativeEventBuilderV2CreationStep.scene,
        () => setScene(
          projectPath: projectPath,
          eventId: eventId,
          sceneId: sceneId,
          environment: environment,
        ),
      );
      if (failure != null) return failure;
    }

    final reusePolicy = request.reusePolicy;
    if (reusePolicy != null) {
      final failure = await runStep(
        NarrativeEventBuilderV2CreationStep.reusePolicy,
        () => setReusePolicy(
          projectPath: projectPath,
          eventId: eventId,
          reusePolicy: reusePolicy,
          environment: environment,
        ),
      );
      if (failure != null) return failure;
    }

    if (request.publish) {
      final failure = await runStep(
        NarrativeEventBuilderV2CreationStep.publication,
        () => publish(
          projectPath: projectPath,
          eventId: eventId,
          environment: environment,
        ),
      );
      if (failure != null) return failure;
    }

    try {
      final snapshot = await _reloadRecord(projectPath, eventId);
      final finalWrite = writes.last;
      return NarrativeEventBuilderV2CreationResult(
        status: writes.any(
          (write) =>
              write.status == NarrativeEventBuilderV2WriteStatus.committed,
        )
            ? NarrativeEventBuilderV2WriteStatus.committed
            : finalWrite.status,
        code: finalWrite.code,
        message: finalWrite.message,
        eventId: eventId,
        hasDurableDraft: true,
        failedStep: null,
        initialRegistry: initialRegistry,
        finalRegistry: snapshot.registry,
        finalRecord: snapshot.record,
        writes: List.unmodifiable(writes),
      );
    } on Object {
      return NarrativeEventBuilderV2CreationResult(
        status: NarrativeEventBuilderV2WriteStatus.failed,
        code: 'committedOutOfSync',
        message: 'Le brouillon est enregistré, mais sa relecture a échoué.',
        eventId: eventId,
        hasDurableDraft: true,
        failedStep: NarrativeEventBuilderV2CreationStep.reload,
        initialRegistry: initialRegistry,
        finalRegistry: null,
        finalRecord: null,
        writes: List.unmodifiable(writes),
      );
    }
  }

  Future<NarrativeEventBuilderV2WriteResult> createDraft({
    required String projectPath,
    required String name,
    NarrativeEventSourceRef? source,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _execute(
      projectPath: projectPath,
      environment: environment,
      author: (session) => createNarrativeEventDraft(
        context: session.context,
        expectedRevision: session.projectRevision,
        name: name,
        initialSource: source,
        idGenerator: _idGeneratorFactory(),
      ),
    );
  }

  Future<_ReloadedNarrativeEvent> _reloadRecord(
    String projectPath,
    String eventId,
  ) async {
    final session = await _prepareSession(projectPath);
    return _ReloadedNarrativeEvent(
      registry: session.context.registryOrNull,
      record: _findRecord(session.context.registryOrNull, eventId),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> duplicate({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _execute(
      projectPath: projectPath,
      environment: environment,
      author: (session) => duplicateNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        idGenerator: _idGeneratorFactory(),
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> unpublish({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => unpublishNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> delete({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => deleteNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        dependencyIndex: buildNarrativeDependencyIndex(
          project: session.manifest,
          maps: session.maps,
        ),
      ),
    );
  }

  Future<NarrativeEventAuthoringResult> previewDelete({
    required String projectPath,
    required String eventId,
  }) async {
    final session = await _prepareSession(projectPath);
    return deleteNarrativeEvent(
      context: session.context,
      expectedRevision: session.projectRevision,
      eventId: eventId,
      dependencyIndex: buildNarrativeDependencyIndex(
        project: session.manifest,
        maps: session.maps,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> undo({
    required String undoPath,
  }) async {
    late final NarrativeEventRegistryPersistenceResult persistence;
    try {
      persistence = await _persistenceGateway.undo(undoPath);
    } on Object {
      return const NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.failed,
        code: 'undoException',
        message: 'La dernière modification n’a pas pu être annulée.',
      );
    }
    return NarrativeEventBuilderV2WriteResult(
      status: _writeStatus(persistence),
      code: persistence.code,
      message: persistence.message,
      eventId: persistence.undoEntry?.eventIds.length == 1
          ? persistence.undoEntry!.eventIds.single
          : null,
      persistenceResult: persistence,
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> rename({
    required String projectPath,
    required String eventId,
    required String name,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => renameNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        name: name,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setSource({
    required String projectPath,
    required String eventId,
    required NarrativeEventSourceRef source,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) {
        final current = _findRecord(
          session.context.registryOrNull,
          eventId,
        );
        final currentSource =
            current?.draftOrNull?.source ?? current?.definitionOrNull?.source;
        return currentSource == null
            ? selectNarrativeEventSource(
                context: session.context,
                expectedRevision: session.projectRevision,
                eventId: eventId,
                source: source,
              )
            : replaceNarrativeEventSource(
                context: session.context,
                expectedRevision: session.projectRevision,
                eventId: eventId,
                source: source,
              );
      },
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setConditions({
    required String projectPath,
    required String eventId,
    required List<NarrativeEventCondition> conditions,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventConditions(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        conditions: conditions,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setConditionExpression({
    required String projectPath,
    required String eventId,
    required NarrativeEventConditionExpression expression,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventConditionExpression(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        expression: expression,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setScene({
    required String projectPath,
    required String eventId,
    required String sceneId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventScene(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        sceneId: sceneId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> removeScene({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => removeNarrativeEventScene(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setReusePolicy({
    required String projectPath,
    required String eventId,
    required NarrativeEventReusePolicy reusePolicy,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventReusePolicy(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        reusePolicy: reusePolicy,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setResetPolicy({
    required String projectPath,
    required String eventId,
    required NarrativeEventResetPolicy resetPolicy,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventResetPolicy(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        resetPolicy: resetPolicy,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setPriority({
    required String projectPath,
    required String eventId,
    required int priority,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventPriority(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        priority: priority,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setOrder({
    required String projectPath,
    required String eventId,
    required int order,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => setNarrativeEventOrder(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        order: order,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> publish({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => publishNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
      ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> setEnabled({
    required String projectPath,
    required String eventId,
    required bool enabled,
    required NarrativeEventBuilderV2WriteEnvironment environment,
  }) {
    return _executeForEvent(
      projectPath: projectPath,
      eventId: eventId,
      environment: environment,
      author: (session) => enabled
          ? activateNarrativeEvent(
              context: session.context,
              expectedRevision: session.projectRevision,
              eventId: eventId,
            )
          : deactivateNarrativeEvent(
              context: session.context,
              expectedRevision: session.projectRevision,
              eventId: eventId,
            ),
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> _executeForEvent({
    required String projectPath,
    required String eventId,
    required NarrativeEventBuilderV2WriteEnvironment environment,
    required NarrativeEventAuthoringResult Function(
      NarrativeEventAuthoringSession session,
    ) author,
  }) {
    return _execute(
      projectPath: projectPath,
      environment: environment,
      expectedEventId: eventId,
      author: author,
    );
  }

  Future<NarrativeEventBuilderV2WriteResult> _execute({
    required String projectPath,
    required NarrativeEventBuilderV2WriteEnvironment environment,
    required NarrativeEventAuthoringResult Function(
      NarrativeEventAuthoringSession session,
    ) author,
    String? expectedEventId,
  }) async {
    final blocked = _dirtyGate(environment);
    if (blocked != null) return blocked;

    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.rejected,
        code: 'preflightRejected',
        message: 'La session Event ne peut pas être préparée: $error',
        eventId: expectedEventId,
      );
    }

    final authoring = author(session);
    final eventId = expectedEventId ?? authoring.eventId;
    if (authoring.status == NarrativeEventAuthoringStatus.noOp) {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.noOp,
        code: 'noOp',
        message: 'Aucune modification à enregistrer.',
        eventId: eventId,
        authoringResult: authoring,
      );
    }
    if (authoring.status != NarrativeEventAuthoringStatus.applied ||
        authoring.nextRegistry == null) {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.rejected,
        code: authoring.rejectionCode ?? authoring.status.name,
        message: authoring.humanReason ??
            'Cette modification ne peut pas être enregistrée.',
        eventId: eventId,
        authoringResult: authoring,
      );
    }

    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: _operationIdFactory(),
      result: authoring,
    );
    late final NarrativeEventRegistryPersistenceResult persistence;
    try {
      persistence = await _persistenceGateway.persist(request);
    } on Object {
      return NarrativeEventBuilderV2WriteResult(
        status: NarrativeEventBuilderV2WriteStatus.failed,
        code: 'persistenceException',
        message: 'La modification n’a pas pu être enregistrée.',
        eventId: eventId,
        authoringResult: authoring,
      );
    }
    return NarrativeEventBuilderV2WriteResult(
      status: _writeStatus(persistence),
      code: persistence.code,
      message: persistence.message,
      eventId: eventId,
      authoringResult: authoring,
      persistenceResult: persistence,
    );
  }
}

NarrativeEventBuilderV2CreationResult _creationFailure({
  required NarrativeEventBuilderV2WriteResult write,
  required String? eventId,
  required NarrativeEventBuilderV2CreationStep failedStep,
  required bool hasDurableDraft,
  required NarrativeEventRegistry? initialRegistry,
  required List<NarrativeEventBuilderV2WriteResult> writes,
  NarrativeEventRegistry? finalRegistry,
  NarrativeEventRecord? finalRecord,
}) {
  return NarrativeEventBuilderV2CreationResult(
    status: write.status,
    code: write.code,
    message: write.message,
    eventId: eventId,
    hasDurableDraft: hasDurableDraft,
    failedStep: failedStep,
    initialRegistry: initialRegistry,
    finalRegistry: finalRegistry,
    finalRecord: finalRecord,
    writes: List.unmodifiable(writes),
  );
}

final class _ReloadedNarrativeEvent {
  const _ReloadedNarrativeEvent({
    required this.registry,
    required this.record,
  });

  final NarrativeEventRegistry? registry;
  final NarrativeEventRecord? record;
}

NarrativeEventBuilderV2WriteResult? _dirtyGate(
  NarrativeEventBuilderV2WriteEnvironment environment,
) {
  if (environment.saving) {
    return const NarrativeEventBuilderV2WriteResult(
      status: NarrativeEventBuilderV2WriteStatus.blocked,
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde.',
    );
  }
  if (environment.mapDirty) {
    return const NarrativeEventBuilderV2WriteResult(
      status: NarrativeEventBuilderV2WriteStatus.blocked,
      code: 'mapDirty',
      message: 'Enregistrez la map avant de modifier cet Event.',
    );
  }
  if (environment.projectDirty) {
    return const NarrativeEventBuilderV2WriteResult(
      status: NarrativeEventBuilderV2WriteStatus.blocked,
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de modifier cet Event.',
    );
  }
  return null;
}

NarrativeEventBuilderV2WriteStatus _writeStatus(
  NarrativeEventRegistryPersistenceResult persistence,
) {
  return switch (persistence.status) {
    NarrativeEventRegistryPersistenceStatus.committed ||
    NarrativeEventRegistryPersistenceStatus.recovered =>
      NarrativeEventBuilderV2WriteStatus.committed,
    NarrativeEventRegistryPersistenceStatus.noOp =>
      NarrativeEventBuilderV2WriteStatus.noOp,
    NarrativeEventRegistryPersistenceStatus.staleRevision ||
    NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot =>
      NarrativeEventBuilderV2WriteStatus.conflict,
    NarrativeEventRegistryPersistenceStatus.recoveryRequired =>
      NarrativeEventBuilderV2WriteStatus.recoveryRequired,
    NarrativeEventRegistryPersistenceStatus.blocked =>
      NarrativeEventBuilderV2WriteStatus.blocked,
    NarrativeEventRegistryPersistenceStatus.ioFailure =>
      NarrativeEventBuilderV2WriteStatus.failed,
    NarrativeEventRegistryPersistenceStatus.staleUndo ||
    NarrativeEventRegistryPersistenceStatus.rejected ||
    NarrativeEventRegistryPersistenceStatus.unsupportedRegistry ||
    NarrativeEventRegistryPersistenceStatus.invalidRegistry =>
      NarrativeEventBuilderV2WriteStatus.rejected,
  };
}

String _defaultOperationId() {
  return 'v2_phase2_${DateTime.now().microsecondsSinceEpoch}';
}

NarrativeEventRecord? _findRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id == eventId) return record;
  }
  return null;
}
