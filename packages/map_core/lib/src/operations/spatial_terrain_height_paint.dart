import '../exceptions/map_exceptions.dart';
import '../models/border_ground_footprint.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/spatial_terrain_surface.dart';
import 'spatial_map_operations.dart';

const _epsilon = 1e-6;

final class TerrainHeightPaint {
  const TerrainHeightPaint({
    required this.map,
    required this.surfaceId,
    required this.upsertedSurfaceIds,
    required this.deletedSurfaceIds,
  });
  final MapData map;
  final String? surfaceId;
  final List<String> upsertedSurfaceIds;
  final List<String> deletedSurfaceIds;
}

TerrainHeightPaint paintTerrainCellsAtHeight(
  MapData map,
  Iterable<GridPos> cells, {
  required double height,
  String? newSurfaceId,
  bool reanchorInstances = true,
  bool pinBorderOwnedInstances = false,
}) {
  final scene = map.spatialScene;
  if (scene == null) {
    throw const ValidationException(
      'Painting a height requires a 3D map.',
      code: 'spatial.terrain.paint.dimension_required',
    );
  }
  if (!height.isFinite || height < 0 || height > 1024) {
    throw ValidationException(
      'Choose a height from 0 to 1024 world units.',
      code: 'spatial.terrain.paint.height_invalid',
      details: {'height': height},
    );
  }
  final painted = cells.toSet();
  if (painted.isEmpty ||
      painted.length > 65536 ||
      painted.any(
        (cell) =>
            cell.x < 0 ||
            cell.y < 0 ||
            cell.x >= scene.width ||
            cell.y >= scene.depth,
      )) {
    throw const ValidationException(
      'Paint 1 to 65536 cells inside the map.',
      code: 'spatial.terrain.paint.cells_invalid',
    );
  }
  final ramps = [
    for (final cell in painted)
      if (scene.navigation.ramps.any(
        (r) => r.contains(cell.x + .5, cell.y + .5),
      ))
        cell,
  ];
  if (ramps.isNotEmpty) {
    throw ValidationException(
      'A navigation ramp covers these cells; remove it before painting a height.',
      code: 'spatial.terrain.paint.ramp_conflict',
      details: {'cells': _cellsJson(ramps)},
    );
  }
  final surfaces = scene.terrainSurfaces.surfaces;
  final cut = <SpatialTerrainSurface>[];
  final merge = <SpatialTerrainSurface>[];
  for (final surface in surfaces) {
    final overlapped = painted.any((c) => surface.overlapsCell(c.x, c.y));
    if (overlapped && _maximumOver(surface, painted) > height + _epsilon) {
      cut.add(surface);
    } else if (_flatAt(surface, height) &&
        _cellAligned(surface) &&
        (overlapped || painted.any((c) => _touches(surface, c)))) {
      merge.add(surface);
    }
  }
  for (final surface in cut) {
    if (!_cellAligned(surface)) {
      throw ValidationException(
        'This continuous surface does not follow the grid; edit it directly.',
        code: 'spatial.terrain.paint.surface_not_cell_aligned',
        details: {'surfaceId': surface.id},
      );
    }
  }
  final upserts = <SpatialTerrainSurface>[];
  final deleted = <String>[];
  for (final surface in cut) {
    final remaining = _cellsOf(surface)..removeAll(painted);
    if (remaining.isEmpty) {
      deleted.add(surface.id);
    } else {
      upserts.add(_withCells(surface, remaining));
    }
  }
  final target = merge.isEmpty ? null : merge.first;
  final union = {for (final surface in merge) ..._cellsOf(surface), ...painted};
  final targetId = target?.id ?? newSurfaceId ?? _nextSurfaceId(scene);
  if (target == null && surfaces.any((surface) => surface.id == targetId)) {
    throw ValidationException(
      'This terrain surface identity is already used.',
      code: 'spatial.terrain.paint.surface_identity_conflict',
      details: {'surfaceId': targetId},
    );
  }
  final left = union.map((c) => c.x).reduce((a, b) => a < b ? a : b);
  final top = union.map((c) => c.y).reduce((a, b) => a < b ? a : b);
  final painting = _withCells(
    target ??
        SpatialTerrainSurface(
          id: targetId,
          x: left.toDouble(),
          z: top.toDouble(),
          height: height,
          footprints: [_rectangle(0, 0, 1, 1)],
        ),
    union,
  );
  if (target == null || painting != target) upserts.add(painting);
  deleted.addAll(merge.skip(1).map((surface) => surface.id));
  final count = surfaces.length - deleted.length + (target == null ? 1 : 0);
  if (count > maximumSpatialTerrainSurfaces) {
    throw ValidationException(
      'A map holds at most $maximumSpatialTerrainSurfaces terrain surfaces.',
      code: 'spatial.terrain.paint.surface_limit',
      details: {
        'surfaceCount': count,
        'maximum': maximumSpatialTerrainSurfaces,
      },
    );
  }
  const operations = SpatialMapOperations();
  var result = map;
  if (upserts.isNotEmpty) {
    result = operations.upsertTerrainSurfaces(
      result,
      upserts,
      reanchorInstances: reanchorInstances,
      pinBorderOwnedInstances: pinBorderOwnedInstances,
    );
  }
  if (deleted.isNotEmpty) {
    result = operations.deleteTerrainSurfaces(
      result,
      deleted,
      reanchorInstances: reanchorInstances,
      pinBorderOwnedInstances: pinBorderOwnedInstances,
    );
  }
  return TerrainHeightPaint(
    map: result,
    surfaceId: targetId,
    upsertedSurfaceIds: List.unmodifiable(upserts.map((s) => s.id)),
    deletedSurfaceIds: List.unmodifiable(deleted),
  );
}

double _maximumOver(SpatialTerrainSurface surface, Set<GridPos> cells) {
  var maximum = double.negativeInfinity;
  for (final cell in cells) {
    if (!surface.overlapsCell(cell.x, cell.y)) continue;
    for (final (dx, dz) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      final value = surface.heightAt(
        (cell.x + dx).toDouble(),
        (cell.y + dz).toDouble(),
      );
      if (value > maximum) maximum = value;
    }
  }
  return maximum;
}

bool _flatAt(SpatialTerrainSurface surface, double height) =>
    surface.gradientX == 0 &&
    surface.gradientZ == 0 &&
    (surface.height - height).abs() <= _epsilon;

bool _touches(SpatialTerrainSurface surface, GridPos cell) => const [
  (1, 0),
  (-1, 0),
  (0, 1),
  (0, -1),
].any((d) => surface.contains(cell.x + d.$1 + .5, cell.y + d.$2 + .5));

bool _cellAligned(SpatialTerrainSurface surface) => surface.footprints.every((
  footprint,
) {
  final xs = footprint.points.map((p) => surface.x + p.x).toSet();
  final zs = footprint.points.map((p) => surface.z + p.z).toSet();
  return xs.length == 2 &&
      zs.length == 2 &&
      [...xs, ...zs].every((v) => (v - v.roundToDouble()).abs() <= _epsilon);
});

Set<GridPos> _cellsOf(SpatialTerrainSurface surface) {
  final bounds = surface.bounds;
  return {
    for (var y = bounds.top.round(); y < bounds.bottom.round(); y++)
      for (var x = bounds.left.round(); x < bounds.right.round(); x++)
        if (surface.contains(x + .5, y + .5)) GridPos(x: x, y: y),
  };
}

SpatialTerrainSurface _withCells(
  SpatialTerrainSurface surface,
  Set<GridPos> cells,
) {
  final rectangles = decomposeCellsIntoRectangles(cells);
  if (rectangles.length > maximumSpatialTerrainSurfaceFootprints) {
    throw ValidationException(
      'This shape needs ${rectangles.length} rectangles; a terrain surface holds at most $maximumSpatialTerrainSurfaceFootprints.',
      code: 'spatial.terrain.paint.footprint_limit',
      details: {
        'surfaceId': surface.id,
        'footprintCount': rectangles.length,
        'maximum': maximumSpatialTerrainSurfaceFootprints,
      },
    );
  }
  return surface.copyWith(
    footprints: [
      for (final r in rectangles)
        _rectangle(
          r.x - surface.x,
          r.y - surface.z,
          r.x + r.width - surface.x,
          r.y + r.height - surface.z,
        ),
    ],
  );
}

List<({int x, int y, int width, int height})> decomposeCellsIntoRectangles(
  Set<GridPos> cells,
) {
  final remaining = cells.toSet();
  final ordered = cells.toList()
    ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
  final rectangles = <({int x, int y, int width, int height})>[];
  for (final start in ordered) {
    if (!remaining.contains(start)) continue;
    var width = 1;
    while (remaining.contains(GridPos(x: start.x + width, y: start.y))) {
      width++;
    }
    var height = 1;
    while (List.generate(
      width,
      (i) => GridPos(x: start.x + i, y: start.y + height),
    ).every(remaining.contains)) {
      height++;
    }
    for (var y = start.y; y < start.y + height; y++) {
      for (var x = start.x; x < start.x + width; x++) {
        remaining.remove(GridPos(x: x, y: y));
      }
    }
    rectangles.add((x: start.x, y: start.y, width: width, height: height));
  }
  return rectangles;
}

BorderGroundFootprint _rectangle(num left, num top, num right, num bottom) =>
    BorderGroundFootprint(
      points: [
        BorderGroundPoint(x: left.toDouble(), z: top.toDouble()),
        BorderGroundPoint(x: right.toDouble(), z: top.toDouble()),
        BorderGroundPoint(x: right.toDouble(), z: bottom.toDouble()),
        BorderGroundPoint(x: left.toDouble(), z: bottom.toDouble()),
      ],
    );

String _nextSurfaceId(MapSpatialScene scene) {
  final ids = {for (final s in scene.terrainSurfaces.surfaces) s.id};
  var index = 1;
  while (ids.contains('terrain_surface_$index')) {
    index++;
  }
  return 'terrain_surface_$index';
}

List<Map<String, int>> _cellsJson(List<GridPos> cells) => [
  for (final cell in cells.take(20)) {'x': cell.x, 'y': cell.y},
];
