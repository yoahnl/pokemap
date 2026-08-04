import '../exceptions/map_exceptions.dart';
import '../models/border_ground_variant_role.dart';

/// Resolves the visual role of one Border ground cell from its neighbours.
BorderGroundVariantRole resolveBorderGroundVariantRoleAt({
  required int x,
  required int y,
  required bool Function(int x, int y) matchesAt,
}) {
  _requireNonNegativeCoordinate(x: x, y: y);
  final mask = _resolveCardinalMaskAt(
    x: x,
    y: y,
    matchesAt: matchesAt,
  );
  if (mask != 15) {
    return resolveBorderGroundVariantRoleFromCardinalMask(mask);
  }

  final hasNE = matchesAt(x + 1, y - 1);
  final hasSE = matchesAt(x + 1, y + 1);
  final hasSW = matchesAt(x - 1, y + 1);
  final hasNW = matchesAt(x - 1, y - 1);

  if (!hasNE && hasSE && hasSW && hasNW) {
    return BorderGroundVariantRole.innerCornerNE;
  }
  if (hasNE && !hasSE && hasSW && hasNW) {
    return BorderGroundVariantRole.innerCornerSE;
  }
  if (hasNE && hasSE && !hasSW && hasNW) {
    return BorderGroundVariantRole.innerCornerSW;
  }
  if (hasNE && hasSE && hasSW && !hasNW) {
    return BorderGroundVariantRole.innerCornerNW;
  }

  return BorderGroundVariantRole.cross;
}

/// Maps north = 1, east = 2, south = 4 and west = 8 to a Border role.
BorderGroundVariantRole resolveBorderGroundVariantRoleFromCardinalMask(
  int mask,
) =>
    switch (mask) {
      0 => BorderGroundVariantRole.isolated,
      1 => BorderGroundVariantRole.endNorth,
      2 => BorderGroundVariantRole.endEast,
      3 => BorderGroundVariantRole.cornerNE,
      4 => BorderGroundVariantRole.endSouth,
      5 => BorderGroundVariantRole.vertical,
      6 => BorderGroundVariantRole.cornerSE,
      7 => BorderGroundVariantRole.teeEast,
      8 => BorderGroundVariantRole.endWest,
      9 => BorderGroundVariantRole.cornerNW,
      10 => BorderGroundVariantRole.horizontal,
      11 => BorderGroundVariantRole.teeNorth,
      12 => BorderGroundVariantRole.cornerSW,
      13 => BorderGroundVariantRole.teeWest,
      14 => BorderGroundVariantRole.teeSouth,
      15 => BorderGroundVariantRole.cross,
      _ =>
        throw ValidationException('Invalid Border ground cardinal mask: $mask'),
    };

int _resolveCardinalMaskAt({
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
      'Border ground coordinates must be non-negative: ($x, $y)',
    );
  }
}
