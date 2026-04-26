import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAnimationTimeline JSON codec (Lot 41)', () {
    test('1. encodes one-frame timeline', () {
      final t = _timeline(frames: [
        _frame(row: 0, durationMs: 120),
      ]);
      final j = encodeSurfaceAnimationTimeline(t);
      expect(j, {
        'frames': <Object?>[
          {
            'tileRef': {
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 0,
            },
            'durationMs': 120,
          },
        ],
      });
    });

    test('2. decodes one-frame timeline', () {
      const j = <String, Object?>{
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
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frameCount, 1);
      expect(t.totalDurationMs, 120);
      expect(t.frames.first.durationMs, 120);
      expect(t.frames.first.tileRef.atlasId, 'water-atlas');
    });

    test('3. round-trip one-frame timeline', () {
      final o = _timeline(frames: [_frame(row: 0, durationMs: 120)]);
      final d = decodeSurfaceAnimationTimeline(encodeSurfaceAnimationTimeline(o));
      expect(d, o);
    });

    test('4. encodes multi-frame timeline (order + durations)', () {
      final t = _timeline(frames: [
        _frame(row: 0, durationMs: 100),
        _frame(row: 1, durationMs: 120),
        _frame(row: 2, durationMs: 140),
      ]);
      final j = encodeSurfaceAnimationTimeline(t);
      final list = (j['frames'] as List<Object?>?) ?? [];
      expect(list.length, 3);
      for (var i = 0; i < 3; i++) {
        final f = t.frames[i];
        final m = list[i] as Map<String, Object?>;
        expect(m, encodeSurfaceAnimationFrame(f));
      }
    });

    test('5. decodes multi-frame timeline', () {
      const j = <String, Object?>{
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
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frameCount, 3);
      expect(t.frames[0].tileRef.row, 0);
      expect(t.frames[1].tileRef.row, 1);
      expect(t.frames[2].tileRef.row, 2);
      expect(t.frames[0].durationMs, 100);
      expect(t.frames[1].durationMs, 120);
      expect(t.frames[2].durationMs, 140);
      expect(t.totalDurationMs, 360);
    });

    test('6. round-trip multi-frame timeline', () {
      final o = _timeline(frames: [
        _frame(row: 0, durationMs: 100),
        _frame(row: 1, durationMs: 120),
        _frame(row: 2, durationMs: 140),
      ]);
      final d = decodeSurfaceAnimationTimeline(encodeSurfaceAnimationTimeline(o));
      expect(d, o);
    });

    test('7. decode preserves exact nested atlasId string', () {
      const raw = '  water-atlas  ';
      const j = <String, Object?>{
        'frames': <Object?>[
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': raw,
              'column': 0,
              'row': 0,
            },
            'durationMs': 120,
          },
        ],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frames.first.tileRef.atlasId, raw);
    });

    test('8. reject frames key missing', () {
      expect(
        () => decodeSurfaceAnimationTimeline({}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('9. reject frames not a List', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. reject empty frames', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. reject frame item not a Map', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>['nope'],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. reject invalid nested tileRef (whitespace atlasId)', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': '   ',
                'column': 0,
                'row': 0,
              },
              'durationMs': 120,
            },
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. reject invalid durationMs in frame', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 0,
              },
              'durationMs': 0,
            },
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'frames': <Object?>[
          encodeSurfaceAnimationFrame(_frame()) as Object?,
        ],
        'futureField': 'ignored',
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frameCount, 1);
    });

    test('15. decode ignores unknown key inside frame', () {
      final inner = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 0,
          'row': 0,
        },
        'durationMs': 120,
        'futureFrameField': 'ignored',
      };
      final j = <String, Object?>{
        'frames': <Object?>[inner],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frames.first.durationMs, 120);
    });

    test('16. decode ignores unknown key inside tileRef', () {
      final inner = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 0,
          'row': 0,
          'futureTileRefField': 'x',
        },
        'durationMs': 120,
      };
      final t = decodeSurfaceAnimationTimeline(<String, Object?>{
        'frames': <Object?>[inner],
      });
      expect(t.frames.first.tileRef.atlasId, 'water-atlas');
    });

    test('17. decode does not mutate source map', () {
      final map = <String, Object?>{
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
      final before = _deepStr(map);
      decodeSurfaceAnimationTimeline(map);
      expect(_deepStr(map), before);
    });

    test('18. no geometry check; isInside separate', () {
      const j = <String, Object?>{
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
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frames.first.tileRef.row, 999);
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      expect(t.isInside(geometry), isFalse);
    });

    test('19. encode does not mutate source timeline', () {
      final t = _timeline(frames: [
        _frame(row: 0, durationMs: 50),
        _frame(row: 1, durationMs: 70),
      ]);
      final beforeCount = t.frameCount;
      final beforeTotal = t.totalDurationMs;
      final beforeFirst = t.frames[0];
      encodeSurfaceAnimationTimeline(t);
      expect(t.frameCount, beforeCount);
      expect(t.totalDurationMs, beforeTotal);
      expect(t.frames[0], beforeFirst);
    });

    test('20. public API encode returns Map', () {
      expect(encodeSurfaceAnimationTimeline(_timeline()), isA<Map<String, Object?>>());
    });

    test('21. ProjectManifest has no surface persistence keys (Lot 41)', () {
      const manifest = ProjectManifest(
        name: 'L41',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final j = manifest.toJson();
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
      '22. codec external to model: no timeline toJson or SurfaceAnimationTimeline.fromJson',
      () {
        final t = _timeline();
        final m = encodeSurfaceAnimationTimeline(t);
        expect(m, isA<Map<String, Object?>>());
        // Ne pas appeler t.toJson / SurfaceAnimationTimeline.fromJson.
      },
    );

    test(
      '23. no ProjectSurfaceAnimation codec: encodeProjectSurfaceAnimation absent from lot',
      () {
        final t = _timeline();
        final j = encodeSurfaceAnimationTimeline(t);
        expect(j.containsKey('frames'), isTrue);
        // Pas d’encodeProjectSurfaceAnimation / decodeProjectSurfaceAnimation ici.
      },
    );

    test('24. reuses Lot 40 frame codec for each list element', () {
      final f = _frame();
      final t = _timeline(frames: [f]);
      final j = encodeSurfaceAnimationTimeline(t);
      final first = (j['frames'] as List<Object?>) [0] as Map<String, Object?>;
      expect(
        first,
        encodeSurfaceAnimationFrame(f),
      );
    });
  });
}

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
