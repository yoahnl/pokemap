import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_map_bridge_models.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

typedef PrepareNarrativeEventMapBridgeSession
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);
typedef NarrativeEventIdGeneratorFactory = NarrativeEventIdGenerator Function();

final class CreateNarrativeEventFromMapSourceUseCase {
  CreateNarrativeEventFromMapSourceUseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventMapBridgeSession? prepareSession,
    NarrativeEventIdGeneratorFactory? eventIdGeneratorFactory,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _eventIdGeneratorFactory =
            eventIdGeneratorFactory ?? NarrativeEventIdGenerator.new,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventMapBridgeSession _prepareSession;
  final NarrativeEventIdGeneratorFactory _eventIdGeneratorFactory;
  final String Function() _operationIdFactory;

  Future<NarrativeEventMapCreationResult> call({
    required String projectPath,
    required NarrativeEventMapCreationIntent intent,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    bool allowAdditionalEvent = false,
  }) async {
    final blocked = _dirtyGuard(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventMapCreationResult.preflightRejected(error);
    }

    final existingLinks = _exactLinks(
      session.context.registryOrNull,
      intent.source,
    );
    if (existingLinks.isNotEmpty && !allowAdditionalEvent) {
      return NarrativeEventMapCreationResult.existingLinks(existingLinks);
    }

    final authoringResult = createNarrativeEventDraft(
      context: session.context,
      expectedRevision: session.projectRevision,
      name: intent.humanName,
      initialSource: intent.source,
      idGenerator: _eventIdGeneratorFactory(),
    );
    if (authoringResult.status != NarrativeEventAuthoringStatus.applied ||
        authoringResult.nextRegistry == null ||
        authoringResult.eventId == null) {
      return NarrativeEventMapCreationResult.authoringRejected(
        authoringResult,
      );
    }

    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: _operationIdFactory(),
      result: authoringResult,
    );
    late final NarrativeEventRegistryPersistenceResult persistenceResult;
    try {
      persistenceResult = await _persistenceGateway.persist(request);
    } on Object {
      return NarrativeEventMapCreationResult.persistenceException(
        authoringResult,
      );
    }
    if (!persistenceResult.succeeded) {
      return NarrativeEventMapCreationResult.persistenceRejected(
        authoringResult: authoringResult,
        persistenceResult: persistenceResult,
      );
    }
    return NarrativeEventMapCreationResult.committed(
      eventId: authoringResult.eventId!,
      nextRegistry: request.nextRegistry,
      previousRegistry: request.previousRegistry,
      authoringResult: authoringResult,
      persistenceResult: persistenceResult,
    );
  }
}

NarrativeEventMapCreationResult? _dirtyGuard({
  required bool mapDirty,
  required bool projectDirty,
  required bool saving,
}) {
  if (saving) {
    return NarrativeEventMapCreationResult.blocked(
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde avant de créer un Event.',
    );
  }
  if (mapDirty) {
    return NarrativeEventMapCreationResult.blocked(
      code: 'mapDirty',
      message: 'Enregistrez la map avant de créer un Event depuis sa source.',
    );
  }
  if (projectDirty) {
    return NarrativeEventMapCreationResult.blocked(
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de créer un Event.',
    );
  }
  return null;
}

List<NarrativeEventMapLinkedEvent> _exactLinks(
  NarrativeEventRegistry? registry,
  NarrativeEventSourceRef source,
) {
  final links = <NarrativeEventMapLinkedEvent>[];
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    final link = record.when<NarrativeEventMapLinkedEvent?>(
      draft: (draft) => draft.source == source
          ? NarrativeEventMapLinkedEvent(
              eventId: draft.id,
              name: draft.name,
              order: draft.order,
              enabled: null,
            )
          : null,
      configured: (definition, enabled) => definition.source == source
          ? NarrativeEventMapLinkedEvent(
              eventId: definition.id,
              name: definition.name,
              order: definition.order,
              enabled: enabled,
            )
          : null,
    );
    if (link != null) links.add(link);
  }
  links.sort((left, right) {
    final orderComparison = left.order.compareTo(right.order);
    if (orderComparison != 0) return orderComparison;
    return compareNarrativeEventUtf16(left.eventId, right.eventId);
  });
  return List.unmodifiable(links);
}

String _defaultOperationId() {
  return 'v2_23_${DateTime.now().microsecondsSinceEpoch}';
}
