import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'cut_obstacle_action.dart';
import 'field_action.dart';
import 'field_ability_gate.dart';
import 'gameplay_intent.dart';
import 'gameplay_movement_effect.dart';
import 'gameplay_step.dart';
import 'gameplay_step_result.dart';
import 'gameplay_world_state.dart';

enum FieldObstacleBlockReason {
  disabled,
  invalidTarget,
  unsupportedMap,
  missingMapInstance,
  alreadyCleared,
  missingMove,
  locked,
  inactiveStrength,
  blockedDestination,
}

sealed class FieldObstacleEvaluation {
  const FieldObstacleEvaluation();
}

final class CanUseFieldObstacle extends FieldObstacleEvaluation {
  const CanUseFieldObstacle(this.partyIndex, this.kind);
  final int partyIndex;
  final FieldObstacleKind kind;
}

final class FieldObstacleUnavailable extends FieldObstacleEvaluation {
  const FieldObstacleUnavailable(this.reason);
  final FieldObstacleBlockReason reason;
}

final class FieldObstacleTicket {
  const FieldObstacleTicket(
      {required this.fieldAction,
      required this.instance,
      required this.entityId,
      required this.playerPosition,
      required this.playerFacing,
      this.playerPixelPosition});
  final FieldActionTicket fieldAction;
  final MapInstanceRef instance;
  final String entityId;
  final GridPos playerPosition;
  final PixelOffset? playerPixelPosition;
  final EntityFacing playerFacing;
}

sealed class FieldObstacleCommit {
  const FieldObstacleCommit();
}

final class FieldObstacleApplied extends FieldObstacleCommit {
  const FieldObstacleApplied(this.gameState, this.entityId);
  final GameState gameState;
  final String entityId;
}

final class StrengthPushApplied extends FieldObstacleCommit {
  const StrengthPushApplied(this.gameState, this.movement, this.entityId,
      {this.slide});
  final GameState gameState;
  final GameplayStepResult movement;
  final String entityId;
  final FieldObstacleSlide? slide;
}

final class FieldObstacleSlide {
  const FieldObstacleSlide({
    required this.instance,
    required this.entityId,
    required this.direction,
    required this.expectedPosition,
    required this.remainingSteps,
  });

  final MapInstanceRef instance;
  final String entityId;
  final Direction direction;
  final GridPos expectedPosition;
  final int remainingSteps;
}

sealed class FieldObstacleSlideResult {
  const FieldObstacleSlideResult();
}

final class FieldObstacleSlideMoved extends FieldObstacleSlideResult {
  const FieldObstacleSlideMoved({
    required this.gameState,
    required this.world,
    required this.from,
    required this.to,
    required this.slide,
  });

  final GameState gameState;
  final GameplayWorldState world;
  final GridPos from;
  final GridPos to;
  final FieldObstacleSlide? slide;
}

final class FieldObstacleSlideStopped extends FieldObstacleSlideResult {
  const FieldObstacleSlideStopped({this.reason});
  final FieldObstacleBlockReason? reason;
}

final class FieldObstacleSlideRefused extends FieldObstacleSlideResult {
  const FieldObstacleSlideRefused(this.refusal);
  final FieldActionRefusal refusal;
}

final class FieldObstacleRefused extends FieldObstacleCommit {
  const FieldObstacleRefused(this.refusal, {this.evaluation});
  final FieldActionRefusal refusal;
  final FieldObstacleEvaluation? evaluation;
}

FieldObstacleEvaluation evaluateFieldObstacleAttempt(
    {required MapData map,
    required GameState gameState,
    required String entityId,
    ProjectSettings? projectSettings}) {
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.unsupportedMap);
  }
  if (map.id.isEmpty ||
      map.id != gameState.currentMapId ||
      entityId.isEmpty ||
      entityId.trim() != entityId) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.invalidTarget);
  }
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (instance == null) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.missingMapInstance);
  }
  final matches =
      map.entities.where((entity) => entity.id == entityId).toList();
  if (matches.length != 1) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.invalidTarget);
  }
  final entity = matches.single, obstacle = entity.fieldObstacle;
  final direction = gameState.playerFacing.asDirection;
  final front = GridPos(
      x: gameState.playerPosition.x + direction.dx,
      y: gameState.playerPosition.y + direction.dy);
  final savedPosition = gameState.mapInstanceWorldState
      .fieldObstaclePosition(instance, entity.id);
  bool inside(GridPos pos) =>
      pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x < map.size.width &&
      pos.y < map.size.height;
  if (obstacle == null ||
      entity.kind != MapEntityKind.custom ||
      !entity.blocksMovement ||
      entity.size.width != 1 ||
      entity.size.height != 1 ||
      entity.npc != null ||
      entity.sign != null ||
      entity.item != null ||
      entity.spawn != null ||
      entity.healingDisplay != null ||
      entity.pos != front ||
      !inside(entity.pos) ||
      !inside(gameState.playerPosition) ||
      (savedPosition != null &&
          (!obstacle.isPushable ||
              entity.pos != savedPosition)) ||
      map.entities
              .where((candidate) =>
                  resolveEntityCollisionCells(candidate).contains(entity.pos))
              .length !=
          1) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.invalidTarget);
  }
  if (gameState.mapInstanceWorldState
      .isFieldObstacleCleared(instance, entityId)) {
    return const FieldObstacleUnavailable(
        FieldObstacleBlockReason.alreadyCleared);
  }
  final ability = obstacle.ability;
  if (ability == null) {
    return const FieldObstacleUnavailable(FieldObstacleBlockReason.invalidTarget);
  }
  final gate = evaluateFieldAbilityGate(
      ability: ability,
      supportedAbilities: const {
        FieldAbility.cut,
        FieldAbility.strength,
        FieldAbility.rockSmash
      },
      unlockedFieldAbilities:
          gameState.progression.unlockedFieldAbilities.toSet(),
      party: gameState.party,
      projectSettings: projectSettings);
  return switch (gate.status) {
    FieldAbilityGateStatus.disabled =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.disabled),
    FieldAbilityGateStatus.unsupported =>
      throw StateError('Unsupported field obstacle ability.'),
    FieldAbilityGateStatus.missingMove =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.missingMove),
    FieldAbilityGateStatus.locked =>
      const FieldObstacleUnavailable(FieldObstacleBlockReason.locked),
    FieldAbilityGateStatus.usable =>
      CanUseFieldObstacle(gate.partyIndex!, obstacle.kind),
  };
}

FieldObstacleRefused? _revalidate(
    {required FieldObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
    required String confirmedEntityId,
    MapData? authoringMap,
    ProjectManifest? project,
    GameplayWorldState? collisionWorld}) {
  if (ticket.fieldAction.issuedAtStateRevision != currentStateRevision) {
    return const FieldObstacleRefused(FieldActionRefusal.staleStateRevision);
  }
  if (ticket.entityId != confirmedEntityId ||
      ticket.instance.mapId != map.id ||
      ticket.instance != gameState.mapInstanceWorldState.instanceRef(map.id) ||
      ticket.playerPosition != gameState.playerPosition ||
      ticket.playerPixelPosition != gameState.playerPixelPosition ||
      ticket.playerFacing != gameState.playerFacing ||
      !map.entities.any((entity) =>
          entity.id == ticket.entityId &&
          entity.pos == ticket.fieldAction.targetCell &&
          entity.fieldObstacle?.ability == ticket.fieldAction.ability)) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  if (collisionWorld != null &&
      collisionWorld
              .entityAt(ticket.fieldAction.targetCell.x,
                  ticket.fieldAction.targetCell.y)
              ?.id !=
          ticket.entityId) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  try {
    applyFieldObstacleWorldStateToMap(
        map: map,
        authoringMap: authoringMap,
        instances: gameState.mapInstanceWorldState,
        movingPlatformWorldState: gameState.movingPlatformWorldState,
        movingPropWorldState: gameState.movingPropWorldState,
        instance: ticket.instance,
        project: project,
        npcMapPresencePredicate: collisionWorld?.npcMapPresencePredicate,
        mapEntityPresencePredicate: collisionWorld?.mapEntityPresencePredicate);
  } on Object {
    return const FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation:
            FieldObstacleUnavailable(FieldObstacleBlockReason.invalidTarget));
  }
  final evaluation = evaluateFieldObstacleAttempt(
      map: map, gameState: gameState, entityId: ticket.entityId,
      projectSettings: project?.settings);
  if (evaluation is! CanUseFieldObstacle) {
    return FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: evaluation);
  }
  return null;
}

FieldObstacleCommit commitDestructibleFieldObstacleAction(
    {required FieldObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
    required String confirmedEntityId,
    MapData? authoringMap,
    ProjectManifest? project,
    GameplayWorldState? collisionWorld}) {
  final refusal = _revalidate(
      ticket: ticket,
      map: map,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: confirmedEntityId,
      authoringMap: authoringMap,
      project: project,
      collisionWorld: collisionWorld);
  if (refusal != null) return refusal;
  if (ticket.fieldAction.ability != FieldAbility.cut &&
      ticket.fieldAction.ability != FieldAbility.rockSmash) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  return FieldObstacleApplied(
      gameState.copyWith(
          mapInstanceWorldState: gameState.mapInstanceWorldState
              .clearFieldObstacle(ticket.instance, ticket.entityId)),
      ticket.entityId);
}

FieldObstacleCommit commitStrengthActivation(
    {required FieldObstacleTicket ticket,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
    required String confirmedEntityId,
    MapData? authoringMap,
    ProjectManifest? project,
    GameplayWorldState? collisionWorld}) {
  final refusal = _revalidate(
      ticket: ticket,
      map: map,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: confirmedEntityId,
      authoringMap: authoringMap,
      project: project,
      collisionWorld: collisionWorld);
  if (refusal != null) return refusal;
  if (ticket.fieldAction.ability != FieldAbility.strength) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  return FieldObstacleApplied(
      gameState.copyWith(
          mapInstanceWorldState: gameState.mapInstanceWorldState
              .activateStrength(ticket.instance)),
      ticket.entityId);
}

FieldObstacleCommit commitStrengthPush(
    {required FieldObstacleTicket ticket,
    required GameplayWorldState world,
    required GameState gameState,
    required int currentStateRevision,
    MapData? authoringMap,
    ProjectManifest? project,
    Iterable<PixelRect> characterReservations = const []}) {
  final refusal = _revalidate(
      ticket: ticket,
      map: world.map,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: ticket.entityId,
      authoringMap: authoringMap,
      project: project,
      collisionWorld: world);
  if (refusal != null) return refusal;
  if (ticket.fieldAction.ability != FieldAbility.strength ||
      world.player.pos != gameState.playerPosition ||
      world.player.facing.asFacing != gameState.playerFacing ||
      world.player.movementMode != MovementMode.walk ||
      (gameState.playerPixelPosition != null &&
          gameState.playerPixelPosition !=
              PixelOffset(
                  x: world.player.playerPositionPx.leftPx,
                  y: world.player.playerPositionPx.topPx))) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  if (!gameState.mapInstanceWorldState.isStrengthActive(ticket.instance)) {
    return const FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: FieldObstacleUnavailable(
            FieldObstacleBlockReason.inactiveStrength));
  }
  final direction = world.player.facing, source = ticket.fieldAction.targetCell;
  final target =
      GridPos(x: source.x + direction.dx, y: source.y + direction.dy);
  final rect = PixelRect(
      leftPx: target.x * world.tileWidthPx,
      topPx: target.y * world.tileHeightPx,
      widthPx: world.tileWidthPx,
      heightPx: world.tileHeightPx);
  final reservations = characterReservations.toList(growable: false);
  if (target.x < 0 ||
      target.y < 0 ||
      target.x >= world.map.size.width ||
      target.y >= world.map.size.height ||
      world.isWaterCell(target.x, target.y) ||
      world.worldStaticObstaclesCollidePixelRect(rect) ||
      reservations.any((other) => _overlap(rect, other))) {
    return const FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: FieldObstacleUnavailable(
            FieldObstacleBlockReason.blockedDestination));
  }
  final candidate = world.withEntityPosition(ticket.entityId, target);
  final movement = stepGameplayWorld(
      candidate,
      MoveIntent(direction,
          pixelsPerStep:
              direction.dx == 0 ? world.tileHeightPx : world.tileWidthPx),
      characterReservations: reservations);
  if ((movement is! Moved &&
          movement is! WarpTriggered &&
          movement is! PlacedElementInteracted) ||
      movement.world.player.pos != source) {
    return const FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: FieldObstacleUnavailable(
            FieldObstacleBlockReason.blockedDestination));
  }
  final player = movement.world.player;
  return StrengthPushApplied(
      gameState.copyWith(
          playerPosition: player.pos,
          playerPixelPosition: PixelOffset(
              x: player.playerPositionPx.leftPx,
              y: player.playerPositionPx.topPx),
          mapInstanceWorldState: gameState.mapInstanceWorldState
              .moveFieldObstacle(ticket.instance, ticket.entityId, target)),
      movement,
      ticket.entityId,
      slide: resolveGameplaySlideEffectAt(world.map, target, direction) == null
          ? null
          : FieldObstacleSlide(
              instance: ticket.instance,
              entityId: ticket.entityId,
              direction: direction,
              expectedPosition: target,
              remainingSteps: (direction.dx == 0
                      ? world.map.size.height
                      : world.map.size.width) -
                  1));
}

FieldObstacleSlideResult stepFieldObstacleSlide({
  required FieldObstacleSlide slide,
  required GameplayWorldState world,
  required GameState gameState,
  MapData? authoringMap,
  ProjectManifest? project,
  Iterable<PixelRect> characterReservations = const [],
}) {
  final map = world.map;
  final extent = slide.direction.dx == 0 ? map.size.height : map.size.width;
  final source = slide.expectedPosition;
  final matches =
      map.entities.where((entity) => entity.id == slide.entityId).toList();
  if (map.spatialScene != null ||
      map.version == ProjectVersion.v9 ||
      map.id != gameState.currentMapId ||
      map.id != slide.instance.mapId ||
      gameState.mapInstanceWorldState.instanceRef(map.id) != slide.instance ||
      slide.entityId.isEmpty ||
      slide.entityId.trim() != slide.entityId ||
      slide.remainingSteps < 0 ||
      slide.remainingSteps >= extent ||
      source.x < 0 ||
      source.y < 0 ||
      source.x >= map.size.width ||
      source.y >= map.size.height ||
      matches.length != 1 ||
      matches.single.pos != source ||
      matches.single.fieldObstacle?.isPushable != true ||
      matches.single.kind != MapEntityKind.custom ||
      !matches.single.blocksMovement ||
      matches.single.size != const GridSize(width: 1, height: 1) ||
      world.entityAt(source.x, source.y)?.id != slide.entityId ||
      world.player.pos != gameState.playerPosition ||
      world.player.facing.asFacing != gameState.playerFacing ||
      world.player.facing != slide.direction ||
      world.player.movementMode != MovementMode.walk ||
      (gameState.playerPixelPosition != null &&
          gameState.playerPixelPosition !=
              PixelOffset(
                  x: world.player.playerPositionPx.leftPx,
                  y: world.player.playerPositionPx.topPx))) {
    return const FieldObstacleSlideRefused(FieldActionRefusal.targetChanged);
  }
  if (gameState.mapInstanceWorldState
          .isFieldObstacleCleared(slide.instance, slide.entityId) ||
      gameState.mapInstanceWorldState
              .fieldObstaclePosition(slide.instance, slide.entityId) !=
          source ||
      (matches.single.fieldObstacle!.kind == FieldObstacleKind.strengthBoulder &&
          (!gameState.mapInstanceWorldState.isStrengthActive(slide.instance) ||
          evaluateFieldAbilityGate(
                  ability: FieldAbility.strength,
                  supportedAbilities: const {FieldAbility.strength},
                  unlockedFieldAbilities:
                      gameState.progression.unlockedFieldAbilities.toSet(),
                  party: gameState.party,
                  projectSettings: project?.settings)
              .status !=
          FieldAbilityGateStatus.usable))) {
    return const FieldObstacleSlideRefused(
        FieldActionRefusal.noLongerAvailable);
  }
  try {
    applyFieldObstacleWorldStateToMap(
        map: map,
        authoringMap: authoringMap,
        instances: gameState.mapInstanceWorldState,
        instance: slide.instance,
        project: project,
        movingPlatformWorldState: gameState.movingPlatformWorldState,
        movingPropWorldState: gameState.movingPropWorldState,
        npcMapPresencePredicate: world.npcMapPresencePredicate,
        mapEntityPresencePredicate: world.mapEntityPresencePredicate);
  } on Object {
    return const FieldObstacleSlideRefused(
        FieldActionRefusal.noLongerAvailable);
  }
  if (slide.remainingSteps == 0 ||
      resolveGameplaySlideEffectAt(map, source, slide.direction) == null) {
    return const FieldObstacleSlideStopped();
  }
  final target = GridPos(
      x: source.x + slide.direction.dx, y: source.y + slide.direction.dy);
  final rect = PixelRect(
      leftPx: target.x * world.tileWidthPx,
      topPx: target.y * world.tileHeightPx,
      widthPx: world.tileWidthPx,
      heightPx: world.tileHeightPx);
  if (target.x < 0 ||
      target.y < 0 ||
      target.x >= map.size.width ||
      target.y >= map.size.height ||
      world.isWaterCell(target.x, target.y) ||
      world.worldStaticObstaclesCollidePixelRect(rect) ||
      _overlap(rect, world.player.playerCollisionRectPx) ||
      characterReservations.any((reservation) => _overlap(rect, reservation))) {
    return const FieldObstacleSlideStopped(
        reason: FieldObstacleBlockReason.blockedDestination);
  }
  final moved = world.withEntityPosition(slide.entityId, target);
  final remaining = slide.remainingSteps - 1;
  return FieldObstacleSlideMoved(
    gameState: gameState.copyWith(
        mapInstanceWorldState: gameState.mapInstanceWorldState
            .moveFieldObstacle(slide.instance, slide.entityId, target)),
    world: moved,
    from: source,
    to: target,
    slide: remaining == 0 ||
            resolveGameplaySlideEffectAt(map, target, slide.direction) == null
        ? null
        : FieldObstacleSlide(
            instance: slide.instance,
            entityId: slide.entityId,
            direction: slide.direction,
            expectedPosition: target,
            remainingSteps: remaining),
  );
}

bool _overlap(PixelRect a, PixelRect b) =>
    a.leftPx < b.leftPx + b.widthPx &&
    a.leftPx + a.widthPx > b.leftPx &&
    a.topPx < b.topPx + b.heightPx &&
    a.topPx + a.heightPx > b.topPx;
