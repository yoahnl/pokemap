import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/runtime_path_autotile.dart';

void main() {
  group('RuntimePathAutotileSet animation', () {
    test('resolves animated variant frame using elapsed time', () {
      final set = RuntimePathAutotileSet.fromPreset(_animatedPreset());
      const variant = TerrainPathVariant.horizontal;

      final frameAt0 = set.frameForVariantAt(variant, elapsedMs: 0);
      final frameAt120 = set.frameForVariantAt(variant, elapsedMs: 120);
      final frameAt220 = set.frameForVariantAt(variant, elapsedMs: 220);

      expect(frameAt0?.source, const TilesetSourceRect(x: 0, y: 0));
      expect(frameAt120?.source, const TilesetSourceRect(x: 1, y: 0));
      expect(frameAt220?.source, const TilesetSourceRect(x: 0, y: 0));
    });

    test('uses frame tileset override when provided', () {
      final set = RuntimePathAutotileSet.fromPreset(_animatedPreset());
      const variant = TerrainPathVariant.horizontal;

      expect(
        set.resolvedTilesetIdForVariantAt(variant, elapsedMs: 0),
        'base_tileset',
      );
      expect(
        set.resolvedTilesetIdForVariantAt(variant, elapsedMs: 120),
        'water_fx_tileset',
      );
    });

    test('returns null source for missing variant mapping', () {
      final set = RuntimePathAutotileSet.fromPreset(_animatedPreset());
      expect(
        set.sourceForVariantAt(TerrainPathVariant.cross, elapsedMs: 0),
        isNull,
      );
    });

    test('animates a single-frame variant from a matching animated source', () {
      final set = RuntimePathAutotileSet.fromPreset(_waterEdgeLikePreset());

      final frameAt0 = set.frameForVariantAt(
        TerrainPathVariant.teeSouth,
        elapsedMs: 0,
      );
      final frameAt220 = set.frameForVariantAt(
        TerrainPathVariant.teeSouth,
        elapsedMs: 220,
      );

      expect(frameAt0?.source, const TilesetSourceRect(x: 2, y: 79));
      expect(frameAt220?.source, const TilesetSourceRect(x: 8, y: 79));
    });
  });
}

ProjectPathPreset _animatedPreset() {
  return const ProjectPathPreset(
    id: 'water',
    name: 'Water',
    tilesetId: 'base_tileset',
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.horizontal,
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0),
            durationMs: 100,
          ),
          TilesetVisualFrame(
            tilesetId: 'water_fx_tileset',
            source: TilesetSourceRect(x: 1, y: 0),
            durationMs: 100,
          ),
        ],
      ),
    ],
  );
}

ProjectPathPreset _waterEdgeLikePreset() {
  return const ProjectPathPreset(
    id: 'water_edge',
    name: 'water_edge',
    surfaceKind: PathSurfaceKind.water,
    tilesetId: 'tech_nature_animations',
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.endSouth,
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 79),
            durationMs: 100,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 5, y: 79),
            durationMs: 100,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 8, y: 79),
            durationMs: 100,
          ),
        ],
      ),
      PathPresetVariantMapping(
        variant: TerrainPathVariant.teeSouth,
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 79),
            durationMs: null,
          ),
        ],
      ),
    ],
  );
}
