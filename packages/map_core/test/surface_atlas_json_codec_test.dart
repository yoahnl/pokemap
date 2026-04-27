import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geometry({
  int width = 32,
  int height = 32,
  int columns = 23,
  int rows = 32,
  SurfaceAtlasLayout layout =
      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: width, height: height),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: layout,
  );
}

ProjectSurfaceAtlas _atlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  SurfaceAtlasGeometry? geometry,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: geometry ?? _geometry(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

void main() {
  group('surface_atlas_json_codec (Lot 39)', () {
    test('1. encode SurfaceAtlasTileSize', () {
      final m = encodeSurfaceAtlasTileSize(
        SurfaceAtlasTileSize(width: 32, height: 16),
      );
      expect(m, {'width': 32, 'height': 16});
    });

    test('2. decode SurfaceAtlasTileSize', () {
      final t = decodeSurfaceAtlasTileSize({
        'width': 32,
        'height': 16,
      });
      expect(t.width, 32);
      expect(t.height, 16);
    });

    test('3. reject tile size missing / wrong type / width 0', () {
      expect(
        () => decodeSurfaceAtlasTileSize({'height': 16}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString().contains('width'),
            'mentions width',
            isTrue,
          ),
        ),
      );
      expect(
        () => decodeSurfaceAtlasTileSize({
          'width': 1,
          'height': 'x',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileSize({'width': 0, 'height': 1}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('4. encode SurfaceAtlasGridSize', () {
      final m = encodeSurfaceAtlasGridSize(
        SurfaceAtlasGridSize(columns: 23, rows: 32),
      );
      expect(m, {'columns': 23, 'rows': 32});
    });

    test('5. decode SurfaceAtlasGridSize', () {
      final g = decodeSurfaceAtlasGridSize({
        'columns': 23,
        'rows': 32,
      });
      expect(g.columns, 23);
      expect(g.rows, 32);
    });

    test('6. reject grid size missing / wrong type / columns 0', () {
      expect(
        () => decodeSurfaceAtlasGridSize({'rows': 1}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGridSize({
          'columns': 1,
          'rows': true,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGridSize({
          'columns': 0,
          'rows': 1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. encode/decode layout grid', () {
      expect(encodeSurfaceAtlasLayout(SurfaceAtlasLayout.grid), 'grid');
      expect(decodeSurfaceAtlasLayout('grid'), SurfaceAtlasLayout.grid);
    });

    test('8. encode/decode layout columnsAreVariantsRowsAreFrames', () {
      const l = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
      expect(encodeSurfaceAtlasLayout(l), 'columnsAreVariantsRowsAreFrames');
      expect(
        decodeSurfaceAtlasLayout('columnsAreVariantsRowsAreFrames'),
        l,
      );
    });

    test('9. reject layout unknown or wrong casing', () {
      expect(
        () => decodeSurfaceAtlasLayout('unknown'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString().contains('SurfaceAtlasLayout'),
            'msg',
            isTrue,
          ),
        ),
      );
      expect(
        () => decodeSurfaceAtlasLayout('Grid'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. encode SurfaceAtlasGeometry', () {
      final g = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final m = encodeSurfaceAtlasGeometry(g);
      expect(
        m,
        {
          'tileSize': {'width': 32, 'height': 32},
          'gridSize': {'columns': 23, 'rows': 32},
          'layout': 'columnsAreVariantsRowsAreFrames',
        },
      );
    });

    test('11. decode SurfaceAtlasGeometry + tileCount', () {
      final g = decodeSurfaceAtlasGeometry({
        'tileSize': {'width': 32, 'height': 32},
        'gridSize': {'columns': 23, 'rows': 32},
        'layout': 'columnsAreVariantsRowsAreFrames',
      });
      final expected = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(g, expected);
      expect(g.tileCount, 23 * 32);
    });

    test('12. reject geometry missing nested / wrong types', () {
      expect(
        () => decodeSurfaceAtlasGeometry({
          'gridSize': {
            'columns': 1,
            'rows': 1,
          },
          'layout': 'grid',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGeometry({
          'tileSize': {
            'width': 1,
            'height': 1,
          },
          'gridSize': 3,
          'layout': 'grid',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGeometry({
          'tileSize': {
            'width': 1,
            'height': 1,
          },
          'gridSize': {
            'columns': 1,
            'rows': 1,
          },
          'layout': 1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. encode ProjectSurfaceAtlas minimal', () {
      final a = _atlas(categoryId: null, sortOrder: 0);
      final m = encodeProjectSurfaceAtlas(a);
      expect(m.containsKey('categoryId'), isFalse);
      expect(m['sortOrder'], 0);
      expect(m['id'], 'water-atlas');
      expect(m['name'], 'Water Atlas');
      expect(m['tilesetId'], 'nature-tileset');
      expect(m['geometry'], isA<Map<String, Object?>>());
    });

    test('14. encode ProjectSurfaceAtlas full', () {
      final a = _atlas(
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      final m = encodeProjectSurfaceAtlas(a);
      expect(m['categoryId'], 'animated-surfaces');
      expect(m['sortOrder'], 42);
    });

    test('15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)',
        () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 8, 'height': 8},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
      });
      expect(a.categoryId, isNull);
      expect(a.sortOrder, 0);
    });

    test('16. decode ProjectSurfaceAtlas full', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 8, 'height': 8},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'categoryId': 'animated-surfaces',
        'sortOrder': 42,
      });
      expect(a.categoryId, 'animated-surfaces');
      expect(a.sortOrder, 42);
    });

    test('17. round-trip ProjectSurfaceAtlas', () {
      final atlas = _atlas(
        categoryId: 'cat',
        sortOrder: 7,
        geometry: _geometry(
          width: 16,
          height: 8,
          columns: 2,
          rows: 3,
        ),
      );
      final json = encodeProjectSurfaceAtlas(atlas);
      final back = decodeProjectSurfaceAtlas(json);
      expect(back, atlas);
    });

    test('18. exact strings preserved (no trim in codec)', () {
      const id = '  water-atlas  ';
      const name = '  Water Atlas  ';
      const tid = '  nature-tileset  ';
      const cat = '  animated  ';
      final a = _atlas(
        id: id,
        name: name,
        tilesetId: tid,
        categoryId: cat,
        sortOrder: 0,
        geometry: _geometry(
          width: 8,
          height: 8,
          columns: 1,
          rows: 1,
        ),
      );
      final j = encodeProjectSurfaceAtlas(a);
      final b = decodeProjectSurfaceAtlas(j);
      expect(b.id, id);
      expect(b.name, name);
      expect(b.tilesetId, tid);
      expect(b.categoryId, cat);
    });

    test(
        '19. reject id / name / tilesetId missing, wrong type, whitespace tileset',
        () {
      final baseG = {
        'tileSize': {'width': 1, 'height': 1},
        'gridSize': {'columns': 1, 'rows': 1},
        'layout': 'grid',
      };
      expect(
        () => decodeProjectSurfaceAtlas({
          'name': 'n',
          'tilesetId': 't',
          'geometry': baseG,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 1,
          'tilesetId': 't',
          'geometry': baseG,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': '   ',
          'geometry': baseG,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('20. reject geometry missing or non-map on atlas', () {
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
          'geometry': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. reject categoryId non-string non-null', () {
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
          'geometry': {
            'tileSize': {'width': 1, 'height': 1},
            'gridSize': {'columns': 1, 'rows': 1},
            'layout': 'grid',
          },
          'categoryId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('22. decode categoryId null in JSON', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'categoryId': null,
      });
      expect(a.categoryId, isNull);
    });

    test('23. reject sortOrder non-int', () {
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
          'geometry': {
            'tileSize': {'width': 1, 'height': 1},
            'gridSize': {'columns': 1, 'rows': 1},
            'layout': 'grid',
          },
          'sortOrder': '1',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode sortOrder negative', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'sortOrder': -10,
      });
      expect(a.sortOrder, -10);
    });

    test('25. decode ignores unknown top-level key', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'futureField': 'ignored',
      });
      expect(a.id, 'a');
    });

    test('26. tilesetId not resolved against manifest', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 'missing-tileset',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
      });
      expect(a.tilesetId, 'missing-tileset');
    });

    test('27. decode does not mutate source map', () {
      final map = <String, Object?>{
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': <String, Object?>{
          'tileSize': <String, Object?>{'width': 1, 'height': 1},
          'gridSize': <String, Object?>{'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
      };
      final before = _deepStr(map);
      decodeProjectSurfaceAtlas(map);
      final after = _deepStr(map);
      expect(before, after);
    });

    test('28. public API returns Map from encode', () {
      final m = encodeProjectSurfaceAtlas(_atlas());
      expect(m, isA<Map<String, Object?>>());
    });

    test('29. ProjectManifest has no surface persistence keys (Lot 39)', () {
      final manifest = ProjectManifest(
        name: 'L39',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),);
      final j = manifest.toJson();
      expect(j.containsKey('surfaceCatalog'), isTrue);
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('30. codec external to models: no model toJson / fromJson', () {
      final a = _atlas();
      final json = encodeProjectSurfaceAtlas(a);
      expect(json, isA<Map<String, Object?>>());
      // Lot 39: persistence via codec only — models stay JSON-free
      // (do not call atlas.toJson or ProjectSurfaceAtlas.fromJson).
    });
  });
}

String _deepStr(Object? o) {
  if (o is Map) {
    return '{${o.keys.map((k) => '$k:${_deepStr(o[k])}').join(',')}}';
  }
  if (o is String) {
    return o;
  }
  if (o is int) {
    return '$o';
  }
  if (o == null) {
    return 'null';
  }
  return o.toString();
}
