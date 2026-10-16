import 'package:map_core/map_core.dart';

import 'actor_route_motion.dart';
import 'direction.dart';
import 'field_ability_gate.dart';
import 'field_action.dart';
import 'gameplay_world_state.dart';

enum WaterfallBlockReason {
  unsupportedMap,
  invalidTarget,
  wrongDirection,
  requiresSurf,
  missingMove,
  locked,
  obstructed,
}

sealed class WaterfallEvaluation {
  const WaterfallEvaluation();
}

final class CanUseWaterfall extends WaterfallEvaluation {
  const CanUseWaterfall(this.partyIndex, this.cells);
  final int partyIndex;
  final List<GridPos> cells;
}

final class WaterfallUnavailable extends WaterfallEvaluation {
  const WaterfallUnavailable(this.reason);
  final WaterfallBlockReason reason;
}

final class WaterfallActionTicket {
  const WaterfallActionTicket({
    required this.fieldAction,
    required this.zone,
    required this.entryState,
    required this.instance,
  });
  final FieldActionTicket fieldAction;
  final MapGameplayZone zone;
  final GameState entryState;
  final MapInstanceRef? instance;
}

bool isWaterfallZone(MapGameplayZone zone) =>
    zone.kind == GameplayZoneKind.fieldAction &&
    zone.fieldAction?.actionKind == FieldActionZoneKind.waterfall;

List<GridPos> waterfallRouteCells(MapGameplayZone zone) {
  final route = zone.fieldAction!.waterfall!;
  return [route.entry, ...route.path, route.exit]
      .map((cell) =>
          GridPos(x: zone.area.pos.x + cell.x, y: zone.area.pos.y + cell.y))
      .toList(growable: false);
}

EntityFacing waterfallFacing(MapGameplayZone zone) =>
    switch (zone.fieldAction!.waterfall!.direction) {
      MapConnectionDirection.north => EntityFacing.north,
      MapConnectionDirection.south => EntityFacing.south,
      MapConnectionDirection.east => EntityFacing.east,
      MapConnectionDirection.west => EntityFacing.west,
    };

MapGameplayZone? findWaterfallTarget(
    {required MapData map, required GameState gameState}) {
  return findAllGameplayZonesAtPos(map, gameState.playerPosition)
      .where(isWaterfallZone)
      .where(
          (zone) => waterfallRouteCells(zone).first == gameState.playerPosition)
      .firstOrNull;
}

WaterfallEvaluation evaluateWaterfallAttempt({
  required MapData map,
  required GameState gameState,
  required String zoneId,
  GameplayWorldState? world,
  ProjectManifest? project,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    return const WaterfallUnavailable(WaterfallBlockReason.unsupportedMap);
  }
  final zones = map.gameplayZones.where((zone) => zone.id == zoneId).toList();
  if (map.id != gameState.currentMapId ||
      zones.length != 1 ||
      !isWaterfallZone(zones.single)) {
    return const WaterfallUnavailable(WaterfallBlockReason.invalidTarget);
  }
  final zone = zones.single;
  try {
    validateFieldActionZone(map, zone);
  } on Object {
    return const WaterfallUnavailable(WaterfallBlockReason.invalidTarget);
  }
  final cells = waterfallRouteCells(zone);
  if (cells.first != gameState.playerPosition) {
    return const WaterfallUnavailable(WaterfallBlockReason.invalidTarget);
  }
  final facing = waterfallFacing(zone);
  if (facing != gameState.playerFacing) {
    return const WaterfallUnavailable(WaterfallBlockReason.wrongDirection);
  }
  if (zone.fieldAction!.waterfall!.requiresSurf &&
      gameState.playerMovementMode != MovementMode.surf) {
    return const WaterfallUnavailable(WaterfallBlockReason.requiresSurf);
  }
  final gate = evaluateFieldAbilityGate(
      ability: FieldAbility.waterfall,
      supportedAbilities: const {FieldAbility.waterfall},
      unlockedFieldAbilities:
          gameState.progression.unlockedFieldAbilities.toSet(),
      party: gameState.party);
  if (gate.status == FieldAbilityGateStatus.missingMove) {
    return const WaterfallUnavailable(WaterfallBlockReason.missingMove);
  }
  if (gate.status != FieldAbilityGateStatus.usable) {
    return const WaterfallUnavailable(WaterfallBlockReason.locked);
  }
  var trial = world ??
      GameplayWorldState.initial(
          map: map,
          playerPos: gameState.playerPosition,
          playerFacing: facing.asDirection,
          playerMovementMode: gameState.playerMovementMode,
          project: project);
  if (trial.map.id != map.id ||
      trial.player.pos != gameState.playerPosition ||
      trial.player.movementMode != gameState.playerMovementMode) {
    return const WaterfallUnavailable(WaterfallBlockReason.invalidTarget);
  }
  for (final cell in cells.skip(1)) {
    final plan = planActorRouteMove(
        world: trial,
        target: SceneActorTarget.player(mapId: map.id),
        direction: facing,
        through: false,
        waterfallZone: zone,
        dynamicBlockedCells: dynamicBlockedCells,
        characterReservations: characterReservations);
    if (plan == null || plan.to != cell) {
      return const WaterfallUnavailable(WaterfallBlockReason.obstructed);
    }
    trial = trial.withPlayer(plan.playerState!);
  }
  return CanUseWaterfall(gate.partyIndex!, List.unmodifiable(cells.skip(1)));
}

FieldActionRefusal? validateWaterfallTicket({
  required WaterfallActionTicket ticket,
  required MapData map,
  required GameState gameState,
  required int currentStateRevision,
}) {
  if (ticket.fieldAction.issuedAtStateRevision != currentStateRevision) {
    return FieldActionRefusal.staleStateRevision;
  }
  if (ticket.fieldAction.ability != FieldAbility.waterfall ||
      ticket.fieldAction.targetCell != gameState.playerPosition ||
      ticket.entryState.currentMapId != gameState.currentMapId ||
      ticket.entryState.playerPosition != gameState.playerPosition ||
      ticket.entryState.playerPixelPosition != gameState.playerPixelPosition ||
      ticket.entryState.playerFacing != gameState.playerFacing ||
      ticket.entryState.playerMovementMode != gameState.playerMovementMode ||
      ticket.instance != gameState.mapInstanceWorldState.instanceRef(map.id) ||
      findGameplayZoneById(map, ticket.zone.id) != ticket.zone) {
    return FieldActionRefusal.targetChanged;
  }
  return null;
}
