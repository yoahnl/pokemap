// ignore_for_file: invalid_annotation_target

import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import 'legacy_path_surface_view.dart';
import 'legacy_project_surface_catalog_view.dart';

/// Read-only inventory of legacy surface usages across maps.
///
/// This view bridges the Lot 7 catalog (presets declared in ProjectManifest)
/// and actual map usage (TerrainLayer cells and PathLayer cells). It is
/// deliberately not a persisted Surface model and deliberately not a unified
/// surface hierarchy. Terrain and path usages remain separate to preserve
/// legacy semantics while future Surface Engine work takes shape.
///
/// Key design points:
/// - Pure function: does not mutate catalog, maps, layers, or cells.
/// - Read-only lists: all exposed collections are unmodifiable.
/// - Terrain usage is by TerrainType, not by preset id, because TerrainLayer
///   cells store TerrainType values, not ProjectTerrainPreset references.
/// - Path usage distinguishes resolved (preset found) vs missing (preset not
///   found) to help migration planning without auto-correcting.
/// - Order preservation: map order, layer order, and first-appearance order
///   are kept deterministic.
final class LegacyProjectSurfaceUsageView {
  LegacyProjectSurfaceUsageView({
    required List<LegacyTerrainSurfaceUsage> terrainUsages,
    required List<LegacyPathSurfaceUsage> pathUsages,
    required List<LegacyMissingPathSurfaceUsage> missingPathSurfaceUsages,
  })  : terrainUsages = List.unmodifiable(terrainUsages),
        pathUsages = List.unmodifiable(pathUsages),
        missingPathSurfaceUsages = 
            List.unmodifiable(missingPathSurfaceUsages);

  /// Terrain usages by TerrainType, in discovery order.
  ///
  /// Discovery order: map order → layer order → first appearance of
  /// TerrainType in the grid. TerrainType.none cells are ignored.
  final List<LegacyTerrainSurfaceUsage> terrainUsages;

  /// Path usages with resolved presets, in discovery order.
  ///
  /// Discovery order: map order → layer order. Only layers with active cells
  /// and a preset found in the catalog appear here.
  final List<LegacyPathSurfaceUsage> pathUsages;

  /// Path usages with missing presets, in discovery order.
  ///
  /// Includes layers with active cells but presetId not found in catalog,
  /// or presetId empty. Helps migration planning without auto-correcting.
  final List<LegacyMissingPathSurfaceUsage> missingPathSurfaceUsages;

  /// Whether at least one terrain usage exists.
  bool get hasTerrainUsage => terrainUsages.isNotEmpty;

  /// Whether at least one path usage exists.
  bool get hasPathUsage => pathUsages.isNotEmpty;

  /// Whether at least one missing path surface usage exists.
  bool get hasMissingPathSurfaceUsage => missingPathSurfaceUsages.isNotEmpty;

  /// Whether all usage lists are empty.
  bool get isEmpty => !hasTerrainUsage && !hasPathUsage && !hasMissingPathSurfaceUsage;

  /// Returns all terrain usages with [type], preserving discovery order.
  ///
  /// The returned list is unmodifiable. If no usages match, returns an empty
  /// list.
  List<LegacyTerrainSurfaceUsage> terrainUsagesByType(TerrainType type) {
    return List.unmodifiable(
      terrainUsages.where((usage) => usage.terrainType == type),
    );
  }

  /// Returns all path usages with [presetId], preserving discovery order.
  ///
  /// The returned list is unmodifiable. If no usages match, returns an empty
  /// list.
  List<LegacyPathSurfaceUsage> pathUsagesByPresetId(String presetId) {
    return List.unmodifiable(
      pathUsages.where((usage) => usage.presetId == presetId),
    );
  }

  /// Returns all missing path usages with [presetId], preserving discovery order.
  ///
  /// The returned list is unmodifiable. If no usages match, returns an empty
  /// list.
  List<LegacyMissingPathSurfaceUsage> missingPathUsagesByPresetId(String presetId) {
    return List.unmodifiable(
      missingPathSurfaceUsages.where((usage) => usage.presetId == presetId),
    );
  }
}

/// One terrain usage: a TerrainType appearing in a TerrainLayer.
///
/// This is deliberately keyed by TerrainType, not by ProjectTerrainPreset.id,
/// because TerrainLayer cells store TerrainType values. Multiple terrain
/// presets may share the same TerrainType, and the legacy data model does not
/// track which specific preset was used when painting. Future Surface Engine
/// work will need to decide how to resolve this ambiguity.
final class LegacyTerrainSurfaceUsage {
  const LegacyTerrainSurfaceUsage({
    required this.mapId,
    required this.mapName,
    required this.layerIndex,
    required this.layerId,
    required this.layerName,
    required this.terrainType,
    required this.cellCount,
  });

  /// Map id from MapData.id.
  final String mapId;

  /// Map name from MapData.name.
  final String mapName;

  /// Zero-based index of the layer within MapData.layers.
  final int layerIndex;

  /// Layer id from MapLayer.id.
  final String layerId;

  /// Layer name from MapLayer.name.
  final String layerName;

  /// Terrain role found in cells.
  final TerrainType terrainType;

  /// Number of cells with this TerrainType in the layer.
  final int cellCount;
}

/// One path usage: a PathLayer with active cells and a resolved preset.
///
/// Only created when PathLayer.presetId is non-empty and found in the
/// catalog. The surface view is the catalog's snapshot of that preset.
final class LegacyPathSurfaceUsage {
  const LegacyPathSurfaceUsage({
    required this.mapId,
    required this.mapName,
    required this.layerIndex,
    required this.layerId,
    required this.layerName,
    required this.presetId,
    required this.surface,
    required this.activeCellCount,
  });

  /// Map id from MapData.id.
  final String mapId;

  /// Map name from MapData.name.
  final String mapName;

  /// Zero-based index of the layer within MapData.layers.
  final int layerIndex;

  /// Layer id from MapLayer.id.
  final String layerId;

  /// Layer name from MapLayer.name.
  final String layerName;

  /// Preset id from PathLayer.presetId.
  final String presetId;

  /// Catalog view of the resolved preset.
  final LegacyPathSurfaceView surface;

  /// Number of active (true) cells in the layer.
  final int activeCellCount;
}

/// One missing path usage: a PathLayer with active cells but no resolved preset.
///
/// Created when PathLayer.presetId is empty or not found in the catalog.
/// Helps migration planning by flagging layers that need preset assignment
/// without auto-correcting the source data.
final class LegacyMissingPathSurfaceUsage {
  const LegacyMissingPathSurfaceUsage({
    required this.mapId,
    required this.mapName,
    required this.layerIndex,
    required this.layerId,
    required this.layerName,
    required this.presetId,
    required this.activeCellCount,
  });

  /// Map id from MapData.id.
  final String mapId;

  /// Map name from MapData.name.
  final String mapName;

  /// Zero-based index of the layer within MapData.layers.
  final int layerIndex;

  /// Layer id from MapLayer.id.
  final String layerId;

  /// Layer name from MapLayer.name.
  final String layerName;

  /// Preset id from PathLayer.presetId (may be empty).
  final String presetId;

  /// Number of active (true) cells in the layer.
  final int activeCellCount;
}

/// Creates a read-only legacy surface usage view from [catalog] and [maps].
///
/// This is a pure function. It does not mutate the catalog, maps, layers,
/// or cells. It analyzes TerrainLayer cells and PathLayer cells to build an
/// inventory of actual surface usage, separate from preset declarations.
///
/// Terrain usage is reported by TerrainType because TerrainLayer cells store
/// TerrainType values. Path usage is split into resolved (preset found) and
/// missing (preset not found) to help migration planning.
///
/// Order preservation:
/// - Maps are processed in [maps] iteration order.
/// - Layers are processed in MapData.layers order.
/// - TerrainType first appearance is preserved within each TerrainLayer.
LegacyProjectSurfaceUsageView createLegacyProjectSurfaceUsageView({
  required LegacyProjectSurfaceCatalogView catalog,
  required Iterable<MapData> maps,
}) {
  final terrainUsages = <LegacyTerrainSurfaceUsage>[];
  final pathUsages = <LegacyPathSurfaceUsage>[];
  final missingPathUsages = <LegacyMissingPathSurfaceUsage>[];

  for (final map in maps) {
    _analyzeMapTerrainLayers(map, terrainUsages);
    _analyzeMapPathLayers(map, catalog, pathUsages, missingPathUsages);
  }

  return LegacyProjectSurfaceUsageView(
    terrainUsages: terrainUsages,
    pathUsages: pathUsages,
    missingPathSurfaceUsages: missingPathUsages,
  );
}

void _analyzeMapTerrainLayers(
  MapData map,
  List<LegacyTerrainSurfaceUsage> terrainUsages,
) {
  for (var layerIndex = 0; layerIndex < map.layers.length; layerIndex += 1) {
    final layer = map.layers[layerIndex];
    if (layer is! TerrainLayer) {
      continue;
    }

    // Count cells by TerrainType, ignoring TerrainType.none
    final countsByType = <TerrainType, int>{};
    for (final cell in layer.terrains) {
      if (cell == TerrainType.none) {
        continue;
      }
      countsByType[cell] = (countsByType[cell] ?? 0) + 1;
    }

    // Preserve first-appearance order by scanning the grid again
    final seenTypes = <TerrainType>{};
    for (final cell in layer.terrains) {
      if (cell == TerrainType.none || seenTypes.contains(cell)) {
        continue;
      }
      seenTypes.add(cell);
      final count = countsByType[cell] ?? 0;
      if (count > 0) {
        terrainUsages.add(
          LegacyTerrainSurfaceUsage(
            mapId: map.id,
            mapName: map.name,
            layerIndex: layerIndex,
            layerId: layer.id,
            layerName: layer.name,
            terrainType: cell,
            cellCount: count,
          ),
        );
      }
    }
  }
}

void _analyzeMapPathLayers(
  MapData map,
  LegacyProjectSurfaceCatalogView catalog,
  List<LegacyPathSurfaceUsage> pathUsages,
  List<LegacyMissingPathSurfaceUsage> missingPathUsages,
) {
  for (var layerIndex = 0; layerIndex < map.layers.length; layerIndex += 1) {
    final layer = map.layers[layerIndex];
    if (layer is! PathLayer) {
      continue;
    }

    // Count active cells
    var activeCellCount = 0;
    for (final cell in layer.cells) {
      if (cell) {
        activeCellCount += 1;
      }
    }

    if (activeCellCount == 0) {
      // No active cells: no usage to report
      continue;
    }

    final presetId = layer.presetId;
    final surface = catalog.pathSurfaceById(presetId);

    if (surface != null) {
      pathUsages.add(
        LegacyPathSurfaceUsage(
          mapId: map.id,
          mapName: map.name,
          layerIndex: layerIndex,
          layerId: layer.id,
          layerName: layer.name,
          presetId: presetId,
          surface: surface,
          activeCellCount: activeCellCount,
        ),
      );
    } else {
      // Missing preset: report it for migration planning
      missingPathUsages.add(
        LegacyMissingPathSurfaceUsage(
          mapId: map.id,
          mapName: map.name,
          layerIndex: layerIndex,
          layerId: layer.id,
          layerName: layer.name,
          presetId: presetId,
          activeCellCount: activeCellCount,
        ),
      );
    }
  }
}
