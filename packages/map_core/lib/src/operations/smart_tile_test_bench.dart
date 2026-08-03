import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';
import 'smart_tile_cell_context.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_templates.dart';

/// Whether the manual cell-grid bench can reproduce this topology exactly.
///
/// Wang topologies read dedicated edge/corner lattices in production. The
/// semantic-cell bench cannot edit those lattices faithfully, so it fails
/// closed and leaves Wang inspection to the dedicated lattice bench.
bool smartTileTestGridSupportsTopology(SmartTileTopology topology) =>
    switch (topology) {
      SmartTileTopology.uniform ||
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.blob8 =>
        true,
      SmartTileTopology.wangEdge4 ||
      SmartTileTopology.wangCorner4 ||
      SmartTileTopology.wang8 =>
        false,
    };

@immutable
final class SmartTileTestBenchCase {
  const SmartTileTestBenchCase({
    required this.id,
    required this.context,
  });

  final String id;
  final SmartTileCellContext context;
}

@immutable
final class SmartTileTemplateBenchResult {
  const SmartTileTemplateBenchResult({
    required this.mask,
    required this.context,
    required this.resolution,
  });

  final int mask;
  final SmartTileCellContext context;
  final SmartTileResolution resolution;
}

List<SmartTileTestBenchCase> generateSmartTileTemplateScenarios({
  required ProjectSmartTilePreset preset,
  required String materialId,
}) {
  final masks = smartTileCanonicalMasks(preset.templateHint);
  return List<SmartTileTestBenchCase>.unmodifiable(
    <SmartTileTestBenchCase>[
      for (final mask in masks)
        SmartTileTestBenchCase(
          id: smartTileCanonicalRuleId(mask),
          context: smartTileTemplateCaseForMask(
            mask: mask,
            topology: preset.topology,
            materialId: materialId,
          ).context,
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
  final masks = smartTileCanonicalMasks(preset.templateHint);
  return List<SmartTileTemplateBenchResult>.unmodifiable(
    <SmartTileTemplateBenchResult>[
      for (var index = 0; index < scenarios.length; index++)
        SmartTileTemplateBenchResult(
          mask: masks[index],
          context: scenarios[index].context,
          resolution: resolveSmartTile(
            preset: preset,
            materials: materials,
            context: scenarios[index].context,
            x: masks[index],
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
    if (!smartTileTestGridSupportsTopology(preset.topology)) {
      throw UnsupportedError(
        'The manual Smart Tile cell grid cannot represent '
        '${preset.topology.name} lattices exactly.',
      );
    }
    return resolveSmartTile(
      preset: preset,
      materials: materials,
      context: SmartTileCellContext.fromCellGrid(
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
