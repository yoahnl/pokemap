import 'package:map_core/map_core.dart';

import 'field_ability_gate.dart';
import 'field_action.dart';
import 'field_obstacle_action.dart';
import 'spatial_npc_interaction.dart';
import 'spatial_field_obstacle_pose.dart';

final class SpatialFieldObstacleTicket {
  const SpatialFieldObstacleTicket._(
      {required this.instance,
      required this.entity,
      required this.modelInstance,
      required this.model,
      required this.x,
      required this.z,
      required this.facing,
      required this.playerPosition,
      required this.playerPixelPosition,
      required this.playerSpatialPosition,
      required this.issuedAtStateRevision,
      required this.obstaclePosition,
      required this.modelRuntimeState});

  final MapInstanceRef instance;
  final MapEntity entity;
  final SpatialModelInstance modelInstance;
  final ProjectModel3dEntry model;
  final double x, z;
  final EntityFacing facing;
  final GridPos playerPosition;
  final PixelOffset? playerPixelPosition;
  final PlayerSpatialPosition? playerSpatialPosition;
  final int issuedAtStateRevision;
  final GridPos? obstaclePosition;
  final SpatialModelRuntimeState? modelRuntimeState;
  String get entityId => entity.id;
  FieldObstacleKind get kind => entity.fieldObstacle!.kind;
}

MapEntity? findSpatialFieldObstacleTarget(
    {required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required double x,
    required double z,
    required EntityFacing facing,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider}) {
  final resources = models.toList();
  final scene = map.spatialScene;
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (scene == null || instance == null || map.id != gameState.currentMapId) {
    return null;
  }
  bool cleared(String? id) =>
      id != null &&
      gameState.mapInstanceWorldState.isFieldObstacleCleared(instance, id);
  final absentModels = <String, String>{
    for (final model in scene.instances)
      if (cleared(model.entityId) ||
          model.entityId != null &&
              !(entityIsPresent?.call(model.entityId!) ?? true))
        model.id: model.modelId,
  };
  final targetIds = <String>{
    for (final entity in map.entities)
      if (!cleared(entity.id) &&
          (entityIsPresent?.call(entity.id) ?? true) &&
          isValidSpatialFieldObstacle(map, entity) &&
          _isStaticLiveTarget(map, entity, gameState) &&
          _hasSupportedStrengthModel(map, entity, resources))
        entity.id,
  };
  final entityBlockers = [
    for (final entity in map.entities)
      if (entity.blocksMovement &&
          entity.kind != MapEntityKind.spawn &&
          (entityIsPresent?.call(entity.id) ?? true) &&
          !targetIds.contains(entity.id) &&
          !cleared(entity.id) &&
          !scene.instances.any((model) => model.entityId == entity.id))
        (
          x: ((actorStateProvider?.call(entity.id) ??
                          gameState.spatialWorldState
                              .actorState(map.id, entity.id))
                      ?.x ??
                  entity.pos.x + .5) -
              .5,
          z: ((actorStateProvider?.call(entity.id) ??
                          gameState.spatialWorldState
                              .actorState(map.id, entity.id))
                      ?.z ??
                  entity.pos.y + .5) -
              .5,
          width: entity.size.width,
          depth: entity.size.height,
        ),
  ];
  try {
    final hit = findSpatialModelInteraction(
        scene: scene,
        models: resources,
        instances: scene.instances
            .where((model) => targetIds.contains(model.entityId)),
        modelStateProvider: (id) {
          final saved = gameState.spatialWorldState.modelState(map.id, id);
          final absentModelId = absentModels[id];
          if (absentModelId == null) {
            final instance =
                scene.instances.singleWhere((entry) => entry.id == id);
            return spatialFieldObstacleModelPose(
                mapId: map.id,
                entity: map.entities
                    .where((entity) => entity.id == instance.entityId)
                    .firstOrNull,
                instance: instance,
                world: gameState.mapInstanceWorldState,
                baseState: saved);
          }
          return SpatialModelRuntimeState(
              modelId: absentModelId,
              animationIndex: null,
              normalizedTime: 0,
              blocksMovement: false);
        },
        additionalPositionBlocked: (px, pz) => entityBlockers.any((entity) =>
            px >= entity.x &&
            px < entity.x + entity.width &&
            pz >= entity.z &&
            pz < entity.z + entity.depth),
        x: x,
        z: z,
        facing: facing);
    if (hit == null) return null;
    final matches =
        map.entities.where((entity) => entity.id == hit.entityId).toList();
    return matches.length == 1 ? matches.single : null;
  } on Object {
    return null;
  }
}

FieldObstacleEvaluation evaluateSpatialFieldObstacleAttempt(
    {required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required String entityId,
    required double x,
    required double z,
    required EntityFacing facing,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider,
    ProjectSettings? projectSettings}) {
  if (map.spatialScene == null || map.version != ProjectVersion.v9) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.unsupportedMap);
  }
  if (map.id != gameState.currentMapId ||
      entityId.isEmpty ||
      entityId.trim() != entityId ||
      !x.isFinite ||
      !z.isFinite ||
      gameState.playerFacing != facing ||
      (gameState.playerSpatialPosition?.x ?? gameState.playerPosition.x + .5) !=
          x ||
      (gameState.playerSpatialPosition?.z ?? gameState.playerPosition.y + .5) !=
          z) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.invalidTarget);
  }
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (instance == null) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.missingMapInstance);
  }
  if (gameState.mapInstanceWorldState
      .isFieldObstacleCleared(instance, entityId)) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.alreadyCleared);
  }
  final target = findSpatialFieldObstacleTarget(
      map: map,
      gameState: gameState,
      models: models,
      x: x,
      z: z,
      facing: facing,
      actorStateProvider: actorStateProvider,
      entityIsPresent: entityIsPresent);
  if (target == null || target.id != entityId) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.invalidTarget);
  }
  final obstacle = target.fieldObstacle!;
  final gate = evaluateFieldAbilityGate(
      ability: obstacle.ability!,
      supportedAbilities: const {
        FieldAbility.cut,
        FieldAbility.rockSmash,
        FieldAbility.strength
      },
      unlockedFieldAbilities:
          gameState.progression.unlockedFieldAbilities.toSet(),
      party: gameState.party,
      projectSettings: projectSettings);
  return switch (gate.status) {
    FieldAbilityGateStatus.disabled =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.disabled),
    FieldAbilityGateStatus.missingMove =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.missingMove),
    FieldAbilityGateStatus.locked =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.locked),
    FieldAbilityGateStatus.unsupported =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.invalidTarget),
    FieldAbilityGateStatus.usable =>
      CanUseFieldObstacle(gate.partyIndex!, obstacle.kind),
  };
}

bool _hasSupportedStrengthModel(
    MapData map, MapEntity entity, List<ProjectModel3dEntry> models) {
  if (entity.fieldObstacle!.kind != FieldObstacleKind.strengthBoulder) {
    return true;
  }
  final instance = map.spatialScene!.instances
      .singleWhere((entry) => entry.entityId == entity.id);
  final matches =
      models.where((model) => model.id == instance.modelId).toList();
  return matches.length == 1 && matches.single.rampProfile == null;
}

bool _isStaticLiveTarget(MapData map, MapEntity entity, GameState gameState) {
  final model = map.spatialScene!.instances
      .singleWhere((model) => model.entityId == entity.id);
  final live = gameState.spatialWorldState.modelState(map.id, model.id);
  return live == null ||
      live.modelId == model.modelId &&
          live.blocksMovement &&
          live.animationIndex == null &&
          live.normalizedTime == 0 &&
          live.translationY == 0 &&
          (entity.fieldObstacle?.kind != FieldObstacleKind.strengthBoulder ||
              live.translationX == 0 && live.translationZ == 0);
}

SpatialFieldObstacleTicket? issueSpatialFieldObstacleTicket(
    {required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required String entityId,
    required double x,
    required double z,
    required EntityFacing facing,
    required int stateRevision,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider,
    ProjectSettings? projectSettings}) {
  final resources = models.toList();
  if (stateRevision < 0 ||
      evaluateSpatialFieldObstacleAttempt(
          map: map,
          gameState: gameState,
          models: resources,
          entityId: entityId,
          x: x,
          z: z,
          facing: facing,
          actorStateProvider: actorStateProvider,
          entityIsPresent: entityIsPresent,
          projectSettings: projectSettings) is! CanUseFieldObstacle) {
    return null;
  }
  final entity = map.entities.singleWhere((entity) => entity.id == entityId);
  final modelInstance = map.spatialScene!.instances
      .singleWhere((model) => model.entityId == entityId);
  final matching =
      resources.where((model) => model.id == modelInstance.modelId).toList();
  if (matching.length != 1) return null;
  return SpatialFieldObstacleTicket._(
      instance: gameState.mapInstanceWorldState.instanceRef(map.id)!,
      entity: entity,
      modelInstance: modelInstance,
      model: matching.single,
      x: x,
      z: z,
      facing: facing,
      playerPosition: gameState.playerPosition,
      playerPixelPosition: gameState.playerPixelPosition,
      playerSpatialPosition: gameState.playerSpatialPosition,
      issuedAtStateRevision: stateRevision,
      obstaclePosition: gameState.mapInstanceWorldState
          .fieldObstaclePositionForMap(map.id, entityId),
      modelRuntimeState:
          gameState.spatialWorldState.modelState(map.id, modelInstance.id));
}

FieldObstacleCommit commitSpatialDestructibleFieldObstacleAction(
    {required SpatialFieldObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required double x,
    required double z,
    required EntityFacing facing,
    required int currentStateRevision,
    required String confirmedEntityId,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider,
    ProjectSettings? projectSettings}) {
  if (ticket.kind != FieldObstacleKind.cutTree &&
      ticket.kind != FieldObstacleKind.rockSmashRock) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  return _commitSpatialFieldObstacle(
      ticket: ticket,
      map: map,
      gameState: gameState,
      models: models,
      x: x,
      z: z,
      facing: facing,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: confirmedEntityId,
      entityIsPresent: entityIsPresent,
      actorStateProvider: actorStateProvider,
      projectSettings: projectSettings,
      activateStrength: false);
}

FieldObstacleCommit commitSpatialStrengthActivation(
    {required SpatialFieldObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required double x,
    required double z,
    required EntityFacing facing,
    required int currentStateRevision,
    required String confirmedEntityId,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider,
    ProjectSettings? projectSettings}) {
  if (ticket.kind != FieldObstacleKind.strengthBoulder ||
      ticket.instance != gameState.mapInstanceWorldState.instanceRef(map.id) ||
      gameState.mapInstanceWorldState.isStrengthActive(ticket.instance)) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  return _commitSpatialFieldObstacle(
      ticket: ticket,
      map: map,
      gameState: gameState,
      models: models,
      x: x,
      z: z,
      facing: facing,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: confirmedEntityId,
      entityIsPresent: entityIsPresent,
      actorStateProvider: actorStateProvider,
      projectSettings: projectSettings,
      activateStrength: true);
}

FieldObstacleCommit _commitSpatialFieldObstacle(
    {required SpatialFieldObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required double x,
    required double z,
    required EntityFacing facing,
    required int currentStateRevision,
    required String confirmedEntityId,
    required bool activateStrength,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider,
    ProjectSettings? projectSettings}) {
  if (ticket.issuedAtStateRevision != currentStateRevision) {
    return const FieldObstacleRefused(FieldActionRefusal.staleStateRevision);
  }
  final resources = models.toList();
  final targets =
      map.entities.where((entity) => entity.id == ticket.entityId).toList();
  final bindings = map.spatialScene?.instances
      .where((model) => model.entityId == ticket.entityId)
      .toList();
  final matching =
      resources.where((model) => model.id == ticket.model.id).toList();
  if (ticket.entityId != confirmedEntityId ||
      ticket.instance.mapId != map.id ||
      ticket.instance != gameState.mapInstanceWorldState.instanceRef(map.id) ||
      ticket.x != x ||
      ticket.z != z ||
      ticket.facing != facing ||
      ticket.playerPosition != gameState.playerPosition ||
      ticket.playerPixelPosition != gameState.playerPixelPosition ||
      ticket.playerSpatialPosition != gameState.playerSpatialPosition ||
      ticket.kind == FieldObstacleKind.strengthBoulder &&
          (ticket.obstaclePosition !=
                  gameState.mapInstanceWorldState
                      .fieldObstaclePositionForMap(map.id, ticket.entityId) ||
              ticket.modelRuntimeState !=
                  gameState.spatialWorldState
                      .modelState(map.id, ticket.modelInstance.id)) ||
      targets.length != 1 ||
      targets.single != ticket.entity ||
      bindings == null ||
      bindings.length != 1 ||
      bindings.single != ticket.modelInstance ||
      matching.length != 1 ||
      matching.single != ticket.model) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  final evaluation = evaluateSpatialFieldObstacleAttempt(
      map: map,
      gameState: gameState,
      models: resources,
      entityId: ticket.entityId,
      x: x,
      z: z,
      facing: facing,
      actorStateProvider: actorStateProvider,
      entityIsPresent: entityIsPresent,
      projectSettings: projectSettings);
  if (evaluation is! CanUseFieldObstacle) {
    return FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: evaluation);
  }
  return FieldObstacleApplied(
      gameState.copyWith(
          mapInstanceWorldState: activateStrength
              ? gameState.mapInstanceWorldState
                  .activateStrength(ticket.instance)
              : gameState.mapInstanceWorldState.clearFieldObstacle(
                  ticket.instance, ticket.entityId,
                  resetPolicy: ticket.entity.fieldObstacle!.resetPolicy)),
      ticket.entityId);
}
