import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/project_manifest.dart';

const String legacyTerrainSmartTileCategoryId = 'smart_terrain_migrated';
const String legacyPathSmartTileCategoryId = 'smart_path_migrated';
const String legacySmartTileEmptyMaterialId = 'smart_material_empty';
const String legacySmartTileConversionDeferredCode =
    'legacy_smart_tile_conversion_deferred';

String legacyTerrainSmartTilePresetId(String legacyPresetId) =>
    'smart_terrain_$legacyPresetId';

String legacyPathSmartTilePresetId(String legacyPresetId) =>
    'smart_path_$legacyPresetId';

String legacyTerrainSmartTileMaterialId(String legacyPresetId) =>
    'smart_material_terrain_$legacyPresetId';

String legacyPathSmartTileMaterialId(String legacyPresetId) =>
    'smart_material_path_$legacyPresetId';

@immutable
final class LegacySmartTileMigrationReport {
  const LegacySmartTileMigrationReport({
    required this.migratedTerrainPresets,
    required this.migratedPathPresets,
    required this.migratedTerrainLayers,
    required this.migratedPathLayers,
    required this.removedEmptyTerrainLayers,
    this.warnings = const <String>[],
  });

  final int migratedTerrainPresets;
  final int migratedPathPresets;
  final int migratedTerrainLayers;
  final int migratedPathLayers;
  final int removedEmptyTerrainLayers;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

@immutable
final class LegacySmartTileMigrationResult {
  const LegacySmartTileMigrationResult({
    required this.project,
    required this.maps,
    required this.report,
  });

  final ProjectManifest project;
  final List<MapData> maps;
  final LegacySmartTileMigrationReport report;
}

/// STN-01 deliberately defers legacy conversion until the all-or-nothing
/// removal lot. Returning the original immutable values prevents a partial v5
/// projection when a legacy preset, pattern, or map cannot be converted.
LegacySmartTileMigrationResult migrateLegacyTerrainAndPathsToSmartTiles({
  required ProjectManifest project,
  required Iterable<MapData> maps,
  bool removeLegacyDefinitions = false,
}) {
  return LegacySmartTileMigrationResult(
    project: project,
    maps: List<MapData>.unmodifiable(maps),
    report: const LegacySmartTileMigrationReport(
      migratedTerrainPresets: 0,
      migratedPathPresets: 0,
      migratedTerrainLayers: 0,
      migratedPathLayers: 0,
      removedEmptyTerrainLayers: 0,
      warnings: <String>[legacySmartTileConversionDeferredCode],
    ),
  );
}
