import '../exceptions/map_exceptions.dart';
import '../models/map_layer.dart';
import '../models/surface.dart';

/// Immutable occupancy index for one Surface placement collection.
///
/// Building the index is O(P). Every subsequent role lookup probes at most the
/// eight neighboring coordinates, so editor/runtime callers can resolve a
/// whole layer without repeatedly enumerating the same placements.
///
/// The index deliberately owns no application cache or revision policy. Those
/// concerns stay in the editor/runtime packages that know when a layer changes.
final class SurfacePlacementTopology {
  SurfacePlacementTopology(Iterable<SurfaceCellPlacement> placements) {
    final mutableCoordinatesByPresetId = <String, Set<(int, int)>>{};
    for (final placement in placements) {
      final presetId = placement.surfacePresetId.trim();
      if (presetId.isEmpty) {
        // An empty preset never matched the validated query adapter before the
        // optimization, so retaining it would only create unreachable state.
        continue;
      }
      mutableCoordinatesByPresetId
          .putIfAbsent(presetId, () => <(int, int)>{})
          .add((placement.x, placement.y));
    }

    _coordinatesByPresetId = Map<String, Set<(int, int)>>.unmodifiable(
      <String, Set<(int, int)>>{
        for (final entry in mutableCoordinatesByPresetId.entries)
          entry.key: Set<(int, int)>.unmodifiable(entry.value),
      },
    );
    occupiedCoordinateCount = _coordinatesByPresetId.values.fold<int>(
      0,
      (total, coordinates) => total + coordinates.length,
    );
  }

  late final Map<String, Set<(int, int)>> _coordinatesByPresetId;

  /// Number of unique `(preset, x, y)` occupancy entries held by the index.
  late final int occupiedCoordinateCount;

  /// Resolves a role from the already-indexed occupancy domain.
  SurfaceVariantRole roleAt({
    required int x,
    required int y,
    required String surfacePresetId,
  }) {
    _requireNonNegativeCoordinate(x: x, y: y);
    final normalizedPresetId = _requireSurfacePresetId(surfacePresetId);
    final matchingCoordinates =
        _coordinatesByPresetId[normalizedPresetId] ?? const <(int, int)>{};

    return resolveSurfaceVariantRoleAt(
      x: x,
      y: y,
      matchesAt: (nextX, nextY) => matchingCoordinates.contains((nextX, nextY)),
    );
  }
}

/// Resolves the V0 visual role for a sparse Surface placement.
///
/// The resolver is deliberately pure and read-only: it computes a derived
/// [SurfaceVariantRole] from neighboring placements without writing that role
/// back into map JSON. Only placements from the same SurfaceLayer input and the
/// same normalized `surfacePresetId` connect to each other; terrain, path, and
/// other Surface presets are invisible to this calculation.
SurfaceVariantRole resolveSurfaceVariantRoleForPlacement({
  required Iterable<SurfaceCellPlacement> placements,
  required int x,
  required int y,
  required String surfacePresetId,
}) {
  _requireNonNegativeCoordinate(x: x, y: y);
  final normalizedPresetId = _requireSurfacePresetId(surfacePresetId);
  return SurfacePlacementTopology(placements).roleAt(
    x: x,
    y: y,
    surfacePresetId: normalizedPresetId,
  );
}

/// Resolves a native Surface role against an arbitrary complete occupancy
/// domain.
///
/// The callback is intentionally asset-agnostic. Border uses it to classify a
/// cell against the complete painted region before retaining only its inner
/// ground band; ordinary Surface layers keep using the placement adapter
/// above.
SurfaceVariantRole resolveSurfaceVariantRoleAt({
  required int x,
  required int y,
  required bool Function(int x, int y) matchesAt,
}) {
  _requireNonNegativeCoordinate(x: x, y: y);
  final mask = _resolveSurfaceCardinalMaskAt(
    x: x,
    y: y,
    matchesAt: matchesAt,
  );
  if (mask != 15) {
    return resolveSurfaceVariantRoleFromCardinalMask(mask);
  }

  final hasNE = matchesAt(x + 1, y - 1);
  final hasSE = matchesAt(x + 1, y + 1);
  final hasSW = matchesAt(x - 1, y + 1);
  final hasNW = matchesAt(x - 1, y - 1);

  if (!hasNE && hasSE && hasSW && hasNW) {
    return SurfaceVariantRole.innerCornerNE;
  }
  if (hasNE && !hasSE && hasSW && hasNW) {
    return SurfaceVariantRole.innerCornerSE;
  }
  if (hasNE && hasSE && !hasSW && hasNW) {
    return SurfaceVariantRole.innerCornerSW;
  }
  if (hasNE && hasSE && hasSW && !hasNW) {
    return SurfaceVariantRole.innerCornerNW;
  }

  return SurfaceVariantRole.cross;
}

/// Maps the V0 cardinal neighbor mask to the native Surface role vocabulary.
///
/// Mask bits follow the existing path autotile convention:
/// north = 1, east = 2, south = 4, west = 8.
SurfaceVariantRole resolveSurfaceVariantRoleFromCardinalMask(int mask) {
  return switch (mask) {
    0 => SurfaceVariantRole.isolated,
    1 => SurfaceVariantRole.endNorth,
    2 => SurfaceVariantRole.endEast,
    3 => SurfaceVariantRole.cornerNE,
    4 => SurfaceVariantRole.endSouth,
    5 => SurfaceVariantRole.vertical,
    6 => SurfaceVariantRole.cornerSE,
    7 => SurfaceVariantRole.teeEast,
    8 => SurfaceVariantRole.endWest,
    9 => SurfaceVariantRole.cornerNW,
    10 => SurfaceVariantRole.horizontal,
    11 => SurfaceVariantRole.teeNorth,
    12 => SurfaceVariantRole.cornerSW,
    13 => SurfaceVariantRole.teeWest,
    14 => SurfaceVariantRole.teeSouth,
    15 => SurfaceVariantRole.cross,
    _ => throw ValidationException('Invalid surface cardinal mask: $mask'),
  };
}

int _resolveSurfaceCardinalMaskAt({
  required int x,
  required int y,
  required bool Function(int x, int y) matchesAt,
}) {
  var mask = 0;
  if (matchesAt(x, y - 1)) mask |= 1;
  if (matchesAt(x + 1, y)) mask |= 2;
  if (matchesAt(x, y + 1)) mask |= 4;
  if (matchesAt(x - 1, y)) mask |= 8;
  return mask;
}

void _requireNonNegativeCoordinate({
  required int x,
  required int y,
}) {
  if (x < 0 || y < 0) {
    throw ValidationException(
      'Surface role coordinates must be non-negative: ($x, $y)',
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
