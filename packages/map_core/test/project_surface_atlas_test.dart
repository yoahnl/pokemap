import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geometry({
  SurfaceAtlasLayout layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: layout,
  );
}

void main() {
  group('ProjectSurfaceAtlas', () {
    test('minimal atlas: fields and derived geometry', () {
      final atlas = ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'Water Atlas',
        tilesetId: 'outdoor-water',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
          layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
        ),
      );
      expect(atlas.id, 'water-atlas');
      expect(atlas.name, 'Water Atlas');
      expect(atlas.tilesetId, 'outdoor-water');
      expect(atlas.categoryId, isNull);
      expect(atlas.sortOrder, 0);
      expect(atlas.geometry.tileCount, 736);
      expect(
        atlas.geometry.layout,
        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
    });

    test('preserves categoryId and sortOrder', () {
      final atlas = ProjectSurfaceAtlas(
        id: 'a1',
        name: 'A',
        tilesetId: 't1',
        geometry: _geometry(),
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(atlas.categoryId, 'animated-surfaces');
      expect(atlas.sortOrder, 42);
    });

    test('stores id, name, tilesetId exactly (no auto-trim on fields)', () {
      const rawId = '  water-atlas  ';
      const rawName = '  Water Atlas  ';
      const rawTileset = '  outdoor-water  ';
      final atlas = ProjectSurfaceAtlas(
        id: rawId,
        name: rawName,
        tilesetId: rawTileset,
        geometry: _geometry(),
      );
      expect(atlas.id, rawId);
      expect(atlas.name, rawName);
      expect(atlas.tilesetId, rawTileset);
    });

    test('rejects empty id: empty string', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: '',
          name: 'N',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty id: whitespace only', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: '   ',
          name: 'N',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: empty string', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: '',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: whitespace only', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: '   ',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty tilesetId: empty string', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: 'n',
          tilesetId: '',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty tilesetId: whitespace only', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: 'n',
          tilesetId: '   ',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('keeps the same geometry instance (no re-wrap)', () {
      final geom = _geometry();
      final atlas = ProjectSurfaceAtlas(
        id: 'x',
        name: 'X',
        tilesetId: 'y',
        geometry: geom,
      );
      expect(atlas.geometry, same(geom));
    });

    test('value equality: same values', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: 'c',
        sortOrder: 1,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: 'c',
        sortOrder: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: id differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'a',
        name: 'n',
        tilesetId: 't',
        geometry: g,
      );
      final b = ProjectSurfaceAtlas(
        id: 'b',
        name: 'n',
        tilesetId: 't',
        geometry: g,
      );
      expect(a, isNot(b));
    });

    test('value equality: name differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n1',
        tilesetId: 't',
        geometry: g,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n2',
        tilesetId: 't',
        geometry: g,
      );
      expect(a, isNot(b));
    });

    test('value equality: tilesetId differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't1',
        geometry: g,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't2',
        geometry: g,
      );
      expect(a, isNot(b));
    });

    test('value equality: geometry differs (layout)', () {
      final g1 = _geometry(
        layout: SurfaceAtlasLayout.grid,
      );
      final g2 = _geometry(
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g1,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g2,
      );
      expect(a, isNot(b));
    });

    test('value equality: geometry differs (grid size)', () {
      final g1 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      );
      final g2 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 3, rows: 2),
      );
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g1,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g2,
      );
      expect(a, isNot(b));
    });

    test('value equality: categoryId differs (including null vs non-null)', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: 'c',
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: null,
      );
      expect(a, isNot(b));
    });

    test('value equality: sortOrder differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        sortOrder: 0,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        sortOrder: 1,
      );
      expect(a, isNot(b));
    });

    test('export: type available via map_core', () {
      final atlas = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: _geometry(),
      );
      expect(atlas, isA<ProjectSurfaceAtlas>());
    });

    test('ProjectManifest toJson: no top-level surface* keys', () {
      const manifest = ProjectManifest(
        name: 'L23',
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
