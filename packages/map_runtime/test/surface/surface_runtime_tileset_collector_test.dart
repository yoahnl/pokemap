import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/surface/surface_runtime_tileset_collector.dart';

void main() {
  group('collectSurfaceRuntimeTilesetIds', () {
    test('collects the tileset used by a placed Surface preset', () {
      final map = _mapWithSurfacePlacements([
        const SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
      ]);
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas')],
          ),
        ],
        presets: [_preset(id: 'water', animationId: 'water-isolated')],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(map: map, catalog: catalog),
        {'water-tiles'},
      );
    });

    test('deduplicates tilesets while scanning every animation frame', () {
      final map = _mapWithSurfacePlacements([
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
      ]);
      final catalog = _catalog(
        atlases: [
          _atlas(id: 'atlas-a', tilesetId: 'shared-water-tiles'),
          _atlas(id: 'atlas-b', tilesetId: 'foam-tiles'),
          _atlas(id: 'atlas-c', tilesetId: 'shared-water-tiles'),
        ],
        animations: [
          _animation(
            id: 'water-loop',
            frames: [
              _frame(atlasId: 'atlas-a', column: 0),
              _frame(atlasId: 'atlas-b', column: 1),
              _frame(atlasId: 'atlas-c', column: 2),
            ],
          ),
        ],
        presets: [_preset(id: 'water', animationId: 'water-loop')],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(map: map, catalog: catalog),
        {'shared-water-tiles', 'foam-tiles'},
      );
    });

    test('ignores missing preset animation and atlas references without crash',
        () {
      final map = _mapWithSurfacePlacements([
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'missing'),
        const SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'broken'),
        const SurfaceCellPlacement(x: 2, y: 0, surfacePresetId: 'no-atlas'),
      ]);
      final catalog = _catalog(
        animations: [
          _animation(
            id: 'anim-with-missing-atlas',
            frames: [_frame(atlasId: 'missing-atlas')],
          ),
        ],
        presets: [
          _preset(id: 'broken', animationId: 'missing-animation'),
          _preset(id: 'no-atlas', animationId: 'anim-with-missing-atlas'),
        ],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(map: map, catalog: catalog),
        isEmpty,
      );
    });

    test('ignores empty SurfaceLayer and non-Surface layers', () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        tilesetId: 'base-world',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(id: 'surface-empty', name: 'Surfaces'),
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: [TerrainType.grass],
          ),
          MapLayer.path(
            id: 'path',
            name: 'Path',
            presetId: 'road',
            cells: [true],
          ),
        ],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(
            map: map, catalog: ProjectSurfaceCatalog()),
        isEmpty,
      );
    });
  });
}

MapData _mapWithSurfacePlacements(List<SurfaceCellPlacement> placements) {
  return MapData(
    id: 'route-1',
    name: 'Route 1',
    tilesetId: 'base-world',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.surface(
        id: 'surface',
        name: 'Surfaces',
        placements: placements,
      ),
    ],
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas> atlases = const [],
  List<ProjectSurfaceAnimation> animations = const [],
  List<ProjectSurfacePreset> presets = const [],
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases,
    animations: animations,
    presets: presets,
  );
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
      gridSize: SurfaceAtlasGridSize(columns: 8, rows: 8),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
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

SurfaceAnimationFrame _frame({
  required String atlasId,
  int column = 0,
  int row = 0,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
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
