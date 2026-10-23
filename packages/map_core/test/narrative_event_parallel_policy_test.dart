import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('incomplete drafts validate each supplied parallel field independently', () {
    NarrativeEventDraft draft({NarrativeEventSourceRef? source, NarrativeEventReusePolicy? reusePolicy}) => NarrativeEventDraft(
      id: 'evt_00000000-0000-7000-8000-000000000001', name: 'Partial parallel', source: source,
      conditions: const [], reusePolicy: reusePolicy, priority: 0, order: 0,
      parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 100));
    expect(() => draft(source: NarrativeEventSourceRef.entityInteract('map', 'entity')), throwsArgumentError);
    expect(() => draft(reusePolicy: NarrativeEventReusePolicy.oneShot), throwsArgumentError);
    expect(draft().parallelPolicy, isNotNull);
    expect(draft(source: NarrativeEventSourceRef.entityAutorun('map', 'entity')).parallelPolicy, isNotNull);
  });
  test('parallel map entry rejects a spatial project before publication', () {
    final map = MapData(id: 'map', name: 'Map', version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4), spatialScene: MapSpatialScene(width: 4, depth: 4));
    final scene = SceneAsset(id: 'scene', name: 'Scene', graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start), SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [SceneEdge(id: 'edge', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.defaultFlow)]));
    final record = NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
      id: 'evt_00000000-0000-7000-8000-000000000001', name: 'Spatial parallel',
      source: NarrativeEventSourceRef.mapEnter('map'), conditions: const [], sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.reusable, priority: 0, order: 0,
      parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 100)), enabled: false);
    final registry = NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, records: [record], legacyClaims: const []);
    final project = ProjectManifest(name: 'Spatial', version: ProjectVersion.v9,
      maps: const [ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'map.json')], tilesets: const [],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD), scenes: [scene], eventRegistry: registry);
    final report = buildNarrativeEventValidationReport(registry: registry, catalog: buildNarrativeEventProjectCatalog(project: project, maps: [map]));
    expect(report.hasBlockingDiagnostics, isTrue);
    expect(report.diagnostics.any((diagnostic) => diagnostic.code == 'narrativeEventParallelInvalid'), isTrue);
  });
  test(
    'parallel policy survives definition and draft publication wire roundtrip',
    () {
      final definition = NarrativeEventDefinition(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Background counter',
        source: NarrativeEventSourceRef.entityAutorun('map', 'npc'),
        conditions: const [],
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
        parallelPolicy: NarrativeEventParallelPolicy(
          cadenceMs: 100,
          ownerVariantId: 'page_0',
        ),
      );
      expect(
        NarrativeEventDefinition.fromJson(definition.toJson()),
        definition,
      );
      expect(
        () => NarrativeEventDefinition.fromJson({
          ...definition.toJson(),
          'reusePolicy': 'oneShot',
        }),
        throwsFormatException,
      );
      final draft = NarrativeEventDraft.fromJson(definition.toJson());
      expect(draft.parallelPolicy, definition.parallelPolicy);
      expect(NarrativeEventDraft.fromJson(draft.toJson()), draft);
    },
  );

  test('parallel policy rejects invalid cadence and one-shot execution', () {
    for (final cadence in [0, 99, 60001]) {
      expect(
        () => NarrativeEventParallelPolicy(cadenceMs: cadence),
        throwsArgumentError,
      );
    }
    expect(
      () => NarrativeEventDefinition(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Invalid one shot',
        source: NarrativeEventSourceRef.mapEnter('map'),
        conditions: const [],
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
        parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 100),
      ),
      throwsArgumentError,
    );
  });

  test(
    'parallel policy wire requires canonical integer cadence and known fields',
    () {
      for (final json in <Map<String, Object?>>[
        {'cadenceMs': 100.0},
        {'cadenceMs': 100, 'unknown': true},
        {'cadenceMs': 100, 'ownerVariantId': ' page'},
        {'cadenceMs': 100, 'ownerVariantId': null},
      ]) {
        expect(
          () => NarrativeEventParallelPolicy.fromJson(json),
          throwsFormatException,
        );
      }
    },
  );
}
