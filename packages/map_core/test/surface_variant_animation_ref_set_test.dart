import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceVariantAnimationRef _r(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

void main() {
  group('SurfaceVariantAnimationRefSet', () {
    test('minimal set: length, isEmpty, isNotEmpty, first ref', () {
      final ref = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      );
      final set = SurfaceVariantAnimationRefSet(refs: [ref]);
      expect(set.refs.length, 1);
      expect(set.length, 1);
      expect(set.isEmpty, isFalse);
      expect(set.isNotEmpty, isTrue);
      expect(set.refs.first, ref);
    });

    test('rejects empty refs', () {
      expect(
        () => SurfaceVariantAnimationRefSet(refs: []),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate role (different animationId)', () {
      expect(
        () => SurfaceVariantAnimationRefSet(
          refs: [
            _r(SurfaceVariantRole.isolated, 'a'),
            _r(SurfaceVariantRole.isolated, 'b'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('allows same animationId for different roles', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'shared-loop'),
          _r(SurfaceVariantRole.horizontal, 'shared-loop'),
        ],
      );
      expect(set.length, 2);
    });

    test('preserves input order (not sorted by standard order)', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.cross, 'c'),
          _r(SurfaceVariantRole.isolated, 'i'),
          _r(SurfaceVariantRole.horizontal, 'h'),
        ],
      );
      expect(set.refs[0].role, SurfaceVariantRole.cross);
      expect(set.refs[1].role, SurfaceVariantRole.isolated);
      expect(set.refs[2].role, SurfaceVariantRole.horizontal);
    });

    test('exposed refs list is unmodifiable', () {
      final ref = _r(SurfaceVariantRole.isolated, 'a');
      final set = SurfaceVariantAnimationRefSet(refs: [ref]);
      expect(
        () => set.refs.add(ref),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('defensive copy: mutating source list after build does not change set', () {
      final r1 = _r(SurfaceVariantRole.isolated, '1');
      final source = <SurfaceVariantAnimationRef>[r1];
      final set = SurfaceVariantAnimationRefSet(refs: source);
      source.add(_r(SurfaceVariantRole.cross, 'x'));
      expect(set.length, 1);
      expect(set.refs.length, 1);
      expect(set.refs.first, r1);
    });

    test('containsRole: true for present roles', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
          _r(SurfaceVariantRole.cross, 'b'),
        ],
      );
      expect(set.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(set.containsRole(SurfaceVariantRole.cross), isTrue);
    });

    test('containsRole: false when role absent', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
        ],
      );
      expect(set.containsRole(SurfaceVariantRole.cross), isFalse);
    });

    test('refForRole: returns ref when present', () {
      final r = _r(SurfaceVariantRole.teeWest, 'tw');
      final set = SurfaceVariantAnimationRefSet(refs: [r]);
      expect(set.refForRole(SurfaceVariantRole.teeWest), r);
    });

    test('refForRole: null when absent', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.isolated, 'a')],
      );
      expect(set.refForRole(SurfaceVariantRole.cross), isNull);
    });

    test('animationIdForRole: id when present', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.vertical, 'v-fx')],
      );
      expect(set.animationIdForRole(SurfaceVariantRole.vertical), 'v-fx');
    });

    test('animationIdForRole: null when absent', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.isolated, 'a')],
      );
      expect(set.animationIdForRole(SurfaceVariantRole.horizontal), isNull);
    });

    test('coversAllRoles: true for covered subset', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
          _r(SurfaceVariantRole.horizontal, 'b'),
          _r(SurfaceVariantRole.vertical, 'c'),
        ],
      );
      expect(
        set.coversAllRoles([
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.horizontal,
        ]),
        isTrue,
      );
    });

    test('coversAllRoles: false if one role missing', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
          _r(SurfaceVariantRole.horizontal, 'b'),
          _r(SurfaceVariantRole.vertical, 'c'),
        ],
      );
      expect(
        set.coversAllRoles([
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.cross,
        ]),
        isFalse,
      );
    });

    test('coversAllRoles: true for empty iterable (vacuous every)', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.isolated, 'a')],
      );
      expect(set.coversAllRoles([]), isTrue);
    });

    test('can cover all of standardSurfaceVariantRoleOrder in input order', () {
      final list = <SurfaceVariantAnimationRef>[
        for (final role in standardSurfaceVariantRoleOrder)
          _r(role, 'anim-${role.name}'),
      ];
      final set = SurfaceVariantAnimationRefSet(refs: list);
      expect(set.length, standardSurfaceVariantRoleOrder.length);
      for (var i = 0; i < set.refs.length; i++) {
        expect(set.refs[i].role, standardSurfaceVariantRoleOrder[i]);
      }
      expect(set.coversAllRoles(standardSurfaceVariantRoleOrder), isTrue);
    });

    test('value equality: same refs in same order', () {
      final a = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
          _r(SurfaceVariantRole.cross, 'b'),
        ],
      );
      final b = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
          _r(SurfaceVariantRole.cross, 'b'),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: different order => not equal', () {
      final a = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.isolated, 'a'),
          _r(SurfaceVariantRole.cross, 'b'),
        ],
      );
      final b = SurfaceVariantAnimationRefSet(
        refs: [
          _r(SurfaceVariantRole.cross, 'b'),
          _r(SurfaceVariantRole.isolated, 'a'),
        ],
      );
      expect(a, isNot(b));
    });

    test('value equality: same role different animationId', () {
      final a = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.isolated, 'a')],
      );
      final b = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.isolated, 'b')],
      );
      expect(a, isNot(b));
    });

    test('export: type via map_core', () {
      final set = SurfaceVariantAnimationRefSet(
        refs: [_r(SurfaceVariantRole.isolated, 'x')],
      );
      expect(set, isA<SurfaceVariantAnimationRefSet>());
    });

    test('set is only a collection of refs (no ProjectSurfacePreset)', () {
      final r1 = _r(SurfaceVariantRole.innerCornerNE, 'n');
      final r2 = _r(SurfaceVariantRole.teeSouth, 's');
      final set = SurfaceVariantAnimationRefSet(refs: [r1, r2]);
      expect(set.refs, [r1, r2]);
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L30',
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
