import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_layer.dart';

/// Returns whether [layer] is the sparse SurfaceLayer introduced for Surface
/// placement authoring.
bool isSurfaceLayer(MapLayer layer) => layer is SurfaceLayer;

/// Returns the read-only sparse placements of a SurfaceLayer.
///
/// Surface placements deliberately keep only x/y/surfacePresetId. The autotile
/// role is resolved later from neighboring placements so map JSON does not
/// fossilize a derived tile choice.
List<SurfaceCellPlacement> getSurfacePlacements(MapLayer layer) {
  final surfaceLayer = _requireSurfaceLayer(layer);
  return List<SurfaceCellPlacement>.unmodifiable(surfaceLayer.placements);
}

/// Finds the placement at [x]/[y] if it exists.
SurfaceCellPlacement? surfacePlacementAt({
  required MapLayer layer,
  required int x,
  required int y,
}) {
  final surfaceLayer = _requireSurfaceLayer(layer);
  _requireNonNegativeCoordinate(x: x, y: y);
  for (final placement in surfaceLayer.placements) {
    if (placement.x == x && placement.y == y) {
      return placement;
    }
  }
  return null;
}

/// Paints or replaces one sparse Surface placement.
///
/// A coordinate can hold only one placement in V0. Painting the same x/y again
/// replaces the existing preset instead of appending a duplicate; after each
/// write placements are sorted for stable JSON diffs.
MapLayer paintSurfacePlacement({
  required MapLayer layer,
  required GridSize mapSize,
  required int x,
  required int y,
  required String surfacePresetId,
}) {
  final surfaceLayer = _requireSurfaceLayer(layer);
  _requireValidMapSize(mapSize);
  _requireInBounds(mapSize: mapSize, x: x, y: y);
  final normalizedPresetId = _requireSurfacePresetId(surfacePresetId);

  final updated = <SurfaceCellPlacement>[
    for (final placement in surfaceLayer.placements)
      if (placement.x != x || placement.y != y) placement,
    SurfaceCellPlacement(
      x: x,
      y: y,
      surfacePresetId: normalizedPresetId,
    ),
  ];

  return surfaceLayer.copyWith(placements: _sortedPlacements(updated));
}

/// Removes one sparse Surface placement.
///
/// The operation is intentionally a no-op when the cell is empty so erase tools
/// can be called repeatedly without manufacturing diagnostics or side effects.
MapLayer eraseSurfacePlacement({
  required MapLayer layer,
  required int x,
  required int y,
}) {
  final surfaceLayer = _requireSurfaceLayer(layer);
  _requireNonNegativeCoordinate(x: x, y: y);
  final updated = surfaceLayer.placements
      .where((placement) => placement.x != x || placement.y != y)
      .toList(growable: false);
  if (updated.length == surfaceLayer.placements.length) {
    return layer;
  }
  return surfaceLayer.copyWith(placements: updated);
}

/// Clears all sparse placements while preserving layer metadata.
MapLayer clearSurfacePlacements(MapLayer layer) {
  final surfaceLayer = _requireSurfaceLayer(layer);
  if (surfaceLayer.placements.isEmpty) {
    return layer;
  }
  return surfaceLayer.copyWith(placements: const []);
}

/// Replaces all placements after validating bounds and duplicate coordinates.
///
/// Bulk replacement refuses duplicate x/y entries because silently choosing a
/// winner would make imports and future editor tools depend on input order.
MapLayer replaceSurfacePlacements({
  required MapLayer layer,
  required GridSize mapSize,
  required Iterable<SurfaceCellPlacement> placements,
}) {
  final surfaceLayer = _requireSurfaceLayer(layer);
  _requireValidMapSize(mapSize);

  final seenCoordinates = <String>{};
  final normalized = <SurfaceCellPlacement>[];
  var index = 0;
  for (final placement in placements) {
    _requireInBounds(mapSize: mapSize, x: placement.x, y: placement.y);
    final coordinateKey = _coordinateKey(placement.x, placement.y);
    if (!seenCoordinates.add(coordinateKey)) {
      throw ValidationException(
        'Surface placement[$index] duplicates coordinates '
        '(${placement.x}, ${placement.y})',
      );
    }
    normalized.add(
      SurfaceCellPlacement(
        x: placement.x,
        y: placement.y,
        surfacePresetId: _requireSurfacePresetId(placement.surfacePresetId),
      ),
    );
    index++;
  }

  return surfaceLayer.copyWith(placements: _sortedPlacements(normalized));
}

SurfaceLayer _requireSurfaceLayer(MapLayer layer) {
  if (layer is SurfaceLayer) {
    return layer;
  }
  throw const ValidationException('Operation requires a SurfaceLayer');
}

void _requireValidMapSize(GridSize mapSize) {
  if (mapSize.width <= 0 || mapSize.height <= 0) {
    throw const ValidationException('Map size must be positive');
  }
}

void _requireInBounds({
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _requireNonNegativeCoordinate(x: x, y: y);
  if (x >= mapSize.width || y >= mapSize.height) {
    throw ValidationException(
      'Surface placement is outside map bounds: ($x, $y)',
    );
  }
}

void _requireNonNegativeCoordinate({
  required int x,
  required int y,
}) {
  if (x < 0 || y < 0) {
    throw ValidationException(
      'Surface placement coordinates must be non-negative: ($x, $y)',
    );
  }
}

String _requireSurfacePresetId(String surfacePresetId) {
  final normalized = surfacePresetId.trim();
  if (normalized.isEmpty) {
    throw const ValidationException('surfacePresetId cannot be empty');
  }
  return normalized;
}

List<SurfaceCellPlacement> _sortedPlacements(
  Iterable<SurfaceCellPlacement> placements,
) {
  final sorted = placements.toList(growable: false)
    ..sort((a, b) {
      final yComparison = a.y.compareTo(b.y);
      if (yComparison != 0) return yComparison;
      final xComparison = a.x.compareTo(b.x);
      if (xComparison != 0) return xComparison;
      return a.surfacePresetId.compareTo(b.surfacePresetId);
    });
  return List<SurfaceCellPlacement>.unmodifiable(sorted);
}

String _coordinateKey(int x, int y) => '$x:$y';
