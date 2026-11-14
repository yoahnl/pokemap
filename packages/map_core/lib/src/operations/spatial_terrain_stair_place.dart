import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/project_model3d.dart';
import '../models/spatial_navigation.dart';
import 'spatial_map_operations.dart';
import 'spatial_terrain_slope_paint.dart';
import 'spatial_terrain_slope_plan.dart';
import 'spatial_terrain_stair_model.dart';

const _epsilon = 1e-6;
const _turnOrder = [
  SpatialRampDirection.north,
  SpatialRampDirection.west,
  SpatialRampDirection.south,
  SpatialRampDirection.east,
];

final class TerrainStairPlacement {
  const TerrainStairPlacement({
    required this.slope,
    required this.instance,
    required this.stair,
  });
  final TerrainSlopePaint slope;
  final SpatialModelInstance instance;
  final TerrainStairModel stair;
  MapData get map => slope.map;
}

TerrainStairPlacement placeTerrainStair({
  required ProjectManifest manifest,
  required MapData map,
  required GridPos cell,
  required String modelId,
  bool reanchorInstances = true,
}) {
  final scene = map.spatialScene;
  if (scene == null) {
    throw const ValidationException(
      'A stair requires a 3D map.',
      code: 'spatial.terrain.paint.dimension_required',
    );
  }
  final stair = terrainStairModel(manifest, map, modelId);
  final plan = planTerrainStair(map, cell, stair);
  final slope = applyTerrainSlope(
    manifest: manifest,
    map: map,
    plan: plan,
    reanchorInstances: reanchorInstances,
  );
  final instance = stairInstance(slope.map.spatialScene!, plan, stair);
  return TerrainStairPlacement(
    slope: TerrainSlopePaint(
      map: const SpatialMapOperations().upsertInstance(slope.map, instance),
      plan: slope.plan,
      surfaceId: slope.surfaceId,
      traces: slope.traces,
      refreshedBorders: slope.refreshedBorders,
      staleBorders: slope.staleBorders,
      resolvedBorderFeatures: slope.resolvedBorderFeatures,
    ),
    instance: instance,
    stair: stair,
  );
}

TerrainSlopePlan planTerrainStair(
  MapData map,
  GridPos cell,
  TerrainStairModel stair,
) {
  final scene = map.spatialScene!;
  bool inside(GridPos c) =>
      c.x >= 0 && c.y >= 0 && c.x < scene.width && c.y < scene.depth;
  double height(GridPos c) => scene.worldHeightAt(c.x + .5, c.y + .5);
  if (!inside(cell)) {
    throw ValidationException(
      'Click inside the map.',
      code: 'spatial.stair.cells_invalid',
      details: {'cell': cell.toJson()},
    );
  }
  final here = height(cell);
  final steps = [
    for (final direction in _turnOrder)
      if (_neighbor(cell, direction) case final next
          when inside(next) && (height(next) - here).abs() > _epsilon)
        (direction: direction, next: next, up: height(next) > here),
  ];
  if (steps.isEmpty) {
    throw ValidationException(
      'Click the edge of a cliff.',
      code: 'spatial.stair.no_cliff',
      details: {'cell': cell.toJson()},
    );
  }
  if (steps.length > 1) {
    throw ValidationException(
      'This cell touches several height steps; click a straight part of the cliff.',
      code: 'spatial.stair.edge_ambiguous',
      details: {
        'cell': cell.toJson(),
        'directions': [for (final step in steps) step.direction.name],
      },
    );
  }
  final step = steps.single;
  final direction = step.up ? step.direction : _opposite(step.direction);
  final low = step.up ? cell : step.next, high = step.up ? step.next : cell;
  final lower = height(low), upper = height(high);
  final levels = (upper - lower) / scene.levelHeight;
  if ((levels - stair.levels).abs() > _epsilon) {
    throw ValidationException(
      'This stair climbs ${stair.levels} levels; this cliff is ${levels.toStringAsFixed(2)} levels high.',
      code: 'spatial.stair.height_mismatch',
      details: {'modelLevels': stair.levels, 'stepLevels': levels},
    );
  }
  final alongX =
      direction == SpatialRampDirection.east ||
      direction == SpatialRampDirection.west;
  final (dx, dy) = slopeClimb(direction);
  final crossStart = (alongX ? low.y : low.x) - (stair.acrossCells - 1) ~/ 2;
  final alongNear = alongX ? low.x : low.y;
  final alongFar = alongNear - (alongX ? dx : dy) * (stair.alongCells - 1);
  final alongStart = alongNear < alongFar ? alongNear : alongFar;
  final plan = TerrainSlopePlan(
    direction: direction,
    left: alongX ? alongStart : crossStart,
    top: alongX ? crossStart : alongStart,
    width: alongX ? stair.alongCells : stair.acrossCells,
    depth: alongX ? stair.acrossCells : stair.alongCells,
    lowerHeight: lower,
    upperHeight: upper,
  );
  final blocked = [
    for (final c in plan.cells)
      if (!inside(c) ||
          (height(c) - lower).abs() > _epsilon ||
          scene.navigation.ramps.any((r) => r.contains(c.x + .5, c.y + .5)))
        c,
    for (final c in plan.highSide)
      if (!inside(c) || (height(c) - upper).abs() > _epsilon) c,
  ];
  if (blocked.isNotEmpty) {
    throw ValidationException(
      'This stair needs flat low ground in front of a straight cliff of its width.',
      code: 'spatial.stair.no_room',
      details: {
        'cells': [for (final c in blocked.take(20)) c.toJson()],
      },
    );
  }
  return plan;
}

SpatialModelInstance stairInstance(
  MapSpatialScene scene,
  TerrainSlopePlan plan,
  TerrainStairModel stair,
) {
  final model = stair.model;
  final turns =
      (_turnOrder.indexOf(plan.direction) -
          _turnOrder.indexOf(stair.nativeDirection) +
          4) %
      4;
  final bounds = model.inspection.bounds;
  final center = _rotate(
    ((bounds.min.x + bounds.max.x) / 2 - model.pivot.x) * model.scale,
    ((bounds.min.z + bounds.max.z) / 2 - model.pivot.z) * model.scale,
    turns,
  );
  final ids = {for (final instance in scene.instances) instance.id};
  var index = 1;
  while (ids.contains('stair-$index')) {
    index++;
  }
  return SpatialModelInstance(
    id: 'stair-$index',
    modelId: model.id,
    position: Model3dVector3(
      x: plan.left + plan.width / 2 - center.$1,
      y: plan.lowerHeight - (bounds.min.y - model.pivot.y) * model.scale,
      z: plan.top + plan.depth / 2 - center.$2,
    ),
    rotationDegrees: turns * 90.0,
    blocksMovement: false,
  );
}

GridPos _neighbor(GridPos cell, SpatialRampDirection direction) {
  final (dx, dy) = slopeClimb(direction);
  return GridPos(x: cell.x + dx, y: cell.y + dy);
}

SpatialRampDirection _opposite(SpatialRampDirection direction) =>
    _turnOrder[(_turnOrder.indexOf(direction) + 2) % 4];

(double, double) _rotate(double x, double z, int turns) => switch (turns) {
  0 => (x, z),
  1 => (z, -x),
  2 => (-x, -z),
  _ => (-z, x),
};
