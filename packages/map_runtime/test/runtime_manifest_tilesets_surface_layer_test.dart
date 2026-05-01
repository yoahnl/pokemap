import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  group('runtime manifest tileset collection with SurfaceLayer', () {
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
                    TilesetVisualFrame(
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
