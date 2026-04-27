import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

SurfaceVariantAnimationRefSet _refSet(List<SurfaceVariantAnimationRef> refs) {
  return SurfaceVariantAnimationRefSet(refs: refs);
}

ProjectSurfacePreset _preset({
  String id = 'p1',
  String name = 'N',
  required SurfaceVariantAnimationRefSet variantAnimations,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: variantAnimations,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

SurfaceAnimationTimeline _singleTileTimeline() {
  return SurfaceAnimationTimeline(
    frames: [
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-1',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      ),
    ],
  );
}

void main() {
  group('ProjectSurfacePreset', () {
    test('1. minimal preset: fields and variantCount', () {
      final refs = SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'water-isolated-loop',
          ),
        ],
      );
      final preset = ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: refs,
      );
      expect(preset.id, 'water-surface');
      expect(preset.name, 'Water Surface');
      expect(preset.variantAnimations, refs);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.variantCount, 1);
    });

    test('2. preserves exact same variantAnimations instance', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = _preset(variantAnimations: refs);
      expect(identical(preset.variantAnimations, refs), isTrue);
    });

    test('3. preserves categoryId and sortOrder', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = _preset(
        variantAnimations: refs,
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(preset.categoryId, 'animated-surfaces');
      expect(preset.sortOrder, 42);
    });

    test('4. stores id and name exactly without auto-trim', () {
      const id = '  water-surface  ';
      const name = '  Water Surface  ';
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = ProjectSurfacePreset(
        id: id,
        name: name,
        variantAnimations: refs,
      );
      expect(preset.id, id);
      expect(preset.name, name);
    });

    test('5. rejects empty id: empty and whitespace', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      expect(
        () => ProjectSurfacePreset(
          id: '',
          name: 'N',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectSurfacePreset(
          id: '   ',
          name: 'N',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. rejects empty name: empty and whitespace', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      expect(
        () => ProjectSurfacePreset(
          id: 'i',
          name: '',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectSurfacePreset(
          id: 'i',
          name: '   ',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. does not over-validate categoryId: empty and whitespace allowed', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        variantAnimations: refs,
        categoryId: '',
      );
      final b = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.cross, 'x')]),
        categoryId: '   ',
      );
      expect(a.categoryId, '');
      expect(b.categoryId, '   ');
    });

    test('8. allows negative sortOrder', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = _preset(
        variantAnimations: refs,
        sortOrder: -10,
      );
      expect(preset.sortOrder, -10);
    });

    test('9. delegating containsRole', () {
      final set = _refSet([
        _ref(SurfaceVariantRole.isolated, 'a'),
        _ref(SurfaceVariantRole.horizontal, 'b'),
      ]);
      final preset = _preset(variantAnimations: set);
      expect(preset.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(preset.containsRole(SurfaceVariantRole.horizontal), isTrue);
      expect(preset.containsRole(SurfaceVariantRole.cross), isFalse);
    });

    test('10. delegating refForRole: present and absent', () {
      final r = _ref(SurfaceVariantRole.isolated, 'loop');
      final set = _refSet([r]);
      final preset = _preset(variantAnimations: set);
      expect(preset.refForRole(SurfaceVariantRole.isolated), r);
      expect(preset.refForRole(SurfaceVariantRole.cross), isNull);
    });

    test('11. delegating animationIdForRole: present and absent', () {
      final set = _refSet([_ref(SurfaceVariantRole.vertical, 'v-id')]);
      final preset = _preset(variantAnimations: set);
      expect(
        preset.animationIdForRole(SurfaceVariantRole.vertical),
        'v-id',
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        isNull,
      );
    });

    test('12. delegating coversAllRoles', () {
      final set = _refSet([
        _ref(SurfaceVariantRole.isolated, 'a'),
        _ref(SurfaceVariantRole.horizontal, 'b'),
        _ref(SurfaceVariantRole.vertical, 'c'),
      ]);
      final preset = _preset(variantAnimations: set);
      expect(
        preset.coversAllRoles(
          [SurfaceVariantRole.isolated, SurfaceVariantRole.horizontal],
        ),
        isTrue,
      );
      expect(
        preset.coversAllRoles(
          [SurfaceVariantRole.isolated, SurfaceVariantRole.cross],
        ),
        isFalse,
      );
      expect(preset.coversAllRoles([]), isTrue);
    });

    test('13. can cover exactly standardSurfaceVariantRoleOrder', () {
      final refs = [
        for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++)
          _ref(
            standardSurfaceVariantRoleOrder[i],
            'anim-$i',
          ),
      ];
      final set = _refSet(refs);
      final preset = _preset(
        id: 'full',
        name: 'Full',
        variantAnimations: set,
      );
      expect(
        preset.variantCount,
        standardSurfaceVariantRoleOrder.length,
      );
      expect(
        preset.coversAllRoles(standardSurfaceVariantRoleOrder),
        isTrue,
      );
    });

    test('14. value equality: identical presets are equal and same hashCode', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        id: 'i',
        name: 'N',
        variantAnimations: s,
        categoryId: 'cat',
        sortOrder: 1,
      );
      final b = _preset(
        id: 'i',
        name: 'N',
        variantAnimations: s,
        categoryId: 'cat',
        sortOrder: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('15. value equality: different id', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(id: 'a1', name: 'N', variantAnimations: s);
      final b = _preset(id: 'a2', name: 'N', variantAnimations: s);
      expect(a, isNot(equals(b)));
    });

    test('16. value equality: different name', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(name: 'A', variantAnimations: s);
      final b = _preset(name: 'B', variantAnimations: s);
      expect(a, isNot(equals(b)));
    });

    test('17. value equality: different variantAnimations', () {
      final base = _refSet([_ref(SurfaceVariantRole.isolated, 'same')]);
      // Different animationId
      final a = _preset(variantAnimations: base);
      final b1 = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'other')]),
      );
      expect(a, isNot(equals(b1)));
      // Different order (RefSet is order-sensitive)
      final c = _refSet([
        _ref(SurfaceVariantRole.cross, 'x'),
        _ref(SurfaceVariantRole.isolated, 'i'),
      ]);
      final d = _refSet([
        _ref(SurfaceVariantRole.isolated, 'i'),
        _ref(SurfaceVariantRole.cross, 'x'),
      ]);
      expect(c, isNot(equals(d)));
      final pC = _preset(id: 'p', name: 'n', variantAnimations: c);
      final pD = _preset(id: 'p', name: 'n', variantAnimations: d);
      expect(pC, isNot(equals(pD)));
      // Different role
      final e = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.cross, 'x')]),
      );
      final f = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.teeWest, 'x')]),
      );
      expect(e, isNot(equals(f)));
    });

    test('18. value equality: different categoryId', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        variantAnimations: s,
        categoryId: 'c1',
      );
      final b = _preset(
        variantAnimations: s,
        categoryId: 'c2',
      );
      expect(a, isNot(equals(b)));
    });

    test('19. value equality: different sortOrder', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        variantAnimations: s,
        sortOrder: 0,
      );
      final b = _preset(
        variantAnimations: s,
        sortOrder: 1,
      );
      expect(a, isNot(equals(b)));
    });

    test('20. public export: ProjectSurfacePreset via map_core', () {
      final preset = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'a')]),
      );
      expect(preset, isA<ProjectSurfacePreset>());
    });

    test(
        '21. V0 visual-only: preset has no kind / surfaceKind / behavior field',
        () {
      final preset = _preset(
        id: 'vis',
        name: 'Visual',
        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'a')]),
      );
      expect(preset.id, 'vis');
    });

    test('22. coexists with ProjectSurfaceAnimation without resolution', () {
      final animation = ProjectSurfaceAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        timeline: _singleTileTimeline(),
      );
      final r = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: animation.id,
      );
      final set = SurfaceVariantAnimationRefSet(refs: [r]);
      final preset = ProjectSurfacePreset(
        id: 'p',
        name: 'P',
        variantAnimations: set,
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.cross),
        animation.id,
      );
    });

    test('23. ProjectManifest still has no Surface persistence keys (Lot 21–31)', () {
      final manifest = ProjectManifest(
        name: 'L31 smoke',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),);
      final map = manifest.toJson();
      const forbidden = <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ];
      for (final key in forbidden) {
        expect(map.containsKey(key), isFalse, reason: 'unexpected key: $key');
      }
    });
  });
}
