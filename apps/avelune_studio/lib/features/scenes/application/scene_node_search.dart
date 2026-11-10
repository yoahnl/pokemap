import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/studio_search_text.dart';
import 'scene_labels.dart';

List<SceneNode> sceneNodeMatches(SceneAsset scene, String query) => [
  for (final node in scene.graph.nodes)
    if (studioSearchMatches(
      '${sceneNodeName(scene.graph, node.id)} ${sceneKindLabel(node.kind)} ${node.id}',
      query,
    ))
      node,
];
