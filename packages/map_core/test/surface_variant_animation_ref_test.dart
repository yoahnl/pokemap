import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAnimationTimeline _minimalTimeline() {
  return SurfaceAnimationTimeline(
    frames: [
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 1,
      ),
    ],
  );
}

void main() {
  group('SurfaceVariantAnimationRef', () {
    test('minimal ref holds role and animationId', () {
      final ref = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      );
      expect(ref.role, SurfaceVariantRole.isolated);
      expect(ref.animationId, 'water-isolated-loop');
    });

    test('accepts several distinct roles (sample)', () {
      final roles = <SurfaceVariantRole>[
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
        SurfaceVariantRole.vertical,
        SurfaceVariantRole.cornerNE,
        SurfaceVariantRole.innerCornerSW,
        SurfaceVariantRole.teeSouth,
        SurfaceVariantRole.cross,
      ];
      for (var i = 0; i < roles.length; i++) {
        final r = roles[i];
        final ref = SurfaceVariantAnimationRef(
          role: r,
          animationId: 'a$i',
        );
        expect(ref.role, r);
      }
    });

    test('stores animationId exactly without auto-trim', () {
      const raw = '  water-loop  ';
      final ref = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: raw,
      );
      expect(ref.animationId, raw);
    });

    test('rejects empty animationId: empty string', () {
      expect(
        () => SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty animationId: whitespace only', () {
      expect(
        () => SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('value equality: same values => equal and same hash', () {
      final a = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.teeWest,
        animationId: 'x',
      );
      final b = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.teeWest,
        animationId: 'x',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: different role', () {
      const id = 'same';
      final a = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: id,
      );
      final b = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: id,
      );
      expect(a, isNot(b));
    });

    test('value equality: different animationId', () {
      final a = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'a',
      );
      final b = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'b',
      );
      expect(a, isNot(b));
    });

    test('export: type visible through map_core', () {
      final ref = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'a',
      );
      expect(ref, isA<SurfaceVariantAnimationRef>());
    });

    test('coexists with ProjectSurfaceAnimation: id string only, no resolution', () {
      final animation = ProjectSurfaceAnimation(
        id: 'water-loop',
        name: 'Water',
        timeline: _minimalTimeline(),
      );
      final ref = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: animation.id,
      );
      expect(ref.animationId, animation.id);
    });

    test('one ref per role in standardSurfaceVariantRoleOrder (length + order)', () {
      final refs = <SurfaceVariantAnimationRef>[
        for (final role in standardSurfaceVariantRoleOrder)
          SurfaceVariantAnimationRef(
            role: role,
            animationId: 'anim-${role.name}',
          ),
      ];
      expect(refs.length, standardSurfaceVariantRoleOrder.length);
      for (var i = 0; i < refs.length; i++) {
        expect(refs[i].role, standardSurfaceVariantRoleOrder[i]);
        expect(refs[i].animationId, 'anim-${refs[i].role.name}');
      }
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L29',
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
