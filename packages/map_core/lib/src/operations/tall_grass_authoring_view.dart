import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';

/// Read-only authoring inventory for the tall-grass product case.
///
/// This is deliberately a transition view over existing contracts:
/// - [ProjectTerrainPreset] with [TerrainType.grass] for terrain visuals;
/// - [ProjectPathPreset] with [PathSurfaceKind.tallGrass] for path/autotile
///   visuals;
/// - [ProjectEncounterTable] and [MapGameplayZone] with [EncounterKind.walk]
///   for encounter behavior.
///
/// It does not create or persist a SurfaceDefinition and does not merge these
/// contracts into one runtime surface. The goal is to let editor UI expose the
/// signals that already exist without changing project JSON.
final class TallGrassAuthoringView {
  TallGrassAuthoringView({
    required List<ProjectTerrainPreset> grassTerrainPresets,
    required List<ProjectPathPreset> tallGrassPathPresets,
    required List<ProjectEncounterTable> walkEncounterTables,
    required List<TallGrassEncounterZoneUsage> walkEncounterZones,
  })  : grassTerrainPresets = List.unmodifiable(grassTerrainPresets),
        tallGrassPathPresets = List.unmodifiable(tallGrassPathPresets),
        walkEncounterTables = List.unmodifiable(walkEncounterTables),
        walkEncounterZones = List.unmodifiable(walkEncounterZones);

  /// Terrain visual candidates. These are grass terrain presets, not a
  /// guarantee that the author intended every one of them to be tall grass.
  final List<ProjectTerrainPreset> grassTerrainPresets;

  /// Dedicated tall-grass path/autotile visual candidates.
  final List<ProjectPathPreset> tallGrassPathPresets;

  /// Reusable walk encounter tables, the encounter kind used by tall grass.
  final List<ProjectEncounterTable> walkEncounterTables;

  /// Walk encounter zones already placed on loaded maps.
  final List<TallGrassEncounterZoneUsage> walkEncounterZones;

  bool get hasGrassTerrainPresets => grassTerrainPresets.isNotEmpty;

  bool get hasTallGrassPathPresets => tallGrassPathPresets.isNotEmpty;

  bool get hasVisualCandidates =>
      hasGrassTerrainPresets || hasTallGrassPathPresets;

  bool get hasWalkEncounterTables => walkEncounterTables.isNotEmpty;

  bool get hasMappedWalkEncounterZones => walkEncounterZones.isNotEmpty;

  bool get hasAuthoringSignals =>
      hasVisualCandidates ||
      hasWalkEncounterTables ||
      hasMappedWalkEncounterZones;

  /// Minimum project-level setup before a map can reasonably author tall grass.
  ///
  /// Placed walk zones are deliberately not required here: those are map-level
  /// authoring work that may happen after the project has visual and encounter
  /// building blocks.
  bool get isReadyForProjectAuthoring =>
      hasVisualCandidates && hasWalkEncounterTables;

  List<TallGrassAuthoringReadinessItem> get readinessItems =>
      List.unmodifiable([
        TallGrassAuthoringReadinessItem(
          id: TallGrassAuthoringReadinessItem.visualCandidateId,
          isSatisfied: hasVisualCandidates,
        ),
        TallGrassAuthoringReadinessItem(
          id: TallGrassAuthoringReadinessItem.walkEncounterTableId,
          isSatisfied: hasWalkEncounterTables,
        ),
        TallGrassAuthoringReadinessItem(
          id: TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId,
          isSatisfied: hasMappedWalkEncounterZones,
        ),
      ]);
}

/// A placed walk encounter zone that can participate in tall-grass authoring.
final class TallGrassEncounterZoneUsage {
  const TallGrassEncounterZoneUsage({
    required this.mapId,
    required this.mapName,
    required this.zoneId,
    required this.zoneName,
    required this.area,
    required this.encounterTableId,
  });

  final String mapId;
  final String mapName;
  final String zoneId;
  final String zoneName;
  final MapRect area;
  final String? encounterTableId;
}

/// One read-only preparation check for tall-grass authoring.
final class TallGrassAuthoringReadinessItem {
  const TallGrassAuthoringReadinessItem({
    required this.id,
    required this.isSatisfied,
  });

  static const String visualCandidateId = 'visual_candidate';
  static const String walkEncounterTableId = 'walk_encounter_table';
  static const String mappedWalkEncounterZoneId = 'mapped_walk_encounter_zone';

  final String id;
  final bool isSatisfied;
}

/// Creates a read-only tall-grass authoring view from existing project data.
///
/// [maps] is optional because a [ProjectManifest] only stores map entries, not
/// loaded [MapData]. Passing loaded maps enriches the view with placed walk
/// encounter zones; omitting maps still reports project-level presets and
/// encounter tables.
TallGrassAuthoringView createTallGrassAuthoringView({
  required ProjectManifest manifest,
  Iterable<MapData> maps = const [],
}) {
  final grassTerrainPresets = manifest.terrainPresets
      .where((preset) => preset.terrainType == TerrainType.grass)
      .toList(growable: false);
  final tallGrassPathPresets = manifest.pathPresets
      .where((preset) => preset.surfaceKind == PathSurfaceKind.tallGrass)
      .toList(growable: false);
  final walkEncounterTables = manifest.encounterTables
      .where((table) => table.encounterKind == EncounterKind.walk)
      .toList(growable: false);
  final walkEncounterZones = <TallGrassEncounterZoneUsage>[];

  for (final map in maps) {
    for (final zone in map.gameplayZones) {
      final encounter = zone.encounter;
      if (zone.kind != GameplayZoneKind.encounter ||
          encounter == null ||
          encounter.encounterKind != EncounterKind.walk) {
        continue;
      }
      walkEncounterZones.add(
        TallGrassEncounterZoneUsage(
          mapId: map.id,
          mapName: map.name,
          zoneId: zone.id,
          zoneName: zone.name,
          area: zone.area,
          encounterTableId: encounter.encounterTableId,
        ),
      );
    }
  }

  return TallGrassAuthoringView(
    grassTerrainPresets: grassTerrainPresets,
    tallGrassPathPresets: tallGrassPathPresets,
    walkEncounterTables: walkEncounterTables,
    walkEncounterZones: walkEncounterZones,
  );
}
