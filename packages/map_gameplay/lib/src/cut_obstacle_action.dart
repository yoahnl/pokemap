import 'package:map_core/map_core.dart';

import 'field_action.dart';
import 'direction.dart';

enum CutObstacleBlockReason {
  invalidTarget,
  unsupportedMap,
  missingMapInstance,
  alreadyCleared,
  missingMove,
  locked
}

sealed class CutObstacleEvaluation {
  const CutObstacleEvaluation();
}

final class CanPromptCutObstacle extends CutObstacleEvaluation {
  const CanPromptCutObstacle(this.partyIndex);
  final int partyIndex;
}

final class CutObstacleUnavailable extends CutObstacleEvaluation {
  const CutObstacleUnavailable(this.reason);
  final CutObstacleBlockReason reason;
}

final class CutObstacleTicket {
  const CutObstacleTicket(
      {required this.fieldAction,
      required this.instance,
      required this.entityId,
      required this.playerPosition,
      required this.playerFacing});
  final FieldActionTicket fieldAction;
  final MapInstanceRef instance;
  final String entityId;
  final GridPos playerPosition;
  final EntityFacing playerFacing;
}

sealed class CutObstacleCommit {
  const CutObstacleCommit();
}

final class CutObstacleApplied extends CutObstacleCommit {
  const CutObstacleApplied(this.gameState, this.entityId);
  final GameState gameState;
  final String entityId;
}

final class CutObstacleRefused extends CutObstacleCommit {
  const CutObstacleRefused(this.refusal, {this.evaluation});
  final FieldActionRefusal refusal;
  final CutObstacleEvaluation? evaluation;
}

CutObstacleEvaluation evaluateCutObstacleAttempt(
    {required MapData map,
    required GameState gameState,
    required String entityId}) {
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.unsupportedMap);
  }
  if (map.id.trim().isEmpty ||
      map.id != gameState.currentMapId ||
      entityId.trim().isEmpty ||
      entityId.trim() != entityId) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.invalidTarget);
  }
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (instance == null) {
    return const CutObstacleUnavailable(
        CutObstacleBlockReason.missingMapInstance);
  }
  final matches =
      map.entities.where((entity) => entity.id == entityId).toList();
  if (matches.length != 1) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.invalidTarget);
  }
  final entity = matches.single;
  final direction = gameState.playerFacing.asDirection;
  final front = GridPos(
      x: gameState.playerPosition.x + direction.dx,
      y: gameState.playerPosition.y + direction.dy);
  if (entity.kind != MapEntityKind.custom ||
      entity.fieldObstacle?.kind != FieldObstacleKind.cutTree ||
      !entity.blocksMovement ||
      entity.size.width != 1 ||
      entity.size.height != 1 ||
      entity.npc != null ||
      entity.sign != null ||
      entity.item != null ||
      entity.spawn != null ||
      entity.pos != front ||
      entity.pos.x < 0 ||
      entity.pos.y < 0 ||
      entity.pos.x >= map.size.width ||
      entity.pos.y >= map.size.height ||
      gameState.playerPosition.x < 0 ||
      gameState.playerPosition.y < 0 ||
      gameState.playerPosition.x >= map.size.width ||
      gameState.playerPosition.y >= map.size.height ||
      map.entities
              .where((candidate) =>
                  resolveEntityCollisionCells(candidate).contains(entity.pos))
              .length !=
          1) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.invalidTarget);
  }
  if (gameState.mapInstanceWorldState
      .isFieldObstacleCleared(instance, entityId)) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.alreadyCleared);
  }
  if (!partyHasUsableFieldMove(gameState.party, FieldAbility.cut)) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.missingMove);
  }
  if (!gameState.progression.unlockedFieldAbilities
      .contains(FieldAbility.cut)) {
    return const CutObstacleUnavailable(CutObstacleBlockReason.locked);
  }
  return CanPromptCutObstacle(gameState.party.members.indexWhere((pokemon) =>
      !pokemon.isFainted &&
      pokemon.knownMoveIds.contains(FieldAbility.cut.moveId)));
}

CutObstacleCommit commitCutObstacleAction(
    {required CutObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
    required String confirmedEntityId}) {
  if (ticket.fieldAction.issuedAtStateRevision != currentStateRevision) {
    return const CutObstacleRefused(FieldActionRefusal.staleStateRevision);
  }
  if (ticket.fieldAction.ability != FieldAbility.cut ||
      ticket.entityId != confirmedEntityId ||
      ticket.instance.mapId != map.id ||
      ticket.instance != gameState.mapInstanceWorldState.instanceRef(map.id) ||
      ticket.playerPosition != gameState.playerPosition ||
      ticket.playerFacing != gameState.playerFacing ||
      !map.entities.any((entity) =>
          entity.id == ticket.entityId &&
          entity.pos == ticket.fieldAction.targetCell)) {
    return const CutObstacleRefused(FieldActionRefusal.targetChanged);
  }
  final evaluation = evaluateCutObstacleAttempt(
      map: map, gameState: gameState, entityId: ticket.entityId);
  if (evaluation is! CanPromptCutObstacle) {
    return CutObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: evaluation);
  }
  return CutObstacleApplied(
      gameState.copyWith(
          mapInstanceWorldState: gameState.mapInstanceWorldState
              .clearFieldObstacle(ticket.instance, ticket.entityId)),
      ticket.entityId);
}

MapData applyFieldObstacleWorldStateToMap(
    {required MapData map,
    required MapInstanceWorldState instances,
    required MapInstanceRef instance}) {
  if (map.id != instance.mapId || instances.instanceRef(map.id) != instance) {
    throw StateError(
        'The field obstacle projection requires the current map instance.');
  }
  if ((map.spatialScene != null || map.version == ProjectVersion.v9) &&
      map.entities.any((entity) => entity.fieldObstacle != null)) {
    throw StateError('Field obstacles require a two-dimensional map.');
  }
  final entities = map.entities
      .where((entity) =>
          entity.fieldObstacle == null ||
          !instances.isFieldObstacleCleared(instance, entity.id))
      .toList();
  return entities.length == map.entities.length
      ? map
      : map.copyWith(entities: entities);
}
