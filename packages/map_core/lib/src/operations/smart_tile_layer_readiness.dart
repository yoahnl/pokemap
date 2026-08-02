import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import 'smart_tile_catalog_validation.dart';
import 'smart_tile_layer_context.dart';
import 'smart_tile_layer_operations.dart';
import 'smart_tile_resolver.dart';

@immutable
final class SmartTileLayerReadinessReport {
  const SmartTileLayerReadinessReport({
    required this.unassignedCellCount,
    required this.intentionalEmptyCellCount,
    required this.unresolvedCellCount,
    required this.diagnostics,
  });

  final int unassignedCellCount;
  final int intentionalEmptyCellCount;
  final int unresolvedCellCount;
  final List<SmartTileDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any((item) => item.isError);
}

SmartTileLayerReadinessReport analyzeSmartTileLayerReadiness({
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
}) {
  final materialList = List<ProjectSmartTileMaterial>.unmodifiable(materials);
  final materialById = <String, ProjectSmartTileMaterial>{
    for (final material in materialList) material.id: material,
  };
  final semanticCells = smartTileSemanticCells(layer);
  final diagnostics = <SmartTileDiagnostic>[];
  var unassignedCellCount = 0;
  var intentionalEmptyCellCount = 0;
  var unresolvedCellCount = 0;

  for (var y = 0; y < map.size.height; y += 1) {
    for (var x = 0; x < map.size.width; x += 1) {
      final cellIndex = y * map.size.width + x;
      final paletteIndex = semanticCells[cellIndex];
      final materialId =
          paletteIndex == 0 ? null : layer.materialPalette[paletteIndex];
      final material = materialId == null ? null : materialById[materialId];

      if (materialId == null) {
        unassignedCellCount += 1;
        if (preset.coveragePolicy == SmartTileCoveragePolicy.complete) {
          diagnostics.add(
            _cellDiagnostic(
              code: 'smart_tiles.layer.unassigned_cell',
              map: map,
              layer: layer,
              preset: preset,
              x: x,
              y: y,
              message: 'Complete Smart Tile layer "${layer.id}" has an '
                  'unassigned cell at ($x, $y).',
            ),
          );
        }
      } else if (material?.isEmpty ?? false) {
        intentionalEmptyCellCount += 1;
      }

      final context = smartTileCellContextForLayerCell(
        layer: layer,
        map: map,
        preset: preset,
        x: x,
        y: y,
      );
      final resolution = resolveSmartTile(
        preset: preset,
        materials: materialList,
        context: context,
        x: x,
        y: y,
        mapId: map.id,
        layerId: layer.id,
        layerSeed: layer.layerSeed,
      );

      if (resolution.status == SmartTileResolutionStatus.noIntent) {
        continue;
      }
      if (resolution.status == SmartTileResolutionStatus.resolved) {
        if (!resolution.usedFallback || preset.coverageProfile.allowFallback) {
          continue;
        }
        unresolvedCellCount += 1;
        diagnostics.add(
          _cellDiagnostic(
            code: 'smart_tiles.layer.fallback_only',
            map: map,
            layer: layer,
            preset: preset,
            x: x,
            y: y,
            message: 'Smart Tile cell ($x, $y) resolves only through '
                'fallback rule "${resolution.ruleId}".',
          ),
        );
        continue;
      }

      unresolvedCellCount += 1;
      diagnostics.add(
        _cellDiagnostic(
          code: 'smart_tiles.layer.unresolved_cell',
          map: map,
          layer: layer,
          preset: preset,
          x: x,
          y: y,
          message: 'Smart Tile cell ($x, $y) is unresolved '
              '(${resolution.status.name}): ${resolution.message}',
        ),
      );
    }
  }

  return SmartTileLayerReadinessReport(
    unassignedCellCount: unassignedCellCount,
    intentionalEmptyCellCount: intentionalEmptyCellCount,
    unresolvedCellCount: unresolvedCellCount,
    diagnostics: List<SmartTileDiagnostic>.unmodifiable(diagnostics),
  );
}

SmartTileDiagnostic _cellDiagnostic({
  required String code,
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTilePreset preset,
  required int x,
  required int y,
  required String message,
}) =>
    SmartTileDiagnostic(
      code: code,
      severity: SmartTileDiagnosticSeverity.error,
      path: r'$.maps['
          '"${map.id}"].layers["${layer.id}"].cells[$x,$y]',
      message: message,
      presetId: preset.id,
    );
