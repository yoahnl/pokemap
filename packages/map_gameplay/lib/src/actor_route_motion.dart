import 'package:map_core/map_core.dart';
import 'movement_terrain_policy.dart';

import 'collision/pixel_movement_resolver.dart';
import 'direction.dart';
import 'gameplay_player_state.dart';
import 'gameplay_world_state.dart';
import 'field_traversal_geometry.dart';

final class ActorRouteMotionPlan {
  const ActorRouteMotionPlan._({
    required this.target,
    required this.direction,
    required this.from,
    required this.to,
    required this.fromPositionPx,
    required this.toPositionPx,
    this.playerState,
  });

  final SceneActorTarget target;
  final EntityFacing direction;
  final GridPos from;
  final GridPos to;
  final PixelPosition fromPositionPx;
  final PixelPosition toPositionPx;
  final GameplayPlayerState? playerState;
}

ActorRouteMotionPlan? planActorRouteMove({
  required GameplayWorldState world,
  required SceneActorTarget target,
  required EntityFacing direction,
  required bool through,
  String? initialCollisionOwnerEntityId,
  MapGameplayZone? fieldTraversalZone,
  ProjectManifest? project,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) =>
    _planActorRouteMove(
        world: world,
        target: target,
        direction: direction,
        deltaX: direction.asDirection.dx,
        deltaY: direction.asDirection.dy,
        through: through,
        initialCollisionOwnerEntityId: initialCollisionOwnerEntityId,
        fieldTraversalZone: fieldTraversalZone,
        project: project,
        dynamicBlockedCells: dynamicBlockedCells,
        characterReservations: characterReservations);

ActorRouteMotionPlan? planActorRouteDiagonalMove({
  required GameplayWorldState world,
  required SceneActorTarget target,
  required EntityFacing horizontal,
  required EntityFacing vertical,
  required bool through,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  if (!const [EntityFacing.west, EntityFacing.east].contains(horizontal) ||
      !const [EntityFacing.north, EntityFacing.south].contains(vertical)) {
    throw ArgumentError(
        'Diagonal movement requires horizontal and vertical axes.');
  }
  final current = target.kind == SceneActorTargetKind.player
      ? world.player.facing.asFacing
      : world.map.entities
          .singleWhere((entity) => entity.id == target.entityId)
          .npc!
          .facing;
  final direction =
      const [EntityFacing.west, EntityFacing.east].contains(current)
          ? horizontal
          : vertical;
  return _planActorRouteMove(
      world: world,
      target: target,
      direction: direction,
      deltaX: horizontal.asDirection.dx,
      deltaY: vertical.asDirection.dy,
      through: through,
      dynamicBlockedCells: dynamicBlockedCells,
      characterReservations: characterReservations);
}

ActorRouteMotionPlan? _planActorRouteMove({
  required GameplayWorldState world,
  required SceneActorTarget target,
  required EntityFacing direction,
  required int deltaX,
  required int deltaY,
  required bool through,
  String? initialCollisionOwnerEntityId,
  MapGameplayZone? fieldTraversalZone,
  ProjectManifest? project,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  if (target.mapId != world.map.id || world.map.spatialScene != null) {
    throw StateError('Actor route requires its active 2D map.');
  }
  final dx = deltaX * world.tileWidthPx;
  final dy = deltaY * world.tileHeightPx;
  late final GridPos from;
  late final PixelPosition fromPosition;
  late final int spriteWidth;
  late final int spriteHeight;
  late final PixelRect sourceFootprint;
  var collisionWorld = world;
  final isPlayer = target.kind == SceneActorTargetKind.player;
  if (isPlayer) {
    from = world.player.pos;
    fromPosition = world.player.playerPositionPx;
    spriteWidth = world.player.playerSpriteWidthPx;
    spriteHeight = world.player.playerSpriteHeightPx;
    sourceFootprint = world.player.playerCollisionRectPx;
    if (spriteWidth <= 0 ||
        spriteHeight <= 0 ||
        _project(world, sourceFootprint) != from) {
      throw StateError('Player actor route has an incoherent physical pose.');
    }
  } else {
    final candidates = world.map.entities
        .where((entity) => entity.id == target.entityId)
        .toList(growable: false);
    if (candidates.length != 1 || candidates.single.kind != MapEntityKind.npc) {
      throw StateError('Actor route target must identify one NPC.');
    }
    final actor = candidates.single;
    if (!(world.npcMapPresencePredicate?.call(world.map.id, actor) ?? true) ||
        !(world.mapEntityPresencePredicate?.call(world.map.id, actor) ??
            true)) {
      throw StateError('Actor route target is not present.');
    }
    from = actor.pos;
    fromPosition = PixelPosition(
      leftPx: from.x * world.tileWidthPx,
      topPx: from.y * world.tileHeightPx,
    );
    spriteWidth = actor.size.width * world.tileWidthPx;
    spriteHeight = actor.size.height * world.tileHeightPx;
    sourceFootprint = resolveEntityCollisionRectPx(actor,
        tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
    final previousPresence = world.npcMapPresencePredicate;
    collisionWorld = world.withNpcMapPresencePredicate((mapId, entity) =>
        entity.id != actor.id &&
        (previousPresence?.call(mapId, entity) ?? true));
  }
  final sourceMovementRect =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: fromPosition,
    spriteWidthPx: spriteWidth,
    spriteHeightPx: spriteHeight,
  );
  PixelRect footprintAt(PixelRect movementRect) => isPlayer
      ? movementRect
      : PixelRect(
          leftPx: sourceFootprint.leftPx +
              movementRect.leftPx -
              sourceMovementRect.leftPx,
          topPx: sourceFootprint.topPx +
              movementRect.topPx -
              sourceMovementRect.topPx,
          widthPx: sourceFootprint.widthPx,
          heightPx: sourceFootprint.heightPx,
        );
  List<PixelRect> areasAt(PixelRect movementRect) {
    final footprint = footprintAt(movementRect);
    return [
      footprint,
      if (isPlayer) world.playerCharacterContactRect(footprint)
    ];
  }

  bool inBounds(PixelRect movementRect) =>
      areasAt(movementRect).every((rect) => _inBounds(world, rect));
  if (from.x < 0 ||
      from.y < 0 ||
      from.x >= world.map.size.width ||
      from.y >= world.map.size.height ||
      spriteWidth <= 0 ||
      spriteHeight <= 0 ||
      !inBounds(sourceMovementRect)) {
    throw StateError('Actor route initial footprint is outside the map.');
  }
  PixelRect? initialOwnerContact;
  final ownerId = initialCollisionOwnerEntityId;
  if (ownerId != null) {
    if (!isPlayer || through || ownerId.isEmpty || ownerId.trim() != ownerId) {
      throw StateError(
          'Initial collision owner requires a nonthrough player move.');
    }
    if (project == null ||
        project.settings.dimension != ProjectDimension.twoD ||
        project.maps.where((map) => map.id == world.map.id).length != 1) {
      throw StateError(
          'Initial collision owner requires its unique project map.');
    }
    final owners = world.map.entities.where((entity) => entity.id == ownerId);
    if (owners.length != 1 ||
        !isSceneActorInitialCollisionOwnerReferenceAvailable(
            project, owners.single)) {
      throw StateError(
          'Initial collision owner requires one NPC Character contact.');
    }
    final owner = owners.single;
    final ownerFootprint = resolveEntityCollisionFootprint(owner);
    if (owner.pos != from || ownerFootprint.pos != from) {
      throw StateError('Initial collision owner must match the player anchor.');
    }
    if (!(world.npcMapPresencePredicate?.call(world.map.id, owner) ?? true) ||
        !(world.mapEntityPresencePredicate?.call(world.map.id, owner) ??
            true)) {
      throw StateError('Initial collision owner must be present.');
    }
    final ownerContact = resolveEntityCollisionRectPx(owner,
        tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
    final cell = PixelRect(
      leftPx: from.x * world.tileWidthPx,
      topPx: from.y * world.tileHeightPx,
      widthPx: world.tileWidthPx,
      heightPx: world.tileHeightPx,
    );
    if (!_contains(cell, ownerContact) ||
        !_intersects(world.playerCharacterContactRect(sourceMovementRect),
            ownerContact)) {
      throw StateError('Initial collision owner must overlap inside its cell.');
    }
    initialOwnerContact = ownerContact;
    final previousPresence = world.npcMapPresencePredicate;
    collisionWorld = world.withNpcMapPresencePredicate((mapId, entity) =>
        !(mapId == world.map.id && entity.id == ownerId) &&
        (previousPresence?.call(mapId, entity) ?? true));
  }
  final toPosition = PixelPosition(
      leftPx: fromPosition.leftPx + dx, topPx: fromPosition.topPx + dy);
  final toMovementRect =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: toPosition,
    spriteWidthPx: spriteWidth,
    spriteHeightPx: spriteHeight,
  );
  final to = isPlayer
      ? _project(world, toMovementRect)
      : GridPos(x: from.x + deltaX, y: from.y + deltaY);
  if (to.x < 0 ||
      to.y < 0 ||
      to.x >= world.map.size.width ||
      to.y >= world.map.size.height ||
      !inBounds(toMovementRect)) {
    return null;
  }
  {
    for (final position in _sweptActorRoutePositions(fromPosition, dx, dy)) {
      final rect =
          PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
              spriteTopLeftPx: position,
              spriteWidthPx: spriteWidth,
              spriteHeightPx: spriteHeight);
      if (areasAt(rect).any((area) => !movementTerrainAllowsRect(
          map: world.map,
          rect: area,
          tileWidth: world.tileWidthPx,
          tileHeight: world.tileHeightPx,
          mode: isPlayer ? world.player.movementMode : MovementMode.walk,
          bypassSurfRequirement: through))) {
        return null;
      }
    }
  }
  final ownerContact = initialOwnerContact;
  if (ownerContact != null &&
      (to != GridPos(x: from.x + deltaX, y: from.y + deltaY) ||
          areasAt(toMovementRect)
              .any((rect) => _intersects(rect, ownerContact)))) {
    return null;
  }
  if (fieldTraversalZone != null) {
    final zone = fieldTraversalZone;
    validateFieldActionZone(world.map, zone);
    if (!isPlayer ||
        through ||
        !isFieldTraversalZone(zone) ||
        findGameplayZoneById(world.map, zone.id) != zone) {
      return null;
    }
    final cells = fieldTraversalRouteCells(zone);
    final index = cells.indexOf(from);
    if (index < 0 ||
        index >= cells.length - 1 ||
        cells[index + 1] != to ||
        (fieldTraversalRequiresSurf(zone) &&
            world.player.movementMode != MovementMode.surf)) {
      return null;
    }
    if (zone.fieldAction!.actionKind == FieldActionZoneKind.whirlpool &&
        cells.any((cell) => movementTerrainAt(world.map, cell.x, cell.y) != GameplayMovementTerrain.surf)) {
      return null;
    }
  }
  if (!through) {
    final reservations = characterReservations.toList(growable: false);
    final blockedCells = dynamicBlockedCells.toList(growable: false);
    final playerContact =
        world.playerCharacterContactRect(world.player.playerCollisionRectPx);
    bool blocked(PixelRect movementRect) {
      if (!inBounds(movementRect)) return true;
      final footprint = footprintAt(movementRect);
      final areas = areasAt(movementRect);
      if (collisionWorld.worldStaticObstaclesCollidePixelRect(footprint,
          playerContact: isPlayer,
          permittedFieldTraversalZoneId: fieldTraversalZone?.id)) {
        return true;
      }
      if (!isPlayer && _intersects(footprint, playerContact)) return true;
      if (areas
          .any((area) => reservations.any((rect) => _intersects(area, rect)))) {
        return true;
      }
      for (final cell in blockedCells) {
        final rect = PixelRect(
          leftPx: cell.x * world.tileWidthPx,
          topPx: cell.y * world.tileHeightPx,
          widthPx: world.tileWidthPx,
          heightPx: world.tileHeightPx,
        );
        if (areas.any((area) => _intersects(area, rect))) return true;
      }
      if (areas.any((area) => !movementTerrainAllowsRect(
          map: world.map,
          rect: area,
          tileWidth: world.tileWidthPx,
          tileHeight: world.tileHeightPx,
          mode: isPlayer ? world.player.movementMode : MovementMode.walk))) {
        return true;
      }
      return false;
    }

    if (deltaX != 0 && deltaY != 0) {
      for (final position in _sweptActorRoutePositions(fromPosition, dx, dy)) {
        final rect =
            PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
                spriteTopLeftPx: position,
                spriteWidthPx: spriteWidth,
                spriteHeightPx: spriteHeight);
        if (blocked(rect)) return null;
      }
    } else {
      final resolved = PixelMovementResolverV1.resolveSeparateAxis(
          spriteTopLeftPx: fromPosition,
          deltaXPx: dx,
          deltaYPx: dy,
          spriteWidthPx: spriteWidth,
          spriteHeightPx: spriteHeight,
          worldStaticObstaclesCollidePixelRect: blocked);
      if (resolved.leftPx != toPosition.leftPx ||
          resolved.topPx != toPosition.topPx) {
        return null;
      }
    }
  }
  return ActorRouteMotionPlan._(
    target: target,
    direction: direction,
    from: from,
    to: to,
    fromPositionPx: fromPosition,
    toPositionPx: toPosition,
    playerState: isPlayer
        ? world.player.copyWith(
            pos: to,
            playerPositionPx: toPosition,
            facing: direction.asDirection)
        : null,
  );
}

Iterable<PixelPosition> _sweptActorRoutePositions(
    PixelPosition from, int dx, int dy) sync* {
  final width = dx.abs();
  final height = dy.abs();
  if (width == 0 || height == 0) {
    final pixels = width + height;
    for (var step = 0; step <= pixels; step++) {
      yield PixelPosition(
          leftPx: from.leftPx + dx.sign * step,
          topPx: from.topPx + dy.sign * step);
    }
    return;
  }
  var x = 1;
  var y = 1;
  var previousNumerator = 0;
  var previousDenominator = 1;
  while (x <= width || y <= height) {
    final compare = x * height - y * width;
    final numerator = compare <= 0 ? x : y;
    final denominator = compare <= 0 ? width : height;
    final midpointNumerator =
        previousNumerator * denominator + numerator * previousDenominator;
    final midpointDenominator = 2 * previousDenominator * denominator;
    int floorRatio(int numerator) => numerator >= 0
        ? numerator ~/ midpointDenominator
        : -((-numerator + midpointDenominator - 1) ~/ midpointDenominator);
    final left = floorRatio(dx * midpointNumerator);
    final right = -floorRatio(-dx * midpointNumerator);
    final top = floorRatio(dy * midpointNumerator);
    final bottom = -floorRatio(-dy * midpointNumerator);
    for (final offsetX in [left, if (right != left) right]) {
      for (final offsetY in [top, if (bottom != top) bottom]) {
        yield PixelPosition(
            leftPx: from.leftPx + offsetX, topPx: from.topPx + offsetY);
      }
    }
    previousNumerator = numerator;
    previousDenominator = denominator;
    if (compare <= 0) x++;
    if (compare >= 0) y++;
  }
}

GridPos _project(GameplayWorldState world, PixelRect rect) =>
    PlayerCollisionConventionsV1.projectFeetAnchorToCell(
      playerCollisionRectPx: rect,
      tileWidthPx: world.tileWidthPx,
      tileHeightPx: world.tileHeightPx,
      mapWidthCells: world.map.size.width,
      mapHeightCells: world.map.size.height,
    );

bool _inBounds(GameplayWorldState world, PixelRect rect) =>
    rect.widthPx > 0 &&
    rect.heightPx > 0 &&
    rect.leftPx >= 0 &&
    rect.topPx >= 0 &&
    rect.leftPx + rect.widthPx <= world.map.size.width * world.tileWidthPx &&
    rect.topPx + rect.heightPx <= world.map.size.height * world.tileHeightPx;

bool _intersects(PixelRect a, PixelRect b) =>
    a.leftPx < b.leftPx + b.widthPx &&
    a.leftPx + a.widthPx > b.leftPx &&
    a.topPx < b.topPx + b.heightPx &&
    a.topPx + a.heightPx > b.topPx;

bool _contains(PixelRect area, PixelRect rect) =>
    rect.widthPx > 0 &&
    rect.heightPx > 0 &&
    rect.leftPx >= area.leftPx &&
    rect.topPx >= area.topPx &&
    rect.leftPx + rect.widthPx <= area.leftPx + area.widthPx &&
    rect.topPx + rect.heightPx <= area.topPx + area.heightPx;
