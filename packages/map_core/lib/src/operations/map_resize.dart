import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

MapData resizeMapData(
  MapData map, {
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) {
    throw const ValidationException('Map size must be positive');
  }

  final oldSize = map.size;
  if (oldSize.width == width && oldSize.height == height) return map;

  final newLayers = map.layers
      .map(
        (layer) => layer.map(
          tile: (l) => l.copyWith(
            tiles: _resizeFlattened<int>(
              src: l.tiles,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: 0,
            ),
          ),
          collision: (l) => l.copyWith(
            collisions: _resizeFlattened<bool>(
              src: l.collisions,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: false,
            ),
          ),
          terrain: (l) => l.copyWith(
            terrains: _resizeFlattened<TerrainType>(
              src: l.terrains,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: TerrainType.none,
            ),
          ),
          object: (l) => l,
        ),
      )
      .toList(growable: false);

  return map.copyWith(
    size: GridSize(width: width, height: height),
    layers: newLayers,
  );
}

List<T> _resizeFlattened<T>({
  required List<T> src,
  required GridSize srcSize,
  required GridSize dstSize,
  required T defaultValue,
}) {
  final dstLen = dstSize.width * dstSize.height;
  final dst = List<T>.filled(dstLen, defaultValue, growable: false);

  final copyW = math.min(srcSize.width, dstSize.width);
  final copyH = math.min(srcSize.height, dstSize.height);

  for (var y = 0; y < copyH; y++) {
    final srcRowStart = y * srcSize.width;
    final dstRowStart = y * dstSize.width;
    for (var x = 0; x < copyW; x++) {
      final srcIndex = srcRowStart + x;
      if (srcIndex < 0 || srcIndex >= src.length) continue;
      final dstIndex = dstRowStart + x;
      dst[dstIndex] = src[srcIndex];
    }
  }

  return dst;
}
