// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest projectManifest({
  List<ProjectTerrainPreset> terrainPresets = const [],
  List<ProjectPathPreset> pathPresets = const [],
}) {
  return ProjectManifest(
    name: 'Legacy Surface Usage Test',
    maps: const [],
    tilesets: const [],
    terrainPresets: terrainPresets,
    pathPresets: pathPresets,
        surfaceCatalog: ProjectSurfaceCatalog(),);
}

ProjectTerrainPreset terrainPreset({
  String id = 'legacy-terrain',
  String name = 'Legacy Terrain',
  TerrainType terrainType = TerrainType.grass,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<TerrainPresetVariant>? variants,
}) {
  return ProjectTerrainPreset(
    id: id,
    name: name,
    terrainType: terrainType,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants ??
        [
          terrainVariant([visualFrame(0)])
        ],
  );
}

TerrainPresetVariant terrainVariant(
  List<TilesetVisualFrame> frames, {
  int weight = 1,
}) {
  return TerrainPresetVariant(
    frames: frames,
    weight: weight,
  );
}

ProjectPathPreset pathPreset({
  String id = 'legacy-path',
  String name = 'Legacy Path',
  PathSurfaceKind surfaceKind = PathSurfaceKind.path,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<PathPresetVariantMapping>? variants,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants ??
        [
          pathMapping(TerrainPathVariant.cross, [visualFrame(0)]),
        ],
  );
}

PathPresetVariantMapping pathMapping(
  TerrainPathVariant variant,
  List<TilesetVisualFrame> frames,
) {
  return PathPresetVariantMapping(
    variant: variant,
    frames: frames,
  );
}

TilesetVisualFrame visualFrame(
  int x, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: 0),
    durationMs: durationMs,
  );
}

MapData mapData({
  String id = 'test-map',
  String name = 'Test Map',
  GridSize size = const GridSize(width: 10, height: 10),
  List<MapLayer> layers = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: size,
    layers: layers,
  );
}

void main() {
  group('LegacyProjectSurfaceUsageView', () {
    group('empty inputs', () {
      test('returns empty view when no maps are provided', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [],
        );

        expect(usage.terrainUsages, isEmpty);
        expect(usage.pathUsages, isEmpty);
        expect(usage.missingPathSurfaceUsages, isEmpty);
        expect(usage.hasTerrainUsage, isFalse);
        expect(usage.hasPathUsage, isFalse);
        expect(usage.hasMissingPathSurfaceUsage, isFalse);
        expect(usage.isEmpty, isTrue);
      });

      test('returns empty view when maps have no surface layers', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.tile(id: 'tiles', name: 'Tiles'),
            MapLayer.collision(id: 'collision', name: 'Collision'),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.terrainUsages, isEmpty);
        expect(usage.pathUsages, isEmpty);
        expect(usage.missingPathSurfaceUsages, isEmpty);
        expect(usage.isEmpty, isTrue);
      });
    });

    group('terrain usage', () {
      test('counts terrain cells by TerrainType', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [
                TerrainType.grass,
                TerrainType.grass,
                TerrainType.sand,
                TerrainType.none, // ignored
                TerrainType.grass,
              ],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.terrainUsages, hasLength(2));
        final grassUsage = usage.terrainUsages[0];
        expect(grassUsage.terrainType, TerrainType.grass);
        expect(grassUsage.cellCount, 3);
        expect(grassUsage.mapId, map.id);
        expect(grassUsage.mapName, map.name);
        expect(grassUsage.layerIndex, 0);
        expect(grassUsage.layerId, 'terrain');
        expect(grassUsage.layerName, 'Terrain');

        final sandUsage = usage.terrainUsages[1];
        expect(sandUsage.terrainType, TerrainType.sand);
        expect(sandUsage.cellCount, 1);
      });

      test('preserves first-appearance order within terrain layer', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [
                TerrainType.sand,
                TerrainType.grass,
                TerrainType.sand,
                TerrainType.rock,
                TerrainType.grass,
              ],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.terrainUsages, hasLength(3));
        expect(usage.terrainUsages[0].terrainType, TerrainType.sand);
        expect(usage.terrainUsages[1].terrainType, TerrainType.grass);
        expect(usage.terrainUsages[2].terrainType, TerrainType.rock);
      });

      test('handles multiple terrain layers in same map', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'ground',
              name: 'Ground',
              terrains: [TerrainType.grass, TerrainType.grass],
            ),
            MapLayer.tile(id: 'tiles', name: 'Tiles'),
            MapLayer.terrain(
              id: 'decor',
              name: 'Decor',
              terrains: [TerrainType.sand, TerrainType.sand],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.terrainUsages, hasLength(2));
        expect(usage.terrainUsages[0].layerIndex, 0);
        expect(usage.terrainUsages[0].layerId, 'ground');
        expect(usage.terrainUsages[0].terrainType, TerrainType.grass);
        expect(usage.terrainUsages[1].layerIndex, 2);
        expect(usage.terrainUsages[1].layerId, 'decor');
        expect(usage.terrainUsages[1].terrainType, TerrainType.sand);
      });

      test('ignores TerrainType.none cells', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [
                TerrainType.none,
                TerrainType.none,
                TerrainType.none,
              ],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.terrainUsages, isEmpty);
      });

      test('terrainUsagesByType returns filtered list', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [
                TerrainType.grass,
                TerrainType.sand,
                TerrainType.grass,
              ],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        final grassUsages = usage.terrainUsagesByType(TerrainType.grass);
        expect(grassUsages, hasLength(1));
        expect(grassUsages[0].cellCount, 2);

        final sandUsages = usage.terrainUsagesByType(TerrainType.sand);
        expect(sandUsages, hasLength(1));
        expect(sandUsages[0].cellCount, 1);

        final rockUsages = usage.terrainUsagesByType(TerrainType.rock);
        expect(rockUsages, isEmpty);

        // Verify returned lists are unmodifiable
        expect(() => grassUsages.add(grassUsages[0]), throwsUnsupportedError);
      });
    });

    group('path usage', () {
      test('resolves path preset when found in catalog', () {
        final waterPreset = pathPreset(
          id: 'water',
          surfaceKind: PathSurfaceKind.water,
          variants: [
            pathMapping(TerrainPathVariant.horizontal, [visualFrame(0)]),
          ],
        );
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [waterPreset]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'water-path',
              name: 'Water Path',
              presetId: 'water',
              cells: [true, false, true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.pathUsages, hasLength(1));
        expect(usage.missingPathSurfaceUsages, isEmpty);

        final pathUsage = usage.pathUsages[0];
        expect(pathUsage.presetId, 'water');
        expect(pathUsage.surface.id, 'water');
        expect(pathUsage.surface.surfaceKind, PathSurfaceKind.water);
        expect(pathUsage.activeCellCount, 2);
        expect(pathUsage.mapId, map.id);
        expect(pathUsage.mapName, map.name);
        expect(pathUsage.layerIndex, 0);
        expect(pathUsage.layerId, 'water-path');
        expect(pathUsage.layerName, 'Water Path');
      });

      test('reports missing path preset when not found in catalog', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'missing-path',
              name: 'Missing Path',
              presetId: 'missing-water',
              cells: [true, true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.pathUsages, isEmpty);
        expect(usage.missingPathSurfaceUsages, hasLength(1));

        final missingUsage = usage.missingPathSurfaceUsages[0];
        expect(missingUsage.presetId, 'missing-water');
        expect(missingUsage.activeCellCount, 2);
        expect(missingUsage.mapId, map.id);
        expect(missingUsage.layerId, 'missing-path');
      });

      test('reports missing path preset when presetId is empty', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'empty-path',
              name: 'Empty Path',
              presetId: '',
              cells: [true, true, true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.pathUsages, isEmpty);
        expect(usage.missingPathSurfaceUsages, hasLength(1));

        final missingUsage = usage.missingPathSurfaceUsages[0];
        expect(missingUsage.presetId, '');
        expect(missingUsage.activeCellCount, 3);
      });

      test('ignores path layer with no active cells', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'inactive-path',
              name: 'Inactive Path',
              presetId: 'water',
              cells: [false, false, false],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.pathUsages, isEmpty);
        expect(usage.missingPathSurfaceUsages, isEmpty);
      });

      test('pathUsagesByPresetId returns filtered list', () {
        final waterPreset = pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water);
        final grassPreset = pathPreset(id: 'grass', surfaceKind: PathSurfaceKind.tallGrass);
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [waterPreset, grassPreset]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'water-path',
              name: 'Water Path',
              presetId: 'water',
              cells: [true],
            ),
            MapLayer.path(
              id: 'grass-path',
              name: 'Grass Path',
              presetId: 'grass',
              cells: [true, true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        final waterUsages = usage.pathUsagesByPresetId('water');
        expect(waterUsages, hasLength(1));
        expect(waterUsages[0].activeCellCount, 1);

        final grassUsages = usage.pathUsagesByPresetId('grass');
        expect(grassUsages, hasLength(1));
        expect(grassUsages[0].activeCellCount, 2);

        final missingUsages = usage.pathUsagesByPresetId('missing');
        expect(missingUsages, isEmpty);

        // Verify returned lists are unmodifiable
        expect(() => waterUsages.add(waterUsages[0]), throwsUnsupportedError);
      });

      test('missingPathUsagesByPresetId returns filtered list', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'missing1',
              name: 'Missing 1',
              presetId: 'missing-water',
              cells: [true],
            ),
            MapLayer.path(
              id: 'missing2',
              name: 'Missing 2',
              presetId: 'missing-water',
              cells: [true, true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        final missingUsages = usage.missingPathUsagesByPresetId('missing-water');
        expect(missingUsages, hasLength(2));
        expect(missingUsages[0].activeCellCount, 1);
        expect(missingUsages[1].activeCellCount, 2);

        final otherUsages = usage.missingPathUsagesByPresetId('other');
        expect(otherUsages, isEmpty);

        // Verify returned lists are unmodifiable
        expect(() => missingUsages.add(missingUsages[0]), throwsUnsupportedError);
      });
    });

    group('multiple maps', () {
      test('preserves map order in usage lists', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(
            terrainPresets: [
              terrainPreset(id: 'grass', terrainType: TerrainType.grass),
            ],
            pathPresets: [
              pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
            ],
          ),
        );

        final map1 = mapData(
          id: 'map-1',
          name: 'Map 1',
          layers: [
            MapLayer.terrain(
              id: 'terrain-1',
              name: 'Terrain 1',
              terrains: [TerrainType.grass],
            ),
            MapLayer.path(
              id: 'path-1',
              name: 'Path 1',
              presetId: 'water',
              cells: [true],
            ),
          ],
        );

        final map2 = mapData(
          id: 'map-2',
          name: 'Map 2',
          layers: [
            MapLayer.terrain(
              id: 'terrain-2',
              name: 'Terrain 2',
              terrains: [TerrainType.grass],
            ),
            MapLayer.path(
              id: 'path-2',
              name: 'Path 2',
              presetId: 'water',
              cells: [true, true],
            ),
          ],
        );

        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map1, map2],
        );

        expect(usage.terrainUsages, hasLength(2));
        expect(usage.terrainUsages[0].mapId, 'map-1');
        expect(usage.terrainUsages[1].mapId, 'map-2');

        expect(usage.pathUsages, hasLength(2));
        expect(usage.pathUsages[0].mapId, 'map-1');
        expect(usage.pathUsages[1].mapId, 'map-2');
      });

      test('handles mixed terrain and path usages across maps', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(
            terrainPresets: [
              terrainPreset(id: 'grass', terrainType: TerrainType.grass),
              terrainPreset(id: 'sand', terrainType: TerrainType.sand),
            ],
            pathPresets: [
              pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
            ],
          ),
        );

        final map1 = mapData(
          id: 'terrain-map',
          name: 'Terrain Map',
          layers: [
            MapLayer.terrain(
              id: 'grass',
              name: 'Grass',
              terrains: [TerrainType.grass, TerrainType.grass],
            ),
          ],
        );

        final map2 = mapData(
          id: 'path-map',
          name: 'Path Map',
          layers: [
            MapLayer.path(
              id: 'water',
              name: 'Water',
              presetId: 'water',
              cells: [true, true, true],
            ),
          ],
        );

        final map3 = mapData(
          id: 'mixed-map',
          name: 'Mixed Map',
          layers: [
            MapLayer.terrain(
              id: 'sand',
              name: 'Sand',
              terrains: [TerrainType.sand],
            ),
            MapLayer.path(
              id: 'water-2',
              name: 'Water 2',
              presetId: 'water',
              cells: [true],
            ),
          ],
        );

        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map1, map2, map3],
        );

        expect(usage.terrainUsages, hasLength(2));
        expect(usage.terrainUsages[0].mapId, 'terrain-map');
        expect(usage.terrainUsages[1].mapId, 'mixed-map');

        expect(usage.pathUsages, hasLength(2));
        expect(usage.pathUsages[0].mapId, 'path-map');
        expect(usage.pathUsages[1].mapId, 'mixed-map');
      });
    });

    group('immutability', () {
      test('main lists are unmodifiable', () {
        final waterPreset = pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water);
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [waterPreset]),
        );
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [TerrainType.grass],
            ),
            MapLayer.path(
              id: 'path',
              name: 'Path',
              presetId: 'water',
              cells: [true],
            ),
            MapLayer.path(
              id: 'missing-path',
              name: 'Missing Path',
              presetId: 'missing',
              cells: [true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        // Test with non-empty lists
        expect(usage.terrainUsages, isNotEmpty);
        expect(usage.pathUsages, isNotEmpty);
        expect(usage.missingPathSurfaceUsages, isNotEmpty);
        
        expect(() => usage.terrainUsages.add(usage.terrainUsages[0]), throwsUnsupportedError);
        expect(() => usage.pathUsages.add(usage.pathUsages[0]), throwsUnsupportedError);
        expect(() => usage.missingPathSurfaceUsages.add(usage.missingPathSurfaceUsages[0]), throwsUnsupportedError);
      });

      test('filter methods return unmodifiable lists', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [TerrainType.grass, TerrainType.grass],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        final filtered = usage.terrainUsagesByType(TerrainType.grass);
        expect(filtered, isNotEmpty);
        expect(() => filtered.add(filtered[0]), throwsUnsupportedError);
      });
    });

    group('source immutability', () {
      test('does not mutate catalog', () {
        final manifest = projectManifest(
          terrainPresets: [
            terrainPreset(id: 'grass', terrainType: TerrainType.grass),
          ],
          pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ],
        );
        final catalog = createLegacyProjectSurfaceCatalogView(manifest);
        final originalTerrainCount = catalog.terrainSurfaces.length;
        final originalPathCount = catalog.pathSurfaces.length;

        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [TerrainType.grass],
            ),
            MapLayer.path(
              id: 'path',
              name: 'Path',
              presetId: 'water',
              cells: [true],
            ),
          ],
        );

        createLegacyProjectSurfaceUsageView(catalog: catalog, maps: [map]);

        expect(catalog.terrainSurfaces.length, originalTerrainCount);
        expect(catalog.pathSurfaces.length, originalPathCount);
        expect(catalog.terrainSurfaces[0].id, 'grass');
        expect(catalog.pathSurfaces[0].id, 'water');
      });

      test('does not mutate maps or layers', () {
        final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [TerrainType.grass, TerrainType.sand],
            ),
          ],
        );
        final originalLayer = map.layers[0] as TerrainLayer;
        final originalTerrains = List.of(originalLayer.terrains);

        createLegacyProjectSurfaceUsageView(catalog: catalog, maps: [map]);

        expect(map.layers.length, 1);
        expect((map.layers[0] as TerrainLayer).terrains, originalTerrains);
        expect(map.id, 'test-map');
        expect(map.name, 'Test Map');
      });

      test('does not mutate path layer cells', () {
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ]),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'path',
              name: 'Path',
              presetId: 'water',
              cells: [true, false, true],
            ),
          ],
        );
        final originalLayer = map.layers[0] as PathLayer;
        final originalCells = List.of(originalLayer.cells);
        final originalPresetId = originalLayer.presetId;

        createLegacyProjectSurfaceUsageView(catalog: catalog, maps: [map]);

        expect((map.layers[0] as PathLayer).cells, originalCells);
        expect((map.layers[0] as PathLayer).presetId, originalPresetId);
      });
    });

    group('terrain preset ambiguity', () {
      test('terrain usage is by TerrainType, not preset id', () {
        // Multiple terrain presets can share the same TerrainType.
        // The legacy data model does not track which specific preset was used.
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(
            terrainPresets: [
              terrainPreset(id: 'grass-a', terrainType: TerrainType.grass),
              terrainPreset(id: 'grass-b', terrainType: TerrainType.grass),
            ],
          ),
        );
        final map = mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [TerrainType.grass, TerrainType.grass],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.terrainUsages, hasLength(1));
        expect(usage.terrainUsages[0].terrainType, TerrainType.grass);
        expect(usage.terrainUsages[0].cellCount, 2);
        // The usage does not reference a specific preset id because the source
        // data (TerrainLayer.terrains) does not store that information.
      });
    });

    group('path preset resolution', () {
      test('uses first match when duplicate path presets exist', () {
        // If the catalog has duplicate path preset ids, the catalog's
        // pathSurfaceById returns the first match. This test documents that
        // behavior without changing it.
        final catalog = createLegacyProjectSurfaceCatalogView(
          projectManifest(
            pathPresets: [
              pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water, name: 'Water 1'),
              pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water, name: 'Water 2'),
            ],
          ),
        );
        final map = mapData(
          layers: [
            MapLayer.path(
              id: 'path',
              name: 'Path',
              presetId: 'water',
              cells: [true],
            ),
          ],
        );
        final usage = createLegacyProjectSurfaceUsageView(
          catalog: catalog,
          maps: [map],
        );

        expect(usage.pathUsages, hasLength(1));
        expect(usage.pathUsages[0].surface.name, 'Water 1');
        // The first match is used, consistent with LegacyProjectSurfaceCatalogView.pathSurfaceById
      });
    });
  });
}
