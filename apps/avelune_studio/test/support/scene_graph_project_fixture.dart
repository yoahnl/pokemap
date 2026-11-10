import 'package:map_core/map_core.dart';

SceneAsset sceneCanvasFixture() => SceneAsset(
  id: 'scene',
  name: 'Recette',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'action',
        kind: SceneNodeKind.action,
        title: 'Autoriser le départ',
        payload: SceneActionPayload.consequence(
          SceneSetFactConsequence(factId: 'departure', value: true),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [],
  ),
  layout: SceneGraphLayout(
    nodeLayouts: [
      SceneNodeLayout(nodeId: 'start', x: 60, y: 100),
      SceneNodeLayout(nodeId: 'action', x: 320, y: 80),
      SceneNodeLayout(nodeId: 'end', x: 640, y: 110),
    ],
  ),
);
