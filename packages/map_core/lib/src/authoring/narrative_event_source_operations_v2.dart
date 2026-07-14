import '../catalogs/narrative_event_project_catalog.dart';
import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../read_models/narrative_event_navigation_intent.dart';
import 'narrative_event_authoring_contract.dart';
import 'narrative_event_authoring_support.dart';
import 'narrative_event_configuration_validation.dart';

NarrativeEventAuthoringResult selectNarrativeEventSource({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeEventSourceRef source,
}) {
  return _setNarrativeEventSource(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    source: source,
    requestedMutation: NarrativeEventAuthoringMutation.selectSource,
  );
}

NarrativeEventAuthoringResult replaceNarrativeEventSource({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeEventSourceRef source,
}) {
  return _setNarrativeEventSource(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    source: source,
    requestedMutation: NarrativeEventAuthoringMutation.replaceSource,
  );
}

NarrativeEventAuthoringResult _setNarrativeEventSource({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeEventSourceRef source,
  required NarrativeEventAuthoringMutation requestedMutation,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: requestedMutation,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _sourceRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: requestedMutation,
      code: 'eventMissing',
      message: 'L’événement à modifier n’existe pas.',
    );
  }
  final currentSource = record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
  final impact = _sourceImpact(
    catalog: context.catalog,
    currentSource: currentSource,
    nextSource: source,
    structuralUnpublish: false,
  );
  if (requestedMutation == NarrativeEventAuthoringMutation.selectSource &&
      currentSource != null &&
      currentSource != source) {
    return _sourceRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: requestedMutation,
      code: 'sourceAlreadySelected',
      message: 'Utilisez le remplacement pour changer la source actuelle.',
    );
  }
  if (requestedMutation == NarrativeEventAuthoringMutation.replaceSource &&
      currentSource == null) {
    return _sourceRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: requestedMutation,
      code: 'sourceNotSelected',
      message: 'Choisissez d’abord une source pour cet événement.',
    );
  }
  final unchanged = currentSource == source;
  if (!unchanged && record.enabledOrNull == true) {
    return _sourceRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: requestedMutation,
      code: 'mustDisableFirst',
      message: 'Désactivez l’événement avant de changer sa source.',
    );
  }
  final claimRejection = _claimPinRejection(
    context: context,
    expectedRevision: expectedRevision,
    record: record,
    nextSource: source,
    mutation: requestedMutation,
  );
  if (claimRejection != null) return claimRejection;
  final resolution = context.catalog.resolveSource(source);
  if (resolution.status != NarrativeEventProjectResolutionStatus.found) {
    return _sourceResolutionRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      resolutionStatus: resolution.status,
      option: resolution.valueOrNull,
      mutation: requestedMutation,
    );
  }
  if (unchanged) {
    final catalogRejection = _catalogBlockRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      nextRecord: record,
      mutation: requestedMutation,
    );
    if (catalogRejection != null) return catalogRejection;
    return NarrativeEventAuthoringResult.noOp(
      mutation: requestedMutation,
      registry: registry,
      record: record,
      expectedRevision: expectedRevision,
      impactPreview: impact,
    );
  }
  final nextRecord = record.when(
    draft: (draft) => NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: draft.id,
        name: draft.name,
        source: source,
        conditions: draft.conditions,
        sceneId: draft.sceneId,
        reusePolicy: draft.reusePolicy,
        priority: draft.priority,
        order: draft.order,
      ),
    ),
    configured: (definition, _) =>
        NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: definition.id,
        name: definition.name,
        source: source,
        conditions: definition.conditions,
        sceneId: definition.sceneId,
        reusePolicy: definition.reusePolicy,
        priority: definition.priority,
        order: definition.order,
      ),
      enabled: false,
    ),
  );
  final catalogRejection = _catalogBlockRejection(
    context: context,
    expectedRevision: expectedRevision,
    record: record,
    nextRecord: nextRecord,
    mutation: requestedMutation,
  );
  if (catalogRejection != null) return catalogRejection;
  final nextRegistry = replaceNarrativeEventRecord(registry, nextRecord);
  return NarrativeEventAuthoringResult.applied(
    mutation: requestedMutation,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
    impactPreview: impact,
  );
}

NarrativeEventAuthoringResult removeNarrativeEventSource({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.removeSource,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _sourceRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.removeSource,
      code: 'eventMissing',
      message: 'L’événement à modifier n’existe pas.',
    );
  }
  if (record.enabledOrNull == true) {
    return _sourceRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.removeSource,
      code: 'mustDisableFirst',
      message: 'Désactivez l’événement avant de retirer sa source.',
    );
  }
  final currentSource = record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
  final structuralUnpublish = record.definitionOrNull != null;
  final impact = _sourceImpact(
    catalog: context.catalog,
    currentSource: currentSource,
    nextSource: null,
    structuralUnpublish: structuralUnpublish,
  );
  if (currentSource == null) {
    final catalogRejection = _catalogBlockRejection(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      nextRecord: record,
      mutation: NarrativeEventAuthoringMutation.removeSource,
    );
    if (catalogRejection != null) return catalogRejection;
    return NarrativeEventAuthoringResult.noOp(
      mutation: NarrativeEventAuthoringMutation.removeSource,
      registry: registry,
      record: record,
      expectedRevision: expectedRevision,
      impactPreview: impact,
    );
  }
  final claimRejection = _claimPinRejection(
    context: context,
    expectedRevision: expectedRevision,
    record: record,
    nextSource: null,
    mutation: NarrativeEventAuthoringMutation.removeSource,
  );
  if (claimRejection != null) return claimRejection;
  final nextRecord = record.when(
    draft: (draft) => NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: draft.id,
        name: draft.name,
        source: null,
        conditions: draft.conditions,
        sceneId: draft.sceneId,
        reusePolicy: draft.reusePolicy,
        priority: draft.priority,
        order: draft.order,
      ),
    ),
    configured: (definition, _) => NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: definition.id,
        name: definition.name,
        source: null,
        conditions: definition.conditions,
        sceneId: definition.sceneId,
        reusePolicy: definition.reusePolicy,
        priority: definition.priority,
        order: definition.order,
      ),
    ),
  );
  final catalogRejection = _catalogBlockRejection(
    context: context,
    expectedRevision: expectedRevision,
    record: record,
    nextRecord: nextRecord,
    mutation: NarrativeEventAuthoringMutation.removeSource,
  );
  if (catalogRejection != null) return catalogRejection;
  final nextRegistry = replaceNarrativeEventRecord(registry, nextRecord);
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.removeSource,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
    impactPreview: impact,
  );
}

NarrativeEventAuthoringResult? _catalogBlockRejection({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord? record,
  required NarrativeEventRecord nextRecord,
  required NarrativeEventAuthoringMutation mutation,
}) {
  final issue = firstBlockingNarrativeEventCatalogIssue(context);
  if (issue == null ||
      narrativeEventRepairStrictlyReducesCatalogErrors(
        context: context,
        nextRecord: nextRecord,
      )) {
    return null;
  }
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: mutation,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: 'catalogBlocked',
    message: issue.message,
    path: issue.path,
  );
}

NarrativeEventAuthoringResult _sourceResolutionRejection({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord record,
  required NarrativeEventProjectResolutionStatus resolutionStatus,
  required Object? option,
  required NarrativeEventAuthoringMutation mutation,
}) {
  final code = switch (resolutionStatus) {
    NarrativeEventProjectResolutionStatus.missing => 'sourceMissing',
    NarrativeEventProjectResolutionStatus.unavailable => 'sourceUnavailable',
    NarrativeEventProjectResolutionStatus.ambiguous => 'sourceAmbiguous',
    NarrativeEventProjectResolutionStatus.found =>
      throw StateError('A found source cannot be rejected.'),
  };
  final message = switch (resolutionStatus) {
    NarrativeEventProjectResolutionStatus.missing =>
      'La source choisie n’existe plus.',
    NarrativeEventProjectResolutionStatus.unavailable =>
      _unavailableReason(option),
    NarrativeEventProjectResolutionStatus.ambiguous =>
      'La source choisie n’est pas unique.',
    NarrativeEventProjectResolutionStatus.found =>
      throw StateError('A found source cannot be rejected.'),
  };
  return _sourceRejection(
    context: context,
    expectedRevision: expectedRevision,
    record: record,
    mutation: mutation,
    code: code,
    message: message,
  );
}

String _unavailableReason(Object? option) {
  return switch (option) {
    NarrativeSpatialEventSourceOption value =>
      value.unavailableReason ?? 'La source choisie n’est pas disponible.',
    NarrativeOutcomeEventSourceOption value =>
      value.unavailableReason ?? 'La source choisie n’est pas disponible.',
    _ => 'La source choisie n’est pas disponible.',
  };
}

NarrativeEventAuthoringResult _sourceRejection({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord? record,
  required NarrativeEventAuthoringMutation mutation,
  required String code,
  required String message,
}) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: mutation,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: code,
    message: message,
  );
}

NarrativeEventSourceImpactPreview _sourceImpact({
  required NarrativeEventProjectCatalog catalog,
  required NarrativeEventSourceRef? currentSource,
  required NarrativeEventSourceRef? nextSource,
  required bool structuralUnpublish,
}) {
  final current = currentSource == null
      ? null
      : _sourcePresentation(catalog, currentSource);
  final next =
      nextSource == null ? null : _sourcePresentation(catalog, nextSource);
  return NarrativeEventSourceImpactPreview(
    currentSourceSentence: current?.sentence,
    nextSourceSentence: next?.sentence,
    currentMapId: current?.mapId,
    nextMapId: next?.mapId,
    currentOrigin: current?.origin,
    nextOrigin: next?.origin,
    currentNavigation: current?.navigation,
    nextNavigation: next?.navigation,
    diagnosticsLikelyToChange: const [
      'La disponibilité de la source peut changer.',
      'La navigation vers la source peut changer.',
      'L’activation devra être vérifiée à nouveau.',
    ],
    physicalSourceDeleted: false,
    structuralUnpublish: structuralUnpublish,
  );
}

({
  String sentence,
  String? mapId,
  NarrativeEventSourceAuthoringOrigin origin,
  NarrativeEditorDestination? navigation,
}) _sourcePresentation(
  NarrativeEventProjectCatalog catalog,
  NarrativeEventSourceRef source,
) {
  return source.when(
    entityInteract: (mapId, entityId) {
      final option = _spatialOption(catalog, source);
      return (
        sentence: option?.humanDescription ??
            'Interaction avec l’entité $entityId sur $mapId',
        mapId: mapId,
        origin: _spatialOrigin(option),
        navigation: option?.selectable == true
            ? NarrativeEditorDestination.focusEntity(mapId, entityId)
            : null,
      );
    },
    triggerEnter: (mapId, triggerId) {
      final option = _spatialOption(catalog, source);
      return (
        sentence: option?.humanDescription ??
            'Entrée dans la zone $triggerId sur $mapId',
        mapId: mapId,
        origin: _spatialOrigin(option),
        navigation: option?.selectable == true
            ? NarrativeEditorDestination.focusTrigger(mapId, triggerId)
            : null,
      );
    },
    mapEnter: (mapId) {
      final option = _spatialOption(catalog, source);
      return (
        sentence: option?.humanDescription ?? 'Entrée sur la map $mapId',
        mapId: mapId,
        origin: _spatialOrigin(option),
        navigation: option?.selectable == true
            ? NarrativeEditorDestination.openMap(mapId)
            : null,
      );
    },
    outcomeReceived: (outcome) {
      final option = _outcomeOption(catalog, outcome);
      return (
        sentence: option?.humanSourceSentence ??
            'Réception du résultat ${outcome.outcomeId} de ${outcome.producerId}',
        mapId: null,
        origin: _outcomeOrigin(option),
        navigation: option?.selectable == true
            ? NarrativeEditorDestination.openOutcomeProducer(outcome)
            : null,
      );
    },
  );
}

NarrativeEventSourceAuthoringOrigin _spatialOrigin(
  NarrativeSpatialEventSourceOption? option,
) {
  if (option?.selectable != true) {
    return NarrativeEventSourceAuthoringOrigin.unresolvedReference;
  }
  return switch (option?.origin) {
    NarrativeSpatialEventSourceOrigin.canonical =>
      NarrativeEventSourceAuthoringOrigin.canonicalSpatial,
    NarrativeSpatialEventSourceOrigin.legacyCompatibility =>
      NarrativeEventSourceAuthoringOrigin.legacyCompatibilitySpatial,
    null => NarrativeEventSourceAuthoringOrigin.unresolvedReference,
  };
}

NarrativeEventSourceAuthoringOrigin _outcomeOrigin(
  NarrativeOutcomeEventSourceOption? option,
) {
  if (option?.selectable != true) {
    return NarrativeEventSourceAuthoringOrigin.unresolvedReference;
  }
  return switch (option?.origin) {
    NarrativeOutcomeSourceOrigin.scene =>
      NarrativeEventSourceAuthoringOrigin.sceneOutcome,
    NarrativeOutcomeSourceOrigin.battle =>
      NarrativeEventSourceAuthoringOrigin.battleOutcome,
    NarrativeOutcomeSourceOrigin.legacyScenario =>
      NarrativeEventSourceAuthoringOrigin.legacyScenarioOutcome,
    NarrativeOutcomeSourceOrigin.referencedMissing ||
    null =>
      NarrativeEventSourceAuthoringOrigin.unresolvedReference,
  };
}

NarrativeEventAuthoringResult? _claimPinRejection({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord record,
  required NarrativeEventSourceRef? nextSource,
  required NarrativeEventAuthoringMutation mutation,
}) {
  final registry = context.registryOrNull;
  if (registry == null || registry.mode != EventSystemMode.dualRead) {
    return null;
  }
  final claims = registry.legacyClaims
      .where((claim) => claim.targetEventIds.contains(record.id))
      .toList(growable: false);
  if (claims.isEmpty) return null;
  if (nextSource != null &&
      claims.every((claim) => claim.source == nextSource)) {
    return null;
  }
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: mutation,
    registry: registry,
    record: record,
    expectedRevision: expectedRevision,
    code: 'sourceClaimPinned',
    message:
        'Cette source est protégée par la compatibilité avec les événements existants.',
  );
}

NarrativeSpatialEventSourceOption? _spatialOption(
  NarrativeEventProjectCatalog catalog,
  NarrativeEventSourceRef source,
) {
  final matches = catalog.spatialSources.optionsForSource(source);
  return matches.length == 1 ? matches.single : null;
}

NarrativeOutcomeEventSourceOption? _outcomeOption(
  NarrativeEventProjectCatalog catalog,
  NarrativeOutcomeRef outcome,
) {
  final matches = catalog.outcomeSources.optionsForOutcome(outcome);
  return matches.length == 1 ? matches.single : null;
}
