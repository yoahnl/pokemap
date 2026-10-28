import 'package:map_core/map_core.dart';
import 'direction.dart';
import 'field_ability_gate.dart';
import 'field_action.dart';
import 'gameplay_world_state.dart';
import 'movement_terrain_policy.dart';

enum DiveBlockReason {
  disabled,
  unsupportedMap,
  invalidTarget,
  inactivePair,
  invalidTerrain,
  wrongMode,
  missingMove,
  locked,
  obstructed
}

sealed class DiveEvaluation {
  const DiveEvaluation();
}

final class DiveUnavailable extends DiveEvaluation {
  const DiveUnavailable(this.reason);
  final DiveBlockReason reason;
}

final class CanUseDive extends DiveEvaluation {
  const CanUseDive(
      {required this.partyIndex,
      required this.sourceZoneId,
      required this.targetZoneId,
      required this.targetMapId,
      required this.arrivalSpawnId,
      required this.position,
      required this.facing,
      required this.arrivalMovementMode});
  final int partyIndex;
  final String sourceZoneId, targetZoneId, targetMapId, arrivalSpawnId;
  final GridPos position;
  final EntityFacing facing;
  final MovementMode arrivalMovementMode;
}

MapGameplayZone? findDiveTarget(
    {required MapData map, required GameState gameState}) {
  final points = findAllGameplayZonesAtPos(map, gameState.playerPosition)
      .where(isDiveZone)
      .toList();
  return points.length == 1 ? points.single : null;
}

bool isDiveEndpointPoseSafe({required GameplayWorldState world}) {
  final rect = world.player.playerCollisionRectPx;
  return !world.worldStaticObstaclesCollidePlayerCollisionRect() &&
      [rect, world.playerCharacterContactRect(rect)].every((area) =>
          movementTerrainAllowsRect(
              map: world.map,
              rect: area,
              tileWidth: world.tileWidthPx,
              tileHeight: world.tileHeightPx,
              mode: world.player.movementMode));
}

bool divePairHasSafeArrivals(
    {required MapData sourceMap,
    required String sourceZoneId,
    required MapData targetMap,
    required String targetZoneId,
    ProjectManifest? project}) {
  try {
    validateDiveZonePair(
        sourceMap: sourceMap,
        sourceZoneId: sourceZoneId,
        targetMap: targetMap,
        targetZoneId: targetZoneId);
    for (final entry in [
      (sourceMap, sourceZoneId),
      (targetMap, targetZoneId)
    ]) {
      final zone = findGameplayZoneById(entry.$1, entry.$2)!;
      final dive = zone.fieldAction!.dive!;
      final spawn = entry.$1.entities
          .singleWhere((entity) => entity.id == dive.arrivalSpawnId);
      final mode = dive.role == DiveZoneRole.surface
          ? MovementMode.surf
          : MovementMode.dive;
      final requiredTerrain = dive.role == DiveZoneRole.surface
          ? GameplayMovementTerrain.surf
          : GameplayMovementTerrain.underwater;
      if (movementTerrainAt(entry.$1, spawn.pos.x, spawn.pos.y) !=
          requiredTerrain) {
        return false;
      }
      final world = GameplayWorldState.initial(
          map: entry.$1,
          playerPos: spawn.pos,
          playerFacing: spawn.spawn!.facing.asDirection,
          playerMovementMode: mode,
          project: project,
          tileWidth: project?.settings.tileWidth ?? 16,
          tileHeight: project?.settings.tileHeight ?? 16);
      if (!isDiveEndpointPoseSafe(world: world)) {
        return false;
      }
    }
    return true;
  } on Object {
    return false;
  }
}

DiveEvaluation evaluateDiveAttempt(
    {required MapData sourceMap,
    required MapData? targetMap,
    required GameState gameState,
    required String zoneId,
    ProjectManifest? project,
    GameplayWorldState? sourceWorld,
    GameplayWorldState? targetWorld}) {
  if (sourceMap.spatialScene != null ||
      sourceMap.version == ProjectVersion.v9 ||
      targetMap?.spatialScene != null ||
      targetMap?.version == ProjectVersion.v9) {
    return const DiveUnavailable(DiveBlockReason.unsupportedMap);
  }
  final zones =
      sourceMap.gameplayZones.where((zone) => zone.id == zoneId).toList();
  if (sourceMap.id != gameState.currentMapId ||
      zones.length != 1 ||
      !isDiveZone(zones.single) ||
      zones.single.area.pos != gameState.playerPosition) {
    return const DiveUnavailable(DiveBlockReason.invalidTarget);
  }
  final source = zones.single;
  final payload = source.fieldAction!.dive;
  if (payload?.link == null || targetMap == null) {
    return const DiveUnavailable(DiveBlockReason.inactivePair);
  }
  try {
    validateDiveZonePair(
        sourceMap: sourceMap,
        sourceZoneId: zoneId,
        targetMap: targetMap,
        targetZoneId: payload!.link!.zoneId);
  } on Object {
    return const DiveUnavailable(DiveBlockReason.inactivePair);
  }
  final expectedMode = payload.role == DiveZoneRole.surface
      ? MovementMode.surf
      : MovementMode.dive;
  if (gameState.playerMovementMode != expectedMode) {
    return const DiveUnavailable(DiveBlockReason.wrongMode);
  }
  if (!divePairHasSafeArrivals(
      sourceMap: sourceMap,
      sourceZoneId: zoneId,
      targetMap: targetMap,
      targetZoneId: payload.link!.zoneId,
      project: project)) {
    return const DiveUnavailable(DiveBlockReason.obstructed);
  }
  final target = findGameplayZoneById(targetMap, payload.link!.zoneId)!;
  final spawn = targetMap.entities.singleWhere(
      (entity) => entity.id == target.fieldAction!.dive!.arrivalSpawnId);
  final arrivalMode =
      expectedMode == MovementMode.surf ? MovementMode.dive : MovementMode.surf;
  if (sourceWorld != null &&
      (sourceWorld.map != sourceMap ||
          sourceWorld.player.pos != gameState.playerPosition ||
          sourceWorld.player.movementMode != expectedMode ||
          !isDiveEndpointPoseSafe(world: sourceWorld))) {
    return const DiveUnavailable(DiveBlockReason.obstructed);
  }
  if (targetWorld != null &&
      (targetWorld.map != targetMap ||
          targetWorld.player.pos != spawn.pos ||
          targetWorld.player.movementMode != arrivalMode ||
          !isDiveEndpointPoseSafe(world: targetWorld))) {
    return const DiveUnavailable(DiveBlockReason.obstructed);
  }
  final gate = evaluateFieldAbilityGate(
      ability: FieldAbility.dive,
      supportedAbilities: const {FieldAbility.dive},
      unlockedFieldAbilities:
          gameState.progression.unlockedFieldAbilities.toSet(),
      party: gameState.party,
      projectSettings: expectedMode == MovementMode.dive ? null : project?.settings);
  if (gate.status != FieldAbilityGateStatus.usable) {
    return DiveUnavailable(gate.status == FieldAbilityGateStatus.disabled
        ? DiveBlockReason.disabled
        : gate.status == FieldAbilityGateStatus.locked
        ? DiveBlockReason.locked
        : DiveBlockReason.missingMove);
  }
  return CanUseDive(
      partyIndex: gate.partyIndex!,
      sourceZoneId: source.id,
      targetZoneId: target.id,
      targetMapId: targetMap.id,
      arrivalSpawnId: spawn.id,
      position: spawn.pos,
      facing: spawn.spawn!.facing,
      arrivalMovementMode: arrivalMode);
}

final class DiveActionTicket {
  const DiveActionTicket(
      {required this.evaluation,
      required this.gameState,
      required this.sourceMap,
      required this.targetMap,
      required this.issuedAtStateRevision});
  final CanUseDive evaluation;
  final GameState gameState;
  final MapData sourceMap, targetMap;
  final int issuedAtStateRevision;
}

FieldActionRefusal? validateDiveTicket(
    {required DiveActionTicket ticket,
    required MapData sourceMap,
    required MapData? targetMap,
    required GameState gameState,
    required int currentStateRevision,
    ProjectManifest? project,
    GameplayWorldState? sourceWorld}) {
  if (ticket.issuedAtStateRevision != currentStateRevision ||
      ticket.gameState != gameState) {
    return FieldActionRefusal.staleStateRevision;
  }
  if (ticket.sourceMap != sourceMap || ticket.targetMap != targetMap) {
    return FieldActionRefusal.targetChanged;
  }
  final result = evaluateDiveAttempt(
      sourceMap: sourceMap,
      targetMap: targetMap,
      gameState: gameState,
      zoneId: ticket.evaluation.sourceZoneId,
      project: project,
      sourceWorld: sourceWorld);
  return result is CanUseDive &&
          result.position == ticket.evaluation.position &&
          result.arrivalSpawnId == ticket.evaluation.arrivalSpawnId &&
          result.arrivalMovementMode == ticket.evaluation.arrivalMovementMode &&
          result.facing == ticket.evaluation.facing
      ? null
      : FieldActionRefusal.noLongerAvailable;
}
