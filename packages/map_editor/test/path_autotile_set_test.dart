import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';

void main() {
  group('PathAutotileSet animation fallback', () {
    test('animates a single-frame variant from a matching animated source', () {
      final set = PathAutotileSet.fromPreset(_waterEdgeLikePreset());

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
