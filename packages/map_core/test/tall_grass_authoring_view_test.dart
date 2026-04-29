import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('TallGrassAuthoringView', () {
    test('collects existing project signals without merging contracts', () {
      final manifest = ProjectManifest(
        name: 'Tall Grass Project',
        maps: const [],
        tilesets: const [],
        terrainPresets: const [
          ProjectTerrainPreset(
            id: 'grass_visual',
            name: 'Grass Visual',
            terrainType: TerrainType.grass,
          ),
          ProjectTerrainPreset(
            id: 'sand_visual',
            name: 'Sand Visual',
            terrainType: TerrainType.sand,
          ),
        ],
        pathPresets: const [
          ProjectPathPreset(
            id: 'tall_grass_path',
            name: 'Tall Grass Path',
            surfaceKind: PathSurfaceKind.tallGrass,
          ),
          ProjectPathPreset(
            id: 'water_path',
            name: 'Water Path',
            surfaceKind: PathSurfaceKind.water,
          ),
        ],
        encounterTables: const [
          ProjectEncounterTable(
            id: 'route_1_grass',
            name: 'Route 1 Grass',
            encounterKind: EncounterKind.walk,
          ),
          ProjectEncounterTable(
            id: 'route_1_surf',
            name: 'Route 1 Surf',
            encounterKind: EncounterKind.surf,
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
      const map = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: GridSize(width: 4, height: 3),
        gameplayZones: [
          MapGameplayZone(
            id: 'route_1_grass_zone',
            name: 'Route 1 Grass Zone',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 2, height: 1),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'route_1_grass',
              encounterKind: EncounterKind.walk,
            ),
          ),
          MapGameplayZone(
            id: 'route_1_surf_zone',
            name: 'Route 1 Surf Zone',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'route_1_surf',
              encounterKind: EncounterKind.surf,
            ),
          ),
        ],
      );

      final view = createTallGrassAuthoringView(
        manifest: manifest,
        maps: [map],
      );

      expect(view.grassTerrainPresets.map((preset) => preset.id), [
        'grass_visual',
      ]);
      expect(view.tallGrassPathPresets.map((preset) => preset.id), [
        'tall_grass_path',
      ]);
      expect(view.walkEncounterTables.map((table) => table.id), [
        'route_1_grass',
      ]);
      expect(view.walkEncounterZones.map((zone) => zone.zoneId), [
        'route_1_grass_zone',
      ]);
      expect(view.walkEncounterZones.single.mapId, 'route_1');
      expect(view.walkEncounterZones.single.mapName, 'Route 1');
      expect(view.walkEncounterZones.single.encounterTableId, 'route_1_grass');
      expect(view.hasVisualCandidates, isTrue);
      expect(view.hasWalkEncounterTables, isTrue);
      expect(view.hasMappedWalkEncounterZones, isTrue);
      expect(view.hasAuthoringSignals, isTrue);
    });

    test('reports readiness without requiring placed map zones', () {
      final view = createTallGrassAuthoringView(
        manifest: ProjectManifest(
          name: 'Ready Project',
          maps: const [],
          tilesets: const [],
          terrainPresets: const [
            ProjectTerrainPreset(
              id: 'grass_visual',
              name: 'Grass Visual',
              terrainType: TerrainType.grass,
            ),
          ],
          encounterTables: const [
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 Grass',
              encounterKind: EncounterKind.walk,
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      expect(view.isReadyForProjectAuthoring, isTrue);
      expect(
        view.readinessItems.map((item) => item.id),
        [
          TallGrassAuthoringReadinessItem.visualCandidateId,
          TallGrassAuthoringReadinessItem.walkEncounterTableId,
          TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId,
        ],
      );
      expect(
        view.readinessItems.map((item) => item.isSatisfied),
        [true, true, false],
      );
    });

    test('exposes immutable empty lists when no signals exist', () {
      final view = createTallGrassAuthoringView(
        manifest: ProjectManifest(
          name: 'Empty Project',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      expect(view.grassTerrainPresets, isEmpty);
      expect(view.tallGrassPathPresets, isEmpty);
      expect(view.walkEncounterTables, isEmpty);
      expect(view.walkEncounterZones, isEmpty);
      expect(view.hasVisualCandidates, isFalse);
      expect(view.hasWalkEncounterTables, isFalse);
      expect(view.hasMappedWalkEncounterZones, isFalse);
      expect(view.hasAuthoringSignals, isFalse);
      expect(view.isReadyForProjectAuthoring, isFalse);
      expect(
        view.readinessItems.map((item) => item.isSatisfied),
        [false, false, false],
      );
      expect(
        () => view.walkEncounterZones.add(
          const TallGrassEncounterZoneUsage(
            mapId: 'route',
            mapName: 'Route',
            zoneId: 'zone',
            zoneName: 'Zone',
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            encounterTableId: null,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
