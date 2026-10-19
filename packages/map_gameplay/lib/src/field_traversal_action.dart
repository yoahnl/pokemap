import 'package:map_core/map_core.dart';

import 'actor_route_motion.dart';
import 'direction.dart';
import 'field_ability_gate.dart';
import 'field_action.dart';
import 'field_traversal_geometry.dart';
import 'gameplay_world_state.dart';
import 'movement_terrain_policy.dart';

enum FieldTraversalBlockReason {
  unsupportedMap,
  invalidTarget,
  wrongDirection,
  requiresSurf,
  missingMove,
  locked,
  obstructed,
  requiresWater,
}

final class FieldTraversalEvaluation {
  const FieldTraversalEvaluation.unavailable(this.reason)
      : partyIndex = null,
        cells = const [];
  const FieldTraversalEvaluation.usable(this.partyIndex, this.cells)
      : reason = null;
  final FieldTraversalBlockReason? reason;
  final int? partyIndex;
  final List<GridPos> cells;
}

abstract class FieldTraversalActionTicket {
  const FieldTraversalActionTicket(
      {required this.fieldAction,
      required this.zone,
      required this.entryState,
      required this.instance});
  final FieldActionTicket fieldAction;
  final MapGameplayZone zone;
  final GameState entryState;
  final MapInstanceRef? instance;
}

FieldTraversalEvaluation evaluateFieldTraversalAttempt({
  required FieldAbility ability,
  required FieldActionZoneKind kind,
  required MapData map,
  required GameState gameState,
  required String zoneId,
  GameplayWorldState? world,
  ProjectManifest? project,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  if ((kind == FieldActionZoneKind.waterfall &&
          ability != FieldAbility.waterfall) ||
      (kind == FieldActionZoneKind.whirlpool &&
          ability != FieldAbility.whirlpool) ||
      !const {FieldActionZoneKind.waterfall, FieldActionZoneKind.whirlpool}
          .contains(kind)) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.invalidTarget);
  }
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.unsupportedMap);
  }
  final zones = map.gameplayZones.where((zone) => zone.id == zoneId).toList();
  if (map.id != gameState.currentMapId ||
      zones.length != 1 ||
      !isFieldTraversalZone(zones.single) ||
      zones.single.fieldAction!.actionKind != kind) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.invalidTarget);
  }
  final zone = zones.single;
  try {
    validateFieldActionZone(map, zone);
  } on Object {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.invalidTarget);
  }
  final cells = fieldTraversalRouteCells(zone);
  if (cells.first != gameState.playerPosition) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.invalidTarget);
  }
  final facing = fieldTraversalFacing(zone);
  if (facing != gameState.playerFacing) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.wrongDirection);
  }
  if (fieldTraversalRequiresSurf(zone) &&
      gameState.playerMovementMode != MovementMode.surf) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.requiresSurf);
  }
  final gate = evaluateFieldAbilityGate(
      ability: ability,
      supportedAbilities: {ability},
      unlockedFieldAbilities:
          gameState.progression.unlockedFieldAbilities.toSet(),
      party: gameState.party);
  if (gate.status == FieldAbilityGateStatus.missingMove) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.missingMove);
  }
  if (gate.status != FieldAbilityGateStatus.usable) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.locked);
  }
  if (kind == FieldActionZoneKind.whirlpool &&
      cells.any((cell) =>
          movementTerrainAt(map, cell.x, cell.y) !=
          GameplayMovementTerrain.surf)) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.requiresWater);
  }
  var trial = world ??
      GameplayWorldState.initial(
          map: map,
          gameState: gameState,
          movingPlatformWorldState: gameState.movingPlatformWorldState,
          playerPos: gameState.playerPosition,
          playerFacing: facing.asDirection,
          playerMovementMode: gameState.playerMovementMode,
          project: project);
  if (trial.map.id != map.id ||
      trial.player.pos != gameState.playerPosition ||
      trial.player.movementMode != gameState.playerMovementMode) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.invalidTarget);
  }
  for (final cell in cells.skip(1)) {
    final plan = planActorRouteMove(
        world: trial,
        target: SceneActorTarget.player(mapId: map.id),
        direction: facing,
        through: false,
        fieldTraversalZone: zone,
        dynamicBlockedCells: dynamicBlockedCells,
        characterReservations: characterReservations);
    if (plan == null || plan.to != cell) {
      return const FieldTraversalEvaluation.unavailable(
          FieldTraversalBlockReason.obstructed);
    }
    trial = trial.withPlayer(plan.playerState!);
  }
  return FieldTraversalEvaluation.usable(
      gate.partyIndex!, List.unmodifiable(cells.skip(1)));
}

FieldActionRefusal? validateFieldTraversalTicket({
  required FieldTraversalActionTicket ticket,
  required FieldAbility ability,
  required MapData map,
  required GameState gameState,
  required int currentStateRevision,
}) {
  if (ticket.fieldAction.issuedAtStateRevision != currentStateRevision) {
    return FieldActionRefusal.staleStateRevision;
  }
  if (map.id != gameState.currentMapId ||
      !isFieldTraversalZone(ticket.zone) ||
      (ticket.zone.fieldAction!.actionKind == FieldActionZoneKind.whirlpool
          ? ability != FieldAbility.whirlpool
          : ability != FieldAbility.waterfall) ||
      ticket.fieldAction.ability != ability ||
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
