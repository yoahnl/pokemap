import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAtlasTileSize', () {
    test('keeps width and height', () {
      final size = SurfaceAtlasTileSize(width: 32, height: 16);
      expect(size.width, 32);
      expect(size.height, 16);
    });

    test('rejects non-positive width: 0', () {
      expect(
        () => SurfaceAtlasTileSize(width: 0, height: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive width: -1', () {
      expect(
        () => SurfaceAtlasTileSize(width: -1, height: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive height: 0', () {
      expect(
        () => SurfaceAtlasTileSize(width: 1, height: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive height: -1', () {
      expect(
        () => SurfaceAtlasTileSize(width: 1, height: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('value equality: same values => equal and same hashCode', () {
      final a = SurfaceAtlasTileSize(width: 12, height: 8);
      final b = SurfaceAtlasTileSize(width: 12, height: 8);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: different => not equal', () {
      final a = SurfaceAtlasTileSize(width: 12, height: 8);
      final b = SurfaceAtlasTileSize(width: 10, height: 8);
      expect(a, isNot(b));
    });
  });

  group('SurfaceAtlasGridSize', () {
    test('keeps columns, rows, tileCount', () {
      final g = SurfaceAtlasGridSize(columns: 23, rows: 32);
      expect(g.columns, 23);
      expect(g.rows, 32);
      expect(g.tileCount, 736);
    });

    test('rejects non-positive columns: 0', () {
      expect(
        () => SurfaceAtlasGridSize(columns: 0, rows: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive columns: -1', () {
      expect(
        () => SurfaceAtlasGridSize(columns: -1, rows: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive rows: 0', () {
      expect(
        () => SurfaceAtlasGridSize(columns: 1, rows: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive rows: -1', () {
      expect(
        () => SurfaceAtlasGridSize(columns: 1, rows: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('value equality: same => equal; different => not', () {
      final a = SurfaceAtlasGridSize(columns: 2, rows: 3);
      final b = SurfaceAtlasGridSize(columns: 2, rows: 3);
      final c = SurfaceAtlasGridSize(columns: 2, rows: 4);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('SurfaceAtlasGeometry', () {
    test('keeps fields and delegates tileCount', () {
      final tileSize = SurfaceAtlasTileSize(width: 32, height: 32);
      final gridSize = SurfaceAtlasGridSize(columns: 23, rows: 32);
      final geometry = SurfaceAtlasGeometry(
        tileSize: tileSize,
        gridSize: gridSize,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(geometry.tileSize, same(tileSize));
      expect(geometry.gridSize, same(gridSize));
      expect(
        geometry.layout,
        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(geometry.tileCount, 736);
    });

    test('default layout is grid', () {
      final tileSize = SurfaceAtlasTileSize(width: 8, height: 8);
      final gridSize = SurfaceAtlasGridSize(columns: 1, rows: 1);
      final geometry = SurfaceAtlasGeometry(
        tileSize: tileSize,
        gridSize: gridSize,
      );
      expect(geometry.layout, SurfaceAtlasLayout.grid);
    });

    test('containsGridCoordinate: interior points in range', () {
      final tile = SurfaceAtlasTileSize(width: 1, height: 1);
      final grid = SurfaceAtlasGridSize(columns: 3, rows: 2);
      final g = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(g.containsGridCoordinate(column: 0, row: 0), isTrue);
      expect(g.containsGridCoordinate(column: 2, row: 1), isTrue);
      expect(g.containsGridCoordinate(column: 1, row: 1), isTrue);
    });

    test('containsGridCoordinate: out of range or negative', () {
      final tile = SurfaceAtlasTileSize(width: 1, height: 1);
      final grid = SurfaceAtlasGridSize(columns: 3, rows: 2);
      final g = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(g.containsGridCoordinate(column: -1, row: 0), isFalse);
      expect(g.containsGridCoordinate(column: 0, row: -1), isFalse);
      expect(g.containsGridCoordinate(column: 3, row: 0), isFalse);
      expect(g.containsGridCoordinate(column: 0, row: 2), isFalse);
      expect(g.containsGridCoordinate(column: 99, row: 99), isFalse);
    });

    test('value equality: layout / tile / grid disambiguation', () {
      final t = SurfaceAtlasTileSize(width: 16, height: 16);
      final g32 = SurfaceAtlasGridSize(columns: 2, rows: 2);
      final a = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: g32,
        layout: SurfaceAtlasLayout.grid,
      );
      final b = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: g32,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      final c = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: g32,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(a, isNot(c));

      final t2 = SurfaceAtlasTileSize(width: 8, height: 8);
      final aTile = SurfaceAtlasGeometry(
        tileSize: t2,
        gridSize: g32,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a, isNot(aTile));

      final gOther = SurfaceAtlasGridSize(columns: 3, rows: 2);
      final aGrid = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: gOther,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a, isNot(aGrid));
    });
  });

  group('public export & manifest unchanged', () {
    test('map_core exposes all new types', () {
      // Types referenced above; if export breaks, this file will not resolve.
      expect(SurfaceAtlasLayout.values, isNotEmpty);
    });

    test('ProjectManifest toJson() still has no surface* top-level keys', () {
      final manifest = ProjectManifest(
        name: 'L22',
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
