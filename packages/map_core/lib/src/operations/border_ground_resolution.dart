import 'dart:typed_data';

import '../models/border_blueprint.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_local_resolution_scope.dart';
import 'border_rle_codec.dart';
import 'border_ground_variant_role_resolver.dart';

/// Resolves the optional Border ground strictly inside a region's
/// morphological edge band.
///
/// Ground roles are evaluated against the complete region mask. Filtering to
/// [BorderPublishedGround.edgeBandCells] happens only afterwards, so a band
/// cell keeps the same role it would have had if the whole region were
/// materialized as one Border ground.
List<BorderResolvedGroundCell> resolveBorderGroundBand({
  required BorderRegionGeometry region,
  required BorderPublishedGround ground,
}) {
  final distances = _distanceFromRegionBoundary(region);
  final result = <BorderResolvedGroundCell>[];

  bool matchesAt(int x, int y) => _isFilled(region, x, y);

  for (var y = 0; y < region.height; y += 1) {
    for (var x = 0; x < region.width; x += 1) {
      final index = y * region.width + x;
      final distance = distances[index];
      if (distance == 0 || distance > ground.edgeBandCells) {
        continue;
      }
      final role = resolveBorderGroundVariantRoleAt(
        x: x,
        y: y,
        matchesAt: matchesAt,
      );
      result.add(
        BorderResolvedGroundCell(
          x: x,
          y: y,
          visualSnapshotId: ground.visualSnapshotIdsByRole[role]!,
          resolvedRole: role,
        ),
      );
    }
  }

  return List<BorderResolvedGroundCell>.unmodifiable(result);
}

/// Resolves only ground cells intersecting [scope] and retains distant cells.
///
/// The bounded distance query is equivalent to the complete distance
/// transform for the published edge-band depth, without visiting distant
/// ground subproblems.
List<BorderResolvedGroundCell> resolveBorderGroundBandLocally({
  required BorderRegionGeometry region,
  required BorderPublishedGround ground,
  required GridSize tileSizePx,
  required BorderLocalResolutionScope scope,
}) {
  final result = <BorderResolvedGroundCell>[
    for (final cell in scope.previousBaseGround)
      if (scope.retainsGround(cell, tileSizePx)) cell,
  ];

  bool matchesAt(int x, int y) => _isFilled(region, x, y);

  for (final cell in _affectedGroundCells(
    region: region,
    tileSizePx: tileSizePx,
    affectedBoundsPx: scope.affectedBoundsPx,
  )) {
    scope.recordRecomputedCell(cell);
    if (!_isFilled(region, cell.x, cell.y) ||
        !_withinBoundaryDistance(
          region,
          x: cell.x,
          y: cell.y,
          maximumDistance: ground.edgeBandCells,
        )) {
      continue;
    }
    final role = resolveBorderGroundVariantRoleAt(
      x: cell.x,
      y: cell.y,
      matchesAt: matchesAt,
    );
    result.add(
      BorderResolvedGroundCell(
        x: cell.x,
        y: cell.y,
        visualSnapshotId: ground.visualSnapshotIdsByRole[role]!,
        resolvedRole: role,
      ),
    );
  }
  result.sort((first, second) {
    final row = first.y.compareTo(second.y);
    return row != 0 ? row : first.x.compareTo(second.x);
  });
  return List<BorderResolvedGroundCell>.unmodifiable(result);
}

List<GridPos> _affectedGroundCells({
  required BorderRegionGeometry region,
  required GridSize tileSizePx,
  required List<BorderPixelRect> affectedBoundsPx,
}) {
  final cells = <GridPos>{};
  for (final bounds in affectedBoundsPx) {
    if (bounds.right <= 0 ||
        bounds.bottom <= 0 ||
        bounds.x >= region.width * tileSizePx.width ||
        bounds.y >= region.height * tileSizePx.height) {
      continue;
    }
    final firstX = _clamp(
      _floorDiv(bounds.x, tileSizePx.width),
      0,
      region.width - 1,
    );
    final lastX = _clamp(
      _floorDiv(bounds.right - 1, tileSizePx.width),
      0,
      region.width - 1,
    );
    final firstY = _clamp(
      _floorDiv(bounds.y, tileSizePx.height),
      0,
      region.height - 1,
    );
    final lastY = _clamp(
      _floorDiv(bounds.bottom - 1, tileSizePx.height),
      0,
      region.height - 1,
    );
    for (var y = firstY; y <= lastY; y += 1) {
      for (var x = firstX; x <= lastX; x += 1) {
        cells.add(GridPos(x: x, y: y));
      }
    }
  }
  final ordered = cells.toList(growable: false)
    ..sort((first, second) {
      final row = first.y.compareTo(second.y);
      return row != 0 ? row : first.x.compareTo(second.x);
    });
  return ordered;
}

int _floorDiv(int value, int positiveDivisor) {
  var result = value ~/ positiveDivisor;
  if (value.isNegative && value.remainder(positiveDivisor) != 0) {
    result -= 1;
  }
  return result;
}

int _clamp(int value, int minimum, int maximum) =>
    value < minimum ? minimum : (value > maximum ? maximum : value);

bool _withinBoundaryDistance(
  BorderRegionGeometry region, {
  required int x,
  required int y,
  required int maximumDistance,
}) {
  for (var distance = 1; distance <= maximumDistance; distance += 1) {
    for (var deltaX = -distance; deltaX <= distance; deltaX += 1) {
      final deltaY = distance - deltaX.abs();
      if (!_isFilled(region, x + deltaX, y + deltaY) ||
          (deltaY != 0 && !_isFilled(region, x + deltaX, y - deltaY))) {
        return true;
      }
    }
  }
  return false;
}

/// Returns one-based cardinal distance from the exterior for filled cells.
/// Empty cells retain zero and are never materialized.
List<int> _distanceFromRegionBoundary(BorderRegionGeometry region) {
  final cellCount = checkedBorderRleCellCount(
    width: region.width,
    height: region.height,
    path: r'$.region',
  );
  final distances = Uint16List(cellCount);
  const infinity = 0xffff;
  for (var y = 0; y < region.height; y += 1) {
    for (var x = 0; x < region.width; x += 1) {
      if (!_isFilled(region, x, y)) {
        continue;
      }
      final index = y * region.width + x;
      distances[index] = infinity;
    }
  }

  for (var y = 0; y < region.height; y += 1) {
    for (var x = 0; x < region.width; x += 1) {
      final index = y * region.width + x;
      if (distances[index] == 0) {
        continue;
      }
      final north = y == 0 ? 0 : distances[index - region.width];
      final west = x == 0 ? 0 : distances[index - 1];
      final candidate = (north < west ? north : west) + 1;
      if (candidate < distances[index]) {
        distances[index] = candidate;
      }
    }
  }

  for (var y = region.height - 1; y >= 0; y -= 1) {
    for (var x = region.width - 1; x >= 0; x -= 1) {
      final index = y * region.width + x;
      if (distances[index] == 0) {
        continue;
      }
      final south =
          y + 1 == region.height ? 0 : distances[index + region.width];
      final east = x + 1 == region.width ? 0 : distances[index + 1];
      final candidate = (south < east ? south : east) + 1;
      if (candidate < distances[index]) {
        distances[index] = candidate;
      }
    }
  }

  return distances;
}

bool _isFilled(BorderRegionGeometry region, int x, int y) =>
    x >= 0 &&
    y >= 0 &&
    x < region.width &&
    y < region.height &&
    region.cells[y * region.width + x];
