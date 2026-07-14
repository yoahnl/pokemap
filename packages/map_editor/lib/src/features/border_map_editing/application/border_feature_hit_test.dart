import 'package:map_core/map_core.dart';

/// Finds the visually uppermost authored Border feature at one map cell.
///
/// Hit testing uses editable geometry only. It deliberately ignores blueprint
/// publication, materialization and every non-Border layer so stale content
/// remains selectable for repair.
BorderFeature? hitTestBorderFeature({
  required BorderLayer layer,
  required GridPos position,
}) {
  for (final feature in layer.content.features.reversed) {
    if (_geometryContains(feature.geometry, position)) {
      return feature;
    }
  }
  return null;
}

bool _geometryContains(BorderFeatureGeometry geometry, GridPos position) =>
    switch (geometry) {
      BorderRegionGeometry region => position.x >= 0 &&
          position.y >= 0 &&
          position.x < region.width &&
          position.y < region.height &&
          region.cells[position.y * region.width + position.x],
      BorderStrokeGeometry stroke => stroke.strokes.any(
          (segment) => segment.points.contains(position),
        ),
    };
