import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPreset frames', () {
    test('serializes and deserializes animated variant frames', () {
      final decoded = ProjectPathPreset.fromJson({
        'id': 'water_path',
        'name': 'Water Path',
        'surfaceKind': 'water',
        'tilesetId': 'outdoor',
        'variants': [
          {
            'variant': 'horizontal',
            'frames': [
              {
                'source': {'x': 2, 'y': 4, 'width': 1, 'height': 1},
                'durationMs': 90,
              },
              {
                'source': {'x': 3, 'y': 4, 'width': 1, 'height': 1},
                'durationMs': 110,
              },
            ],
          },
        ],
      });

      expect(decoded.surfaceKind, PathSurfaceKind.water);
      expect(decoded.variants.length, 1);
      expect(decoded.variants.first.frames.length, 2);
      expect(
        decoded.variants.first.frames.first.source,
        const TilesetSourceRect(x: 2, y: 4),
      );
      expect(decoded.variants.first.frames.last.durationMs, 110);
    });

    test('path preset variant accepts legacy source payload', () {
      final decoded = PathPresetVariantMapping.fromJson({
        'variant': 'horizontal',
        'source': {
          'x': 5,
          'y': 6,
          'width': 1,
          'height': 1,
        },
      });

      expect(decoded.variant, TerrainPathVariant.horizontal);
      expect(decoded.frames.length, 1);
      expect(
        decoded.frames.first.source,
        const TilesetSourceRect(x: 5, y: 6),
      );
    });

    test('validator rejects non-positive path frame durations', () {
      const manifest = ProjectManifest(
        name: 'project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'outdoor',
            name: 'Outdoor',
            relativePath: 'tilesets/outdoor.png',
          ),
        ],
        pathPresets: [
          ProjectPathPreset(
            id: 'water_path',
            name: 'Water',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'outdoor',
            variants: [
              PathPresetVariantMapping(
                variant: TerrainPathVariant.cross,
                frames: [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                    durationMs: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
