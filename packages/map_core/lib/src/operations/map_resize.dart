import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/border_diagnostics.dart';
import '../models/border_layer.dart';
import '../models/enums.dart';
import '../models/environment.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import 'border_resize.dart';

/// Atomic map-level result for the Border-aware resize path.
final class MapResizeWithBorderDiagnosticsResult {
  factory MapResizeWithBorderDiagnosticsResult({
    required MapData? map,
    required BorderDiagnosticsReport diagnosticReport,
    required bool canApply,
  }) {
    final hasErrors = diagnosticReport.hasErrors;
    if ((map == null) != hasErrors) {
      throw const ValidationException(
        'MapResizeWithBorderDiagnosticsResult.map must be null exactly when '
        'errors exist',
      );
    }
    if (canApply != !hasErrors) {
      throw const ValidationException(
        'MapResizeWithBorderDiagnosticsResult.canApply must be true exactly '
        'when no errors exist',
      );
    }
    return MapResizeWithBorderDiagnosticsResult._(
      map: map,
      diagnosticReport: diagnosticReport,
      canApply: canApply,
    );
  }

  const MapResizeWithBorderDiagnosticsResult._({
    required this.map,
    required this.diagnosticReport,
    required this.canApply,
  });

  final MapData? map;
  final BorderDiagnosticsReport diagnosticReport;
  final bool canApply;
}

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

  if (map.layers.any((layer) => layer is BorderLayer)) {
    throw const ValidationException(
      'Maps with Border layers must be resized with '
      'resizeMapDataWithBorderDiagnostics',
    );
  }

  return _resizeMapDataLegacyLayers(
    map,
    width: width,
    height: height,
  );
}

/// Resizes a complete map after atomically preflighting every Border layer.
MapResizeWithBorderDiagnosticsResult resizeMapDataWithBorderDiagnostics(
  MapData map, {
  required int width,
  required int height,
  required GridSize tileSizePx,
}) {
  final oldSize = map.size;
  final newSize = GridSize(width: width, height: height);
  final borderLayers = map.layers.whereType<BorderLayer>().toList(
        growable: false,
      );
  if (borderLayers.isEmpty) {
    return MapResizeWithBorderDiagnosticsResult(
      map: resizeMapData(map, width: width, height: height),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
      canApply: true,
    );
  }

  final resizedBorderContents = Map<BorderLayer, BorderLayerContent>.identity();
  final diagnostics = <BorderDiagnostic>[];

  for (final layer in borderLayers) {
    final result = resizeBorderLayerContent(
      content: layer.content,
      oldMapSize: oldSize,
      newMapSize: newSize,
      tileSizePx: tileSizePx,
      layerId: layer.id,
    );
    diagnostics.addAll(result.diagnosticReport.diagnostics);
    final resizedContent = result.content;
    if (resizedContent != null) {
      resizedBorderContents[layer] = resizedContent;
    }
  }

  final report = BorderDiagnosticsReport(diagnostics: diagnostics);
  if (report.hasErrors) {
    return MapResizeWithBorderDiagnosticsResult(
      map: null,
      diagnosticReport: report,
      canApply: false,
    );
  }
  if (oldSize == newSize) {
    return MapResizeWithBorderDiagnosticsResult(
      map: map,
      diagnosticReport: report,
      canApply: true,
    );
  }

  return MapResizeWithBorderDiagnosticsResult(
    map: _resizeMapDataLegacyLayers(
      map,
      width: width,
      height: height,
      resizedBorderContents: resizedBorderContents,
    ),
    diagnosticReport: report,
    canApply: true,
  );
}

MapData _resizeMapDataLegacyLayers(
  MapData map, {
  required int width,
  required int height,
  Map<BorderLayer, BorderLayerContent>? resizedBorderContents,
}) {
  final oldSize = map.size;

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
          path: (l) => l.copyWith(
            cells: _resizeFlattened<bool>(
              src: l.cells,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: false,
            ),
          ),
          surface: (l) => l.copyWith(
            placements: l.placements
                .where((placement) =>
                    placement.x >= 0 &&
                    placement.y >= 0 &&
                    placement.x < width &&
                    placement.y < height)
                .toList(growable: false),
          ),
          object: (l) => l,
          environment: (l) => l.copyWith(
            content: EnvironmentLayerContent(
              targetTileLayerId: l.content.targetTileLayerId,
              areas: l.content.areas
                  .map(
                    (area) => EnvironmentArea(
                      id: area.id,
                      name: area.name,
                      presetId: area.presetId,
                      mask: EnvironmentAreaMask(
                        width: width,
                        height: height,
                        cells: _resizeFlattened<bool>(
                          src: area.mask.cells,
                          srcSize: oldSize,
                          dstSize: GridSize(width: width, height: height),
                          defaultValue: false,
                        ),
                      ),
                      seed: area.seed,
                      paramsOverride: area.paramsOverride,
                      generatedPlacementIds:
                          area.generatedPlacementIds.toList(),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          border: (l) => l.copyWith(
            content: resizedBorderContents?[l] ?? l.content,
          ),
        ),
      )
      .toList(growable: false);

  final newPlacedElements = map.placedElements
      .where(
        (instance) =>
            instance.pos.x >= 0 &&
            instance.pos.y >= 0 &&
            instance.pos.x < width &&
            instance.pos.y < height,
      )
      .toList(growable: false);

  return map.copyWith(
    size: GridSize(width: width, height: height),
    layers: newLayers,
    placedElements: newPlacedElements,
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
