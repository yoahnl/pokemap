import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/spatial_navigation.dart';

const _epsilon = 1e-6;

final class TerrainSlopePlan {
  TerrainSlopePlan({
    required this.direction,
    required this.left,
    required this.top,
    required this.width,
    required this.depth,
    required this.lowerHeight,
    required this.upperHeight,
  });

  final SpatialRampDirection direction;
  final int left, top, width, depth;
  final double lowerHeight, upperHeight;

  bool get alongX =>
      direction == SpatialRampDirection.east ||
      direction == SpatialRampDirection.west;

  int get length => alongX ? width : depth;

  late final Set<GridPos> cells = Set.unmodifiable({
    for (var y = top; y < top + depth; y++)
      for (var x = left; x < left + width; x++) GridPos(x: x, y: y),
  });

  Set<GridPos> get highSide {
    final (dx, dy) = slopeClimb(direction);
    return {
      for (final cell in cells)
        if (!cells.contains(GridPos(x: cell.x + dx, y: cell.y + dy)))
          GridPos(x: cell.x + dx, y: cell.y + dy),
    };
  }
}

(int, int) slopeClimb(SpatialRampDirection direction) => switch (direction) {
  SpatialRampDirection.north => (0, -1),
  SpatialRampDirection.south => (0, 1),
  SpatialRampDirection.east => (1, 0),
  SpatialRampDirection.west => (-1, 0),
};

TerrainSlopePlan planTerrainSlope(MapData map, GridPos from, GridPos to) {
  final scene = _scene(map);
  for (final cell in [from, to]) {
    if (!_inside(scene, cell)) {
      throw ValidationException(
        'Drag inside the map.',
        code: 'spatial.slope.cells_invalid',
        details: {'cell': cell.toJson()},
      );
    }
  }
  final dx = to.x - from.x, dy = to.y - from.y;
  if (dx.abs() == dy.abs()) {
    throw const ValidationException(
      'Drag along one axis, from the low side to the high side.',
      code: 'spatial.slope.direction_ambiguous',
    );
  }
  final alongX = dx.abs() > dy.abs();
  final direction = alongX
      ? (dx > 0 ? SpatialRampDirection.east : SpatialRampDirection.west)
      : (dy > 0 ? SpatialRampDirection.south : SpatialRampDirection.north);
  final crossStart = alongX ? math.min(from.y, to.y) : math.min(from.x, to.x);
  final crossEnd = alongX ? math.max(from.y, to.y) : math.max(from.x, to.x);
  final step = (alongX ? dx : dy).sign;
  final start = alongX ? from.x : from.y, end = alongX ? to.x : to.y;
  GridPos at(int along, int cross) =>
      alongX ? GridPos(x: along, y: cross) : GridPos(x: cross, y: along);
  double height(GridPos cell) => scene.worldHeightAt(cell.x + .5, cell.y + .5);
  final lower = height(from), read = height(to);
  if (read < lower - _epsilon) {
    throw ValidationException(
      'Drag from the low side to the high side.',
      code: 'spatial.slope.downhill',
      details: {'lowerHeight': lower, 'upperHeight': read},
    );
  }
  final flat = (read - lower).abs() <= _epsilon;
  final upper = flat ? lower + scene.levelHeight : read;
  var last = end;
  bool rowAt(int along, double value) => [
    for (var cross = crossStart; cross <= crossEnd; cross++) at(along, cross),
  ].every((cell) => (height(cell) - value).abs() <= _epsilon);
  if (!flat) {
    while (last != start && rowAt(last, upper)) {
      last -= step;
    }
  }
  final uneven = [
    for (var along = start; along != last + step; along += step)
      for (var cross = crossStart; cross <= crossEnd; cross++)
        if ((height(at(along, cross)) - lower).abs() > _epsilon)
          at(along, cross),
  ];
  if (uneven.isNotEmpty || upper > 1024) {
    throw ValidationException(
      'A slope needs flat ground at the low level under all its cells.',
      code: 'spatial.slope.ground_not_flat',
      details: {
        'lowerHeight': lower,
        'cells': [for (final cell in uneven.take(20)) cell.toJson()],
      },
    );
  }
  final ramps = [
    for (var along = start; along != last + step; along += step)
      for (var cross = crossStart; cross <= crossEnd; cross++)
        if (scene.navigation.ramps.any(
          (ramp) =>
              ramp.contains(at(along, cross).x + .5, at(along, cross).y + .5),
        ))
          at(along, cross),
  ];
  if (ramps.isNotEmpty) {
    throw ValidationException(
      'A navigation ramp covers these cells; remove it before adding a slope.',
      code: 'spatial.terrain.paint.ramp_conflict',
      details: {
        'cells': [for (final cell in ramps.take(20)) cell.toJson()],
      },
    );
  }
  final alongStart = math.min(start, last), alongEnd = math.max(start, last);
  return TerrainSlopePlan(
    direction: direction,
    left: alongX ? alongStart : crossStart,
    top: alongX ? crossStart : alongStart,
    width: alongX ? alongEnd - alongStart + 1 : crossEnd - crossStart + 1,
    depth: alongX ? crossEnd - crossStart + 1 : alongEnd - alongStart + 1,
    lowerHeight: lower,
    upperHeight: upper,
  );
}

MapSpatialScene _scene(MapData map) {
  final scene = map.spatialScene;
  if (scene == null) {
    throw const ValidationException(
      'A slope requires a 3D map.',
      code: 'spatial.terrain.paint.dimension_required',
    );
  }
  return scene;
}

bool _inside(MapSpatialScene scene, GridPos cell) =>
    cell.x >= 0 && cell.y >= 0 && cell.x < scene.width && cell.y < scene.depth;
