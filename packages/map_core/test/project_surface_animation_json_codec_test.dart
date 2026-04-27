import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSurfaceAnimation JSON codec (Lot 42)', () {
    test('1. encodes minimal ProjectSurfaceAnimation', () {
      final t = _timeline();
      final a = _animation(
        timeline: t,
        syncGroupId: null,
        categoryId: null,
        sortOrder: 0,
      );
      final j = encodeProjectSurfaceAnimation(a);
      expect(j['id'], 'water-loop');
      expect(j['name'], 'Water Loop');
      expect(j['timeline'], encodeSurfaceAnimationTimeline(t));
      expect(j['sortOrder'], 0);
      expect(j.containsKey('syncGroupId'), isFalse);
      expect(j.containsKey('categoryId'), isFalse);
    });

    test('2. decodes minimal ProjectSurfaceAnimation', () {
      const j = <String, Object?>{
        'id': 'water-loop',
        'name': 'Water Loop',
        'timeline': <String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 0,
              },
              'durationMs': 120,
            },
          ],
        },
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.id, 'water-loop');
      expect(a.name, 'Water Loop');
      expect(a.frameCount, 1);
      expect(a.syncGroupId, isNull);
      expect(a.categoryId, isNull);
      expect(a.sortOrder, 0);
    });

    test('3. round-trip minimal animation', () {
      final o = _animation();
      final d = decodeProjectSurfaceAnimation(encodeProjectSurfaceAnimation(o));
      expect(d, o);
    });

    test('4. encodes full animation (sync, category, sort)', () {
      final a = _animation(
        syncGroupId: 'water',
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      final j = encodeProjectSurfaceAnimation(a);
      expect(j['syncGroupId'], 'water');
      expect(j['categoryId'], 'animated-surfaces');
      expect(j['sortOrder'], 42);
    });

    test('5. decodes full animation', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'N',
        'timeline': encodeSurfaceAnimationTimeline(_timeline()) as Object?,
        'syncGroupId': 'water',
        'categoryId': 'animated-surfaces',
        'sortOrder': 42,
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.syncGroupId, 'water');
      expect(a.categoryId, 'animated-surfaces');
      expect(a.sortOrder, 42);
    });

    test('6. round-trip full animation', () {
      final o = _animation(
        syncGroupId: 's',
        categoryId: 'c',
        sortOrder: 7,
      );
      final d = decodeProjectSurfaceAnimation(encodeProjectSurfaceAnimation(o));
      expect(d, o);
    });

    test('7. encode preserves multi-frame timeline', () {
      final tl = _timeline(frames: [
        _frame(row: 0, durationMs: 100),
        _frame(row: 1, durationMs: 120),
        _frame(row: 2, durationMs: 140),
      ]);
      final a = _animation(timeline: tl);
      final j = encodeProjectSurfaceAnimation(a);
      final tlJson = j['timeline'] as Map<String, Object?>?;
      final frames = tlJson!['frames'] as List<Object?>?;
      expect(frames!.length, 3);
      for (var i = 0; i < 3; i++) {
        expect(
          frames[i],
          encodeSurfaceAnimationFrame(tl.frames[i]),
        );
      }
    });

    test('8. decodes multi-frame timeline', () {
      const j = <String, Object?>{
        'id': 'x',
        'name': 'Y',
        'timeline': <String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 0,
              },
              'durationMs': 100,
            },
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 1,
              },
              'durationMs': 120,
            },
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 2,
              },
              'durationMs': 140,
            },
          ],
        },
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.frameCount, 3);
      expect(a.totalDurationMs, 360);
      expect(a.timeline.frames[0].tileRef.row, 0);
      expect(a.timeline.frames[2].tileRef.row, 2);
    });

    test('9. decode preserves exact id/name/sync/category strings', () {
      const id = '  water-loop  ';
      const name = '  Water Loop  ';
      const sync = '  water  ';
      const cat = '  animated  ';
      final j = <String, Object?>{
        'id': id,
        'name': name,
        'timeline': encodeSurfaceAnimationTimeline(_timeline()) as Object?,
        'syncGroupId': sync,
        'categoryId': cat,
        'sortOrder': 0,
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.id, id);
      expect(a.name, name);
      expect(a.syncGroupId, sync);
      expect(a.categoryId, cat);
    });

    test('10. reject id missing / wrong type / whitespace-only', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{'name': 'n', 'timeline': _minimalTimelineJson()}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 123,
          'name': 'n',
          'timeline': _minimalTimelineJson(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': '   ',
          'name': 'n',
          'timeline': _minimalTimelineJson(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. reject name missing / wrong type / whitespace-only', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'i',
          'timeline': _minimalTimelineJson(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'i',
          'name': 123,
          'timeline': _minimalTimelineJson(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'i',
          'name': '   ',
          'timeline': _minimalTimelineJson(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. reject timeline missing / not a Map', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{'id': 'a', 'name': 'b'}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'timeline': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. reject empty timeline frames', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'timeline': <String, Object?>{'frames': <Object?>[]},
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': _minimalTimelineJson(),
        'futureField': 'ignored',
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.id, 'a');
    });

    test('15. decode ignores unknown keys in timeline / frame / tileRef', () {
      final inner = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 0,
          'row': 0,
          'x': 1,
        },
        'durationMs': 120,
        'f': 2,
      };
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': <String, Object?>{
          'frames': <Object?>[inner],
          'g': 3,
        },
        'h': 4,
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.frameCount, 1);
    });

    test('16. decode accepts syncGroupId: null in JSON', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': _minimalTimelineJson(),
        'syncGroupId': null,
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.syncGroupId, isNull);
    });

    test('17. reject syncGroupId non-string non-null', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'timeline': _minimalTimelineJson(),
          'syncGroupId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('18. reject syncGroupId whitespace-only (model + codec)', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'timeline': _minimalTimelineJson(),
          'syncGroupId': '   ',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('19. decode accepts categoryId: null', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': _minimalTimelineJson(),
        'categoryId': null,
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.categoryId, isNull);
    });

    test('20. reject categoryId non-string non-null', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'timeline': _minimalTimelineJson(),
          'categoryId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. decode accepts sortOrder absent (default 0)', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': _minimalTimelineJson(),
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.sortOrder, 0);
    });

    test('22. decode accepts negative sortOrder', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': _minimalTimelineJson(),
        'sortOrder': -10,
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.sortOrder, -10);
    });

    test('23. reject sortOrder non-int', () {
      expect(
        () => decodeProjectSurfaceAnimation(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'timeline': _minimalTimelineJson(),
          'sortOrder': '10',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode does not mutate source map', () {
      final m = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': <String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 0,
              },
              'durationMs': 120,
            },
          ],
        },
      };
      final before = _deepStr(m);
      decodeProjectSurfaceAnimation(m);
      expect(_deepStr(m), before);
    });

    test('25. encode does not mutate source animation', () {
      final a = _animation(
        syncGroupId: 's',
        categoryId: 'c',
        sortOrder: 3,
      );
      final id = a.id;
      final name = a.name;
      final fc = a.frameCount;
      final td = a.totalDurationMs;
      final sy = a.syncGroupId;
      final cat = a.categoryId;
      final so = a.sortOrder;
      encodeProjectSurfaceAnimation(a);
      expect(a.id, id);
      expect(a.name, name);
      expect(a.frameCount, fc);
      expect(a.totalDurationMs, td);
      expect(a.syncGroupId, sy);
      expect(a.categoryId, cat);
      expect(a.sortOrder, so);
    });

    test('26. no geometry in codec; isInside is separate', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': <String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 999,
                'row': 999,
              },
              'durationMs': 120,
            },
          ],
        },
      };
      final a = decodeProjectSurfaceAnimation(j);
      final g = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a.isInside(g), isFalse);
    });

    test('27. no external resolution of atlasId', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'timeline': <String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'missing-atlas',
                'column': 0,
                'row': 0,
              },
              'durationMs': 1,
            },
          ],
        },
      };
      final a = decodeProjectSurfaceAnimation(j);
      expect(a.timeline.frames.first.tileRef.atlasId, 'missing-atlas');
    });

    test('28. public API encode returns Map', () {
      expect(encodeProjectSurfaceAnimation(_animation()), isA<Map<String, Object?>>());
    });

    test('29. ProjectManifest has no surface persistence keys (Lot 42)', () {
      const manifest = ProjectManifest(
        name: 'L42',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final ju = manifest.toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(ju.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '30. codec external to model: no animation.toJson or ProjectSurfaceAnimation.fromJson',
      () {
        final a = _animation();
        final m = encodeProjectSurfaceAnimation(a);
        expect(m, isA<Map<String, Object?>>());
        // Ne pas appeler a.toJson / ProjectSurfaceAnimation.fromJson.
      },
    );

    test(
      '31. no preset / catalog / variant ref codec in this lot',
      () {
        final j = encodeProjectSurfaceAnimation(_animation());
        expect(j.containsKey('id'), isTrue);
        // Pas d’encodeProjectSurfacePreset, encodeProjectSurfaceCatalog, etc.
      },
    );

    test('32. reuses Lot 41 timeline codec (json[timeline] == encodeTimeline)', () {
      final a = _animation();
      final j = encodeProjectSurfaceAnimation(a);
      expect(
        j['timeline'],
        encodeSurfaceAnimationTimeline(a.timeline),
      );
    });
  });
}

Map<String, Object?> _minimalTimelineJson() => <String, Object?>{
      'frames': <Object?>[
        <String, Object?>{
          'tileRef': <String, Object?>{
            'atlasId': 'water-atlas',
            'column': 0,
            'row': 0,
          },
          'durationMs': 120,
        },
      ],
    };

SurfaceAnimationFrame _frame({
  String atlasId = 'water-atlas',
  int column = 0,
  int row = 0,
  int durationMs = 120,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

SurfaceAnimationTimeline _timeline({List<SurfaceAnimationFrame>? frames}) {
  return SurfaceAnimationTimeline(
    frames: frames ?? [_frame()],
  );
}

ProjectSurfaceAnimation _animation({
  String id = 'water-loop',
  String name = 'Water Loop',
  SurfaceAnimationTimeline? timeline,
  String? syncGroupId,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: timeline ?? _timeline(),
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
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
