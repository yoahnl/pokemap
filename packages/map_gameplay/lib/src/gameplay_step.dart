import 'package:map_core/map_core.dart';

import 'collision/pixel_movement_resolver.dart';
import 'direction.dart';
import 'gameplay_hazard.dart';
import 'gameplay_intent.dart';
import 'movement_block_reason.dart';
import 'gameplay_step_result.dart';
import 'gameplay_world_state.dart';

GameplayStepResult stepGameplayWorld(
  GameplayWorldState world,
  GameplayIntent intent,
) {
  return switch (intent) {
    MoveIntent move => _resolveMove(world, move),
    InteractIntent() => _resolveInteract(world),
  };
}

/// Déplacement **réellement pixel-level** : [playerPositionPx] + résolveur séparé H/V.
GameplayStepResult _resolveMove(GameplayWorldState world, MoveIntent intent) {
  final direction = intent.direction;
  final step = intent.pixelsPerStep;
  final facingWorld = world.withPlayer(
    world.player.copyWith(facing: direction),
  );

  final feet = facingWorld.player.pos;
  final nextCellX = feet.x + direction.dx;
  final nextCellY = feet.y + direction.dy;
  final isOutOfBounds = nextCellX < 0 ||
      nextCellY < 0 ||
      nextCellX >= facingWorld.map.size.width ||
      nextCellY >= facingWorld.map.size.height;

  if (isOutOfBounds) {
    final connectionDirection = _connectionDirectionForMove(direction);
    final connection = findMapConnection(facingWorld.map, connectionDirection);
    if (connection == null) {
      return Blocked(
        facingWorld,
        reason: GameplayMovementBlockReason.outOfBounds,
      );
    }
    return ConnectionTriggered(
      facingWorld,
      TriggeredConnection(
        direction: connection.direction,
        targetMapId: connection.targetMapId,
        offset: connection.offset,
        sourcePos: facingWorld.player.pos,
      ),
    );
  }

  if (facingWorld.isWaterCell(nextCellX, nextCellY) &&
      facingWorld.player.movementMode != MovementMode.surf) {
    return Blocked(
      facingWorld,
      reason: GameplayMovementBlockReason.waterRequiresSurf,
    );
  }

  final dx = direction.dx * step;
  final dy = direction.dy * step;

  final resolvedTopLeft = PixelMovementResolverV1.resolveSeparateAxis(
    spriteTopLeftPx: facingWorld.player.playerPositionPx,
    deltaXPx: dx,
    deltaYPx: dy,
    spriteWidthPx: facingWorld.player.playerSpriteWidthPx,
    spriteHeightPx: facingWorld.player.playerSpriteHeightPx,
    worldStaticObstaclesCollidePixelRect:
        facingWorld.worldStaticObstaclesCollidePixelRect,
  );

  final unchanged =
      resolvedTopLeft.leftPx == facingWorld.player.playerPositionPx.leftPx &&
          resolvedTopLeft.topPx == facingWorld.player.playerPositionPx.topPx;

  if (unchanged) {
    final bumpWarp = facingWorld.warpOnBumpAt(nextCellX, nextCellY, direction);
    if (bumpWarp != null) {
      return WarpTriggered(
        facingWorld,
        TriggeredWarp(
          warpId: bumpWarp.id,
          targetMapId: bumpWarp.targetMapId,
          targetPos: bumpWarp.targetPos,
          triggerMode: bumpWarp.triggerMode,
        ),
      );
    }
    final bumpBehavior =
        facingWorld.placedElementBehaviorOnBumpAt(nextCellX, nextCellY);
    if (bumpBehavior != null) {
      return PlacedElementInteracted(
        facingWorld,
        bumpBehavior.element,
        bumpBehavior.behavior,
        MapPlacedElementTriggerType.onBump,
      );
    }
    final pathBumpSignal = _buildPathTriggerSignal(
      activation: facingWorld.pathAnimationRuleOnBumpAt(nextCellX, nextCellY),
      sourcePos: GridPos(x: nextCellX, y: nextCellY),
    );
    return Blocked(
      facingWorld,
      reason: GameplayMovementBlockReason.solid,
      pathAnimationSignals: pathBumpSignal == null
          ? const <PathAnimationSignal>[]
          : <PathAnimationSignal>[pathBumpSignal],
    );
  }

  final newGridPos = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
    playerCollisionRectPx:
        PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
      spriteTopLeftPx: resolvedTopLeft,
      spriteWidthPx: facingWorld.player.playerSpriteWidthPx,
      spriteHeightPx: facingWorld.player.playerSpriteHeightPx,
    ),
    tileWidthPx: facingWorld.tileWidthPx,
    tileHeightPx: facingWorld.tileHeightPx,
    mapWidthCells: facingWorld.map.size.width,
    mapHeightCells: facingWorld.map.size.height,
  );

  final movedWorld = facingWorld.withPlayer(
    facingWorld.player.copyWith(
      playerPositionPx: resolvedTopLeft,
      pos: newGridPos,
    ),
  );
  final previousPos = facingWorld.player.pos;
  final targetPos = movedWorld.player.pos;

  final warp = movedWorld.warpOnEnterAt(
    movedWorld.player.pos.x,
    movedWorld.player.pos.y,
    direction,
  );
  if (warp != null) {
    return WarpTriggered(
      movedWorld,
      TriggeredWarp(
        warpId: warp.id,
        targetMapId: warp.targetMapId,
        targetPos: warp.targetPos,
        triggerMode: warp.triggerMode,
      ),
    );
  }

  final pathSignals = _collectPathAnimationSignalsOnMove(
    world: movedWorld,
    previousPos: previousPos,
    targetPos: targetPos,
  );

  final movementBehavior = _resolveMovementTriggeredBehavior(
    world: movedWorld,
    targetX: movedWorld.player.pos.x,
    targetY: movedWorld.player.pos.y,
    previousPos: previousPos,
  );
  if (movementBehavior != null && movementBehavior is PlacedElementInteracted) {
    return PlacedElementInteracted(
      movementBehavior.world,
      movementBehavior.element,
      movementBehavior.behavior,
      movementBehavior.trigger,
      pathAnimationSignals: pathSignals,
    );
  }

  return Moved(
    movedWorld,
    hazardEffect: _resolveHazardEffectAt(movedWorld, targetPos),
    pathAnimationSignals: pathSignals,
  );
}

GameplayHazardEffect? _resolveHazardEffectAt(
  GameplayWorldState world,
  GridPos position,
) {
  MapGameplayZone? bestZone;
  for (final zone in world.map.gameplayZones) {
    if (zone.kind != GameplayZoneKind.hazard) continue;
    final hazard = zone.hazard;
    if (hazard == null || hazard.damagePerStep <= 0) continue;
    if (!_containsPos(zone.area, position)) continue;
    if (bestZone == null || zone.priority >= bestZone.priority) {
      bestZone = zone;
    }
  }

  if (bestZone == null) return null;
  final hazard = bestZone.hazard!;
  return GameplayHazardEffect(
    zoneId: bestZone.id,
    zoneName: bestZone.name,
    hazardKind: hazard.hazardKind,
    damagePerStep: hazard.damagePerStep,
    position: position,
    priority: bestZone.priority,
  );
}

bool _containsPos(MapRect rect, GridPos pos) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}

GameplayStepResult? _resolveMovementTriggeredBehavior({
  required GameplayWorldState world,
  required int targetX,
  required int targetY,
  required GridPos previousPos,
}) {
  for (final trigger in _movementTriggerPriority) {
    final activation = switch (trigger) {
      MapPlacedElementTriggerType.onEnter =>
        world.placedElementBehaviorOnEnterAt(targetX, targetY),
      MapPlacedElementTriggerType.onExit =>
        world.placedElementBehaviorOnExitTransition(
          from: previousPos,
          to: world.player.pos,
        ),
      MapPlacedElementTriggerType.onNear =>
        world.placedElementBehaviorOnNearTransition(
          from: previousPos,
          to: world.player.pos,
        ),
      _ => null,
    };
    if (activation == null) {
      continue;
    }
    if (!_passesBehaviorScopeForMovement(
      world: world,
      activation: activation,
      trigger: trigger,
      previousPos: previousPos,
    )) {
      continue;
    }
    return PlacedElementInteracted(
      world,
      activation.element,
      activation.behavior,
      trigger,
    );
  }
  return null;
}

const List<MapPlacedElementTriggerType> _movementTriggerPriority =
    <MapPlacedElementTriggerType>[
  MapPlacedElementTriggerType.onEnter,
  MapPlacedElementTriggerType.onExit,
  MapPlacedElementTriggerType.onNear,
];

MapConnectionDirection _connectionDirectionForMove(Direction direction) {
  return switch (direction) {
    Direction.north => MapConnectionDirection.north,
    Direction.south => MapConnectionDirection.south,
    Direction.east => MapConnectionDirection.east,
    Direction.west => MapConnectionDirection.west,
  };
}

GameplayStepResult _resolveInteract(GameplayWorldState world) {
  final facing = world.player.facing;
  final tx = world.player.pos.x + facing.dx;
  final ty = world.player.pos.y + facing.dy;
  final entity = world.entityAt(tx, ty);

  if (entity != null) {
    return switch (entity.kind) {
      MapEntityKind.npc => NpcInteracted(world, entity),
      MapEntityKind.sign => SignInteracted(world, entity),
      MapEntityKind.item => ItemInteracted(world, entity),
      _ => EntityInteracted(world, entity),
    };
  }

  final actionBehavior = world.placedElementBehaviorOnActionAt(tx, ty);
  if (actionBehavior != null &&
      _passesBehaviorScopeForAction(
        world: world,
        activation: actionBehavior,
      )) {
    return PlacedElementInteracted(
      world,
      actionBehavior.element,
      actionBehavior.behavior,
      MapPlacedElementTriggerType.onAction,
    );
  }

  final pathActionSignal = _buildPathTriggerSignal(
    activation: world.pathAnimationRuleOnActionAt(tx, ty),
    sourcePos: GridPos(x: tx, y: ty),
  );
  return NothingToInteract(
    world,
    pathAnimationSignals: pathActionSignal == null
        ? const <PathAnimationSignal>[]
        : <PathAnimationSignal>[pathActionSignal],
  );
}

List<PathAnimationSignal> _collectPathAnimationSignalsOnMove({
  required GameplayWorldState world,
  required GridPos previousPos,
  required GridPos targetPos,
}) {
  final signals = <PathAnimationSignal>[];

  final enterActivation = world.pathAnimationRuleOnEnterAt(
    targetPos.x,
    targetPos.y,
  );
  final previousEnterActivation = world.pathAnimationRuleOnEnterAt(
    previousPos.x,
    previousPos.y,
  );
  if (!_isSamePathAnimationRuleActivation(
    previousEnterActivation,
    enterActivation,
  )) {
    final signal = _buildPathTriggerSignal(
      activation: enterActivation,
      sourcePos: targetPos,
    );
    if (signal != null) {
      signals.add(signal);
    }
  }

  final stepSignal = _buildPathTriggerSignal(
    activation: world.pathAnimationRuleOnStepAt(targetPos.x, targetPos.y),
    sourcePos: targetPos,
  );
  if (stepSignal != null) {
    signals.add(stepSignal);
  }

  final nearActivation = world.pathAnimationRuleOnNearTransition(
    from: previousPos,
    to: targetPos,
  );
  final nearSignal = _buildPathTriggerSignal(
    activation: nearActivation,
    sourcePos: targetPos,
  );
  if (nearSignal != null) {
    signals.add(nearSignal);
  }

  final previousInsideActivation = world.pathAnimationRuleWhileInsideAt(
    previousPos.x,
    previousPos.y,
  );
  final currentInsideActivation = world.pathAnimationRuleWhileInsideAt(
    targetPos.x,
    targetPos.y,
  );
  if (!_isSamePathAnimationRuleActivation(
    previousInsideActivation,
    currentInsideActivation,
  )) {
    if (previousInsideActivation != null) {
      signals.add(
        _buildPathSetActiveSignal(
          activation: previousInsideActivation,
          sourcePos: previousPos,
          active: false,
        ),
      );
    }
    if (currentInsideActivation != null) {
      signals.add(
        _buildPathSetActiveSignal(
          activation: currentInsideActivation,
          sourcePos: targetPos,
          active: true,
        ),
      );
    }
  }

  return signals;
}

PathAnimationSignal? _buildPathTriggerSignal({
  required PathAnimationRuleActivation? activation,
  required GridPos sourcePos,
}) {
  if (activation == null) {
    return null;
  }
  return PathAnimationSignal(
    kind: PathAnimationSignalKind.trigger,
    layerId: activation.layerId,
    presetId: activation.presetId,
    ruleId: activation.ruleId,
    trigger: activation.rule.trigger,
    mode: activation.rule.mode,
    sourcePos: sourcePos,
    scope: activation.rule.scope,
  );
}

PathAnimationSignal _buildPathSetActiveSignal({
  required PathAnimationRuleActivation activation,
  required GridPos sourcePos,
  required bool active,
}) {
  return PathAnimationSignal(
    kind: PathAnimationSignalKind.setActive,
    layerId: activation.layerId,
    presetId: activation.presetId,
    ruleId: activation.ruleId,
    trigger: activation.rule.trigger,
    mode: activation.rule.mode,
    sourcePos: sourcePos,
    scope: activation.rule.scope,
    active: active,
  );
}

bool _passesBehaviorScopeForMovement({
  required GameplayWorldState world,
  required PlacedElementBehaviorActivation activation,
  required MapPlacedElementTriggerType trigger,
  required GridPos previousPos,
}) {
  final scope = activation.behavior.triggerScope;
  switch (scope) {
    case MapPlacedElementTriggerScope.defaultScope:
      return true;
    case MapPlacedElementTriggerScope.oncePerEnter:
      if (trigger != MapPlacedElementTriggerType.onEnter) {
        return true;
      }
      final previousActivation = world.placedElementBehaviorOnEnterAt(
        previousPos.x,
        previousPos.y,
      );
      return !_isSameBehaviorActivation(previousActivation, activation);
    case MapPlacedElementTriggerScope.whileInsideSingleShot:
      if (trigger == MapPlacedElementTriggerType.onEnter) {
        final previousActivation = world.placedElementBehaviorOnEnterAt(
          previousPos.x,
          previousPos.y,
        );
        return !_isSameBehaviorActivation(previousActivation, activation);
      }
      if (trigger == MapPlacedElementTriggerType.onNear) {
        final previousActivation = world.placedElementBehaviorOnNearAt(
          previousPos.x,
          previousPos.y,
        );
        return !_isSameBehaviorActivation(previousActivation, activation);
      }
      return true;
    case MapPlacedElementTriggerScope.facingOnly:
      if (trigger != MapPlacedElementTriggerType.onNear) {
        return true;
      }
      return world.isFacingPlacedElement(
        playerPos: world.player.pos,
        facing: world.player.facing,
        element: activation.element,
      );
    case MapPlacedElementTriggerScope.nearCardinalOnly:
      return true;
  }
}

bool _passesBehaviorScopeForAction({
  required GameplayWorldState world,
  required PlacedElementBehaviorActivation activation,
}) {
  final scope = activation.behavior.triggerScope;
  switch (scope) {
    case MapPlacedElementTriggerScope.defaultScope:
    case MapPlacedElementTriggerScope.oncePerEnter:
    case MapPlacedElementTriggerScope.whileInsideSingleShot:
    case MapPlacedElementTriggerScope.nearCardinalOnly:
      return true;
    case MapPlacedElementTriggerScope.facingOnly:
      return world.isFacingPlacedElement(
        playerPos: world.player.pos,
        facing: world.player.facing,
        element: activation.element,
      );
  }
}

bool _isSameBehaviorActivation(
  PlacedElementBehaviorActivation? a,
  PlacedElementBehaviorActivation? b,
) {
  if (a == null || b == null) {
    return false;
  }
  return a.element.id == b.element.id &&
      _behaviorIdentity(a.behavior) == _behaviorIdentity(b.behavior);
}

bool _isSamePathAnimationRuleActivation(
  PathAnimationRuleActivation? a,
  PathAnimationRuleActivation? b,
) {
  if (a == null || b == null) {
    return false;
  }
  return a.layerId == b.layerId && a.ruleId == b.ruleId;
}

String _behaviorIdentity(MapPlacedElementBehavior behavior) {
  final behaviorId = behavior.id.trim();
  if (behaviorId.isNotEmpty) {
    return behaviorId;
  }
  return '${behavior.trigger.name}:${behavior.effect.type.name}';
}
