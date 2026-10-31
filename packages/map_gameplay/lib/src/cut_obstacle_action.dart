import 'package:map_core/map_core.dart';

import 'field_action.dart';
import 'field_ability_gate.dart';
import 'direction.dart';
import 'gameplay_world_state.dart';
import 'npc_instance_pose_projection.dart';

enum CutObstacleBlockReason {
  disabled,
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
    required String entityId,
    ProjectSettings? projectSettings}) {
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
  final gate = evaluateFieldAbilityGate(
    ability: FieldAbility.cut,
    supportedAbilities: const {FieldAbility.cut},
    unlockedFieldAbilities:
        gameState.progression.unlockedFieldAbilities.toSet(),
    party: gameState.party,
    projectSettings: projectSettings,
  );
  return switch (gate.status) {
    FieldAbilityGateStatus.disabled =>
      const CutObstacleUnavailable(CutObstacleBlockReason.disabled),
    FieldAbilityGateStatus.unsupported =>
      throw StateError('The Cut obstacle action requires Cut support.'),
    FieldAbilityGateStatus.missingMove =>
      const CutObstacleUnavailable(CutObstacleBlockReason.missingMove),
    FieldAbilityGateStatus.locked =>
      const CutObstacleUnavailable(CutObstacleBlockReason.locked),
    FieldAbilityGateStatus.usable => CanPromptCutObstacle(gate.partyIndex!),
  };
}

CutObstacleCommit commitCutObstacleAction(
    {required CutObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
    required String confirmedEntityId,
    ProjectSettings? projectSettings}) {
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
      map: map, gameState: gameState, entityId: ticket.entityId,
      projectSettings: projectSettings);
  if (evaluation is! CanPromptCutObstacle) {
    return CutObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: evaluation);
  }
  return CutObstacleApplied(
      gameState.copyWith(
          mapInstanceWorldState: gameState.mapInstanceWorldState
              .clearFieldObstacle(ticket.instance, ticket.entityId, resetPolicy: map.entities.singleWhere((entity) => entity.id == ticket.entityId).fieldObstacle!.resetPolicy)),
      ticket.entityId);
}

MapData applyFieldObstacleWorldStateToMap(
    {required MapData map,
    required MapInstanceWorldState instances,
    required MapInstanceRef instance,
    MapData? authoringMap,
    MovingPlatformWorldState movingPlatformWorldState =
        const MovingPlatformWorldState.empty(),
    MovingPropWorldState movingPropWorldState =
        const MovingPropWorldState.empty(),
    ProjectManifest? project,
    PeriodicRewardSceneLookup? lookupRewardScenes,
    NpcMapPresencePredicate? npcMapPresencePredicate,
    MapEntityPresencePredicate? mapEntityPresencePredicate}) {
  if (map.id != instance.mapId || instances.instanceRef(map.id) != instance) {
    throw StateError(
        'The field obstacle projection requires the current map instance.');
  }
  if ((map.spatialScene != null || map.version == ProjectVersion.v9) &&
      map.entities.any((entity) => entity.fieldObstacle != null)) {
    throw StateError('Field obstacles require a two-dimensional map.');
  }
  final source = authoringMap ?? map;
  if (source.id != map.id ||
      source.size != map.size ||
      source.version != map.version) {
    throw StateError(
        'Field obstacle projection requires matching authored map geometry.');
  }
  final saved = instances.instancesByMapId[map.id]!;
  final positions = {...saved.fieldObstaclePositions, ...?instances.persistentFieldObstaclePositions[map.id]};
  MapEntity entityFor(String id) {
    final matches = source.entities.where((entity) => entity.id == id).toList();
    if (matches.length != 1 || matches.single.fieldObstacle == null) {
      throw StateError('Saved field obstacle $id is absent or ambiguous.');
    }
    final entity = matches.single;
    if (entity.kind != MapEntityKind.custom ||
        !entity.blocksMovement ||
        entity.size.width != 1 ||
        entity.size.height != 1 ||
        entity.npc != null ||
        entity.sign != null ||
        entity.item != null ||
        entity.spawn != null ||
        entity.healingDisplay != null) {
      throw StateError('Saved field obstacle $id has an incompatible shape.');
    }
    return entity;
  }

  for (final id in saved.consumedInteractiveEncounterEntityIds) {
    final matches = source.entities.where((entity) => entity.id == id).toList();
    if (source.version != ProjectVersion.v8 || source.spatialScene != null || matches.length != 1 ||
        matches.single.interactiveEncounter?.reusePolicy != InteractiveEncounterReusePolicy.oncePerMapInstance ||
        (matches.single.interactiveEncounter?.trigger == InteractiveEncounterTrigger.afterRockSmash && !instances.isFieldObstacleCleared(instance, id))) {
      throw StateError('Saved interactive encounter ${map.id}/$id is absent or incompatible.');
    }
    assertValidMapEntityTypedPayloads(matches.single);
  }

  for (final id in {...saved.clearedFieldObstacleIds, ...?instances.persistentClearedObstacles[map.id]}) {
    if (entityFor(id).fieldObstacle!.isPushable ||
        positions.containsKey(id)) {
      throw StateError('A Strength boulder cannot be cleared.');
    }
  }
  for (final entry in positions.entries) {
    final obstacle = entityFor(entry.key).fieldObstacle!;
    final persistent = instances.persistentFieldObstaclePositions[map.id]?.containsKey(entry.key) ?? false;
    if (!obstacle.isPushable ||
        persistent && (obstacle.kind != FieldObstacleKind.strengthBoulder || obstacle.resetPolicy != FieldObstacleResetPolicy.persistent) ||
        entry.value.x < 0 ||
        entry.value.y < 0 ||
        entry.value.x >= map.size.width ||
        entry.value.y >= map.size.height) {
      throw StateError(
          'Saved boulder ${entry.key} has an incompatible position.');
    }
  }
  final candidates = authoringMap == null
      ? map.entities
      : [
          ...map.entities.where((entity) => entity.fieldObstacle == null),
          ...source.entities.where((entity) => entity.fieldObstacle != null),
        ];
  final entities = [
    for (final entity in candidates)
      if (!instances.isFieldObstacleCleared(instance, entity.id))
        positions.containsKey(entity.id)
            ? entity.copyWith(pos: instances.fieldObstaclePositionForMap(map.id, entity.id)!)
            : entity,
  ];
  final projected = applyNpcInstancePosesToMap(
    map: map.copyWith(entities: entities),
    authoringMap: source,
    instances: instances,
    instance: instance,
    project: project,
    lookupRewardScenes: lookupRewardScenes,
    movingPlatformWorldState: movingPlatformWorldState,
    movingPropWorldState: movingPropWorldState,
    npcMapPresencePredicate: npcMapPresencePredicate,
    mapEntityPresencePredicate: mapEntityPresencePredicate,
  );
  for (final id in {
    ...positions.keys
  }) {
    final entity = entities.singleWhere((entity) => entity.id == id);
    if (entity.kind == MapEntityKind.npc &&
        (!(npcMapPresencePredicate?.call(map.id, entity) ?? true) ||
            !(mapEntityPresencePredicate?.call(map.id, entity) ?? true))) {
      continue;
    }
    final world = GameplayWorldState.initial(
      map: projected.copyWith(
          entities: projected.entities.where((entity) => entity.id != id).toList()),
      playerPos: const GridPos(x: 0, y: 0),
      movingPlatformWorldState: movingPlatformWorldState,
      movingPropWorldState: movingPropWorldState,
      project: project,
      tileWidth: project?.settings.tileWidth ?? 16,
      tileHeight: project?.settings.tileHeight ?? 16,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
    final rect = resolveEntityCollisionRectPx(entity,
        tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
    if (world.isWaterCell(entity.pos.x, entity.pos.y) ||
        world.worldStaticObstaclesCollidePixelRect(rect)) {
      throw StateError(
          'Saved entity $id overlaps an occupied or impassable cell.');
    }
  }
  return projected == map ? map : projected;
}
