import 'dart:typed_data';

import '../models/border_blueprint.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import 'border_rle_codec.dart';
import 'surface_variant_role_resolver.dart';

/// Resolves the optional Surface ground strictly inside a region's
/// morphological edge band.
///
/// Surface roles are evaluated against the complete region mask. Filtering to
/// [BorderPublishedGround.edgeBandCells] happens only afterwards, so a band
/// cell keeps the same role it would have had if the whole region were
/// materialized as one Surface.
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
      final role = resolveSurfaceVariantRoleAt(
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
