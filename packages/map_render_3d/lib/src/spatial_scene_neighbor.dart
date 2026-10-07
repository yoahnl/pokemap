import 'dart:typed_data';
import 'dart:ui';

import 'package:map_core/map_core.dart';

final class SpatialSceneNeighbor {
  const SpatialSceneNeighbor({
    required this.map,
    required this.offset,
    required this.loadGroundImage,
  });

  final MapData map;
  final Offset offset;
  final Future<Uint8List> Function(String id) loadGroundImage;
}

Offset spatialConnectionOffset(
  GridSize source,
  GridSize target,
  MapConnectionDirection direction,
  int offset,
) => switch (direction) {
  MapConnectionDirection.east => Offset(
    source.width.toDouble(),
    offset.toDouble(),
  ),
  MapConnectionDirection.west => Offset(
    -target.width.toDouble(),
    offset.toDouble(),
  ),
  MapConnectionDirection.north => Offset(
    offset.toDouble(),
    -target.height.toDouble(),
  ),
  MapConnectionDirection.south => Offset(
    offset.toDouble(),
    source.height.toDouble(),
  ),
};
