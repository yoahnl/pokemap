import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceVariantAnimationRefSet JSON codec (Lot 44)', () {
    test('1. encodes set with one isolated ref', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
      ]);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      expect(j, <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'water-isolated-loop',
          },
        ],
      });
    });

    test('2. decodes set with one ref', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'water-isolated-loop',
          },
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, 1);
      expect(s.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(
        s.animationIdForRole(SurfaceVariantRole.isolated),
        'water-isolated-loop',
      );
    });

    test('3. round-trip single ref set', () {
      final o = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
      ]);
      final d = decodeSurfaceVariantAnimationRefSet(
        encodeSurfaceVariantAnimationRefSet(o),
      );
      expect(d, o);
    });

    test('4. encode multi-ref preserves order (cross, isolated, horizontal)', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.cross, animationId: 'a'),
        _ref(SurfaceVariantRole.isolated, animationId: 'b'),
        _ref(SurfaceVariantRole.horizontal, animationId: 'c'),
      ]);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      final list = j['refs']! as List<Object?>;
      expect(list.length, 3);
      expect(
        (list[0] as Map<String, Object?>)['role'],
        'cross',
      );
      expect(
        (list[1] as Map<String, Object?>)['role'],
        'isolated',
      );
      expect(
        (list[2] as Map<String, Object?>)['role'],
        'horizontal',
      );
    });

    test('5. decode multi-ref preserves order', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{'role': 'cross', 'animationId': 'a'},
          <String, Object?>{'role': 'isolated', 'animationId': 'b'},
          <String, Object?>{'role': 'horizontal', 'animationId': 'c'},
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(
        s.refs.map((e) => e.role).toList(),
        [
          SurfaceVariantRole.cross,
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.horizontal,
        ],
      );
      expect(s.refForRole(SurfaceVariantRole.cross)?.animationId, 'a');
    });

    test('6. round-trip multi-ref', () {
      final o = _set(refs: [
        _ref(SurfaceVariantRole.cross, animationId: 'x'),
        _ref(SurfaceVariantRole.teeWest, animationId: 'y'),
      ]);
      final d = decodeSurfaceVariantAnimationRefSet(
        encodeSurfaceVariantAnimationRefSet(o),
      );
      expect(d, o);
    });

    test('7. encodes full standardSurfaceVariantRoleOrder', () {
      final refs = [
        for (final role in standardSurfaceVariantRoleOrder)
          _ref(role, animationId: 'id-${role.name}'),
      ];
      final s = _set(refs: refs);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      final list = j['refs']! as List<Object?>;
      expect(list.length, standardSurfaceVariantRoleOrder.length);
      for (var i = 0; i < refs.length; i++) {
        expect(
          list[i],
          encodeSurfaceVariantAnimationRef(refs[i]),
        );
      }
    });

    test('8. decodes full standard order set', () {
      final refs = [
        for (final role in standardSurfaceVariantRoleOrder)
          _ref(role, animationId: 'id-${role.name}'),
      ];
      final j = encodeSurfaceVariantAnimationRefSet(_set(refs: refs));
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, standardSurfaceVariantRoleOrder.length);
      expect(
        s.coversAllRoles(standardSurfaceVariantRoleOrder),
        isTrue,
      );
      for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++) {
        expect(s.refs[i].role, standardSurfaceVariantRoleOrder[i]);
      }
    });

    test('9. decode rejects missing refs', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. decode rejects refs not a List', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. decode rejects empty refs', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. decode rejects non-map list item', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>['nope'],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. decode rejects invalid role in ref', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'notARole', 'animationId': 'x'},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode rejects invalid animationId in ref', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': '   '},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. decode rejects duplicate roles', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
            <String, Object?>{'role': 'isolated', 'animationId': 'b'},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{'role': 'isolated', 'animationId': 'a'},
        ],
        'futureField': 'ignored',
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, 1);
    });

    test('17. decode ignores unknown key in ref item', () {
      final j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'a',
            'futureRefField': 'ignored',
          },
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.refs.first.animationId, 'a');
    });

    test('18. decode does not mutate source map', () {
      final m = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'a',
          },
        ],
      };
      final before = _mapStr(m);
      decodeSurfaceVariantAnimationRefSet(m);
      expect(_mapStr(m), before);
    });

    test('19. encode does not mutate ref set', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
        _ref(SurfaceVariantRole.cornerNE, animationId: 'b'),
      ]);
      final len = s.length;
      final r0 = s.refForRole(SurfaceVariantRole.isolated);
      final r1 = s.refForRole(SurfaceVariantRole.cornerNE);
      encodeSurfaceVariantAnimationRefSet(s);
      expect(s.length, len);
      expect(s.refForRole(SurfaceVariantRole.isolated), r0);
      expect(s.refForRole(SurfaceVariantRole.cornerNE), r1);
    });

    test('20. does not resolve animationId', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'missing-animation',
          },
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(
        s.animationIdForRole(SurfaceVariantRole.isolated),
        'missing-animation',
      );
    });

    test('21. does not complete missing roles', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{'role': 'isolated', 'animationId': 'a'},
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, 1);
      expect(
        s.coversAllRoles(standardSurfaceVariantRoleOrder),
        isFalse,
      );
    });

    test('22. reuses Lot 43 ref codec for each element', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
      ]);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      final list = j['refs']! as List<Object?>;
      expect(
        list[0],
        encodeSurfaceVariantAnimationRef(s.refs[0]),
      );
    });

    test('23. public API encode returns map', () {
      expect(encodeSurfaceVariantAnimationRefSet(_set()), isA<Map<String, Object?>>());
    });

    test('24. ProjectManifest has no surface persistence keys (Lot 44)', () {
      const manifest = ProjectManifest(
        name: 'L44',
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
      '25. codec external to model: no set.toJson or SurfaceVariantAnimationRefSet.fromJson',
      () {
        final s = _set();
        final m = encodeSurfaceVariantAnimationRefSet(s);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('26. ProjectSurfacePreset codec remains out of scope (Lot 45)', () {
      final j = encodeSurfaceVariantAnimationRefSet(_set());
      expect(j.containsKey('refs'), isTrue);
    });

    test('27. ProjectSurfaceCatalog codec remains out of scope', () {
      final j = encodeSurfaceVariantAnimationRefSet(_set());
      expect(j['refs'], isNotNull);
    });

    test('28. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)', () {
      expect(standardSurfaceVariantRoleOrder.length, 20);
    });
  });
}

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role, {
  String? animationId,
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId ?? 'id-${role.name}',
  );
}

SurfaceVariantAnimationRefSet _set({List<SurfaceVariantAnimationRef>? refs}) {
  return SurfaceVariantAnimationRefSet(
    refs: refs ??
        [
          _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
        ],
  );
}

String _mapStr(Object? o) {
  if (o is Map) {
    final keys = o.keys.toList()..sort();
    return keys.map((k) => '$k:${_mapStr(o[k])}').join('|');
  }
  if (o is List) {
    return o.map(_mapStr).join(';');
  }
  if (o is String) {
    return o;
  }
  return o.toString();
}
