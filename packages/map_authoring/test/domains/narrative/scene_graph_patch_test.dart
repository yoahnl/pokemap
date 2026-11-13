import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {
  test('patches a title without replacing other nodes, layouts or scenes', () {
    final project = fixture();
    final dynamic actions = const SceneActions();
    final ProjectManifest result = actions.patchGraph(project,
        maps: <MapData>[],
        sceneId: 'test',
        upsertNodes: [
          SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'Fin')
        ]);
    final updated = result.scenes.first;
    expect(updated.graph.nodes.last.title, 'Fin');
    expect(updated.graph.nodes.first, project.scenes.first.graph.nodes.first);
    expect(updated.graph.edges, project.scenes.first.graph.edges);
    expect(updated.layout, project.scenes.first.layout);
    expect(result.scenes.last, project.scenes.last);
  });

  test('removes a node and its explicit links atomically', () {
    final dynamic actions = const SceneActions();
    final ProjectManifest result = actions.patchGraph(fixture(),
        maps: <MapData>[],
        sceneId: 'test',
        removeNodeIds: ['action'],
        removeEdgeIds: ['enter', 'leave'],
        upsertEdges: [edge('direct', 'start', 'end')]);
    expect(result.scenes.first.graph.nodes.map((node) => node.id),
        ['start', 'end']);
    expect(
        result.scenes.first.layout.nodeLayouts.map((layout) => layout.nodeId),
        ['start', 'end']);
    expect(result.scenes.first.layout.edgeLayouts, isEmpty);
    expect(buildSceneRuntimePlan(result.scenes.first).canBuild, isTrue);
  });

  test('places a created node only when its position is supplied', () {
    final dynamic actions = const SceneActions();
    final patch = (
      nodes: [
        SceneNode(
            id: 'heal',
            kind: SceneNodeKind.action,
            payload:
                SceneActionPayload.consequence(SceneConsequence.healParty()))
      ],
      edges: [edge('leave', 'action', 'heal'), edge('rest', 'heal', 'end')]
    );
    final ProjectManifest unplaced = actions.patchGraph(fixture(),
        maps: <MapData>[],
        sceneId: 'test',
        upsertNodes: patch.nodes,
        upsertEdges: patch.edges);
    expect(unplaced.scenes.first.layout, fixture().scenes.first.layout);
    final ProjectManifest placed = actions.patchGraph(fixture(),
        maps: <MapData>[],
        sceneId: 'test',
        upsertNodes: patch.nodes,
        upsertEdges: patch.edges,
        nodeLayouts: [SceneNodeLayout(nodeId: 'heal', x: 360, y: 20)]);
    expect(placed.scenes.first.layout.nodeLayouts, [
      ...fixture().scenes.first.layout.nodeLayouts,
      SceneNodeLayout(nodeId: 'heal', x: 360, y: 20)
    ]);
    expect(placed.scenes.first.graph, unplaced.scenes.first.graph);
    expect(placed.scenes.last, fixture().scenes.last);
  });

  test('refuses a position for a node the patch does not create', () {
    final project = fixture();
    final before = project.toJson();
    final dynamic actions = const SceneActions();
    for (final layouts in [
      [SceneNodeLayout(nodeId: 'action', x: 1, y: 1)],
      [SceneNodeLayout(nodeId: 'ghost', x: 1, y: 1)],
    ]) {
      expect(
          () => actions.patchGraph(project,
              maps: <MapData>[],
              sceneId: 'test',
              upsertNodes: [
                SceneNode(id: 'action', kind: SceneNodeKind.end, title: 'x')
              ],
              nodeLayouts: layouts),
          throwsA(isA<NarrativeAuthoringException>().having(
              (error) => error.code, 'code', 'scene.graph.invalid_patch')));
    }
    expect(project.toJson(), before);
  });

  test('rejects a dangling removal without mutating its input', () {
    final project = fixture();
    final before = project.toJson();
    final dynamic actions = const SceneActions();
    expect(
        () => actions.patchGraph(project,
            maps: <MapData>[], sceneId: 'test', removeNodeIds: ['action']),
        throwsA(isA<NarrativeAuthoringException>()));
    expect(project.toJson(), before);
  });

  test('rejects unknown removals and conflicting patch identities', () {
    final dynamic actions = const SceneActions();
    expect(
        () => actions.patchGraph(fixture(),
            maps: <MapData>[], sceneId: 'test', removeNodeIds: ['missing']),
        throwsA(isA<NarrativeAuthoringException>()));
    expect(
        () => actions.patchGraph(fixture(),
            maps: <MapData>[],
            sceneId: 'test',
            removeNodeIds: ['end'],
            upsertNodes: [SceneNode(id: 'end', kind: SceneNodeKind.end)]),
        throwsA(isA<NarrativeAuthoringException>()));
  });
}

SceneEdge edge(String id, String from, String to) => SceneEdge(
    id: id,
    fromNodeId: from,
    fromPortId: 'completed',
    toNodeId: to,
    kind: SceneEdgeKind.defaultFlow);

ProjectManifest fixture() =>
    ProjectManifest(name: 'Graph patch', maps: [], tilesets: [], scenes: [
      SceneAsset(
          id: 'test',
          name: 'Test',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'action',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.openPc())),
            SceneNode(id: 'end', kind: SceneNodeKind.end)
          ], edges: [
            edge('enter', 'start', 'action'),
            edge('leave', 'action', 'end')
          ]),
          layout: SceneGraphLayout(nodeLayouts: [
            SceneNodeLayout(nodeId: 'start', x: 10, y: 20),
            SceneNodeLayout(nodeId: 'action', x: 60, y: 20),
            SceneNodeLayout(nodeId: 'end', x: 100, y: 20)
          ], edgeLayouts: [
            SceneEdgeLayout(edgeId: 'enter')
          ])),
      SceneAsset(
          id: 'other',
          name: 'Other',
          graph: SceneGraph(startNodeId: 's', nodes: [
            SceneNode(id: 's', kind: SceneNodeKind.start),
            SceneNode(id: 'e', kind: SceneNodeKind.end)
          ], edges: [
            edge('other_edge', 's', 'e')
          ]))
    ]);
