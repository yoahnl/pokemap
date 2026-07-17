import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

typedef PrepareNarrativeEventSpatialSourceSession
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);

enum NarrativeEventSpatialSourceLinkStatus {
  blocked,
  noOp,
  committed,
  committedOutOfSync,
  rejected,
  preflightRejected,
}

final class NarrativeEventSpatialSourceLinkResult {
  const NarrativeEventSpatialSourceLinkResult({
    required this.status,
    required this.code,
    required this.message,
    this.previousRegistry,
    this.nextRegistry,
    this.authoringResult,
    this.persistenceResult,
  });

  final NarrativeEventSpatialSourceLinkStatus status;
  final String code;
  final String message;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventAuthoringResult? authoringResult;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;
}

final class NarrativeEventSpatialSourceLinkUseCase {
  NarrativeEventSpatialSourceLinkUseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventSpatialSourceSession? prepareSession,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventSpatialSourceSession _prepareSession;
  final String Function() _operationIdFactory;

  Future<NarrativeEventSpatialSourceLinkResult> call({
    required String projectPath,
    required String eventId,
    required NarrativeEventSourceRef source,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;
    if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
      return const NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'nonSpatialSource',
        message: 'Choisissez une entité, une zone ou la map elle-même.',
      );
    }

    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.preflightRejected,
        code: 'preflightRejected',
        message: 'La session Event ne peut pas être préparée: $error',
      );
    }

    final record = _findEventRecord(
      session.context.registryOrNull,
      eventId,
    );
    final currentSource =
        record?.draftOrNull?.source ?? record?.definitionOrNull?.source;
    final authoring = currentSource == null
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

    if (authoring.status == NarrativeEventAuthoringStatus.noOp) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.noOp,
        code: 'noOp',
        message: 'Cette source est déjà liée à l’Event.',
        previousRegistry: authoring.previousRegistry,
        nextRegistry: authoring.nextRegistry ?? session.context.registryOrNull,
        authoringResult: authoring,
      );
    }
    if (authoring.status != NarrativeEventAuthoringStatus.applied ||
        authoring.nextRegistry == null) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: authoring.rejectionCode ?? authoring.status.name,
        message: authoring.humanReason ??
            'La source ne peut pas être liée à cet Event.',
        previousRegistry: authoring.previousRegistry,
        nextRegistry: authoring.nextRegistry,
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
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'persistenceException',
        message: 'La liaison n’a pas pu être enregistrée.',
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        authoringResult: authoring,
      );
    }
    if (!persistence.succeeded) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: persistence.code,
        message: persistence.message,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        authoringResult: authoring,
        persistenceResult: persistence,
      );
    }
    return NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.committed,
      code: persistence.code,
      message: persistence.message,
      previousRegistry: request.previousRegistry,
      nextRegistry: request.nextRegistry,
      authoringResult: authoring,
      persistenceResult: persistence,
    );
  }
}

NarrativeEventSpatialSourceLinkResult? _dirtyGate({
  required bool mapDirty,
  required bool projectDirty,
  required bool saving,
}) {
  if (saving) {
    return const NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.blocked,
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde.',
    );
  }
  if (mapDirty) {
    return const NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.blocked,
      code: 'mapDirty',
      message: 'Enregistrez la map avant de changer la source.',
    );
  }
  if (projectDirty) {
    return const NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.blocked,
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de changer la source.',
    );
  }
  return null;
}

String _defaultOperationId() {
  return 'v2_24_link_${DateTime.now().microsecondsSinceEpoch}';
}

NarrativeEventRecord? _findEventRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id == eventId) return record;
  }
  return null;
}
