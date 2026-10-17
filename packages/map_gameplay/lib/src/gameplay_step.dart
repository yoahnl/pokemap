import 'package:map_core/map_core.dart';
import 'movement_terrain_policy.dart';
import 'moving_platform_gameplay.dart';

import 'collision/pixel_movement_resolver.dart';
import 'collision/border_collision_geometry.dart';
import 'directed_jump_plan.dart';
import 'direction.dart';
import 'gameplay_hazard.dart';
import 'gameplay_intent.dart';
import 'movement_block_reason.dart';
import 'gameplay_step_result.dart';
import 'gameplay_world_state.dart';

GameplayStepResult stepGameplayWorld(
    GameplayWorldState world, GameplayIntent intent,
    {Iterable<PixelRect> characterReservations = const []}) {
  return switch (intent) {
    MoveIntent move => _resolveMove(world, move, characterReservations),
    InteractIntent() => _resolveInteract(world),
  };
}

GameplayEntityBumpContact? resolvePlayerEntityBumpContact(
  GameplayWorldState world,
  Direction direction, {
  int attemptedPixelsPerStep = 1,
  Iterable<PixelRect> characterReservations = const [],
}) {
  final player = world.player;
  final maxStep = direction.dx == 0 ? world.tileHeightPx : world.tileWidthPx;
  final next = GridPos(
    x: player.pos.x + direction.dx,
    y: player.pos.y + direction.dy,
  );
  if (attemptedPixelsPerStep < 1 ||
      attemptedPixelsPerStep > maxStep ||
      world.map.spatialScene != null ||
      world.map.version == ProjectVersion.v9 ||
      player.playerSpriteWidthPx <= 0 ||
      player.playerSpriteHeightPx <= 0 ||
      world.map.id.isEmpty ||
      world.map.id.trim() != world.map.id ||
      next.x < 0 ||
      next.y < 0 ||
      next.x >= world.map.size.width ||
      next.y >= world.map.size.height ||
      movementTerrainBlockReasonAt(
              map: world.map,
              x: next.x,
              y: next.y,
              mode: player.movementMode) !=
          null) {
    return null;
  }
  bool inside(PixelRect rect) => rect.widthPx > 0 && rect.heightPx > 0 &&
      rect.leftPx >= 0 && rect.topPx >= 0 &&
      rect.leftPx + rect.widthPx <= world.map.size.width * world.tileWidthPx &&
      rect.topPx + rect.heightPx <= world.map.size.height * world.tileHeightPx;
  final currentRect = player.playerCollisionRectPx;
  if (!inside(currentRect) ||
      !inside(world.playerCharacterContactRect(currentRect)) ||
      PlayerCollisionConventionsV1.projectFeetAnchorToCell(
        playerCollisionRectPx: currentRect,
        tileWidthPx: world.tileWidthPx,
        tileHeightPx: world.tileHeightPx,
        mapWidthCells: world.map.size.width,
        mapHeightCells: world.map.size.height,
      ) != player.pos ||
      world.worldStaticObstaclesCollidePixelRect(currentRect,
          playerContact: true)) {
    return null;
  }
  final counts = <String, int>{};
  for (final entity in world.map.entities) {
    counts[entity.id] = (counts[entity.id] ?? 0) + 1;
  }
  final reservations = characterReservations.toList(growable: false);
  for (var pixel = 1; pixel <= attemptedPixelsPerStep; pixel++) {
    final attemptedRect = PlayerCollisionConventionsV1
        .playerCollisionRectFromSpriteTopLeft(
      spriteTopLeftPx: PixelPosition(
        leftPx: player.playerPositionPx.leftPx + direction.dx * pixel,
        topPx: player.playerPositionPx.topPx + direction.dy * pixel,
      ),
      spriteWidthPx: player.playerSpriteWidthPx,
      spriteHeightPx: player.playerSpriteHeightPx,
    );
    final contact = world.playerCharacterContactRect(attemptedRect);
    if (!inside(attemptedRect) || !inside(contact) ||
        reservations.any((rect) => _bumpRectsOverlap(contact, rect))) {
      return null;
    }
    if (!world.worldStaticObstaclesCollidePixelRect(attemptedRect,
        playerContact: true)) {
      continue;
    }
    MapEntity? owner;
    PixelRect? ownerRect;
    for (final entity in world.map.entities) {
      if (entity.kind != MapEntityKind.npc || entity.npc == null ||
          !entity.blocksMovement ||
          !(world.npcMapPresencePredicate?.call(world.map.id, entity) ?? true) ||
          !(world.mapEntityPresencePredicate?.call(world.map.id, entity) ?? true)) {
        continue;
      }
      final rect = resolveEntityCollisionRectPx(entity,
        tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
      if (!_bumpRectsOverlap(contact, rect)) {
        continue;
      }
      if (owner != null || counts[entity.id] != 1 ||
          entity.id.isEmpty || entity.id.trim() != entity.id || !inside(rect)) {
        return null;
      }
      owner = entity;
      ownerRect = rect;
    }
    if (owner == null ||
        world.worldStaticObstaclesCollidePixelRect(attemptedRect,
          playerContact: true, ignoredEntityId: owner.id)) {
      return null;
    }
    return GameplayEntityBumpContact(
      mapId: world.map.id,
      entityId: owner.id,
      direction: direction,
      attemptedPixelsPerStep: attemptedPixelsPerStep,
      playerPos: player.pos,
      playerPositionPx: player.playerPositionPx,
      playerSpriteWidthPx: player.playerSpriteWidthPx,
      playerSpriteHeightPx: player.playerSpriteHeightPx,
      entityPos: owner.pos,
      entityCollisionRectPx: ownerRect!,
    );
  }
  return null;
}

List<GameplayTriggerBumpContact> resolvePlayerTriggerBumpContacts(
  GameplayWorldState world,
  Direction direction, {
  int attemptedPixelsPerStep = 1,
  Iterable<PixelRect> characterReservations = const [],
}) {
  if (world.player.facing != direction) return const [];
  final result = stepGameplayWorld(
    world,
    MoveIntent(direction, pixelsPerStep: attemptedPixelsPerStep),
    characterReservations: characterReservations,
  );
  return result is Blocked && result.reason == GameplayMovementBlockReason.solid
      ? result.triggerBumpContacts
      : const [];
}

List<GameplayTriggerBumpContact> _collectTriggerBumpContacts(
  GameplayWorldState world,
  Direction direction, {
  required int attemptedPixelsPerStep,
  required Iterable<PixelRect> characterReservations,
}) {
  final player = world.player;
  final maxStep = direction.dx == 0 ? world.tileHeightPx : world.tileWidthPx;
  final next = GridPos(
    x: player.pos.x + direction.dx,
    y: player.pos.y + direction.dy,
  );
  if (attemptedPixelsPerStep < 1 ||
      attemptedPixelsPerStep > maxStep ||
      world.map.spatialScene != null ||
      world.map.version == ProjectVersion.v9 ||
      player.playerSpriteWidthPx <= 0 ||
      player.playerSpriteHeightPx <= 0 ||
      world.map.id.isEmpty ||
      world.map.id.trim() != world.map.id ||
      next.x < 0 ||
      next.y < 0 ||
      next.x >= world.map.size.width ||
      next.y >= world.map.size.height ||
      movementTerrainBlockReasonAt(
              map: world.map,
              x: next.x,
              y: next.y,
              mode: player.movementMode) !=
          null) {
    return const [];
  }
  bool inside(PixelRect rect) =>
      rect.widthPx > 0 &&
      rect.heightPx > 0 &&
      rect.leftPx >= 0 &&
      rect.topPx >= 0 &&
      rect.leftPx + rect.widthPx <= world.map.size.width * world.tileWidthPx &&
      rect.topPx + rect.heightPx <= world.map.size.height * world.tileHeightPx;
  final currentRect = player.playerCollisionRectPx;
  if (!inside(currentRect) ||
      !inside(world.playerCharacterContactRect(currentRect)) ||
      PlayerCollisionConventionsV1.projectFeetAnchorToCell(
            playerCollisionRectPx: currentRect,
            tileWidthPx: world.tileWidthPx,
            tileHeightPx: world.tileHeightPx,
            mapWidthCells: world.map.size.width,
            mapHeightCells: world.map.size.height,
          ) !=
          player.pos ||
      world.worldStaticObstaclesCollidePixelRect(
        currentRect,
        playerContact: true,
      )) {
    return const [];
  }
  final counts = <String, int>{};
  for (final trigger in world.map.triggers) {
    counts[trigger.id] = (counts[trigger.id] ?? 0) + 1;
  }
  bool contains(MapRect area, GridPos pos) =>
      pos.x >= area.pos.x &&
      pos.y >= area.pos.y &&
      pos.x < area.pos.x + area.size.width &&
      pos.y < area.pos.y + area.size.height;
  final triggers = world.map.triggers
      .where((trigger) {
        final area = trigger.area;
        return trigger.type == TriggerType.event &&
            counts[trigger.id] == 1 &&
            trigger.id.isNotEmpty &&
            trigger.id.trim() == trigger.id &&
            area.size.width > 0 &&
            area.size.height > 0 &&
            area.pos.x >= 0 &&
            area.pos.y >= 0 &&
            area.pos.x + area.size.width <= world.map.size.width &&
            area.pos.y + area.size.height <= world.map.size.height &&
            contains(area, next) &&
            !contains(area, player.pos);
      })
      .toList(growable: false);
  if (triggers.isEmpty) return const [];
  final reservations = characterReservations.toList(growable: false);
  for (var pixel = 1; pixel <= attemptedPixelsPerStep; pixel++) {
    final attemptedRect =
        PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: PixelPosition(
            leftPx: player.playerPositionPx.leftPx + direction.dx * pixel,
            topPx: player.playerPositionPx.topPx + direction.dy * pixel,
          ),
          spriteWidthPx: player.playerSpriteWidthPx,
          spriteHeightPx: player.playerSpriteHeightPx,
        );
    final contact = world.playerCharacterContactRect(attemptedRect);
    if (!inside(attemptedRect) ||
        !inside(contact) ||
        reservations.any((rect) => _bumpRectsOverlap(contact, rect))) {
      return const [];
    }
    if (!world.worldStaticObstaclesCollidePixelRect(
      attemptedRect,
      playerContact: true,
    )) {
      continue;
    }
    if (world.mapEntitiesCollidePixelRect(attemptedRect, playerContact: true)) {
      return const [];
    }
    final contacts = <GameplayTriggerBumpContact>[];
    for (final trigger in triggers) {
      final area = trigger.area;
      final left = area.pos.x * world.tileWidthPx;
      final top = area.pos.y * world.tileHeightPx;
      final right = left + area.size.width * world.tileWidthPx;
      final bottom = top + area.size.height * world.tileHeightPx;
      final clippedLeft = attemptedRect.leftPx > left
          ? attemptedRect.leftPx
          : left;
      final clippedTop = attemptedRect.topPx > top ? attemptedRect.topPx : top;
      final clippedRight = attemptedRect.leftPx + attemptedRect.widthPx < right
          ? attemptedRect.leftPx + attemptedRect.widthPx
          : right;
      final clippedBottom =
          attemptedRect.topPx + attemptedRect.heightPx < bottom
          ? attemptedRect.topPx + attemptedRect.heightPx
          : bottom;
      final clipped = PixelRect(
        leftPx: clippedLeft,
        topPx: clippedTop,
        widthPx: clippedRight - clippedLeft,
        heightPx: clippedBottom - clippedTop,
      );
      if (clipped.widthPx <= 0 ||
          clipped.heightPx <= 0 ||
          !world.worldStaticObstaclesCollidePixelRect(clipped)) {
        continue;
      }
      contacts.add(
        GameplayTriggerBumpContact(
          mapId: world.map.id,
          triggerId: trigger.id,
          direction: direction,
          attemptedPixelsPerStep: attemptedPixelsPerStep,
          playerPos: player.pos,
          playerPositionPx: player.playerPositionPx,
          playerSpriteWidthPx: player.playerSpriteWidthPx,
          playerSpriteHeightPx: player.playerSpriteHeightPx,
          triggerArea: area,
          blockedPlayerCollisionRectPx: attemptedRect,
        ),
      );
    }
    contacts.sort(
      (a, b) => compareNarrativeEventUtf16(a.triggerId, b.triggerId),
    );
    return List.unmodifiable(contacts);
  }
  return const [];
}

bool _bumpRectsOverlap(PixelRect a, PixelRect b) =>
    a.leftPx < b.leftPx + b.widthPx &&
    a.leftPx + a.widthPx > b.leftPx &&
    a.topPx < b.topPx + b.heightPx &&
    a.topPx + a.heightPx > b.topPx;

/// Déplacement **réellement pixel-level** : [playerPositionPx] + résolveur séparé H/V.
GameplayStepResult _resolveMove(GameplayWorldState world, MoveIntent intent,
    Iterable<PixelRect> characterReservations) {
  final direction = intent.direction;
  final step = intent.pixelsPerStep;
  final facingWorld = world.withPlayer(
    world.player.copyWith(facing: direction),
  );

  final feet = facingWorld.player.pos;
  final nextCellX = feet.x + direction.dx;
  final nextCellY = feet.y + direction.dy;
  final jump = step > 0
      ? _resolveBorderJump(facingWorld, direction,
          GridPos(x: nextCellX, y: nextCellY), characterReservations)
      : null;
  if (jump != null) return jump;
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

  final terrainBlock = movementTerrainBlockReasonAt(
      map: facingWorld.map,
      x: nextCellX,
      y: nextCellY,
      mode: facingWorld.player.movementMode);
  if (terrainBlock != null) {
    return Blocked(
      facingWorld,
      reason: terrainBlock,
    );
  }

  final dx = direction.dx * step;
  final dy = direction.dy * step;
  final platformControl = resolveMovingPlatformControlEntry(
    world: facingWorld,
    destination: PixelPosition(
      leftPx: facingWorld.player.playerPositionPx.leftPx + dx,
      topPx: facingWorld.player.playerPositionPx.topPx + dy,
    ),
  );
  final destination = platformControl?.playerPositionPx;

  final resolvedTopLeft = PixelMovementResolverV1.resolveSeparateAxis(
    spriteTopLeftPx: facingWorld.player.playerPositionPx,
    deltaXPx: destination == null
        ? dx
        : destination.leftPx - facingWorld.player.playerPositionPx.leftPx,
    deltaYPx: destination == null
        ? dy
        : destination.topPx - facingWorld.player.playerPositionPx.topPx,
    spriteWidthPx: facingWorld.player.playerSpriteWidthPx,
    spriteHeightPx: facingWorld.player.playerSpriteHeightPx,
    worldStaticObstaclesCollidePixelRect: (rect) {
      if (facingWorld.worldStaticObstaclesCollidePixelRect(rect,
          playerContact: true)) {
        return true;
      }
      final contact = facingWorld.playerCharacterContactRect(rect);
      if ([rect, contact].any((area) => !movementTerrainAllowsRect(
          map: facingWorld.map,
          rect: area,
          tileWidth: facingWorld.tileWidthPx,
          tileHeight: facingWorld.tileHeightPx,
          mode: facingWorld.player.movementMode))) {
        return true;
      }
      return characterReservations.any((obstacle) =>
          contact.leftPx < obstacle.leftPx + obstacle.widthPx &&
          contact.leftPx + contact.widthPx > obstacle.leftPx &&
          contact.topPx < obstacle.topPx + obstacle.heightPx &&
          contact.topPx + contact.heightPx > obstacle.topPx);
    },
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
    final entityContact = step > 0
        ? resolvePlayerEntityBumpContact(
            facingWorld,
            direction,
            attemptedPixelsPerStep: step,
            characterReservations: characterReservations,
          )
        : null;
    return Blocked(
      facingWorld,
      reason: GameplayMovementBlockReason.solid,
      entityBumpContact: entityContact,
      triggerBumpContacts: entityContact == null
          ? _collectTriggerBumpContacts(
              facingWorld,
              direction,
              attemptedPixelsPerStep: step,
              characterReservations: characterReservations,
            )
          : const [],
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
  return resolveGameplayArrival(movedWorld,
      previousPos: facingWorld.player.pos,
      direction: direction,
      platformControl: platformControl);
}

GameplayStepResult resolveGameplayArrival(GameplayWorldState world,
    {required GridPos previousPos,
    required Direction direction,
    MovingPlatformControlActivation? platformControl}) {
  final movedWorld = world;
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
    );
  }

  return Moved(
    movedWorld,
    hazardEffect: _resolveHazardEffectAt(movedWorld, targetPos),
    platformControl: platformControl,
  );
}

GameplayStepResult? _resolveBorderJump(
  GameplayWorldState world,
  Direction direction,
  GridPos via,
  Iterable<PixelRect> reservations,
) {
  final matching = world.borderJumpBindings.where((binding) =>
    binding.mapId == world.map.id &&
    binding.carrierCell == via &&
    binding.allowedDirection == direction
  ).toList(growable: false);
  if (matching.isEmpty) return null;
  if (matching.length != 1) return Blocked(world);
  final binding = matching.single;
  final sourceCell = GridPos(
    x: via.x - direction.dx,
    y: via.y - direction.dy,
  );
  final landing = GridPos(
    x: via.x + direction.dx,
    y: via.y + direction.dy,
  );
  final source = world.player.playerPositionPx;
  final viaPosition = PixelPosition(
    leftPx: source.leftPx + direction.dx * world.tileWidthPx,
    topPx: source.topPx + direction.dy * world.tileHeightPx,
  );
  final landingPosition = PixelPosition(
    leftPx: source.leftPx + direction.dx * world.tileWidthPx * 2,
    topPx: source.topPx + direction.dy * world.tileHeightPx * 2,
  );
  final obstacles = reservations.toList(growable: false);
  final exclusion = BorderCollisionExclusion(
    owners: {binding.owner},
    area: binding.carrierArea,
  );
  for (final (cell, position, borderExclusion) in [
    (sourceCell, source, null),
    (via, viaPosition, exclusion),
    (landing, landingPosition, null),
  ]) {
    final rect = PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
      spriteTopLeftPx: position,
      spriteWidthPx: world.player.playerSpriteWidthPx,
      spriteHeightPx: world.player.playerSpriteHeightPx,
    );
    final contact = world.playerCharacterContactRect(rect);
    final anchor = rect.bottomCenterPx;
    if (!_jumpRectInBounds(world, rect) ||
        !_jumpRectInBounds(world, contact) ||
        GridPos(
          x: anchor.xPx ~/ world.tileWidthPx,
          y: anchor.yPx ~/ world.tileHeightPx,
        ) != cell ||
        world.player.pos != sourceCell) {
      return Blocked(world, reason: GameplayMovementBlockReason.outOfBounds);
    }
    if ([rect, contact].any((area) => !movementTerrainAllowsRect(
        map: world.map,
        rect: area,
        tileWidth: world.tileWidthPx,
        tileHeight: world.tileHeightPx,
        mode: world.player.movementMode))) {
      return Blocked(world,
          reason: GameplayMovementBlockReason.invalidMovementTerrain);
    }
    if (world.worldStaticObstaclesCollidePixelRect(
          rect,
          playerContact: true,
          borderExclusion: borderExclusion,
        ) ||
        obstacles.any((obstacle) => _jumpRectsIntersect(contact, obstacle))) {
      return Blocked(world);
    }
  }
  final plan = DirectedJumpPlan(
    binding: binding,
    direction: direction,
    sourcePos: sourceCell,
    viaPos: via,
    landingPos: landing,
    sourcePositionPx: source,
    landingPositionPx: landingPosition,
    durationMs: binding.durationMs,
    peakHeightPx: binding.peakHeightPx,
  );
  return Jumped(
    world.withPlayer(world.player.copyWith(
      pos: landing,
      playerPositionPx: landingPosition,
    )),
    plan: plan,
  );
}

bool _jumpRectInBounds(GameplayWorldState world, PixelRect rect) =>
  rect.leftPx >= 0 &&
  rect.topPx >= 0 &&
  rect.leftPx + rect.widthPx <= world.map.size.width * world.tileWidthPx &&
  rect.topPx + rect.heightPx <= world.map.size.height * world.tileHeightPx;

bool _jumpRectsIntersect(PixelRect a, PixelRect b) =>
  a.leftPx < b.leftPx + b.widthPx &&
  a.leftPx + a.widthPx > b.leftPx &&
  a.topPx < b.topPx + b.heightPx &&
  a.topPx + a.heightPx > b.topPx;

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

  final across = world.entityAt(tx + facing.dx, ty + facing.dy);
  final counterSide = switch (facing) {
    Direction.north => EntityFacing.south,
    Direction.south => EntityFacing.north,
    Direction.east => EntityFacing.west,
    Direction.west => EntityFacing.east,
  };
  if (world.map.spatialScene == null &&
      world.map.version != ProjectVersion.v9 &&
      across != null && across.kind == MapEntityKind.npc &&
      across.npc != null && across.size.width == 1 && across.size.height == 1 &&
      across.npc!.counterInteractionSides.contains(counterSide) &&
      world.isCellCenterBlockedLegacyForGridIndexedSystems(tx, ty) &&
      world.map.entities.where((candidate) =>
          resolveEntityCollisionCells(candidate).contains(across.pos))
          .length == 1) {
    return NpcInteracted(world, across);
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

  final contact = resolvePlayerEntityBumpContact(
    world,
    facing,
    attemptedPixelsPerStep:
        facing.dx == 0 ? world.tileHeightPx : world.tileWidthPx,
  );
  if (contact != null) {
    return NpcInteracted(
      world,
      world.map.entities.singleWhere((entity) => entity.id == contact.entityId),
    );
  }

  return NothingToInteract(world);
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

String _behaviorIdentity(MapPlacedElementBehavior behavior) {
  final behaviorId = behavior.id.trim();
  if (behaviorId.isNotEmpty) {
    return behaviorId;
  }
  return '${behavior.trigger.name}:${behavior.effect.type.name}';
}
