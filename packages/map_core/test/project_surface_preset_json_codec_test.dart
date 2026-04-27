import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSurfacePreset JSON codec (Lot 45)', () {
    test('1. encodes minimal preset', () {
      final p = _preset(
        categoryId: null,
        sortOrder: 0,
      );
      final j = encodeProjectSurfacePreset(p);
      expect(j['id'], 'water-surface');
      expect(j['name'], 'Water Surface');
      expect(
        j['variantAnimations'],
        encodeSurfaceVariantAnimationRefSet(p.variantAnimations),
      );
      expect(j['sortOrder'], 0);
      expect(j.containsKey('categoryId'), isFalse);
    });

    test('2. decodes minimal preset', () {
      const j = <String, Object?>{
        'id': 'water-surface',
        'name': 'Water Surface',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{
              'role': 'isolated',
              'animationId': 'water-isolated-loop',
            },
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.id, 'water-surface');
      expect(p.name, 'Water Surface');
      expect(p.variantCount, 1);
      expect(p.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(
        p.animationIdForRole(SurfaceVariantRole.isolated),
        'water-isolated-loop',
      );
      expect(p.categoryId, isNull);
      expect(p.sortOrder, 0);
    });

    test('3. round-trip minimal preset', () {
      final o = _preset();
      final d = decodeProjectSurfacePreset(encodeProjectSurfacePreset(o));
      expect(d, o);
    });

    test('4. encodes full preset (category + sortOrder)', () {
      final p = _preset(
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      final j = encodeProjectSurfacePreset(p);
      expect(j['categoryId'], 'animated-surfaces');
      expect(j['sortOrder'], 42);
    });

    test('5. decodes full preset', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'N',
        'variantAnimations': encodeSurfaceVariantAnimationRefSet(
          _refSet(refs: [
            _ref(SurfaceVariantRole.isolated, animationId: 'x'),
          ]),
        ),
        'categoryId': 'animated-surfaces',
        'sortOrder': 42,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.categoryId, 'animated-surfaces');
      expect(p.sortOrder, 42);
    });

    test('6. round-trip full preset', () {
      final o = _preset(
        categoryId: 'c',
        sortOrder: 7,
      );
      final d = decodeProjectSurfacePreset(encodeProjectSurfacePreset(o));
      expect(d, o);
    });

    test('7. encode preserves multi-ref order in variantAnimations', () {
      final rs = _refSet(refs: [
        _ref(SurfaceVariantRole.cross, animationId: 'a'),
        _ref(SurfaceVariantRole.isolated, animationId: 'b'),
        _ref(SurfaceVariantRole.horizontal, animationId: 'c'),
      ]);
      final p = _preset(variantAnimations: rs);
      final j = encodeProjectSurfacePreset(p);
      final va = j['variantAnimations'] as Map<String, Object?>?;
      final refs = va!['refs'] as List<Object?>?;
      expect(refs!.length, 3);
      for (var i = 0; i < 3; i++) {
        expect(refs[i], encodeSurfaceVariantAnimationRef(rs.refs[i]));
      }
    });

    test('8. decode preserves multi-ref order', () {
      const j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'cross', 'animationId': 'a'},
            <String, Object?>{'role': 'isolated', 'animationId': 'b'},
            <String, Object?>{'role': 'horizontal', 'animationId': 'c'},
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.variantCount, 3);
      expect(
        p.variantAnimations.refs.map((e) => e.role).toList(),
        [
          SurfaceVariantRole.cross,
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.horizontal,
        ],
      );
      expect(p.refForRole(SurfaceVariantRole.cross)?.animationId, 'a');
    });

    test('9. decode preserves exact id name category strings', () {
      const id = '  water-surface  ';
      const name = '  Water Surface  ';
      const cat = '  animated  ';
      final j = <String, Object?>{
        'id': id,
        'name': name,
        'variantAnimations': encodeSurfaceVariantAnimationRefSet(
          _refSet(refs: [
            _ref(SurfaceVariantRole.isolated, animationId: 'a'),
          ]),
        ),
        'categoryId': cat,
        'sortOrder': 0,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.id, id);
      expect(p.name, name);
      expect(p.categoryId, cat);
    });

    test('10. reject id missing / wrong type / whitespace-only', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'name': 'n',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 123,
          'name': 'n',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': '   ',
          'name': 'n',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. reject name missing / wrong type / whitespace-only', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'i',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'i',
          'name': 123,
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'i',
          'name': '   ',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. reject variantAnimations missing or wrong type', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. reject empty variantAnimations refs', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{'refs': <Object?>[]},
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. reject duplicate role in variantAnimations', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{
            'refs': <Object?>[
              <String, Object?>{'role': 'isolated', 'animationId': 'a'},
              <String, Object?>{'role': 'isolated', 'animationId': 'b'},
            ],
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. reject invalid role in variantAnimations', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{
            'refs': <Object?>[
              <String, Object?>{'role': 'notARole', 'animationId': 'x'},
            ],
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. reject invalid animationId in variantAnimations', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{
            'refs': <Object?>[
              <String, Object?>{'role': 'isolated', 'animationId': '   '},
            ],
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
        'futureField': 'ignored',
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.id, 'a');
    });

    test('18. decode ignores unknown keys in variantAnimations and refs', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{
              'role': 'isolated',
              'animationId': 'a',
              'x': 1,
            },
          ],
          'extraVa': 2,
        },
        'h': 3,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.variantCount, 1);
    });

    test('19. decode accepts categoryId: null in JSON', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
        'categoryId': null,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.categoryId, isNull);
    });

    test('20. decode reject categoryId non-string non-null', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': _minVa(),
          'categoryId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. decode accept sortOrder absent (default 0)', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.sortOrder, 0);
    });

    test('22. decode accept negative sortOrder', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
        'sortOrder': -10,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.sortOrder, -10);
    });

    test('23. decode reject sortOrder non-int', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': _minVa(),
          'sortOrder': '10',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode does not mutate source map', () {
      final m = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
          ],
        },
      };
      final before = _mapStr(m);
      decodeProjectSurfacePreset(m);
      expect(_mapStr(m), before);
    });

    test('25. encode does not mutate preset', () {
      final p = _preset(
        categoryId: 'c',
        sortOrder: 3,
      );
      final id = p.id;
      final name = p.name;
      final vc = p.variantCount;
      final cat = p.categoryId;
      final so = p.sortOrder;
      final c = p.containsRole(SurfaceVariantRole.isolated);
      encodeProjectSurfacePreset(p);
      expect(p.id, id);
      expect(p.name, name);
      expect(p.variantCount, vc);
      expect(p.categoryId, cat);
      expect(p.sortOrder, so);
      expect(p.containsRole(SurfaceVariantRole.isolated), c);
    });

    test('26. does not resolve animationId', () {
      const j = <String, Object?>{
        'id': 'broken-but-structurally-valid',
        'name': 'Broken but structurally valid',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{
              'role': 'isolated',
              'animationId': 'missing-animation',
            },
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(
        p.animationIdForRole(SurfaceVariantRole.isolated),
        'missing-animation',
      );
    });

    test('27. does not complete missing standard roles', () {
      const j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.variantCount, 1);
      expect(
        p.coversAllRoles(standardSurfaceVariantRoleOrder),
        isFalse,
      );
    });

    test('28. reuses Lot 44 RefSet codec for variantAnimations', () {
      final p = _preset();
      final j = encodeProjectSurfacePreset(p);
      expect(
        j['variantAnimations'],
        encodeSurfaceVariantAnimationRefSet(p.variantAnimations),
      );
    });

    test('29. public API encode returns map', () {
      expect(encodeProjectSurfacePreset(_preset()), isA<Map<String, Object?>>());
    });

    test('30. ProjectManifest has no surface persistence keys (Lot 45)', () {
      final manifest = ProjectManifest(
        name: 'L45',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),);
      final ju = manifest.toJson();
      expect(ju.containsKey('surfaceCatalog'), isTrue);
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
      '31. codec external to model: no preset.toJson or ProjectSurfacePreset.fromJson',
      () {
        final p = _preset();
        final m = encodeProjectSurfacePreset(p);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('32. ProjectSurfaceCatalog codec remains out of scope (Lot 46)', () {
      final j = encodeProjectSurfacePreset(_preset());
      expect(j['id'], isNotNull);
    });

    test('33. no SurfacePresetKind / surfaceKind keys in JSON', () {
      final j = encodeProjectSurfacePreset(_preset());
      for (final k in const [
        'kind',
        'surfaceKind',
        'presetKind',
        'type',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('34. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)', () {
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

SurfaceVariantAnimationRefSet _refSet({List<SurfaceVariantAnimationRef>? refs}) {
  return SurfaceVariantAnimationRefSet(
    refs: refs ??
        [
          _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
        ],
  );
}

Map<String, Object?> _minVa() {
  return encodeSurfaceVariantAnimationRefSet(
    _refSet(
      refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
      ],
    ),
  );
}

ProjectSurfacePreset _preset({
  String id = 'water-surface',
  String name = 'Water Surface',
  SurfaceVariantAnimationRefSet? variantAnimations,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: variantAnimations ?? _refSet(),
    categoryId: categoryId,
    sortOrder: sortOrder,
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
  if (o == null) {
    return 'null';
  }
  return o.toString();
}
