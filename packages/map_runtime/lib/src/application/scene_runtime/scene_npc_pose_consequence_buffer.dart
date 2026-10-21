import 'package:map_core/map_core.dart';

void retireSceneNpcPosesPublishedByActorRoute({
  required SceneInteractiveCommand? command,
  required MapInstanceRef? scope,
  required MapInstanceWorldState? before,
  required MapInstanceWorldState? after,
  required List<SceneConsequence> consequences,
  required List<String?> pokemonGrantOperationIds,
  required List<String?> railProgressionOperationIds,
}) {
  if (command is! SceneActorRouteInteractiveCommand ||
      command.target.kind != SceneActorTargetKind.entity ||
      scope == null ||
      scope.mapId != command.target.mapId ||
      before?.instanceRef(scope.mapId) != scope ||
      after?.instanceRef(scope.mapId) != scope) {
    return;
  }
  final entityId = command.target.entityId!;
  final beforePose = before!.instancesByMapId[scope.mapId]!.npcPoses[entityId];
  final afterPose = after!.instancesByMapId[scope.mapId]!.npcPoses[entityId];
  if (afterPose == null || identical(beforePose, afterPose)) return;
  if (consequences.length != pokemonGrantOperationIds.length ||
      consequences.length != railProgressionOperationIds.length) {
    throw StateError(
      'Scene consequence operation buffers must remain aligned.',
    );
  }
  for (var index = consequences.length - 1; index >= 0; index--) {
    final consequence = consequences[index];
    if (consequence is SceneSetNpcPoseConsequence &&
        consequence.mapId == scope.mapId &&
        consequence.entityId == entityId) {
      consequences.removeAt(index);
      pokemonGrantOperationIds.removeAt(index);
      railProgressionOperationIds.removeAt(index);
    }
  }
}
