import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  group('runtime manifest tileset collection', () {
    test('collects Surface atlas tilesets through the runtime manifest path',
        () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        tilesetId: 'base-world',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surfaces',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
            ],
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Surface Runtime',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'base-world',
            name: 'Base World',
            relativePath: 'tilesets/base.png',
          ),
          ProjectTilesetEntry(
            id: 'surface-water',
            name: 'Surface Water',
            relativePath: 'tilesets/water.png',
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(
          atlases: [_atlas(id: 'water-atlas', tilesetId: 'surface-water')],
          animations: [
            _animation(
              id: 'water-isolated',
              frames: [_frame(atlasId: 'water-atlas')],
            ),
          ],
          presets: [_preset(id: 'water', animationId: 'water-isolated')],
        ),
      );

      expect(collectAllRuntimeTilesetIds(map, manifest), {
        'base-world',
        'surface-water',
      });
    });

    test('collects pathPattern center frame tileset overrides', () {
      const map = MapData(
        id: 'route-path',
        name: 'Route Path',
        size: GridSize(width: 2, height: 2),
        layers: [
          MapLayer.path(
            id: 'path',
            name: 'Path',
            presetId: 'water-base',
            cells: [true, true, true, true],
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'PathPattern Runtime',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'base-world',
            name: 'Base World',
            relativePath: 'tilesets/base.png',
          ),
          ProjectTilesetEntry(
            id: 'water-fx',
            name: 'Water FX',
            relativePath: 'tilesets/water_fx.png',
          ),
        ],
        pathPresets: const [
          ProjectPathPreset(
            id: 'water-base',
            name: 'Water Base',
            tilesetId: 'base-world',
            variants: [],
          ),
        ],
        pathPatternPresets: [
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [
                    const TilesetVisualFrame(
                      tilesetId: 'water-fx',
                      source: TilesetSourceRect(x: 3, y: 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      expect(
        collectAllRuntimeTilesetIds(map, manifest),
        containsAll(<String>{'base-world', 'water-fx'}),
      );
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
        version: ProjectVersion.v2,
        tilesetId: 'base-world',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'ground-tiles',
            tiles: <int>[0, 0, 0, 0],
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
        version: ProjectVersion.v2,
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
      addTerrainAndPathPresetTilesetIds(basePresetIds, baseMap, manifest);
      addTerrainAndPathPresetTilesetIds(borderPresetIds, withBorder, manifest);
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

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 4, rows: 4),
    ),
  );
}

ProjectSurfaceAnimation _animation({
  required String id,
  required List<SurfaceAnimationFrame> frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
}

SurfaceAnimationFrame _frame({required String atlasId}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: atlasId, column: 0, row: 0),
    durationMs: 100,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required String animationId,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: animationId,
        ),
      ],
    ),
  );
}
