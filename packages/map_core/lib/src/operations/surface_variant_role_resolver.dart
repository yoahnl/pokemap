import '../exceptions/map_exceptions.dart';
import '../models/map_layer.dart';
import '../models/surface.dart';

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
  final matchingCoordinates = <String>{
    for (final placement in placements)
      if (placement.surfacePresetId.trim() == normalizedPresetId)
        _coordinateKey(placement.x, placement.y),
  };

  bool matchesAt(int nextX, int nextY) {
    return matchingCoordinates.contains(_coordinateKey(nextX, nextY));
  }

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

String _coordinateKey(int x, int y) => '$x:$y';
