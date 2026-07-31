import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('legacy terrain and path Smart Tile migration', () {
    test('publishes native presets and replaces painted legacy layers', () {
      final project = ProjectManifest(
        name: 'Legacy project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'ground',
            name: 'Ground',
            relativePath: 'assets/ground.png',
          ),
        ],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
        terrainPresets: const <ProjectTerrainPreset>[
          ProjectTerrainPreset(
            id: 'grass',
            name: 'Grass',
            terrainType: TerrainType.grass,
            tilesetId: 'ground',
            variants: <TerrainPresetVariant>[
              TerrainPresetVariant(
                frames: <TilesetVisualFrame>[
                  TilesetVisualFrame(
                    source: TilesetSourceRect(
                      x: 4,
                      y: 8,
                      width: 2,
                      height: 2,
                    ),
                  ),
                ],
                weight: 3,
              ),
            ],
          ),
        ],
        pathPresets: <ProjectPathPreset>[
          ProjectPathPreset(
            id: 'dirt',
            name: 'Dirt path',
            tilesetId: 'ground',
            variants: <PathPresetVariantMapping>[
              for (final variant in TerrainPathVariant.values)
                PathPresetVariantMapping(
                  variant: variant,
                  frames: <TilesetVisualFrame>[
                    TilesetVisualFrame(
                      source: TilesetSourceRect(
                        x: variant.index,
                        y: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 2, height: 2),
        layers: const <MapLayer>[
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: <TerrainType>[
              TerrainType.grass,
              TerrainType.grass,
              TerrainType.grass,
              TerrainType.grass,
            ],
          ),
          MapLayer.path(
            id: 'path',
            name: 'Path',
            presetId: 'dirt',
            cells: <bool>[true, true, false, true],
          ),
        ],
      );

      final result = migrateLegacyTerrainAndPathsToSmartTiles(
        project: project,
        maps: <MapData>[map],
        removeLegacyDefinitions: true,
      );

      expect(result.project.version, ProjectVersion.v4);
      expect(result.project.terrainPresets, isEmpty);
      expect(result.project.pathPresets, isEmpty);
      expect(result.project.smartTileCatalog.presets, hasLength(2));
      expect(result.project.smartTileCatalog.atlases, hasLength(1));
      expect(result.project.smartTileCatalog.atlases.single.cellWidth, 32);
      expect(result.project.smartTileCatalog.atlases.single.columns, 20);
      expect(result.project.smartTileCatalog.atlases.single.rows, 13);

      final migratedMap = result.maps.single;
      expect(migratedMap.version, ProjectVersion.v4);
      expect(migratedMap.layers, everyElement(isA<SmartTileLayer>()));
      final terrain = migratedMap.layers[0] as SmartTileLayer;
      expect(terrain.id, 'terrain');
      expect(terrain.usage, SmartTileUsage.terrain);
      expect(terrain.materialCells, <int>[1, 1, 1, 1]);
      final path = migratedMap.layers[1] as SmartTileLayer;
      expect(path.id, 'path');
      expect(path.usage, SmartTileUsage.path);
      expect(path.materialCells, <int>[1, 1, 0, 1]);

      final terrainPreset = result.project.smartTileCatalog.presets
          .singleWhere((preset) => preset.usage == SmartTileUsage.terrain);
      final terrainPart =
          terrainPreset.rules.single.candidates.single.parts.single;
      expect(terrainPart.frameSampling, SmartTileFrameSampling.tessellated);
      final pathPreset = result.project.smartTileCatalog.presets
          .singleWhere((preset) => preset.usage == SmartTileUsage.path);
      expect(pathPreset.templateHint, SmartTileTemplateHint.blob47);
      expect(pathPreset.rules, hasLength(47));
      expect(pathPreset.status, SmartTilePresetStatus.published);
      expect(
        validateProjectSmartTileCatalog(
          catalog: result.project.smartTileCatalog,
          projectTilesetIds:
              result.project.tilesets.map((tileset) => tileset.id),
        ).where((diagnostic) => diagnostic.isError),
        isEmpty,
      );

      final repeated = migrateLegacyTerrainAndPathsToSmartTiles(
        project: result.project,
        maps: result.maps,
        removeLegacyDefinitions: true,
      );
      expect(repeated.project, result.project);
      expect(repeated.maps, result.maps);
      expect(repeated.report.migratedTerrainPresets, 0);
      expect(repeated.report.migratedPathPresets, 0);
    });

    test('uses an explicit empty material for a partial terrain layer', () {
      const project = ProjectManifest(
        name: 'Partial terrain',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'ground',
            name: 'Ground',
            relativePath: 'ground.png',
          ),
        ],
        terrainPresets: <ProjectTerrainPreset>[
          ProjectTerrainPreset(
            id: 'grass',
            name: 'Grass',
            terrainType: TerrainType.grass,
            tilesetId: 'ground',
            variants: <TerrainPresetVariant>[
              TerrainPresetVariant(
                frames: <TilesetVisualFrame>[
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 1),
        layers: <MapLayer>[
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: <TerrainType>[TerrainType.grass, TerrainType.none],
          ),
        ],
      );

      final result = migrateLegacyTerrainAndPathsToSmartTiles(
        project: project,
        maps: const <MapData>[map],
        removeLegacyDefinitions: true,
      );

      final layer = result.maps.single.layers.single as SmartTileLayer;
      expect(layer.materialPalette, <String>[
        '',
        legacyTerrainSmartTileMaterialId('grass'),
        legacySmartTileEmptyMaterialId,
      ]);
      expect(layer.materialCells, <int>[1, 2]);
      expect(result.project.terrainPresets, isEmpty);
      expect(
        result.project.smartTileCatalog.materials
            .singleWhere(
              (material) => material.id == legacySmartTileEmptyMaterialId,
            )
            .isEmpty,
        isTrue,
      );
      expect(result.report.warnings, isEmpty);
      expect(
        resolveSmartTileLayerVisuals(
          map: result.maps.single,
          layer: layer,
          catalog: result.project.smartTileCatalog,
          pass: SmartTileVisualPass.background,
        ).map((visual) => visual.cellX),
        <int>[0],
      );
      expect(
        () => MapValidator.validate(
          result.maps.single,
          projectDialogueContext: result.project,
        ),
        returnsNormally,
      );
    });

    test('tessellated parts select one source cell from a larger frame', () {
      final catalog = ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'ground',
            columns: 8,
            rows: 8,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'material',
            name: 'Material',
            connectionGroupId: 'material',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'preset',
            name: 'Preset',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.cardinal4,
            status: SmartTilePresetStatus.published,
            defaultMaterialId: 'material',
            allowedMaterialIds: <String>['material'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'fallback',
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(
                    id: 'candidate',
                    parts: <SmartTileVisualPart>[
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'atlas',
                            column: 4,
                            row: 2,
                            columnSpan: 2,
                            rowSpan: 2,
                          ),
                        ),
                        frameSampling: SmartTileFrameSampling.tessellated,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      const layer = SmartTileLayer(
        id: 'layer',
        name: 'Layer',
        presetId: 'preset',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'material'],
        materialCells: <int>[1, 1, 1, 1],
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v4,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[layer],
      );

      final visuals = resolveSmartTileLayerVisuals(
        map: map,
        layer: layer,
        catalog: catalog,
        pass: SmartTileVisualPass.background,
      );

      expect(
        visuals.map((visual) => visual.sourceRect).toList(),
        const <SmartTileSourceRect>[
          SmartTileSourceRect(x: 128, y: 64, width: 32, height: 32),
          SmartTileSourceRect(x: 160, y: 64, width: 32, height: 32),
          SmartTileSourceRect(x: 128, y: 96, width: 32, height: 32),
          SmartTileSourceRect(x: 160, y: 96, width: 32, height: 32),
        ],
      );
    });
  });
}
