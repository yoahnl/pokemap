import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene authoring operations', () {
    test('creates a minimal scene draft in ProjectManifest.scenes', () {
      final project = _project();

      final result = createSceneDraftInProject(
        project,
        name: ' Rencontre rival ',
        description: ' Premier brouillon ',
      );

      expect(project.scenes, isEmpty);
      expect(result.updatedProject.scenes, hasLength(1));
      expect(result.createdScene.id, 'scene_rencontre_rival');
      expect(result.createdScene.name, 'Rencontre rival');
      expect(result.createdScene.description, 'Premier brouillon');
      expect(result.createdScene.tags, isEmpty);
      expect(result.createdScene.declaredOutcomes, isEmpty);
      expect(result.createdScene.graph.startNodeId, 'node_start');
      expect(result.createdScene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
      ]);
      expect(result.createdScene.graph.edges.single.id, 'edge_start_end');
      expect(result.createdScene.graph.edges.single.fromPortId, 'completed');
      expect(
        result.createdScene.graph.edges.single.kind,
        SceneEdgeKind.defaultFlow,
      );
      expect(
          result.createdScene.layout.nodeLayouts.map((node) => node.nodeId), [
        'node_start',
        'node_end',
      ]);
    });

    test('generates suffixed ids on collision', () {
      final project = _project(
        scenes: [
          _scene('scene_rencontre_rival'),
          _scene('scene_rencontre_rival_2'),
        ],
      );

      final result = createSceneDraftInProject(
        project,
        name: 'Rencontre rival',
      );

      expect(result.createdScene.id, 'scene_rencontre_rival_3');
      expect(result.updatedProject.scenes, hasLength(3));
    });

    test('rejects an empty scene name', () {
      expect(
        () => createSceneDraftInProject(_project(), name: '   '),
        throwsArgumentError,
      );
    });

    test('does not touch scenarios or storylines', () {
      final scenario = ScenarioAsset(
        id: 'scenario_existing',
        name: 'Existing scenario',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'scenario_node_start',
        nodes: [
          ScenarioNode(
            id: 'scenario_node_start',
            type: ScenarioNodeType.start,
            title: 'Start',
          ),
        ],
      );
      final storyline = StorylineAsset(
        id: 'storyline_existing',
        title: 'Existing storyline',
        type: StorylineType.main,
      );
      final project = _project(
        scenarios: [scenario],
        storylines: [storyline],
      );

      final result = createSceneDraftInProject(project, name: 'Scene');

      expect(result.updatedProject.scenarios, project.scenarios);
      expect(result.updatedProject.storylines, project.storylines);
      expect(result.updatedProject.scenes, hasLength(1));
    });
  });
}

ProjectManifest _project({
  List<SceneAsset> scenes = const [],
  List<ScenarioAsset> scenarios = const [],
  List<StorylineAsset> storylines = const [],
}) {
  return ProjectManifest(
    name: 'Scene authoring test',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
    scenarios: scenarios,
    storylines: storylines,
  );
}

SceneAsset _scene(String id) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
