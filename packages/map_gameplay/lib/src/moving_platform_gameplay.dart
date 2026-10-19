import 'package:map_core/map_core.dart';

import 'gameplay_player_state.dart';
import 'gameplay_world_state.dart';

final class MovingPlatformControlActivation {
  const MovingPlatformControlActivation({
    required this.platformId,
    required this.controlId,
    required this.motion,
    required this.playerPositionPx,
  });
  final String platformId, controlId;
  final MovingPlatformMotion motion;
  final PixelPosition playerPositionPx;
}

MovingPlatformControlActivation? resolveMovingPlatformControlEntry({
  required GameplayWorldState world,
  required PixelPosition destination,
}) {
  if (world.map.movingPlatforms.every(
    (platform) => platform.controls.isEmpty,
  )) {
    return null;
  }
  final start = world.player.playerPositionPx;
  final dx = destination.leftPx - start.leftPx;
  final dy = destination.topPx - start.topPx;
  if (dx != 0 && dy != 0) {
    return null;
  }
  final distance = dx.abs() + dy.abs();
  if (distance == 0) {
    return null;
  }
  final candidates =
      <(MovingPlatformDefinition, MovingPlatformControl, PixelRect)>[];
  final current = world.player.playerCollisionRectPx;
  for (final platform in world.map.movingPlatforms) {
    final pose =
        world.movingPlatformWorldState.platform(world.map.id, platform.id) ??
        platform.initialPose;
    for (final control in platform.controls) {
      final rect = movingPlatformCellRect(
        platform: platform,
        pose: pose,
        cell: control.cellForQuarterTurns(pose.quarterTurns),
      );
      if (!_covered(current, [rect])) {
        candidates.add((platform, control, rect));
      }
    }
  }
  if (candidates.isEmpty) {
    return null;
  }
  for (var pixel = 1; pixel <= distance; pixel++) {
    final position = PixelPosition(
      leftPx: start.leftPx + dx.sign * pixel,
      topPx: start.topPx + dy.sign * pixel,
    );
    final feet =
        PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: position,
          spriteWidthPx: world.player.playerSpriteWidthPx,
          spriteHeightPx: world.player.playerSpriteHeightPx,
        );
    final matching = candidates
        .where((candidate) => _covered(feet, [candidate.$3]))
        .toList();
    if (matching.length > 1) {
      throw const FormatException('Platform controls overlap.');
    }
    if (matching.length == 1) {
      final (platform, control, _) = matching.single;
      return MovingPlatformControlActivation(
        platformId: platform.id,
        controlId: control.id,
        motion: control.motion,
        playerPositionPx: position,
      );
    }
  }
  return null;
}

enum MovingPlatformMoveOutcome {
  moved,
  blocked,
  notRiding,
  rotationRequiresPivot
}

final class MovingPlatformMotionFrame {
  const MovingPlatformMotionFrame(
      {required this.world, required this.worldState, required this.returning});
  final GameplayWorldState world;
  final MovingPlatformWorldState worldState;
  final bool returning;
}

final class MovingPlatformMoveResult {
  MovingPlatformMoveResult(
      {required this.outcome,
      required this.finalWorld,
      required this.finalWorldState,
      required List<MovingPlatformMotionFrame> frames})
      : frames = List.unmodifiable(frames);
  final MovingPlatformMoveOutcome outcome;
  final GameplayWorldState finalWorld;
  final MovingPlatformWorldState finalWorldState;
  final List<MovingPlatformMotionFrame> frames;
}

void validateGameplayMovingPlatformWorldState(
    {required ProjectManifest project,
    required Iterable<MapData> maps,
    required MovingPlatformWorldState worldState,
    MovingPropWorldState movingPropWorldState = const MovingPropWorldState.empty(),
    GameState? gameState,
    NpcMapPresencePredicate? npcMapPresencePredicate,
    MapEntityPresencePredicate? mapEntityPresencePredicate}) {
  final materializedMaps = maps.toList();
  validateMovingPlatformWorldState(
      project: project, maps: materializedMaps, worldState: worldState);
  final tile = PixelSize(
      width: project.settings.tileWidth, height: project.settings.tileHeight);
  for (final map
      in materializedMaps.where((map) => map.movingPlatforms.isNotEmpty)) {
    final state =
        initializeMovingPlatformWorldState(map: map, worldState: worldState);
    final world = GameplayWorldState.initial(
        map: map,
        project: project,
        movingPlatformWorldState: state,
        movingPropWorldState: movingPropWorldState,
        gameState: gameState,
        playerPos: const GridPos(x: 0, y: 0),
        tileWidth: tile.width,
        tileHeight: tile.height,
        npcMapPresencePredicate: npcMapPresencePredicate,
        mapEntityPresencePredicate: mapEntityPresencePredicate);
    for (final rect in movingPlatformSupportRects(
        map: map, worldState: state, tileSize: tile)) {
      if (world.worldStaticObstaclesCollidePixelRect(rect)) {
        throw const FormatException(
            'Saved moving platform support overlaps an obstacle.');
      }
    }
    final boundsByPlatform = <List<PixelRect>>[];
    for (final platform in map.movingPlatforms) {
      final pose = state.platform(map.id, platform.id)!;
      final bounds = _rects(
          platform, platform.variants[pose.quarterTurns].clearanceCells, pose);
      if (boundsByPlatform.any((other) =>
          bounds.any((rect) => other.any((item) => _overlaps(rect, item))))) {
        throw const FormatException(
            'Saved moving platforms overlap one another.');
      }
      boundsByPlatform.add(bounds);
    }
  }
}

MovingPlatformMoveResult moveGameplayPlatform(
    {required GameplayWorldState world,
    required ProjectManifest project,
    required MovingPlatformWorldState worldState,
    required String platformId,
    required MovingPlatformMotion motion}) {
  final map = world.map;
  final tileSize =
      PixelSize(width: world.tileWidthPx, height: world.tileHeightPx);
  validateMovingPlatformDefinitions(
      map: map, project: project, tileSize: tileSize);
  final definitions =
      map.movingPlatforms.where((value) => value.id == platformId).toList();
  if (definitions.length != 1) {
    throw const FormatException('Moving platform is missing.');
  }
  final definition = definitions.single;
  final initialized =
      initializeMovingPlatformWorldState(map: map, worldState: worldState);
  final original = initialized.platform(map.id, platformId)!;
  MovingPlatformMoveResult unchanged(MovingPlatformMoveOutcome outcome,
          [List<MovingPlatformMotionFrame> frames = const []]) =>
      MovingPlatformMoveResult(
          outcome: outcome,
          finalWorld: world,
          finalWorldState: initialized,
          frames: frames);
  final supports = _rects(definition,
      definition.variants[original.quarterTurns].supportCells, original);
  if (!_covered(world.player.playerCollisionRectPx, supports)) {
    return unchanged(MovingPlatformMoveOutcome.notRiding);
  }
  if (motion == MovingPlatformMotion.rotateClockwise &&
      !_covered(world.player.playerCollisionRectPx, [
        movingPlatformCellRect(
            platform: definition,
            pose: original,
            cell: const GridPos(x: 0, y: 0))
      ])) {
    return unchanged(MovingPlatformMoveOutcome.rotationRequiresPivot);
  }
  final travel = definition.travelCells.map((cell) => (cell.x, cell.y)).toSet();
  final otherRects = <PixelRect>[];
  for (final other
      in map.movingPlatforms.where((value) => value.id != platformId)) {
    final pose = initialized.platform(map.id, other.id)!;
    otherRects.addAll(
        _rects(other, other.variants[pose.quarterTurns].clearanceCells, pose));
  }
  bool clear(Iterable<PixelRect> rects) => rects.every((rect) {
        if (rect.leftPx < 0 ||
            rect.topPx < 0 ||
            rect.leftPx + rect.widthPx > map.size.width * tileSize.width ||
            rect.topPx + rect.heightPx > map.size.height * tileSize.height) {
          return false;
        }
        final lattice = definition.lattice;
        final originX = lattice.originLeftPx + lattice.cellOffsetLeftPx;
        final originY = lattice.originTopPx + lattice.cellOffsetTopPx;
        for (var y = ((rect.topPx + 0.5 - originY) / lattice.heightPx).floor();
            y <=
                ((rect.topPx + rect.heightPx - 0.5 - originY) /
                        lattice.heightPx)
                    .floor();
            y++) {
          for (var x =
                  ((rect.leftPx + 0.5 - originX) / lattice.widthPx).floor();
              x <=
                  ((rect.leftPx + rect.widthPx - 0.5 - originX) /
                          lattice.widthPx)
                      .floor();
              x++) {
            if (!travel.contains((x, y))) return false;
          }
        }
        return !world.worldStaticObstaclesCollidePixelRect(
                rect,
                ignoredSupportableTerrainLayerIds: definition.terrainLayerIds) &&
            !otherRects.any((other) => _overlaps(rect, other));
      });
  GameplayWorldState at(
      MovingPlatformWorldState state, GameplayPlayerState player) {
    return world.withMovingPlatformState(project: project, worldState: state)
        .withPlayer(player);
  }

  if (motion == MovingPlatformMotion.rotateClockwise) {
    final pose = MovingPlatformPose(
        leftPx: original.leftPx,
        topPx: original.topPx,
        quarterTurns: (original.quarterTurns + 1) % 4);
    if (!clear(_rects(
            definition,
            definition.variants[original.quarterTurns].rotationClearanceCells,
            original)) ||
        !clear(_rects(definition,
            definition.variants[pose.quarterTurns].clearanceCells, pose)) ||
        !_covered(
            world.player.playerCollisionRectPx,
            _rects(definition,
                definition.variants[pose.quarterTurns].supportCells, pose))) {
      return unchanged(MovingPlatformMoveOutcome.blocked);
    }
    final state = initialized.withPlatform(
        mapId: map.id, platformId: platformId, pose: pose);
    final next = at(state, world.player);
    if (next.worldStaticObstaclesCollidePlayerCollisionRect()) {
      return unchanged(MovingPlatformMoveOutcome.blocked);
    }
    return MovingPlatformMoveResult(
        outcome: MovingPlatformMoveOutcome.moved,
        finalWorld: next,
        finalWorldState: state,
        frames: [
          MovingPlatformMotionFrame(
              world: next, worldState: state, returning: false)
        ]);
  }
  final sign = motion == MovingPlatformMotion.backward ? -1 : 1;
  final (dx, dy) = switch (original.quarterTurns) {
    0 => (sign, 0),
    1 => (0, sign),
    2 => (-sign, 0),
    _ => (0, -sign),
  };
  final distance = definition.translationDistanceCells *
      (dx == 0 ? definition.lattice.heightPx : definition.lattice.widthPx);
  final steps = distance.ceil();
  final frames = <MovingPlatformMotionFrame>[];
  for (var step = 1; step <= steps; step++) {
    final amount = distance * step / steps;
    final x = original.leftPx + dx * amount, y = original.topPx + dy * amount;
    if (x < 0 || y < 0) return _rollback(world, initialized, frames);
    final pose = MovingPlatformPose(
        leftPx: x, topPx: y, quarterTurns: original.quarterTurns);
    final variant = definition.variants[pose.quarterTurns];
    if (!clear(_rects(
            definition,
            motion == MovingPlatformMotion.backward
                ? variant.backwardClearanceCells
                : variant.forwardClearanceCells,
            pose)) ||
        _rects(definition, variant.supportCells, pose).any((rect) =>
            world.worldStaticObstaclesCollidePixelRect(rect,
                ignoredSupportableTerrainLayerIds: definition.terrainLayerIds) ||
            otherRects.any((other) => _overlaps(rect, other)))) {
      return _rollback(world, initialized, frames);
    }
    final state = initialized.withPlatform(
        mapId: map.id, platformId: platformId, pose: pose);
    final playerPosition = PixelPosition(
        leftPx: world.player.playerPositionPx.leftPx +
            pose.leftPx.round() -
            original.leftPx.round(),
        topPx: world.player.playerPositionPx.topPx +
            pose.topPx.round() -
            original.topPx.round());
    final movedPlayer = world.player.copyWith(playerPositionPx: playerPosition);
    final playerCell = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
        playerCollisionRectPx: movedPlayer.playerCollisionRectPx,
        tileWidthPx: tileSize.width,
        tileHeightPx: tileSize.height,
        mapWidthCells: map.size.width,
        mapHeightCells: map.size.height);
    final next = at(state, movedPlayer.copyWith(pos: playerCell));
    if (next.worldStaticObstaclesCollidePlayerCollisionRect() ||
        !_covered(
            next.player.playerCollisionRectPx,
            _rects(definition,
                definition.variants[pose.quarterTurns].supportCells, pose))) {
      return _rollback(world, initialized, frames);
    }
    frames.add(MovingPlatformMotionFrame(
        world: next, worldState: state, returning: false));
  }
  return MovingPlatformMoveResult(
      outcome: MovingPlatformMoveOutcome.moved,
      finalWorld: frames.last.world,
      finalWorldState: frames.last.worldState,
      frames: frames);
}

MovingPlatformMoveResult _rollback(GameplayWorldState original,
    MovingPlatformWorldState state, List<MovingPlatformMotionFrame> frames) {
  final returning = [
    for (var index = frames.length - 2; index >= 0; index--)
      MovingPlatformMotionFrame(
          world: frames[index].world,
          worldState: frames[index].worldState,
          returning: true),
    if (frames.isNotEmpty)
      MovingPlatformMotionFrame(
          world: original, worldState: state, returning: true),
  ];
  return MovingPlatformMoveResult(
      outcome: MovingPlatformMoveOutcome.blocked,
      finalWorld: original,
      finalWorldState: state,
      frames: [...frames, ...returning]);
}

List<PixelRect> _rects(MovingPlatformDefinition definition, List<GridPos> cells,
        MovingPlatformPose pose) =>
    [
      for (final cell in cells)
        movingPlatformCellRect(platform: definition, pose: pose, cell: cell),
    ];

bool _covered(PixelRect rect, List<PixelRect> supports) {
  for (var y = rect.topPx; y < rect.topPx + rect.heightPx; y++) {
    for (var x = rect.leftPx; x < rect.leftPx + rect.widthPx; x++) {
      if (!supports.any((support) =>
          x >= support.leftPx &&
          x < support.leftPx + support.widthPx &&
          y >= support.topPx &&
          y < support.topPx + support.heightPx)) {
        return false;
      }
    }
  }
  return true;
}

bool _overlaps(PixelRect left, PixelRect right) =>
    left.leftPx < right.leftPx + right.widthPx &&
    left.leftPx + left.widthPx > right.leftPx &&
    left.topPx < right.topPx + right.heightPx &&
    left.topPx + left.heightPx > right.topPx;
