import 'package:map_core/map_core.dart';

import 'field_ability_gate.dart';
import 'field_action.dart';
import 'field_traversal_action.dart';
import 'field_traversal_geometry.dart';
import 'spatial_field_obstacle_pose.dart';
import 'spatial_movement_controller.dart';
import 'spatial_surf_water.dart';

final class SpatialFieldTraversalTicket {
  SpatialFieldTraversalTicket._({
    required this.map,
    required this.zone,
    required this.ability,
    required this.entryState,
    required this.instance,
    required List<GridPos> route,
    required this.issuedAtStateRevision,
  }) : route = List.unmodifiable(route);

  final MapData map;
  final MapGameplayZone zone;
  final FieldAbility ability;
  final GameState entryState;
  final MapInstanceRef instance;
  final List<GridPos> route;
  final int issuedAtStateRevision;
}

final class SpatialFieldTraversalStep {
  const SpatialFieldTraversalStep._({
    required this.ticket,
    required this.routeIndex,
    required this.from,
    required this.to,
    required this.fromGroundY,
    required this.toGroundY,
    required this.issuedAtStateRevision,
    required GameState sourceGameState,
  }) : _sourceGameState = sourceGameState;

  final SpatialFieldTraversalTicket ticket;
  final int routeIndex;
  final PlayerSpatialPosition from, to;
  final double fromGroundY, toGroundY;
  final int issuedAtStateRevision;
  final GameState _sourceGameState;

  MapData get map => ticket.map;
  MapGameplayZone get zone => ticket.zone;
  FieldAbility get ability => ticket.ability;
  MapInstanceRef get instance => ticket.instance;

  bool permits(
      MapData map, double fromX, double fromZ, double toX, double toZ) {
    if (map != this.map ||
        findGameplayZoneById(map, zone.id) != zone ||
        !fromX.isFinite ||
        !fromZ.isFinite ||
        !toX.isFinite ||
        !toZ.isFinite) {
      return false;
    }
    final dx = to.x - from.x, dz = to.z - from.z;
    double progress(double x, double z) =>
        (x - from.x) * dx + (z - from.z) * dz;
    bool onSegment(double x, double z) =>
        ((x - from.x) * dz - (z - from.z) * dx).abs() <= 1e-9 &&
        progress(x, z) >= -1e-9 &&
        progress(x, z) <= 1 + 1e-9;
    return onSegment(fromX, fromZ) &&
        onSegment(toX, toZ) &&
        progress(toX, toZ) + 1e-9 >= progress(fromX, fromZ);
  }

  double groundYAt(double x, double z) {
    if (!x.isFinite || !z.isFinite) {
      throw ArgumentError('Invalid traversal pose.');
    }
    if (ability == FieldAbility.whirlpool) {
      return map.spatialScene!.worldHeightAt(x, z);
    }
    final t = ((x - from.x) * (to.x - from.x) + (z - from.z) * (to.z - from.z))
        .clamp(0.0, 1.0);
    return fromGroundY + (toGroundY - fromGroundY) * t;
  }
}

sealed class SpatialFieldTraversalCommit {
  const SpatialFieldTraversalCommit();
}

final class SpatialFieldTraversalApplied extends SpatialFieldTraversalCommit {
  const SpatialFieldTraversalApplied(this.gameState);
  final GameState gameState;
}

final class SpatialFieldTraversalRefused extends SpatialFieldTraversalCommit {
  const SpatialFieldTraversalRefused(this.refusal);
  final FieldActionRefusal refusal;
}

FieldTraversalEvaluation evaluateSpatialFieldTraversalAttempt({
  required FieldAbility ability,
  required MapData map,
  required GameState gameState,
  required Iterable<ProjectModel3dEntry> models,
  required String zoneId,
  ProjectSettings? projectSettings,
  bool Function(String)? entityIsPresent,
  SpatialActorRuntimeState? Function(String)? actorStateProvider,
}) {
  final evaluation =
      _evaluateEntry(ability, map, gameState, zoneId, projectSettings);
  if (evaluation.reason != null) return evaluation;
  final issued = issueSpatialFieldTraversalTicket(
      ability: ability,
      map: map,
      gameState: gameState,
      models: models,
      zoneId: zoneId,
      stateRevision: 0,
      projectSettings: projectSettings,
      entityIsPresent: entityIsPresent,
      actorStateProvider: actorStateProvider);
  return issued == null
      ? const FieldTraversalEvaluation.unavailable(
          FieldTraversalBlockReason.obstructed)
      : evaluation;
}

SpatialFieldTraversalTicket? issueSpatialFieldTraversalTicket({
  required FieldAbility ability,
  required MapData map,
  required GameState gameState,
  required Iterable<ProjectModel3dEntry> models,
  required String zoneId,
  required int stateRevision,
  ProjectSettings? projectSettings,
  bool Function(String)? entityIsPresent,
  SpatialActorRuntimeState? Function(String)? actorStateProvider,
}) {
  if (stateRevision < 0 ||
      _evaluateEntry(ability, map, gameState, zoneId, projectSettings).reason !=
          null) {
    return null;
  }
  final zone = findGameplayZoneById(map, zoneId)!;
  final issued = SpatialFieldTraversalTicket._(
      map: map,
      zone: zone,
      ability: ability,
      entryState: gameState,
      instance: gameState.mapInstanceWorldState.instanceRef(map.id)!,
      route: fieldTraversalRouteCells(zone),
      issuedAtStateRevision: stateRevision);
  final resources = models.toList(growable: false);
  var trial = gameState;
  for (var index = 0; index < issued.route.length - 1; index++) {
    final step = planSpatialFieldTraversalStep(
        ticket: issued,
        map: map,
        gameState: trial,
        models: resources,
        routeIndex: index,
        currentStateRevision: stateRevision,
        projectSettings: projectSettings,
        entityIsPresent: entityIsPresent,
        actorStateProvider: actorStateProvider);
    if (step == null) return null;
    trial = _atStepEnd(trial, step, projectSettings);
  }
  return issued;
}

SpatialFieldTraversalStep? planSpatialFieldTraversalStep({
  required SpatialFieldTraversalTicket ticket,
  required MapData map,
  required GameState gameState,
  required Iterable<ProjectModel3dEntry> models,
  required int routeIndex,
  required int currentStateRevision,
  ProjectSettings? projectSettings,
  bool Function(String)? entityIsPresent,
  SpatialActorRuntimeState? Function(String)? actorStateProvider,
}) {
  if (map != ticket.map ||
      currentStateRevision < ticket.issuedAtStateRevision ||
      routeIndex < 0 ||
      routeIndex >= ticket.route.length - 1 ||
      routeIndex == 0 && currentStateRevision != ticket.issuedAtStateRevision ||
      gameState.currentMapId != map.id ||
      gameState.mapInstanceWorldState.instanceRef(map.id) != ticket.instance ||
      findGameplayZoneById(map, ticket.zone.id) != ticket.zone ||
      gameState.playerFacing != fieldTraversalFacing(ticket.zone) ||
      gameState.playerMovementMode != ticket.entryState.playerMovementMode ||
      routeIndex == 0 &&
          gameState.playerPixelPosition !=
              ticket.entryState.playerPixelPosition ||
      _gate(ticket.ability, gameState, projectSettings).reason != null) {
    return null;
  }
  final cell = ticket.route[routeIndex], next = ticket.route[routeIndex + 1];
  final from = PlayerSpatialPosition(x: cell.x + .5, z: cell.y + .5);
  final to = PlayerSpatialPosition(x: next.x + .5, z: next.y + .5);
  if (gameState.playerPosition != cell ||
      gameState.playerSpatialPosition != from) {
    return null;
  }
  try {
    final scene = map.spatialScene!;
    final step = SpatialFieldTraversalStep._(
        ticket: ticket,
        routeIndex: routeIndex,
        from: from,
        to: to,
        fromGroundY: scene.worldHeightAt(from.x, from.z),
        toGroundY: scene.worldHeightAt(to.x, to.z),
        issuedAtStateRevision: currentStateRevision,
        sourceGameState: gameState);
    final controller = _controller(
        map, gameState, models, entityIsPresent, actorStateProvider);
    if (!controller.canTraverseActor(from.x, from.z, to.x, to.z,
        fieldTraversalStep: step)) {
      return null;
    }
    return step;
  } on Object {
    return null;
  }
}

SpatialFieldTraversalCommit commitSpatialFieldTraversalStep({
  required SpatialFieldTraversalStep step,
  required MapData map,
  required GameState gameState,
  required Iterable<ProjectModel3dEntry> models,
  required int currentStateRevision,
  ProjectSettings? projectSettings,
  bool Function(String)? entityIsPresent,
  SpatialActorRuntimeState? Function(String)? actorStateProvider,
}) {
  if (currentStateRevision != step.issuedAtStateRevision) {
    return const SpatialFieldTraversalRefused(
        FieldActionRefusal.staleStateRevision);
  }
  final source = step._sourceGameState;
  if (map != step.map ||
      gameState.currentMapId != source.currentMapId ||
      gameState.playerPosition != source.playerPosition ||
      gameState.playerPixelPosition != source.playerPixelPosition ||
      gameState.playerSpatialPosition != source.playerSpatialPosition ||
      gameState.playerFacing != source.playerFacing ||
      gameState.playerMovementMode != source.playerMovementMode ||
      gameState.mapInstanceWorldState.instanceRef(map.id) != step.instance) {
    return const SpatialFieldTraversalRefused(FieldActionRefusal.targetChanged);
  }
  final fresh = planSpatialFieldTraversalStep(
      ticket: step.ticket,
      map: map,
      gameState: gameState,
      models: models,
      routeIndex: step.routeIndex,
      currentStateRevision: currentStateRevision,
      projectSettings: projectSettings,
      entityIsPresent: entityIsPresent,
      actorStateProvider: actorStateProvider);
  if (fresh == null) {
    return const SpatialFieldTraversalRefused(
        FieldActionRefusal.noLongerAvailable);
  }
  return SpatialFieldTraversalApplied(
      _atStepEnd(gameState, step, projectSettings));
}

FieldTraversalEvaluation _evaluateEntry(FieldAbility ability, MapData map,
    GameState state, String zoneId, ProjectSettings? settings) {
  if (map.spatialScene == null) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.unsupportedMap);
  }
  final zones = map.gameplayZones.where((zone) => zone.id == zoneId).toList();
  if (map.id != state.currentMapId ||
      zones.length != 1 ||
      !isFieldTraversalZone(zones.single) ||
      (zones.single.fieldAction!.actionKind == FieldActionZoneKind.waterfall
          ? ability != FieldAbility.waterfall
          : ability != FieldAbility.whirlpool) ||
      state.mapInstanceWorldState.instanceRef(map.id) == null) {
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
  final route = fieldTraversalRouteCells(zone), scene = map.spatialScene!;
  if (scene.width != map.size.width ||
      scene.depth != map.size.height ||
      route.any((cell) =>
          cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= scene.width ||
          cell.y >= scene.depth) ||
      state.playerPosition != route.first ||
      state.playerSpatialPosition !=
          PlayerSpatialPosition(x: route.first.x + .5, z: route.first.y + .5)) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.invalidTarget);
  }
  if (state.playerFacing != fieldTraversalFacing(zone)) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.wrongDirection);
  }
  if (fieldTraversalRequiresSurf(zone) &&
      state.playerMovementMode != MovementMode.surf) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.requiresSurf);
  }
  final gate = _gate(ability, state, settings);
  if (gate.reason != null) return gate;
  if (!_routeWaterValid(map, zone)) {
    return const FieldTraversalEvaluation.unavailable(
        FieldTraversalBlockReason.requiresWater);
  }
  return FieldTraversalEvaluation.usable(
      gate.partyIndex, List.unmodifiable(route.skip(1)));
}

FieldTraversalEvaluation _gate(
    FieldAbility ability, GameState state, ProjectSettings? settings) {
  final gate = evaluateFieldAbilityGate(
      ability: ability,
      supportedAbilities: const {
        FieldAbility.waterfall,
        FieldAbility.whirlpool
      },
      unlockedFieldAbilities: state.progression.unlockedFieldAbilities.toSet(),
      party: state.party,
      projectSettings: settings);
  final reason = switch (gate.status) {
    FieldAbilityGateStatus.usable => null,
    FieldAbilityGateStatus.disabled => FieldTraversalBlockReason.disabled,
    FieldAbilityGateStatus.missingMove => FieldTraversalBlockReason.missingMove,
    FieldAbilityGateStatus.locked => FieldTraversalBlockReason.locked,
    FieldAbilityGateStatus.unsupported =>
      FieldTraversalBlockReason.invalidTarget,
  };
  return reason == null
      ? FieldTraversalEvaluation.usable(gate.partyIndex, const [])
      : FieldTraversalEvaluation.unavailable(reason);
}

bool _routeWaterValid(MapData map, MapGameplayZone zone) {
  if (!fieldTraversalRequiresSurf(zone)) return true;
  final water = SpatialSurfWater.fromMap(map);
  return fieldTraversalRouteCells(zone)
      .every((cell) => water.contains(cell.x + .5, cell.y + .5));
}

GameState _atStepEnd(GameState state, SpatialFieldTraversalStep step,
    ProjectSettings? settings) {
  final dx = step.to.x - step.from.x, dz = step.to.z - step.from.z;
  return state.copyWith(
      playerPosition: step.ticket.route[step.routeIndex + 1],
      playerSpatialPosition: step.to,
      playerPixelPosition: state.playerPixelPosition == null
          ? null
          : PixelOffset(
              x: state.playerPixelPosition!.x +
                  (dx * (settings?.tileWidth ?? 16)).round(),
              y: state.playerPixelPosition!.y +
                  (dz * (settings?.tileHeight ?? 16)).round()));
}

SpatialMovementController _controller(
    MapData map,
    GameState state,
    Iterable<ProjectModel3dEntry> models,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider) {
  final world = state.mapInstanceWorldState;
  final scope = world.instanceRef(map.id)!;
  final instances = {
    for (final instance in map.spatialScene!.instances) instance.id: instance
  };
  final entities = {for (final entity in map.entities) entity.id: entity};
  return SpatialMovementController.fromMap(
      map: map,
      models: models,
      spatialArrival: state.playerSpatialPosition,
      facing: state.playerFacing,
      validateSpawn: false,
      initialMovementMode: state.playerMovementMode,
      entityPresencePredicate: (entity) =>
          !world.isFieldObstacleCleared(scope, entity.id) &&
          (entityIsPresent?.call(entity.id) ?? true),
      entityProjection: (entity) {
        final position = world.fieldObstaclePositionForMap(map.id, entity.id);
        return position == null ? entity : entity.copyWith(pos: position);
      },
      modelStateProvider: (id) => spatialFieldObstacleModelPose(
          mapId: map.id,
          entity: entities[instances[id]!.entityId],
          instance: instances[id]!,
          world: world,
          baseState: state.spatialWorldState.modelState(map.id, id)),
      actorStateProvider: (id) =>
          actorStateProvider?.call(id) ??
          state.spatialWorldState.actorState(map.id, id));
}
