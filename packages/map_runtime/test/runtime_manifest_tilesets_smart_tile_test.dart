import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  group('runtime manifest tileset collection', () {
    test('collects every multipart and animated Smart Tile atlas tileset', () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        version: ProjectVersion.v6,
        tilesetId: 'base-world',
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          MapLayer.smartTile(
            id: 'smart-water',
            name: 'Smart water',
            presetId: 'water',
            usage: SmartTileUsage.terrain,
            materialPalette: <String>['', 'water'],
            field: SmartTileField.cell(
              semanticCells: <int>[
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
              ],
            ),
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Smart Tile Runtime',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'base-world',
            name: 'Base World',
            relativePath: 'tilesets/base.png',
          ),
          ProjectTilesetEntry(
            id: 'smart-ground',
            name: 'Smart ground',
            relativePath: 'tilesets/ground.png',
          ),
          ProjectTilesetEntry(
            id: 'smart-foreground',
            name: 'Smart foreground',
            relativePath: 'tilesets/foreground.png',
          ),
          ProjectTilesetEntry(
            id: 'smart-animated',
            name: 'Smart animated',
            relativePath: 'tilesets/animated.png',
          ),
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: const <ProjectSmartTileAtlas>[
            ProjectSmartTileAtlas(
              id: 'ground-atlas',
              name: 'Ground atlas',
              tilesetId: 'smart-ground',
              columns: 1,
              rows: 1,
            ),
            ProjectSmartTileAtlas(
              id: 'foreground-atlas',
              name: 'Foreground atlas',
              tilesetId: 'smart-foreground',
              columns: 1,
              rows: 1,
            ),
            ProjectSmartTileAtlas(
              id: 'animated-atlas',
              name: 'Animated atlas',
              tilesetId: 'smart-animated',
              columns: 1,
              rows: 1,
            ),
          ],
          animations: const <ProjectSmartTileAnimation>[
            ProjectSmartTileAnimation(
              id: 'ripples',
              name: 'Ripples',
              frames: <ProjectSmartTileAnimationFrame>[
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'animated-atlas',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
          ],
          materials: const <ProjectSmartTileMaterial>[
            ProjectSmartTileMaterial(
              id: 'water',
              name: 'Water',
              connectionGroupId: 'water',
            ),
          ],
          presets: const <ProjectSmartTilePreset>[
            ProjectSmartTilePreset(
              id: 'water',
              name: 'Water',
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.uniform,
              templateHint: SmartTileTemplateHint.simple,
              status: SmartTilePresetStatus.published,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'water',
              allowedMaterialIds: <String>['water'],
              rules: <SmartTileRule>[
                SmartTileRule(
                  id: 'uniform',
                  centerMatch: SmartTileSlotMatch.material('water'),
                  candidates: <SmartTileCandidate>[
                    SmartTileCandidate(
                      id: 'visual',
                      parts: <SmartTileVisualPart>[
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'ground-atlas',
                              column: 0,
                              row: 0,
                            ),
                          ),
                        ),
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'foreground-atlas',
                              column: 0,
                              row: 0,
                            ),
                          ),
                          channel: SmartTileRenderChannel.foreground,
                        ),
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.animation(
                            animationId: 'ripples',
                          ),
                          channel: SmartTileRenderChannel.understory,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(collectAllRuntimeTilesetIds(map, manifest), {
        'base-world',
        'smart-ground',
        'smart-foreground',
        'smart-animated',
      });
    });

    test('collects placed-element frame tilesets once in encounter order', () {
      const map = MapData(
        id: 'placed-elements',
        name: 'Placed Elements',
        tilesetId: 'base-world',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.object(id: 'props', name: 'Props'),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'prop-a',
            layerId: 'props',
            elementId: 'port-prop',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'prop-b',
            layerId: 'props',
            elementId: 'port-prop',
            pos: GridPos(x: 1, y: 0),
          ),
          MapPlacedElement(
            id: 'missing',
            layerId: 'props',
            elementId: 'missing-element',
            pos: GridPos(x: 0, y: 1),
          ),
        ],
      );
      const manifest = ProjectManifest(
        name: 'Placed Element Runtime',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'base-world',
            name: 'Base world',
            relativePath: 'tilesets/base.png',
          ),
          ProjectTilesetEntry(
            id: 'prop-base',
            name: 'Prop base',
            relativePath: 'tilesets/prop_base.png',
          ),
          ProjectTilesetEntry(
            id: 'prop-override',
            name: 'Prop override',
            relativePath: 'tilesets/prop_override.png',
          ),
          ProjectTilesetEntry(
            id: 'unused-tileset',
            name: 'Unused tileset',
            relativePath: 'tilesets/unused.png',
          ),
        ],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'port-prop',
            name: 'Port prop',
            tilesetId: 'prop-base',
            categoryId: 'props',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
              TilesetVisualFrame(
                tilesetId: 'prop-override',
                source: TilesetSourceRect(x: 1, y: 0),
              ),
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 2, y: 0),
              ),
            ],
          ),
          ProjectElementEntry(
            id: 'unused-prop',
            name: 'Unused prop',
            tilesetId: 'unused-tileset',
            categoryId: 'props',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );

      expect(
        collectAllRuntimeTilesetIds(map, manifest).toList(growable: false),
        <String>['base-world', 'prop-base', 'prop-override'],
      );
    });

    test('Border layers and snapshots leave every runtime collector unchanged',
        () {
      const baseMap = MapData(
        id: 'border-runtime',
        name: 'Border Runtime',
        version: ProjectVersion.v6,
        tilesetId: 'base-world',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            palette: <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(
                tilesetId: 'ground-tiles',
                localTileId: 0,
              ),
            ],
            cells: <int>[0, 0, 0, 0],
          ),
        ],
      );
      final withBorder = baseMap.copyWith(
        layers: <MapLayer>[
          ...baseMap.layers,
          const MapLayer.border(id: 'border', name: 'Coast'),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Border Runtime',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'base-world',
            name: 'Base world',
            relativePath: 'tilesets/base.png',
          ),
          ProjectTilesetEntry(
            id: 'ground-tiles',
            name: 'Ground',
            relativePath: 'tilesets/ground.png',
          ),
        ],
        borderCatalog: ProjectBorderCatalog(
          visualSnapshots: <BorderVisualSnapshot>[
            BorderVisualSnapshot(
              id: 'border-snapshot-sha256:' '${'a' * 64}',
              contentFingerprint: 'a' * 64,
              frames: <BorderVisualFrameSnapshot>[
                BorderVisualFrameSnapshot(
                  relativeAssetPath:
                      'assets/borders/snapshots/must-not-be-collected.png',
                  sourceRectPx: BorderPixelRect(
                    x: 0,
                    y: 0,
                    width: 16,
                    height: 16,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        collectTilesetIdsReferencedOnMap(withBorder),
        collectTilesetIdsReferencedOnMap(baseMap),
      );

      final basePresetIds = <String>{};
      final borderPresetIds = <String>{};
      addSmartTileTilesetIds(basePresetIds, baseMap, manifest);
      addSmartTileTilesetIds(borderPresetIds, withBorder, manifest);
      expect(borderPresetIds, basePresetIds);

      final expectedAll = collectAllRuntimeTilesetIds(baseMap, manifest);
      final actualAll = collectAllRuntimeTilesetIds(withBorder, manifest);
      expect(actualAll, expectedAll);
      expect(actualAll, <String>{'base-world', 'ground-tiles'});
      expect(actualAll, isNot(contains('border-snapshot-sha256:${'a' * 64}')));
      expect(
        actualAll,
        isNot(
          contains('assets/borders/snapshots/must-not-be-collected.png'),
        ),
      );
    });
  });
}
