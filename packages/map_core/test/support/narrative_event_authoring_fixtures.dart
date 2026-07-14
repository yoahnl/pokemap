import 'package:map_core/map_core.dart';

const authoringRevision = 'sha256:current';
const authoringManifestHash = 'manifest-current';
const authoringMapHashes = {'map_a': 'map-a-current'};
const eventIdA = 'evt_019abcde-0000-7000-8000-000000000001';
const eventIdB = 'evt_019abcde-0000-7000-8000-000000000002';
const eventIdC = 'evt_019abcde-0000-7000-8000-000000000003';
const eventIdD = 'evt_019abcde-0000-7000-8000-000000000004';

final entitySource = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
final triggerSource = NarrativeEventSourceRef.triggerEnter('map_a', 'zone_a');
final mapSource = NarrativeEventSourceRef.mapEnter('map_a');
final outcomeRef = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: 'scene_a',
  outcomeId: 'win',
);
final outcomeSource = NarrativeEventSourceRef.outcomeReceived(outcomeRef);

NarrativeEventProjectCatalog authoringCatalog({
  List<NarrativeSpatialEventSourceOption>? spatialOptions,
  List<NarrativeOutcomeEventSourceOption>? outcomeOptions,
  List<NarrativeEventProjectSceneEntry> scenes = const [],
  List<NarrativeEventProjectFactEntry> facts = const [],
  List<NarrativeEventProjectEventEntry> events = const [],
  List<NarrativeEventProjectDiagnostic> diagnostics = const [],
  String manifestHash = authoringManifestHash,
  Map<String, String> mapHashes = authoringMapHashes,
}) {
  return NarrativeEventProjectCatalog(
    manifestHash: manifestHash,
    mapHashes: mapHashes,
    spatialSources: NarrativeSpatialEventSourceCatalog(
      options: spatialOptions ??
          [
            spatialOption(entitySource),
            spatialOption(triggerSource),
            spatialOption(mapSource),
          ],
      diagnostics: const [],
    ),
    outcomeSources: NarrativeOutcomeEventSourceCatalog(
      options: outcomeOptions ?? [outcomeOption(outcomeRef)],
      diagnostics: const [],
    ),
    scenes: scenes,
    facts: facts,
    events: events,
    diagnostics: diagnostics,
  );
}

NarrativeEventAuthoringContext authoringContext({
  NarrativeEventRegistry? registry,
  EventRegistryDecodeResult? registryState,
  NarrativeEventProjectCatalog? catalog,
  String revision = authoringRevision,
  String manifestHash = authoringManifestHash,
  Map<String, String> mapHashes = authoringMapHashes,
  NarrativeEventSourceIndexBuildResult? sourceIndex,
}) {
  final effectiveRegistry = registry ?? registryState?.registryOrNull;
  final effectiveCatalog = catalog ??
      authoringCatalog(
        events: [
          for (final record
              in effectiveRegistry?.records ?? const <NarrativeEventRecord>[])
            NarrativeEventProjectEventEntry(
              record: record,
              proposed: false,
              inDependencyCycle: false,
              contextuallyValid: record.definitionOrNull != null,
            ),
        ],
      );
  return NarrativeEventAuthoringContext(
    registryState: registryState ??
        (registry == null
            ? EventRegistryDecodeResult.absent()
            : EventRegistryDecodeResult.decoded(registry)),
    revision: revision,
    catalog: effectiveCatalog,
    sourceIndex: sourceIndex ??
        buildNarrativeEventSourceIndex(
          effectiveRegistry?.records ?? const <NarrativeEventRecord>[],
        ),
    manifestHash: manifestHash,
    mapHashes: mapHashes,
  );
}

NarrativeEventProjectCatalog authoringCatalogForRegistry(
  NarrativeEventRegistry registry, {
  List<NarrativeEventProjectSceneEntry> scenes = const [],
  List<NarrativeEventProjectFactEntry> facts = const [],
  List<NarrativeEventProjectDiagnostic> diagnostics = const [],
  Set<String> invalidEventIds = const {},
  Set<String> cycleEventIds = const {},
  List<NarrativeEventProjectEventEntry> extraEvents = const [],
}) {
  return authoringCatalog(
    scenes: scenes,
    facts: facts,
    diagnostics: diagnostics,
    events: [
      for (final record in registry.records)
        NarrativeEventProjectEventEntry(
          record: record,
          proposed: false,
          inDependencyCycle: cycleEventIds.contains(record.id),
          contextuallyValid: record.definitionOrNull != null &&
              !invalidEventIds.contains(record.id),
        ),
      ...extraEvents,
    ],
  );
}

NarrativeEventAuthoringContext configuredAuthoringContext({
  required NarrativeEventRegistry registry,
  List<NarrativeEventProjectSceneEntry>? scenes,
  List<NarrativeEventProjectFactEntry>? facts,
  List<NarrativeEventProjectDiagnostic> diagnostics = const [],
  Set<String> invalidEventIds = const {},
  Set<String> cycleEventIds = const {},
  List<NarrativeEventProjectEventEntry> extraEvents = const [],
  String revision = authoringRevision,
  NarrativeEventSourceIndexBuildResult? sourceIndex,
}) {
  return authoringContext(
    registry: registry,
    revision: revision,
    sourceIndex: sourceIndex,
    catalog: authoringCatalogForRegistry(
      registry,
      scenes: scenes ?? [sceneEntry()],
      facts: facts ?? [factEntry()],
      diagnostics: diagnostics,
      invalidEventIds: invalidEventIds,
      cycleEventIds: cycleEventIds,
      extraEvents: extraEvents,
    ),
  );
}

NarrativeEventProjectSceneEntry sceneEntry({
  String id = 'scene_a',
  bool buildable = true,
}) {
  return NarrativeEventProjectSceneEntry(
    scene: SceneAsset.fromJson({
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
    }),
    buildable: buildable,
  );
}

NarrativeEventProjectFactEntry factEntry({String id = 'fact_a'}) {
  return NarrativeEventProjectFactEntry(
    NarrativeFactDefinition(id: id, label: 'Fact $id'),
  );
}

NarrativeSpatialEventSourceOption spatialOption(
  NarrativeEventSourceRef source, {
  NarrativeSpatialEventSourceAvailability availability =
      NarrativeSpatialEventSourceAvailability.selectable,
}) {
  final identity = source.when(
    entityInteract: (mapId, entityId) => (
      mapId,
      NarrativeSpatialEventSourceOwnerKind.entity,
      entityId,
      'Interaction avec $entityId',
    ),
    triggerEnter: (mapId, triggerId) => (
      mapId,
      NarrativeSpatialEventSourceOwnerKind.trigger,
      triggerId,
      'Entrée dans $triggerId',
    ),
    mapEnter: (mapId) => (
      mapId,
      NarrativeSpatialEventSourceOwnerKind.map,
      null,
      'Entrée sur $mapId',
    ),
    outcomeReceived: (_) => throw ArgumentError('Expected a spatial source.'),
  );
  return NarrativeSpatialEventSourceOption(
    source: source,
    humanLabel: identity.$4,
    humanDescription: identity.$4,
    mapId: identity.$1,
    mapLabel: identity.$1,
    sourceTypeLabel: source.kind.name,
    availability: availability,
    unavailableReason:
        availability == NarrativeSpatialEventSourceAvailability.selectable
            ? null
            : 'Source indisponible',
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: source.toJson().toString(),
    geometry: source.kind == NarrativeEventSourceKind.mapEnter
        ? const NarrativeSpatialSourceGeometrySummary.mapWide()
        : const NarrativeSpatialSourceGeometrySummary.unavailable(),
    ownerKind: identity.$2,
    ownerId: identity.$3,
  );
}

NarrativeOutcomeEventSourceOption outcomeOption(
  NarrativeOutcomeRef outcome, {
  bool selectable = true,
}) {
  return NarrativeOutcomeEventSourceOption(
    outcome: outcome,
    producerLabel: outcome.producerId,
    outcomeLabel: outcome.outcomeId,
    humanSourceSentence:
        'Quand ${outcome.producerId} produit ${outcome.outcomeId}',
    status: selectable
        ? NarrativeOutcomeReachabilityStatus.reachable
        : NarrativeOutcomeReachabilityStatus.outcomeMissing,
    selectable: selectable,
    unavailableReason: selectable ? null : 'Résultat indisponible',
    origin: NarrativeOutcomeSourceOrigin.scene,
    debugTechnicalLabel: outcome.toJson().toString(),
  );
}

NarrativeEventRegistry registryWithRecords(
  List<NarrativeEventRecord> records, {
  EventSystemMode mode = EventSystemMode.legacyOnly,
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord draftRecord({
  String id = eventIdA,
  String name = 'Draft',
  NarrativeEventSourceRef? source,
  List<NarrativeEventCondition> conditions = const [],
  String? sceneId,
  NarrativeEventReusePolicy? reusePolicy,
  int priority = 0,
  int order = 0,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: priority,
      order: order,
    ),
  );
}

NarrativeEventRecord configuredRecord({
  String id = eventIdA,
  String name = 'Configured',
  NarrativeEventSourceRef? source,
  List<NarrativeEventCondition> conditions = const [],
  String sceneId = 'scene_a',
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
  int priority = 0,
  int order = 0,
  bool enabled = false,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source ?? entitySource,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: priority,
      order: order,
    ),
    enabled: enabled,
  );
}

NarrativeEventIdGenerator deterministicGenerator([String id = eventIdA]) {
  return NarrativeEventIdGenerator(rawUuidFactory: () => id.substring(4));
}

LegacySourceClaim authoringClaim({
  NarrativeEventSourceRef? source,
  List<String> targetEventIds = const [eventIdA],
}) {
  final effectiveSource = source ?? entitySource;
  final member = LegacySourceClaimMember(
    provenance: LegacySourceRef.mapEvent('map_a', 'legacy_event_a'),
    sourceFingerprint:
        'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );
  final cohortId = 'lsc_${narrativeEventCanonicalSha256({
        'source': effectiveSource.toJson(),
        'provenances': [member.provenance.toJson()],
      })}';
  final cohortFingerprint = 'sha256:${narrativeEventCanonicalSha256({
        'cohortId': cohortId,
        'members': [member.toJson()],
      })}';
  return LegacySourceClaim(
    cohortId: cohortId,
    source: effectiveSource,
    members: [member],
    cohortFingerprint: cohortFingerprint,
    targetEventIds: targetEventIds,
    migrationReceiptId: 'receipt_a',
  );
}
