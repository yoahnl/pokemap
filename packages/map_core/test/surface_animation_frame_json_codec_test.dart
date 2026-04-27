import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40)', () {
    test('1. encodes SurfaceAtlasTileRef', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'water-atlas',
        column: 3,
        row: 12,
      );
      final j = encodeSurfaceAtlasTileRef(ref);
      expect(j, {
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      });
    });

    test('2. decodes SurfaceAtlasTileRef', () {
      final j = <String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      };
      final r = decodeSurfaceAtlasTileRef(j);
      expect(r.atlasId, 'water-atlas');
      expect(r.column, 3);
      expect(r.row, 12);
    });

    test('3. round-trip SurfaceAtlasTileRef', () {
      final original = _tileRef();
      final decoded = decodeSurfaceAtlasTileRef(encodeSurfaceAtlasTileRef(original));
      expect(decoded, original);
    });

    test('4. preserves exact atlasId string (no trim)', () {
      const raw = '  water-atlas  ';
      final r = decodeSurfaceAtlasTileRef(<String, Object?>{
        'atlasId': raw,
        'column': 3,
        'row': 12,
      });
      expect(r.atlasId, raw);
    });

    test('5. rejects atlasId missing, wrong type, whitespace-only', () {
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{'column': 0, 'row': 0}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 123,
          'column': 0,
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': '   ',
          'column': 0,
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. rejects column missing, wrong type, negative', () {
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': '3',
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': -1,
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. rejects row missing, wrong type, negative', () {
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': 0,
          'row': false,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': 0,
          'row': -1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('8. decode SurfaceAtlasTileRef ignores unknown keys', () {
      final r = decodeSurfaceAtlasTileRef(<String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
        'futureField': 'ignored',
      });
      expect(r, _tileRef());
    });

    test('9. decode SurfaceAtlasTileRef does not mutate source map', () {
      final map = <String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      };
      final before = _deepStr(map);
      decodeSurfaceAtlasTileRef(map);
      expect(_deepStr(map), before);
    });

    test('10. encodes SurfaceAnimationFrame', () {
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 3,
          row: 12,
        ),
        durationMs: 120,
      );
      expect(encodeSurfaceAnimationFrame(f), {
        'tileRef': {
          'atlasId': 'water-atlas',
          'column': 3,
          'row': 12,
        },
        'durationMs': 120,
      });
    });

    test('11. decodes SurfaceAnimationFrame', () {
      const j = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 3,
          'row': 12,
        },
        'durationMs': 120,
      };
      final f = decodeSurfaceAnimationFrame(j);
      expect(f.tileRef.atlasId, 'water-atlas');
      expect(f.tileRef.column, 3);
      expect(f.tileRef.row, 12);
      expect(f.durationMs, 120);
    });

    test('12. round-trip SurfaceAnimationFrame', () {
      final original = _frame();
      final decoded = decodeSurfaceAnimationFrame(encodeSurfaceAnimationFrame(original));
      expect(decoded, original);
    });

    test('13. rejects frame tileRef missing or wrong type', () {
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{'durationMs': 120}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': 'nope',
          'durationMs': 120,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. rejects durationMs missing or wrong type', () {
      final ref = <String, Object?>{'atlasId': 'a', 'column': 0, 'row': 0};
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{'tileRef': ref}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': ref,
          'durationMs': '120',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. rejects durationMs <= 0', () {
      final ref = <String, Object?>{'atlasId': 'a', 'column': 0, 'row': 0};
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': ref,
          'durationMs': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': ref,
          'durationMs': -1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode SurfaceAnimationFrame ignores unknown keys', () {
      final f = decodeSurfaceAnimationFrame(<String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 3,
          'row': 12,
        },
        'durationMs': 120,
        'futureField': 'ignored',
      });
      expect(f, _frame());
    });

    test('17. decode SurfaceAnimationFrame does not mutate source map', () {
      final inner = <String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      };
      final map = <String, Object?>{
        'tileRef': inner,
        'durationMs': 120,
      };
      final before = _deepStr(map);
      decodeSurfaceAnimationFrame(map);
      expect(_deepStr(map), before);
    });

    test('18. does not verify geometry; isInside is separate', () {
      const j = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 999,
          'row': 999,
        },
        'durationMs': 120,
      };
      final frame = decodeSurfaceAnimationFrame(j);
      expect(frame.tileRef.column, 999);
      expect(frame.tileRef.row, 999);

      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      expect(frame.isInside(geometry), isFalse);
    });

    test('19. nested tileRef errors propagate from decode frame', () {
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': <String, Object?>{
            'atlasId': '   ',
            'column': 3,
            'row': 12,
          },
          'durationMs': 120,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('20. public API encodeSurfaceAnimationFrame returns Map', () {
      expect(encodeSurfaceAnimationFrame(_frame()), isA<Map<String, Object?>>());
    });

    test('21. ProjectManifest has no surface persistence keys (Lot 40)', () {
      final manifest = ProjectManifest(
        name: 'L40',
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

    test(
      '22. codec external to models: no Surface toJson or fromJson on ref/frame',
      () {
        final tr = _tileRef();
        final jsonTr = encodeSurfaceAtlasTileRef(tr);
        expect(jsonTr, isA<Map<String, Object?>>());
        final f = _frame();
        final jsonF = encodeSurfaceAnimationFrame(f);
        expect(jsonF, isA<Map<String, Object?>>());
        // Ne pas appeler tr.toJson, SurfaceAtlasTileRef.fromJson, f.toJson,
        // SurfaceAnimationFrame.fromJson — inexistants / hors contrat.
      },
    );

    test(
      '23. no timeline or ProjectSurfaceAnimation codec in this lot',
      () {
        final j = encodeSurfaceAnimationFrame(_frame());
        expect(j.containsKey('tileRef'), isTrue);
        // Pas d’encodeSurfaceAnimationTimeline / encodeProjectSurfaceAnimation.
      },
    );
  });
}

SurfaceAtlasTileRef _tileRef({
  String atlasId = 'water-atlas',
  int column = 3,
  int row = 12,
}) {
  return SurfaceAtlasTileRef(atlasId: atlasId, column: column, row: row);
}

SurfaceAnimationFrame _frame({
  SurfaceAtlasTileRef? tileRef,
  int durationMs = 120,
}) {
  return SurfaceAnimationFrame(
    tileRef: tileRef ?? _tileRef(),
    durationMs: durationMs,
  );
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
