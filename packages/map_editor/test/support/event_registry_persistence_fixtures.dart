import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:path/path.dart' as p;

const persistenceEventA = 'evt_019abcde-0000-7000-8000-000000000101';
const persistenceEventB = 'evt_019abcde-0000-7000-8000-000000000102';

final persistenceSource = NarrativeEventSourceRef.mapEnter('map_a');

final class EventRegistryPersistenceFixture {
  EventRegistryPersistenceFixture({
    required this.root,
    required this.projectPath,
    required this.initialRoot,
    required this.initialBytes,
    required this.initialSentinelBytes,
    required this.session,
  });

  final Directory root;
  final String projectPath;
  final Map<String, Object?> initialRoot;
  final List<int> initialBytes;
  final Map<String, List<int>> initialSentinelBytes;
  final NarrativeEventAuthoringSession session;

  String get revision => narrativeEventRegistryProjectRevision(initialBytes);

  Future<List<int>> readBytes() => File(projectPath).readAsBytes();

  Future<Map<String, Object?>> readRoot() async {
    final decoded = decodeNarrativeEventJsonStrict(
      await File(projectPath).readAsString(),
    );
    return jsonObject(decoded);
  }

  Future<Map<String, List<int>>> readSentinelBytes() async {
    return {
      for (final path in initialSentinelBytes.keys)
        path: await File(path).readAsBytes(),
    };
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<EventRegistryPersistenceFixture> createPersistenceFixture({
  NarrativeEventRegistry? registry,
  MapData? map,
  SceneAsset? scene,
  bool mapViaSymbolicLink = false,
  Map<String, Object?> extraRoot = const {
    'futureRoot': {
      'flag': true,
      'nested': [1, 2, 3],
    },
  },
}) async {
  final root = await Directory.systemTemp.createTemp('pokemap_event_v2_e4_');
  final projectPath = p.join(root.path, 'project.json');
  final effectiveMap = map ??
      const MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
  final manifest = ProjectManifest(
    name: 'Phase E fixture',
    maps: [
      ProjectMapEntry(
        id: effectiveMap.id,
        name: effectiveMap.name,
        relativePath:
            mapViaSymbolicLink ? 'maps/map_alias.json' : 'maps/map_a.json',
      ),
    ],
    tilesets: const [],
    scenes: [scene ?? persistenceScene()],
    facts: [NarrativeFactDefinition(id: 'fact_a', label: 'Fact A')],
    eventRegistry: registry,
  );
  final initialRoot = <String, Object?>{
    ...jsonObject(jsonDecode(jsonEncode(manifest.toJson()))),
    ...extraRoot,
  };
  if (registry == null) initialRoot.remove('eventRegistry');
  final initialBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(
    initialRoot,
  ));
  await File(projectPath).writeAsBytes(initialBytes, flush: true);
  final initialSentinelBytes = <String, List<int>>{
    p.join(root.path, 'maps', 'map_a.json'): utf8.encode(
      const JsonEncoder.withIndent('  ').convert(
        effectiveMap.toJson(),
      ),
    ),
    p.join(root.path, 'scenarios', 'scenario_a.json'):
        utf8.encode('{"scenario":"A"}'),
    p.join(root.path, 'assets', 'sprite.bin'): const [0, 1, 2, 255],
    p.join(root.path, 'runtime', 'save.bin'): const [9, 8, 7, 6],
  };
  for (final entry in initialSentinelBytes.entries) {
    final file = File(entry.key);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value, flush: true);
  }
  if (mapViaSymbolicLink) {
    await Link(p.join(root.path, 'maps', 'map_alias.json')).create(
      'map_a.json',
    );
  }
  final session = await NarrativeEventAuthoringSession.prepare(projectPath);
  return EventRegistryPersistenceFixture(
    root: root,
    projectPath: session.projectPath,
    initialRoot: initialRoot,
    initialBytes: initialBytes,
    initialSentinelBytes: initialSentinelBytes,
    session: session,
  );
}

SceneAsset persistenceScene() => SceneAsset.fromJson(const {
      'id': 'scene_a',
      'name': 'Scene A',
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

NarrativeEventRecord persistenceDraft({
  String id = persistenceEventA,
  String name = 'Draft',
  NarrativeEventSourceRef? source,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      priority: 0,
      order: 0,
    ),
  );
}

NarrativeEventRecord persistenceConfigured({
  String id = persistenceEventA,
  String name = 'Configured',
  bool enabled = false,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: persistenceSource,
      conditions: const [],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

NarrativeEventRegistry persistenceRegistry({
  List<NarrativeEventRecord>? records,
  EventSystemMode mode = EventSystemMode.legacyOnly,
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records ?? [persistenceDraft()],
    legacyClaims: claims,
  );
}

LegacySourceClaim persistenceClaim() {
  final member = LegacySourceClaimMember(
    provenance: LegacySourceRef.mapEvent('map_a', 'legacy_a'),
    sourceFingerprint:
        'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );
  final cohortId = 'lsc_${narrativeEventCanonicalSha256({
        'source': persistenceSource.toJson(),
        'provenances': [member.provenance.toJson()],
      })}';
  final cohortFingerprint = 'sha256:${narrativeEventCanonicalSha256({
        'cohortId': cohortId,
        'members': [member.toJson()],
      })}';
  return LegacySourceClaim(
    cohortId: cohortId,
    source: persistenceSource,
    members: [member],
    cohortFingerprint: cohortFingerprint,
    targetEventIds: const [persistenceEventA],
    migrationReceiptId: 'receipt_a',
  );
}

NarrativeEventRegistryWriteRequest persistenceRequest({
  required EventRegistryPersistenceFixture fixture,
  required String operationId,
  required NarrativeEventRegistry? previousRegistry,
  required NarrativeEventRegistry nextRegistry,
  NarrativeEventAuthoringSession? session,
  String mutation = 'createDraft',
}) {
  final effectiveSession = session ?? fixture.session;
  final revision = effectiveSession.projectRevision;
  final context = effectiveSession.context;
  final result = persistenceAuthoringResult(
    previousRegistry: previousRegistry,
    nextRegistry: nextRegistry,
    expectedRevision: revision,
    mutation: NarrativeEventAuthoringMutation.values.byName(mutation),
    context: context,
  );
  return NarrativeEventRegistryWriteRequest.fromAuthoringSession(
    session: effectiveSession,
    operationId: operationId,
    result: result,
  );
}

NarrativeEventAuthoringResult persistenceAuthoringResult({
  required NarrativeEventRegistry? previousRegistry,
  required NarrativeEventRegistry nextRegistry,
  String expectedRevision = 'authoring-revision',
  NarrativeEventAuthoringMutation mutation =
      NarrativeEventAuthoringMutation.createDraft,
  NarrativeEventAuthoringContext? context,
}) {
  final effectiveContext = context ??
      persistenceAuthoringContext(
        registry: previousRegistry,
        revision: expectedRevision,
      );
  final target = _changedRecord(previousRegistry, nextRegistry);
  return switch (mutation) {
    NarrativeEventAuthoringMutation.createDraft => createNarrativeEventDraft(
        context: effectiveContext,
        expectedRevision: expectedRevision,
        name: target.draftOrNull!.name,
        initialSource: target.draftOrNull!.source,
        idGenerator: NarrativeEventIdGenerator(
          rawUuidFactory: () => target.id.substring(4),
        ),
      ),
    NarrativeEventAuthoringMutation.rename => renameNarrativeEvent(
        context: effectiveContext,
        expectedRevision: expectedRevision,
        eventId: target.id,
        name: target.draftOrNull?.name ?? target.definitionOrNull!.name,
      ),
    _ => throw ArgumentError.value(mutation, 'mutation'),
  };
}

NarrativeEventAuthoringContext persistenceAuthoringContext({
  required NarrativeEventRegistry? registry,
  required String revision,
}) {
  const manifestHash = 'manifest-phase-e-fixture';
  const mapHashes = {'map_a': 'map-a-phase-e-fixture'};
  final catalog = NarrativeEventProjectCatalog(
    manifestHash: manifestHash,
    mapHashes: mapHashes,
    spatialSources: NarrativeSpatialEventSourceCatalog(
      options: [
        NarrativeSpatialEventSourceOption(
          source: persistenceSource,
          humanLabel: 'Entrée sur Map A',
          humanDescription: 'Entrée sur Map A',
          mapId: 'map_a',
          mapLabel: 'Map A',
          sourceTypeLabel: 'Entrée sur une map',
          availability: NarrativeSpatialEventSourceAvailability.selectable,
          origin: NarrativeSpatialEventSourceOrigin.canonical,
          debugTechnicalLabel: 'mapEnter:map_a',
          geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
          ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
        ),
      ],
      diagnostics: const [],
    ),
    outcomeSources: NarrativeOutcomeEventSourceCatalog(
      options: const [],
      diagnostics: const [],
    ),
    scenes: [
      NarrativeEventProjectSceneEntry(
        scene: persistenceScene(),
        buildable: true,
      ),
    ],
    facts: const [],
    events: [
      for (final record in registry?.records ?? const <NarrativeEventRecord>[])
        NarrativeEventProjectEventEntry(
          record: record,
          proposed: false,
          inDependencyCycle: false,
          contextuallyValid: record.definitionOrNull != null,
        ),
    ],
    diagnostics: const [],
  );
  return NarrativeEventAuthoringContext(
    registryState: registry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry),
    revision: revision,
    catalog: catalog,
    sourceIndex: buildNarrativeEventSourceIndex(
      registry?.records ?? const <NarrativeEventRecord>[],
    ),
    manifestHash: manifestHash,
    mapHashes: mapHashes,
  );
}

NarrativeEventRecord _changedRecord(
  NarrativeEventRegistry? previous,
  NarrativeEventRegistry next,
) {
  final previousById = {
    for (final record in previous?.records ?? const <NarrativeEventRecord>[])
      record.id: record,
  };
  return next.records.singleWhere((record) {
    final before = previousById[record.id];
    return canonicalizeNarrativeEventJson(before?.toJson()) !=
        canonicalizeNarrativeEventJson(record.toJson());
  });
}

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map) throw StateError('Expected JSON object.');
  return <String, Object?>{
    for (final entry in value.entries) entry.key as String: entry.value,
  };
}

Map<String, Object?> withoutRegistry(Map<String, Object?> value) {
  return Map<String, Object?>.from(value)..remove('eventRegistry');
}
