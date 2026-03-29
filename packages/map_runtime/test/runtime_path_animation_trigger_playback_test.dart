import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/runtime_path_autotile.dart';

void main() {
  group('RuntimePathAutotileSet trigger playback helpers', () {
    test('frameForVariantStatic returns first frame', () {
      final set = RuntimePathAutotileSet.fromPreset(_preset());
      final frame = set.frameForVariantStatic(TerrainPathVariant.horizontal);
      expect(frame, isNotNull);
      expect(frame!.source, const TilesetSourceRect(x: 0, y: 0));
    });

    test('frameForVariantOneShot advances once and clamps at last frame', () {
      final set = RuntimePathAutotileSet.fromPreset(_preset());
      final frame0 = set.frameForVariantOneShot(
        TerrainPathVariant.horizontal,
        elapsedMs: 0,
      );
      final frame1 = set.frameForVariantOneShot(
        TerrainPathVariant.horizontal,
        elapsedMs: 120,
      );
      final frame2 = set.frameForVariantOneShot(
        TerrainPathVariant.horizontal,
        elapsedMs: 260,
      );
      expect(frame0?.source, const TilesetSourceRect(x: 0, y: 0));
      expect(frame1?.source, const TilesetSourceRect(x: 1, y: 0));
      expect(frame2?.source, const TilesetSourceRect(x: 2, y: 0));
    });

    test('resolvedTilesetId respects frame override', () {
      final set = RuntimePathAutotileSet.fromPreset(_preset());
      final overridden = set.frameForVariantOneShot(
        TerrainPathVariant.horizontal,
        elapsedMs: 120,
      );
      final fallback = set.frameForVariantStatic(TerrainPathVariant.horizontal);
      expect(set.resolvedTilesetId(overridden), 'water_fx');
      expect(set.resolvedTilesetId(fallback), 'base');
    });
  });
}

ProjectPathPreset _preset() {
  return const ProjectPathPreset(
    id: 'water',
    name: 'Water',
    tilesetId: 'base',
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.horizontal,
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0),
            durationMs: 100,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 0),
            tilesetId: 'water_fx',
            durationMs: 100,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 0),
            durationMs: 100,
          ),
        ],
      ),
    ],
  );
}
