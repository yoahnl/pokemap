import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAtlasTileRef', () {
    test('minimal ref holds fields', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'water-atlas',
        column: 3,
        row: 4,
      );
      expect(ref.atlasId, 'water-atlas');
      expect(ref.column, 3);
      expect(ref.row, 4);
    });

    test('stores atlasId exactly without trimming the stored value', () {
      const raw = '  water-atlas  ';
      final ref = SurfaceAtlasTileRef(
        atlasId: raw,
        column: 0,
        row: 0,
      );
      expect(ref.atlasId, raw);
    });

    test('rejects empty atlasId: empty string', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: '', column: 0, row: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty atlasId: whitespace only', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: '   ', column: 0, row: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative column', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: 'a', column: -1, row: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative row', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts column and row zero', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'atlas',
        column: 0,
        row: 0,
      );
      expect(ref.column, 0);
      expect(ref.row, 0);
    });

    test('isInside: true for interior cells', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final a = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 0,
        row: 0,
      );
      final b = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 3,
        row: 2,
      );
      expect(a.isInside(geometry), isTrue);
      expect(b.isInside(geometry), isTrue);
    });

    test('isInside: false when out of grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      void expectOut(int c, int r) {
        expect(
          SurfaceAtlasTileRef(
            atlasId: 'a',
            column: c,
            row: r,
          ).isInside(geometry),
          isFalse,
        );
      }

      expectOut(4, 0);
      expectOut(0, 3);
      expectOut(99, 99);
    });

    test('isInside: same column/row independent of layout enum', () {
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
      final ref = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 1,
        row: 1,
      );
      expect(ref.isInside(gGrid), isTrue);
      expect(ref.isInside(gVertical), isTrue);
    });

    test('value equality: same values and hashCode', () {
      final a = SurfaceAtlasTileRef(atlasId: 'x', column: 2, row: 3);
      final b = SurfaceAtlasTileRef(atlasId: 'x', column: 2, row: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: atlasId differs', () {
      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      final b = SurfaceAtlasTileRef(atlasId: 'b', column: 0, row: 0);
      expect(a, isNot(b));
    });

    test('value equality: column differs', () {
      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      final b = SurfaceAtlasTileRef(atlasId: 'a', column: 1, row: 0);
      expect(a, isNot(b));
    });

    test('value equality: row differs', () {
      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      final b = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 1);
      expect(a, isNot(b));
    });

    test('export: type is visible through map_core', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      expect(ref, isA<SurfaceAtlasTileRef>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L24',
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
