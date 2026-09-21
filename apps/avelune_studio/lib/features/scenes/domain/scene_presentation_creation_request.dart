import 'package:map_core/map_core_domain.dart';

class ScenePresentationCreationRequest {
  const ScenePresentationCreationRequest({
    required this.baseScene,
    required this.scene,
    required this.targetNodeId,
  });
  final SceneAsset baseScene;
  final SceneAsset scene;
  final String targetNodeId;
}
