import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene cinematic authoring', () {
    test('adds a cinematic node from a canonical CinematicAsset', () {
      final scene = _scene(
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
      );
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro', title: 'Intro reveal')],
      );

      final result = addSceneCinematicNodeDraft(
        scene,
        project: project,
        cinematicId: 'cinematic_intro',
        afterNodeId: 'node_start',
      );

      expect(result.createdNode.id, 'node_cinematic');
      expect(result.createdNode.kind, SceneNodeKind.cinematic);
      expect(result.createdNode.title, 'Intro reveal');
      expect(
        result.createdNode.payload,
        SceneCinematicPayload(cinematicId: 'cinematic_intro'),
      );
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.layout.edgeLayouts, scene.layout.edgeLayouts);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(
        result.updatedScene.layout.nodeLayouts
            .singleWhere((layout) => layout.nodeId == 'node_cinematic')
            .x,
        324,
      );
      expect(
          scene.graph.nodes.map((node) => node.id), ['node_start', 'node_end']);
    });

    test('refuses empty, unknown, and bridge-only cinematic ids', () {
      final scene = _scene();

      expect(
        () => addSceneCinematicNodeDraft(
          scene,
          project: _project(cinematics: [_cinematic()]),
          cinematicId: ' ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addSceneCinematicNodeDraft(
          scene,
          project: _project(cinematics: [_cinematic()]),
          cinematicId: 'missing_cinematic',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addSceneCinematicNodeDraft(
          scene,
          project: _project(scenarios: [_scenarioBridge()]),
          cinematicId: 'scenario_cutscene',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updates a cinematic payload to another canonical CinematicAsset', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_cinematic',
            kind: SceneNodeKind.cinematic,
            title: 'Existing cinematic',
            description: 'Keep me.',
            payload: SceneCinematicPayload(cinematicId: 'cinematic_intro'),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_node_cinematic_completed_node_end',
            fromNodeId: 'node_cinematic',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        ],
      );
      final project = _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
          _cinematic(id: 'cinematic_second'),
        ],
      );

      final result = updateSceneCinematicPayload(
        scene,
        nodeId: 'node_cinematic',
        cinematicId: 'cinematic_second',
        project: project,
      );

      expect(result.updatedNode.id, 'node_cinematic');
      expect(result.updatedNode.title, 'Existing cinematic');
      expect(result.updatedNode.description, 'Keep me.');
      expect(result.updatedPayload.cinematicId, 'cinematic_second');
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.layout, scene.layout);
      expect(scene.graph.nodes[1].payload,
          SceneCinematicPayload(cinematicId: 'cinematic_intro'));
    });

    test('refuses invalid cinematic payload updates', () {
      final scene = _scene();
      final project = _project(cinematics: [_cinematic()]);

      expect(
        () => updateSceneCinematicPayload(
          scene,
          nodeId: 'missing_node',
          cinematicId: 'cinematic_intro',
          project: project,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => updateSceneCinematicPayload(
          scene,
          nodeId: 'node_start',
          cinematicId: 'cinematic_intro',
          project: project,
        ),
        throwsA(isA<ArgumentError>()),
      );
      final cinematicScene = addSceneCinematicNodeDraft(
        scene,
        project: project,
        cinematicId: 'cinematic_intro',
      ).updatedScene;
      expect(
        () => updateSceneCinematicPayload(
          cinematicScene,
          nodeId: 'node_cinematic',
          cinematicId: 'scenario_cutscene',
          project: _project(
            cinematics: [_cinematic()],
            scenarios: [_scenarioBridge()],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('exposes and connects cinematic completed as a cinematic edge', () {
      final scene = addSceneCinematicNodeDraft(
        _scene(),
        project: _project(cinematics: [_cinematic()]),
        cinematicId: 'cinematic_intro',
      ).updatedScene;

      expect(
        authorableSceneOutputPortsForKind(SceneNodeKind.cinematic)
            .map((port) => (port.id, port.edgeKind)),
        [('completed', SceneEdgeKind.cinematicCompleted)],
      );

      final result = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_cinematic',
        fromPortId: 'completed',
        toNodeId: 'node_end',
      );

      expect(
        result.createdEdge.id,
        'edge_node_cinematic_completed_node_end',
      );
      expect(result.createdEdge.kind, SceneEdgeKind.cinematicCompleted);
      expect(result.createdEdge.label, 'completed');
    });
  });
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const [],
  List<ScenarioAsset> scenarios = const [],
}) {
  return ProjectManifest(
    name: 'Scene cinematic authoring test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
    scenarios: scenarios,
  );
}

CinematicAsset _cinematic({
  String id = 'cinematic_intro',
  String title = 'Intro cinematic',
}) {
  return CinematicAsset(
    id: id,
    title: title,
    timeline: CinematicTimeline(),
  );
}

ScenarioAsset _scenarioBridge() {
  return const ScenarioAsset(
    id: 'scenario_cutscene',
    name: 'Legacy cutscene',
    entryNodeId: 'scenario_start',
    metadata: {'authoring.cutsceneSchema': 'test'},
  );
}

SceneAsset _scene({
  List<SceneNode>? nodes,
  List<SceneEdge>? edges,
  Map<String, String> metadata = const {},
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Scene Test',
    metadata: metadata,
    declaredOutcomes: declaredOutcomes,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: nodes ??
          [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
      edges: edges ?? const [],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
      ],
    ),
  );
}
