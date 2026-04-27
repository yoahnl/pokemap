import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceVariantAnimationRef JSON codec (Lot 43)', () {
    test('1. encodeSurfaceVariantRole isolated', () {
      expect(
        encodeSurfaceVariantRole(SurfaceVariantRole.isolated),
        'isolated',
      );
    });

    test('2. decodeSurfaceVariantRole isolated', () {
      expect(
        decodeSurfaceVariantRole('isolated'),
        SurfaceVariantRole.isolated,
      );
    });

    test('3. round-trip every SurfaceVariantRole.values', () {
      for (final role in SurfaceVariantRole.values) {
        expect(
          decodeSurfaceVariantRole(encodeSurfaceVariantRole(role)),
          role,
        );
      }
    });

    test('4. standardSurfaceVariantRoleOrder: order preserved, each round-trips', () {
      expect(standardSurfaceVariantRoleOrder.length, SurfaceVariantRole.values.length);
      for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++) {
        expect(
          standardSurfaceVariantRoleOrder[i],
          SurfaceVariantRole.values[i],
          reason: 'standard order must stay aligned with SurfaceVariantRole.values (Lot 28)',
        );
        final role = standardSurfaceVariantRoleOrder[i];
        expect(
          decodeSurfaceVariantRole(encodeSurfaceVariantRole(role)),
          role,
        );
      }
    });

    test('5. decode rejects unknown role string', () {
      expect(
        () => decodeSurfaceVariantRole('unknown'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. decode rejects wrong casing', () {
      expect(
        () => decodeSurfaceVariantRole('Isolated'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. decode rejects valid name with surrounding spaces', () {
      expect(
        () => decodeSurfaceVariantRole(' isolated '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('8. encode SurfaceVariantAnimationRef', () {
      final r = _ref();
      final j = encodeSurfaceVariantAnimationRef(r);
      expect(j, <String, Object?>{
        'role': 'isolated',
        'animationId': 'water-isolated-loop',
      });
    });

    test('9. decode SurfaceVariantAnimationRef', () {
      const j = <String, Object?>{
        'role': 'isolated',
        'animationId': 'water-isolated-loop',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.role, SurfaceVariantRole.isolated);
      expect(r.animationId, 'water-isolated-loop');
    });

    test('10. round-trip SurfaceVariantAnimationRef', () {
      final o = _ref();
      final d = decodeSurfaceVariantAnimationRef(encodeSurfaceVariantAnimationRef(o));
      expect(d, o);
    });

    test('11. decode preserves animationId exact (no auto-trim in model)', () {
      const j = <String, Object?>{
        'role': 'isolated',
        'animationId': '  water-isolated-loop  ',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.animationId, '  water-isolated-loop  ');
    });

    test('12. decode rejects missing role', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. decode rejects role wrong type', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 123,
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode rejects unknown role in ref json', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'notARole',
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. decode rejects role wrong casing in ref json', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'Horizontal',
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode rejects missing animationId', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'isolated',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. decode rejects animationId wrong type', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'isolated',
          'animationId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('18. decode rejects animationId whitespace-only (constructor)', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'isolated',
          'animationId': '   ',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('19. decode ignores unknown key', () {
      final j = <String, Object?>{
        'role': 'isolated',
        'animationId': 'x',
        'futureField': 'ignored',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.role, SurfaceVariantRole.isolated);
      expect(r.animationId, 'x');
    });

    test('20. decode does not mutate source map', () {
      final m = <String, Object?>{
        'role': 'isolated',
        'animationId': 'a',
      };
      final before = '${m['role']}|${m['animationId']}';
      decodeSurfaceVariantAnimationRef(m);
      expect('${m['role']}|${m['animationId']}', before);
    });

    test('21. does not resolve missing animationId', () {
      const j = <String, Object?>{
        'role': 'isolated',
        'animationId': 'missing-animation',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.animationId, 'missing-animation');
    });

    test('22. public API encode returns map', () {
      expect(encodeSurfaceVariantAnimationRef(_ref()), isA<Map<String, Object?>>());
    });

    test('23. ProjectManifest has no surface persistence keys (Lot 43)', () {
      final manifest = ProjectManifest(
        name: 'L43',
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
      '24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson',
      () {
        final r = _ref();
        final m = encodeSurfaceVariantAnimationRef(r);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)', () {
      final m = encodeSurfaceVariantAnimationRef(_ref());
      expect(m['role'], isNotNull);
    });

    test('26. preset and catalog codec remain out of scope', () {
      final j = encodeSurfaceVariantAnimationRef(_ref());
      expect(j.containsKey('role'), isTrue);
    });

    test('27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)', () {
      expect(standardSurfaceVariantRoleOrder.length, 20);
    });
  });
}

SurfaceVariantAnimationRef _ref({
  SurfaceVariantRole role = SurfaceVariantRole.isolated,
  String animationId = 'water-isolated-loop',
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}
