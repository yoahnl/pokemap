import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_templates.dart';

@immutable
final class SmartTileTemplateScenario {
  const SmartTileTemplateScenario({
    required this.mask,
    required this.neighborhood,
  });

  final int mask;
  final SmartTileNeighborhood neighborhood;
}

@immutable
final class SmartTileTemplateBenchResult {
  const SmartTileTemplateBenchResult({
    required this.mask,
    required this.neighborhood,
    required this.resolution,
  });

  final int mask;
  final SmartTileNeighborhood neighborhood;
  final SmartTileResolution resolution;
}

List<SmartTileTemplateScenario> generateSmartTileTemplateScenarios({
  required ProjectSmartTilePreset preset,
  required String materialId,
}) {
  final masks = smartTileCanonicalMasks(preset.templateHint);
  return List<SmartTileTemplateScenario>.unmodifiable(
    <SmartTileTemplateScenario>[
      for (final mask in masks)
        SmartTileTemplateScenario(
          mask: mask,
          neighborhood: _neighborhoodForMask(
            mask: mask,
            materialId: materialId,
          ),
        ),
    ],
  );
}

List<SmartTileTemplateBenchResult> runSmartTileTemplateBench({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required String materialId,
  String mapId = 'smart-tile-test-bench',
  String layerId = 'smart-tile-test-layer',
  int projectSeed = 0,
  int layerSeed = 0,
}) {
  final scenarios = generateSmartTileTemplateScenarios(
    preset: preset,
    materialId: materialId,
  );
  return List<SmartTileTemplateBenchResult>.unmodifiable(
    <SmartTileTemplateBenchResult>[
      for (final scenario in scenarios)
        SmartTileTemplateBenchResult(
          mask: scenario.mask,
          neighborhood: scenario.neighborhood,
          resolution: resolveSmartTile(
            preset: preset,
            materials: materials,
            neighborhood: scenario.neighborhood,
            x: scenario.mask,
            y: 0,
            mapId: mapId,
            layerId: layerId,
            projectSeed: projectSeed,
            layerSeed: layerSeed,
          ),
        ),
    ],
  );
}

@immutable
final class SmartTileTestGrid {
  SmartTileTestGrid({
    required this.width,
    required this.height,
    required List<String?> cells,
  }) : cells = List<String?>.unmodifiable(cells) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Smart Tile test-grid dimensions must be positive.');
    }
    if (cells.length != width * height) {
      throw ArgumentError(
        'Smart Tile test-grid cells must match width × height.',
      );
    }
  }

  factory SmartTileTestGrid.empty({
    required int width,
    required int height,
  }) {
    return SmartTileTestGrid(
      width: width,
      height: height,
      cells: List<String?>.filled(width * height, null),
    );
  }

  final int width;
  final int height;
  final List<String?> cells;

  String? materialAt(int x, int y) {
    _checkCell(x, y);
    return cells[y * width + x];
  }

  SmartTileTestGrid paint({
    required int x,
    required int y,
    required String? materialId,
  }) {
    _checkCell(x, y);
    final next = List<String?>.from(cells);
    next[y * width + x] = materialId;
    return SmartTileTestGrid(width: width, height: height, cells: next);
  }

  SmartTileResolution resolveAt({
    required int x,
    required int y,
    required ProjectSmartTilePreset preset,
    required Iterable<ProjectSmartTileMaterial> materials,
    String mapId = 'smart-tile-test-bench',
    String layerId = 'smart-tile-test-layer',
    int projectSeed = 0,
    int layerSeed = 0,
  }) {
    _checkCell(x, y);
    return resolveSmartTile(
      preset: preset,
      materials: materials,
      neighborhood: SmartTileNeighborhood.fromGrid(
        width: width,
        height: height,
        x: x,
        y: y,
        materialAt: materialAt,
      ),
      x: x,
      y: y,
      mapId: mapId,
      layerId: layerId,
      projectSeed: projectSeed,
      layerSeed: layerSeed,
    );
  }

  void _checkCell(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw RangeError('Smart Tile test-grid cell is outside the grid.');
    }
  }
}

SmartTileNeighborhood _neighborhoodForMask({
  required int mask,
  required String materialId,
}) {
  SmartTileCellSample sample(int bit) => SmartTileCellSample.inside(
        materialId: mask & bit == 0 ? null : materialId,
      );
  return SmartTileNeighborhood(
    centerMaterialId: materialId,
    northWest: sample(smartTileNorthWestBit),
    north: sample(smartTileNorthBit),
    northEast: sample(smartTileNorthEastBit),
    east: sample(smartTileEastBit),
    southEast: sample(smartTileSouthEastBit),
    south: sample(smartTileSouthBit),
    southWest: sample(smartTileSouthWestBit),
    west: sample(smartTileWestBit),
  );
}
