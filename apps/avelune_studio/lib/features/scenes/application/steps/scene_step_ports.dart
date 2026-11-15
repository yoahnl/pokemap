import 'package:map_core/map_core_domain.dart';

List<String> sceneStepPortOrder(SceneNode node, SceneGraph graph) {
  if (node.payload is SceneBranchByOutcomePayload) {
    return [
      for (final port in authorableSceneOutputPortsForNodeInGraph(node, graph))
        port.id,
    ];
  }
  final declared = declaredSceneNodeOutcomePorts(node);
  if (declared.isNotEmpty) return declared;
  return [for (final port in authorableSceneOutputPortsForNode(node)) port.id];
}

String? sceneStepMainPortOf(SceneNode node) => switch (node.payload) {
  SceneActionPayload(:final interactiveCommand?) =>
    interactiveCommand.outputPortIds.firstOrNull,
  SceneBattlePayload() => 'victory',
  _ => null,
};
