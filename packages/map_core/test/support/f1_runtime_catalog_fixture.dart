import 'package:map_core/map_core.dart';

NarrativeEventProjectCatalog f1ProjectCatalogForRegistry(
  NarrativeEventRegistry registry, {
  Set<String> unavailableSceneIds = const {},
  List<NarrativeEventProjectDiagnostic> diagnostics = const [],
}) {
  final sources = <NarrativeEventSourceRef>{};
  final sceneIds = <String>{};
  final factIds = <String>{};
  for (final record in registry.records) {
    final definition = record.definitionOrNull;
    final draft = record.draftOrNull;
    final source = definition?.source ?? draft?.source;
    if (source != null) sources.add(source);
    if (definition != null) {
      sceneIds.add(definition.sceneId);
      for (final condition in definition.conditions) {
        condition.when(
          fact: (factId, _) => factIds.add(factId),
          narrativeEventConsumed: (_, __) {},
        );
      }
    }
  }
  return NarrativeEventProjectCatalog(
    manifestHash: 'f1-runtime-catalog',
    mapHashes: const {},
    spatialSources: NarrativeSpatialEventSourceCatalog(
      options: [
        for (final source in sources)
          if (source.kind != NarrativeEventSourceKind.outcomeReceived)
            _spatialOption(source),
      ],
      diagnostics: const [],
    ),
    outcomeSources: NarrativeOutcomeEventSourceCatalog(
      options: [
        for (final source in sources)
          if (_outcomeOrNull(source) case final outcome?)
            _outcomeOption(outcome),
      ],
      diagnostics: const [],
    ),
    scenes: [
      for (final sceneId in sceneIds)
        NarrativeEventProjectSceneEntry(
          scene: _scene(sceneId),
          buildable: !unavailableSceneIds.contains(sceneId),
        ),
    ],
    facts: [
      for (final factId in factIds)
        NarrativeEventProjectFactEntry(
          NarrativeFactDefinition(id: factId, label: 'Fact $factId'),
        ),
    ],
    events: [
      for (final record in registry.records)
        NarrativeEventProjectEventEntry(
          record: record,
          proposed: false,
          inDependencyCycle: false,
          contextuallyValid: record.definitionOrNull != null,
        ),
    ],
    diagnostics: diagnostics,
  );
}

NarrativeOutcomeRef? _outcomeOrNull(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (_, __) => null,
    triggerEnter: (_, __) => null,
    mapEnter: (_) => null,
    outcomeReceived: (outcome) => outcome,
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': 'Scene $id',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge_end',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

NarrativeSpatialEventSourceOption _spatialOption(
  NarrativeEventSourceRef source,
) {
  final identity = source.when(
    entityInteract: (mapId, entityId) => (
      mapId,
      NarrativeSpatialEventSourceOwnerKind.entity,
      entityId,
    ),
    triggerEnter: (mapId, triggerId) => (
      mapId,
      NarrativeSpatialEventSourceOwnerKind.trigger,
      triggerId,
    ),
    mapEnter: (mapId) => (
      mapId,
      NarrativeSpatialEventSourceOwnerKind.map,
      null,
    ),
    outcomeReceived: (_) => throw ArgumentError('Expected a spatial source.'),
  );
  return NarrativeSpatialEventSourceOption(
    source: source,
    humanLabel: source.kind.name,
    humanDescription: source.kind.name,
    mapId: identity.$1,
    mapLabel: identity.$1,
    sourceTypeLabel: source.kind.name,
    availability: NarrativeSpatialEventSourceAvailability.selectable,
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: source.toJson().toString(),
    geometry: source.kind == NarrativeEventSourceKind.mapEnter
        ? const NarrativeSpatialSourceGeometrySummary.mapWide()
        : const NarrativeSpatialSourceGeometrySummary.unavailable(),
    ownerKind: identity.$2,
    ownerId: identity.$3,
  );
}

NarrativeOutcomeEventSourceOption _outcomeOption(
  NarrativeOutcomeRef outcome,
) {
  return NarrativeOutcomeEventSourceOption(
    outcome: outcome,
    producerLabel: outcome.producerId,
    outcomeLabel: outcome.outcomeId,
    humanSourceSentence: outcome.toJson().toString(),
    status: NarrativeOutcomeReachabilityStatus.reachable,
    selectable: true,
    origin: NarrativeOutcomeSourceOrigin.scene,
    debugTechnicalLabel: outcome.toJson().toString(),
  );
}
