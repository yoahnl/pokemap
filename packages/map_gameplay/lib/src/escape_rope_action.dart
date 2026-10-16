import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_world_state.dart';
import 'items/bag_operations.dart';
import 'items/bag_operation_result.dart';
import 'scene_warp_arrival.dart';

enum EscapeRopeBlockReason {
  unsupportedMap,
  forbiddenMap,
  unavailableContext,
  unknownExit,
  invalidDestination,
  obstructed,
  invalidItem,
  insufficientQuantity,
}

sealed class EscapeRopeEvaluation {
  const EscapeRopeEvaluation();
}

final class EscapeRopeUnavailable extends EscapeRopeEvaluation {
  const EscapeRopeUnavailable(this.reason);
  final EscapeRopeBlockReason reason;
}

final class CanUseEscapeRope extends EscapeRopeEvaluation {
  const CanUseEscapeRope(this.arrival);
  final EscapeReturnPoint arrival;
}

EscapeReturnPoint? escapeReturnPointAfterTransfer({
  required MapData sourceMap,
  required MapData targetMap,
  required GameState sourceState,
}) {
  final sourceId = sourceMap.mapMetadata.escapeRopeDungeonId;
  final targetId = targetMap.mapMetadata.escapeRopeDungeonId;
  if (targetId == null || targetId.isEmpty) return null;
  if (sourceId == targetId) {
    final anchor = sourceState.escapeReturnPoint;
    return anchor?.dungeonId == targetId ? anchor : null;
  }
  if (sourceId != null ||
      sourceState.currentMapId != sourceMap.id ||
      sourceMap.version != ProjectVersion.v8 ||
      sourceMap.spatialScene != null ||
      targetMap.version != ProjectVersion.v8 ||
      targetMap.spatialScene != null ||
      (sourceState.playerMovementMode != MovementMode.walk &&
          sourceState.playerMovementMode != MovementMode.bicycle)) {
    return null;
  }
  return EscapeReturnPoint(
      dungeonId: targetId,
      mapId: sourceMap.id,
      position: sourceState.playerPosition,
      facing: sourceState.playerFacing);
}

EscapeRopeEvaluation evaluateEscapeRopeAttempt({
  required MapData sourceMap,
  required MapData? targetMap,
  required GameState gameState,
  required ProjectItemDefinition item,
  ProjectManifest? project,
  bool validateArrival = true,
}) {
  if (sourceMap.spatialScene != null ||
      sourceMap.version != ProjectVersion.v8 ||
      (targetMap != null &&
          (targetMap.spatialScene != null ||
              targetMap.version != ProjectVersion.v8))) {
    return const EscapeRopeUnavailable(EscapeRopeBlockReason.unsupportedMap);
  }
  if (sourceMap.id != gameState.currentMapId ||
      gameState.playerMovementMode != MovementMode.walk) {
    return const EscapeRopeUnavailable(
        EscapeRopeBlockReason.unavailableContext);
  }
  if (!sourceMap.mapMetadata.allowEscapeRope) {
    return const EscapeRopeUnavailable(EscapeRopeBlockReason.forbiddenMap);
  }
  final anchor = gameState.escapeReturnPoint;
  if (anchor == null ||
      anchor.dungeonId != sourceMap.mapMetadata.escapeRopeDungeonId) {
    return const EscapeRopeUnavailable(EscapeRopeBlockReason.unknownExit);
  }
  final uses = item.uses
      .where((use) => use.contexts.contains(ProjectItemUseContext.overworld));
  if (uses.length != 1 ||
      uses.single.effect is! ProjectItemEscapeRopeEffectDefinition ||
      uses.single.contexts.length != 1 ||
      uses.single.target != ProjectItemTargetKind.world ||
      uses.single.consumption != ProjectItemConsumptionPolicy.onApplied ||
      item.tags.contains('key-item')) {
    return const EscapeRopeUnavailable(EscapeRopeBlockReason.invalidItem);
  }
  if (const BagOperations().quantityOf(gameState.bag, item.id) < 1) {
    return const EscapeRopeUnavailable(
        EscapeRopeBlockReason.insufficientQuantity);
  }
  if (targetMap == null ||
      targetMap.id != anchor.mapId ||
      targetMap.mapMetadata.escapeRopeDungeonId != null ||
      anchor.position.x < 0 ||
      anchor.position.y < 0 ||
      anchor.position.x >= targetMap.size.width ||
      anchor.position.y >= targetMap.size.height) {
    return const EscapeRopeUnavailable(
        EscapeRopeBlockReason.invalidDestination);
  }
  if (!validateArrival) return CanUseEscapeRope(anchor);
  try {
    final world = GameplayWorldState.initial(
        map: targetMap,
        playerPos: anchor.position,
        playerFacing: anchor.facing.asDirection,
        playerMovementMode: MovementMode.walk,
        project: project,
        tileWidth: project?.settings.tileWidth ?? 32,
        tileHeight: project?.settings.tileHeight ?? 32);
    if (!isSceneWarpArrivalAllowed(
        world: world,
        project: project ??
            const ProjectManifest(name: 'Escape', maps: [], tilesets: []))) {
      return const EscapeRopeUnavailable(EscapeRopeBlockReason.obstructed);
    }
  } on Object {
    return const EscapeRopeUnavailable(EscapeRopeBlockReason.obstructed);
  }
  return CanUseEscapeRope(anchor);
}

final class EscapeRopeActionTicket {
  const EscapeRopeActionTicket(
      {required this.evaluation,
      required this.gameState,
      required this.sourceMap,
      required this.targetMap,
      required this.item,
      required this.issuedAtStateRevision});
  final CanUseEscapeRope evaluation;
  final GameState gameState;
  final MapData sourceMap, targetMap;
  final ProjectItemDefinition item;
  final int issuedAtStateRevision;
}

GameState? commitEscapeRopeAction({
  required EscapeRopeActionTicket ticket,
  required MapData sourceMap,
  required MapData? targetMap,
  required GameState gameState,
  required ProjectItemDefinition item,
  required int currentStateRevision,
  ProjectManifest? project,
  bool validateArrival = true,
}) {
  if (ticket.issuedAtStateRevision != currentStateRevision ||
      ticket.gameState != gameState ||
      ticket.sourceMap != sourceMap ||
      ticket.targetMap != targetMap ||
      ticket.item != item) {
    return null;
  }
  final evaluation = evaluateEscapeRopeAttempt(
      sourceMap: sourceMap,
      targetMap: targetMap,
      gameState: gameState,
      item: item,
      project: project,
      validateArrival: validateArrival);
  if (evaluation is! CanUseEscapeRope ||
      evaluation.arrival != ticket.evaluation.arrival) {
    return null;
  }
  final consumed = const BagOperations().consume(BagConsumeRequest(
      bag: gameState.bag,
      itemId: item.id,
      quantity: 1,
      itemTags: item.tags,
      reason: ItemConsumptionReason.appliedEffect));
  if (!consumed.isSuccess) return null;
  return gameState.copyWith(
      currentMapId: evaluation.arrival.mapId,
      playerPosition: evaluation.arrival.position,
      playerPixelPosition: null,
      playerSpatialPosition: null,
      playerFacing: evaluation.arrival.facing,
      playerMovementMode: MovementMode.walk,
      escapeReturnPoint: null,
      bag: consumed.bag);
}
