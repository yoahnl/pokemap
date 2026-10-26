import 'package:flame_3d/components.dart';

import 'spatial_ground.dart';

final class SpatialGroundMeshBatches {
  SpatialGroundMeshBatches(this.build);

  final List<MeshComponent> Function(List<SpatialGroundVisual>) build;
  List<MeshComponent> components = [];
  List<SpatialGroundVisual> _visuals = [];
  List<({int start, int end, bool animated})> _ranges = [];
  List<List<MeshComponent>> _batches = [];

  void resolve(
    List<SpatialGroundVisual> visuals, {
    bool invalidateGeometry = false,
  }) {
    final ranges = <({int start, int end, bool animated})>[];
    for (var start = 0; start < visuals.length;) {
      final animated = visuals[start].visual.isAnimated;
      var end = start + 1;
      while (end < visuals.length &&
          visuals[end].visual.isAnimated == animated) {
        end++;
      }
      ranges.add((start: start, end: end, animated: animated));
      start = end;
    }
    final topologyChanged =
        ranges.length != _ranges.length ||
        ranges.indexed.any((entry) => entry.$2 != _ranges[entry.$1]);
    final batches = <List<MeshComponent>>[];
    for (final (index, range) in ranges.indexed) {
      var changed = invalidateGeometry || topologyChanged;
      for (var item = range.start; !changed && item < range.end; item++) {
        changed = !_sameVisual(_visuals[item], visuals[item]);
      }
      if (changed && !invalidateGeometry && !topologyChanged) {
        var sameGeometry = true;
        for (var item = range.start; sameGeometry && item < range.end; item++) {
          sameGeometry = _sameGeometry(_visuals[item], visuals[item]);
        }
        if (sameGeometry &&
            updateSpatialGroundMeshFrames(
              _batches[index].map((component) => component.mesh),
              visuals.sublist(range.start, range.end),
            )) {
          changed = false;
        }
      }
      batches.add(
        changed
            ? build(visuals.sublist(range.start, range.end))
            : _batches[index],
      );
    }
    _visuals = visuals;
    _ranges = ranges;
    _batches = batches;
    components = [for (final batch in batches) ...batch];
    for (final (index, component) in components.indexed) {
      component.priority = index - components.length;
    }
  }
}

bool _sameVisual(SpatialGroundVisual before, SpatialGroundVisual after) {
  final a = before.visual, b = after.visual;
  return before.height == after.height &&
      before.opacity == after.opacity &&
      (identical(a, b) ||
          a.tilesetId == b.tilesetId &&
              a.sourceRect == b.sourceRect &&
              _sameGeometry(before, after));
}

bool _sameGeometry(SpatialGroundVisual before, SpatialGroundVisual after) {
  final a = before.visual, b = after.visual;
  return before.height == after.height &&
      before.opacity == after.opacity &&
      a.transform == b.transform &&
      a.geometry.destinationRect == b.geometry.destinationRect &&
      a.geometry.visualBounds == b.geometry.visualBounds &&
      a.geometry.anchorOffset == b.geometry.anchorOffset &&
      a.geometry.transformedAnchorOffset ==
          b.geometry.transformedAnchorOffset &&
      a.spatialHeightOffset == b.spatialHeightOffset &&
      a.spatialFollowTerrain == b.spatialFollowTerrain &&
      a.spatialClip == b.spatialClip;
}
