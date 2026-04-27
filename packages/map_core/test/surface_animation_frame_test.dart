import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAnimationFrame', () {
    test('minimal frame holds tileRef and durationMs', () {
      final tileRef = SurfaceAtlasTileRef(
        atlasId: 'water-atlas',
        column: 3,
        row: 4,
      );

      final frame = SurfaceAnimationFrame(
        tileRef: tileRef,
        durationMs: 120,
      );

      expect(frame.tileRef, tileRef);
      expect(frame.durationMs, 120);
    });

    test('preserves the exact same tileRef instance (identity)', () {
      final tileRef = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 0,
        row: 0,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: tileRef,
        durationMs: 50,
      );
      expect(identical(frame.tileRef, tileRef), isTrue);
    });

    test('rejects durationMs == 0', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
      expect(
        () => SurfaceAnimationFrame(tileRef: ref, durationMs: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects durationMs < 0', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
      expect(
        () => SurfaceAnimationFrame(tileRef: ref, durationMs: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts durationMs == 1', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
      final frame = SurfaceAnimationFrame(
        tileRef: ref,
        durationMs: 1,
      );
      expect(frame.durationMs, 1);
    });

    test('isInside: true for interior cell', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 3,
          row: 2,
        ),
        durationMs: 10,
      );
      expect(frame.isInside(geometry), isTrue);
    });

    test('isInside: false when cell out of grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 4,
          row: 0,
        ),
        durationMs: 10,
      );
      expect(frame.isInside(geometry), isFalse);
    });

    test('isInside: same frame independent of layout enum', () {
      final tile = SurfaceAtlasTileSize(width: 8, height: 8);
      final grid = SurfaceAtlasGridSize(columns: 4, rows: 3);
      final gGrid = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      final gVertical = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 1,
        ),
        durationMs: 5,
      );
      expect(frame.isInside(gGrid), isTrue);
      expect(frame.isInside(gVertical), isTrue);
    });

    test('value equality: same tile values and duration => equal and same hash', () {
      final a = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 2,
        ),
        durationMs: 100,
      );
      final b = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 2,
        ),
        durationMs: 100,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: different tileRef (atlasId)', () {
      final a = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final b = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'b',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      expect(a, isNot(b));
    });

    test('value equality: different tileRef (column)', () {
      final a = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final b = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 0,
        ),
        durationMs: 10,
      );
      expect(a, isNot(b));
    });

    test('value equality: different durationMs', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 0,
        row: 0,
      );
      final a = SurfaceAnimationFrame(tileRef: ref, durationMs: 10);
      final b = SurfaceAnimationFrame(tileRef: ref, durationMs: 20);
      expect(a, isNot(b));
    });

    test('export: type is visible through map_core', () {
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 1,
      );
      expect(frame, isA<SurfaceAnimationFrame>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      final manifest = ProjectManifest(
        name: 'L25',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),);
      final map = manifest.toJson();
      expect(map.containsKey('surfaceCatalog'), isTrue);
      for (final key in <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
    });
  });
}
