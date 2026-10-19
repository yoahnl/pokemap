import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'authoring_query_adapter.dart';

final class SceneBattleRecoveryAuthoringGateway {
  const SceneBattleRecoveryAuthoringGateway({required this.queries});

  final AuthoringQueryAdapter queries;

  Future<ProjectManifest> updateDraft(
    String projectRoot, {
    required ProjectManifest project,
    required String sceneId,
    required String nodeId,
    required SceneBattleDefeatRecovery defeatRecovery,
    MapData? activeMap,
  }) async {
    await queries.invalidate(projectRoot);
    final session = await queries.open(projectRoot);
    final scene = project.scenes
        .where((scene) => scene.id == sceneId)
        .firstOrNull;
    final node = scene?.graph.nodes
        .where((node) => node.id == nodeId)
        .firstOrNull;
    if (node == null || node.payload is! SceneBattlePayload) {
      throw StateError('Le combat sélectionné est introuvable.');
    }
    final payload = SceneBattlePayload.fromJson({
      ...node.payload.toJson(),
      'defeatRecovery': defeatRecovery.name,
    });
    final updated = SceneNode(
      id: node.id,
      kind: node.kind,
      title: node.title,
      description: node.description,
      payload: payload,
    );
    return const SceneActions().patchGraph(
      project,
      maps: [
        for (final map in session.maps)
          if (activeMap?.id == map.id) activeMap! else map,
        if (activeMap != null &&
            !session.maps.any((map) => map.id == activeMap.id))
          activeMap,
      ],
      sceneId: sceneId,
      upsertNodes: [updated],
    );
  }
}
