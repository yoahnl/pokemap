import 'package:map_core/map_core_domain.dart';

enum MapCliffSide { left, right, mixed }

final class MapCliffLevels {
  const MapCliffLevels({
    required this.lowLevel,
    required this.highLevel,
    required this.highSide,
    required this.coveredDecorIds,
  });

  final double lowLevel, highLevel;
  final MapCliffSide? highSide;
  final List<String> coveredDecorIds;

  bool get flat => highSide == null;
}

MapCliffLevels? mapCliffLevels(
  MapData map,
  List<GridPos> anchors, {
  required BorderStrokeAlignment alignment,
  bool closed = false,
}) {
  final scene = map.spatialScene;
  if (scene == null || anchors.length < 2) return null;
  final points = closed ? [...anchors, anchors.first] : anchors;
  final gridEdges = alignment == BorderStrokeAlignment.gridEdges;
  final reach = gridEdges ? .5 : 1.0;
  final touched = <GridPos>{};
  double? low, high;
  var leftHigher = 0, rightHigher = 0;

  double? level(double x, double z) {
    if (x < 0 || z < 0 || x >= scene.width || z >= scene.depth) return null;
    return scene.worldHeightAt(x, z) / scene.levelHeight;
  }

  void touch(double x, double z) {
    if (x < 0 || z < 0 || x >= scene.width || z >= scene.depth) return;
    touched.add(GridPos(x: x.floor(), y: z.floor()));
  }

  for (var index = 1; index < points.length; index++) {
    final from = points[index - 1], to = points[index];
    final steps = [
      (to.x - from.x).abs(),
      (to.y - from.y).abs(),
    ].reduce((a, b) => a > b ? a : b);
    if (steps == 0) continue;
    final dx = (to.x - from.x) / steps, dz = (to.y - from.y) / steps;
    final offset = gridEdges ? 0.0 : .5;
    for (var step = 0; step < steps; step++) {
      final midX = from.x + dx * (step + .5) + offset;
      final midZ = from.y + dz * (step + .5) + offset;
      final leftX = midX + dz * reach, leftZ = midZ - dx * reach;
      final rightX = midX - dz * reach, rightZ = midZ + dx * reach;
      final left = level(leftX, leftZ), right = level(rightX, rightZ);
      if (gridEdges) {
        touch(leftX, leftZ);
        touch(rightX, rightZ);
      } else {
        touch(midX - dx * .5, midZ - dz * .5);
        touch(midX + dx * .5, midZ + dz * .5);
      }
      for (final value in [left, right].nonNulls) {
        low = low == null || value < low ? value : low;
        high = high == null || value > high ? value : high;
      }
      if (left == null || right == null) continue;
      if (left - right > .01) leftHigher++;
      if (right - left > .01) rightHigher++;
    }
  }
  if (low == null || high == null) return null;
  return MapCliffLevels(
    lowLevel: low,
    highLevel: high,
    highSide: leftHigher == 0 && rightHigher == 0
        ? null
        : leftHigher > 0 && rightHigher > 0
        ? MapCliffSide.mixed
        : leftHigher > 0
        ? MapCliffSide.left
        : MapCliffSide.right,
    coveredDecorIds: [
      for (final instance in scene.instances)
        if (!instance.id.startsWith('smt_') &&
            !_generatedByBorder(map, instance.id) &&
            touched.contains(
              GridPos(
                x: instance.position.x.floor(),
                y: instance.position.z.floor(),
              ),
            ))
          instance.id,
    ],
  );
}

bool _generatedByBorder(MapData map, String id) =>
    map.layers.whereType<BorderLayer>().any(
      (layer) => layer.content.features.any(
        (feature) => feature.generatedPlacementIds.contains(id),
      ),
    );
