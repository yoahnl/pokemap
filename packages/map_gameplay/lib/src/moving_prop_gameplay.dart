import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'gameplay_world_state.dart';

enum MovingPropMoveOutcome { moved, blocked }

final class MovingPropMotionFrame {
  MovingPropMotionFrame(
      {required Map<String, PixelOffset> positions, required this.returning})
      : positions = Map.unmodifiable(positions);

  final Map<String, PixelOffset> positions;
  final bool returning;
}

final class MovingPropMoveResult {
  MovingPropMoveResult(
      {required this.outcome,
      required this.finalWorldState,
      required List<MovingPropMotionFrame> frames})
      : frames = List.unmodifiable(frames);

  final MovingPropMoveOutcome outcome;
  final MovingPropWorldState finalWorldState;
  final List<MovingPropMotionFrame> frames;
}

void validateGameplayMovingPropWorldState({
  required ProjectManifest project,
  required Iterable<MapData> maps,
  required MovingPropWorldState worldState,
  GameState? gameState,
  MovingPlatformWorldState movingPlatformWorldState =
      const MovingPlatformWorldState.empty(),
  NpcMapPresencePredicate? npcMapPresencePredicate,
  MapEntityPresencePredicate? mapEntityPresencePredicate,
}) {
  final materialized = maps.toList();
  validateMovingPropWorldState(
      project: project, maps: materialized, worldState: worldState);
  for (final map in materialized.where((map) => map.movingProps.isNotEmpty)) {
    if (gameState == null &&
        map.entities.any((entity) => entity.presentation != null)) {
      throw const FormatException(
          'Prop collision validation requires entity presentation state.');
    }
    final world = GameplayWorldState.initial(
        map: map,
        project: project,
        movingPropWorldState: worldState,
        movingPlatformWorldState: movingPlatformWorldState,
        gameState: gameState,
        playerPos: const GridPos(x: 0, y: 0),
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        npcMapPresencePredicate: npcMapPresencePredicate,
        mapEntityPresencePredicate: mapEntityPresencePredicate);
    _validateStationaryProps(world);
  }
}

MovingPropMoveResult moveGameplayProps({
  required GameplayWorldState world,
  required ProjectManifest project,
  required MovingPropWorldState worldState,
  required List<String> propIds,
  required MovingPropState state,
}) {
  if (propIds.isEmpty ||
      propIds.length > 32 ||
      propIds.toSet().length != propIds.length ||
      propIds.any((id) => id.isEmpty || id.trim() != id) ||
      world.movingPropPositions.isNotEmpty) {
    throw const FormatException(
        'Moving prop selection is invalid or already moving.');
  }
  validateMovingPropDefinitions(
      map: world.map,
      project: project,
      tileSize:
          PixelSize(width: world.tileWidthPx, height: world.tileHeightPx));
  final initialized =
      initializeMovingPropWorldState(map: world.map, worldState: worldState);
  final source =
      world.withMovingPropState(project: project, worldState: initialized);
  _validateStationaryProps(source);
  final byId = {for (final prop in source.map.movingProps) prop.id: prop};
  if (propIds.any((id) => !byId.containsKey(id))) {
    throw const FormatException('Moving prop is missing.');
  }
  final selected = [for (final id in propIds) byId[id]!];
  final ignored = propIds.toSet();
  final start = {
    for (final prop in selected)
      prop.id: _position(
          prop, initialized.prop(source.map.id, prop.id) ?? prop.initialState)
  };
  final target = {for (final prop in selected) prop.id: _position(prop, state)};
  var distance = 0;
  for (final id in propIds) {
    distance = math.max(
        distance,
        (target[id]!.x - start[id]!.x).abs() +
            (target[id]!.y - start[id]!.y).abs());
  }
  final frames = <MovingPropMotionFrame>[];
  MovingPropMoveResult blocked() => MovingPropMoveResult(
          outcome: MovingPropMoveOutcome.blocked,
          finalWorldState: initialized,
          frames: [
            ...frames,
            for (var i = frames.length - 2; i >= 0; i--)
              MovingPropMotionFrame(
                  positions: frames[i].positions, returning: true),
            if (frames.isNotEmpty)
              MovingPropMotionFrame(positions: start, returning: true),
          ]);
  final platforms = _platformRects(source);
  final playerRect = source.player.playerCollisionRectPx;
  if (selected
      .any((prop) => _overlaps(_rect(prop, start[prop.id]!), playerRect))) {
    return blocked();
  }
  var previous = start;
  for (var step = 1; step <= distance; step++) {
    final positions = {
      for (final id in propIds)
        id: PixelOffset(
            x: start[id]!.x +
                ((target[id]!.x - start[id]!.x) * step / distance).round(),
            y: start[id]!.y +
                ((target[id]!.y - start[id]!.y) * step / distance).round())
    };
    final rects = [
      for (final prop in selected) _rect(prop, positions[prop.id]!)
    ];
    for (var i = 0; i < selected.length; i++) {
      final rect = rects[i];
      if (source.worldStaticObstaclesCollidePixelRect(rect,
              ignoredMovingPropIds: ignored) ||
          _overlaps(rect, playerRect) ||
          platforms.any((other) => _overlaps(rect, other))) {
        return blocked();
      }
      for (var j = 0; j < i; j++) {
        if (_sweptOverlap(_rect(selected[i], previous[selected[i].id]!), rect,
            _rect(selected[j], previous[selected[j].id]!), rects[j])) {
          return blocked();
        }
      }
    }
    frames.add(MovingPropMotionFrame(positions: positions, returning: false));
    previous = positions;
  }
  var result = initialized;
  for (final prop in selected) {
    result =
        result.withProp(mapId: source.map.id, propId: prop.id, state: state);
  }
  return MovingPropMoveResult(
      outcome: MovingPropMoveOutcome.moved,
      finalWorldState: result,
      frames: frames);
}

void _validateStationaryProps(GameplayWorldState world) {
  final ids = world.map.movingProps.map((prop) => prop.id).toSet();
  final rects = movingPropCollisionRects(
          map: world.map,
          worldState: world.movingPropWorldState,
          positions: world.movingPropPositions)
      .toList();
  final platforms = _platformRects(world);
  for (var i = 0; i < rects.length; i++) {
    if (world.worldStaticObstaclesCollidePixelRect(rects[i],
            ignoredMovingPropIds: ids) ||
        platforms.any((platform) => _overlaps(rects[i], platform)) ||
        rects.take(i).any((other) => _overlaps(rects[i], other))) {
      throw const FormatException('Moving prop state overlaps an obstacle.');
    }
  }
}

List<PixelRect> _platformRects(GameplayWorldState world) => [
      for (final platform in world.map.movingPlatforms)
        for (final cell in platform
            .variants[(world.movingPlatformWorldState
                        .platform(world.map.id, platform.id) ??
                    platform.initialPose)
                .quarterTurns]
            .clearanceCells)
          movingPlatformCellRect(
              platform: platform,
              pose: world.movingPlatformWorldState
                      .platform(world.map.id, platform.id) ??
                  platform.initialPose,
              cell: cell),
    ];

PixelOffset _position(MovingPropDefinition prop, MovingPropState state) =>
    state == MovingPropState.open ? prop.openPositionPx : prop.closedPositionPx;

PixelRect _rect(MovingPropDefinition prop, PixelOffset position) => PixelRect(
    leftPx: position.x + prop.collisionRect.leftPx,
    topPx: position.y + prop.collisionRect.topPx,
    widthPx: prop.collisionRect.widthPx,
    heightPx: prop.collisionRect.heightPx);

bool _overlaps(PixelRect a, PixelRect b) =>
    a.leftPx < b.leftPx + b.widthPx &&
    a.leftPx + a.widthPx > b.leftPx &&
    a.topPx < b.topPx + b.heightPx &&
    a.topPx + a.heightPx > b.topPx;

bool _sweptOverlap(PixelRect a0, PixelRect a1, PixelRect b0, PixelRect b1) {
  var entry = 0.0;
  var exit = 1.0;
  for (final axis in [
    (
      a0.leftPx,
      a0.widthPx,
      b0.leftPx,
      b0.widthPx,
      a1.leftPx - a0.leftPx - b1.leftPx + b0.leftPx
    ),
    (
      a0.topPx,
      a0.heightPx,
      b0.topPx,
      b0.heightPx,
      a1.topPx - a0.topPx - b1.topPx + b0.topPx
    ),
  ]) {
    final (a, sizeA, b, sizeB, velocity) = axis;
    if (velocity == 0) {
      if (a + sizeA <= b || a >= b + sizeB) return false;
    } else {
      final t1 = (b - a - sizeA) / velocity;
      final t2 = (b + sizeB - a) / velocity;
      entry = math.max(entry, math.min(t1, t2));
      exit = math.min(exit, math.max(t1, t2));
    }
  }
  return entry < exit;
}
