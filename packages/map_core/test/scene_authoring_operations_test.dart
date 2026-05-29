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

    test('adds a condition node draft without mutating the original scene', () {
      final scene = _scene(
        'scene_authoring',
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
      );

      final result = addSceneNodeDraft(
        scene,
        kind: SceneNodeKind.condition,
        afterNodeId: 'node_start',
      );

      expect(scene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
      ]);
      expect(result.createdNode.id, 'node_condition');
      expect(result.createdNode.title, 'Condition');
      expect(result.createdNode.kind, SceneNodeKind.condition);
      expect(result.createdNode.payload, isA<SceneConditionPayload>());
      expect(result.updatedScene.id, scene.id);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
        'node_condition',
      ]);
      final layout = result.updatedScene.layout.nodeLayouts
          .firstWhere((layout) => layout.nodeId == 'node_condition');
      expect(layout.x, 324);
      expect(layout.y, 80);
    });

    test('adds merge and end node drafts with stable suffixed ids', () {
      var scene = _scene('scene_authoring');

      final merge = addSceneNodeDraft(scene, kind: SceneNodeKind.merge);
      scene = merge.updatedScene;
      final secondMerge = addSceneNodeDraft(scene, kind: SceneNodeKind.merge);
      scene = secondMerge.updatedScene;
      final end = addSceneNodeDraft(scene, kind: SceneNodeKind.end);

      expect(merge.createdNode.id, 'node_merge');
      expect(merge.createdNode.payload, isA<SceneMergePayload>());
      expect(secondMerge.createdNode.id, 'node_merge_2');
      expect(end.createdNode.id, 'node_end_2');
      expect(end.createdNode.title, 'Fin');
      expect(end.createdNode.payload, isA<SceneEndPayload>());
      expect(end.updatedScene.graph.edges, scene.graph.edges);
      expect(
        end.updatedScene.layout.nodeLayouts
            .map((layout) => layout.nodeId)
            .contains('node_end_2'),
        isTrue,
      );
    });

    test('rejects unsupported node kinds in V0 without fake refs', () {
      final scene = _scene('scene_authoring');

      for (final kind in [
        SceneNodeKind.start,
        SceneNodeKind.yarnDialogue,
        SceneNodeKind.action,
        SceneNodeKind.battle,
        SceneNodeKind.cinematic,
        SceneNodeKind.branchByOutcome,
      ]) {
        expect(
          () => addSceneNodeDraft(scene, kind: kind),
          throwsA(isA<ArgumentError>()),
          reason: '${kind.name} must not be authorable in V0',
        );
      }
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

SceneAsset _scene(
  String id, {
  Map<String, String> metadata = const {},
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  return SceneAsset(
    id: id,
    name: id,
    tags: const ['test'],
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
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
      ],
    ),
    declaredOutcomes: declaredOutcomes,
    metadata: metadata,
  );
}
