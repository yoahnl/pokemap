import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Lot 21 — surface model entrypoint (SurfaceAtlasLayout)', () {
    test('SurfaceAtlasLayout.values exposes exactly the expected cases in order',
        () {
      expect(SurfaceAtlasLayout.values, [
        SurfaceAtlasLayout.grid,
        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
        SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames,
      ]);
    });

    test('ProjectManifest JSON has no surface engine manifest keys yet', () {
      const manifest = ProjectManifest(
        name: 'L21 smoke',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final map = manifest.toJson();
      const forbidden = <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ];
      for (final key in forbidden) {
        expect(map.containsKey(key), isFalse, reason: 'unexpected key: $key');
      }
    });

    test('ProjectPathPreset construction remains available unchanged', () {
      const preset = ProjectPathPreset(
        id: 'l21-preset',
        name: 'L21',
        surfaceKind: PathSurfaceKind.water,
      );
      expect(preset.id, 'l21-preset');
      expect(preset.name, 'L21');
      expect(preset.surfaceKind, PathSurfaceKind.water);
      expect(preset.variants, isEmpty);
    });
  });
}
