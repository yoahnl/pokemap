import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAnimationTimeline _oneFrameTimeline() {
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

String _waterNamePattern(SurfaceVariantRole role) => 'water-${role.name}';

void main() {
  group('createStandardProjectSurfacePreset', () {
    test('1. full preset with default standard order', () {
      final first = standardSurfaceVariantRoleOrder.first;
      final last = standardSurfaceVariantRoleOrder.last;
      final preset = createStandardProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        animationIdForRole: _waterNamePattern,
      );
      expect(preset.id, 'water-surface');
      expect(preset.name, 'Water Surface');
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.variantCount, standardSurfaceVariantRoleOrder.length);
      expect(preset.coversAllRoles(standardSurfaceVariantRoleOrder), isTrue);
      expect(preset.variantAnimations.refs.first.role, first);
      expect(preset.variantAnimations.refs.last.role, last);
      expect(
        _waterNamePattern(first),
        'water-${first.name}',
      );
      expect(
        preset.refForRole(first)!.animationId,
        'water-${first.name}',
      );
    });

    test('2. ref roles list matches standardSurfaceVariantRoleOrder', () {
      final preset = createStandardProjectSurfacePreset(
        id: 'w',
        name: 'W',
        animationIdForRole: _waterNamePattern,
      );
      expect(
        preset.variantAnimations.refs.map((r) => r.role).toList(),
        standardSurfaceVariantRoleOrder,
      );
    });

    test('3. animationIds follow strategy for sample roles', () {
      void check(SurfaceVariantRole role) {
        final p = createStandardProjectSurfacePreset(
          id: 'x',
          name: 'X',
          animationIdForRole: _waterNamePattern,
          roles: [role],
        );
        expect(
          p.animationIdForRole(role),
          'water-${role.name}',
        );
      }

      check(SurfaceVariantRole.isolated);
      check(SurfaceVariantRole.horizontal);
      check(SurfaceVariantRole.cross);
    });

    test('4. preserves categoryId and sortOrder', () {
      final preset = createStandardProjectSurfacePreset(
        id: 'a',
        name: 'A',
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.isolated],
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(preset.categoryId, 'animated-surfaces');
      expect(preset.sortOrder, 42);
    });

    test('5. id and name stored exactly without auto-trim', () {
      const id = '  water-surface  ';
      const name = '  Water Surface  ';
      final preset = createStandardProjectSurfacePreset(
        id: id,
        name: name,
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.isolated],
      );
      expect(preset.id, id);
      expect(preset.name, name);
    });

    test('6. does not over-validate categoryId: empty and whitespace', () {
      final a = createStandardProjectSurfacePreset(
        id: 'a',
        name: 'A',
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.isolated],
        categoryId: '',
      );
      final b = createStandardProjectSurfacePreset(
        id: 'b',
        name: 'B',
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.cross],
        categoryId: '   ',
      );
      expect(a.categoryId, '');
      expect(b.categoryId, '   ');
    });

    test('7. allows negative sortOrder', () {
      final preset = createStandardProjectSurfacePreset(
        id: 'a',
        name: 'A',
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.isolated],
        sortOrder: -10,
      );
      expect(preset.sortOrder, -10);
    });

    test('8. custom subset of roles: count, order, ids', () {
      const roles = [
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
        SurfaceVariantRole.cross,
      ];
      final preset = createStandardProjectSurfacePreset(
        id: 'sub',
        name: 'Sub',
        animationIdForRole: _waterNamePattern,
        roles: roles,
      );
      expect(preset.variantCount, 3);
      expect(
        preset.variantAnimations.refs.map((e) => e.role).toList(),
        roles,
      );
      for (final r in roles) {
        expect(
          preset.animationIdForRole(r),
          'water-${r.name}',
        );
      }
    });

    test('9. preserves non-standard custom order', () {
      const roles = [
        SurfaceVariantRole.cross,
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
      ];
      final preset = createStandardProjectSurfacePreset(
        id: 'o',
        name: 'O',
        animationIdForRole: (role) => 'x-${role.name}',
        roles: roles,
      );
      expect(
        preset.variantAnimations.refs.map((e) => e.role).toList(),
        roles,
      );
    });

    test('10. animationIdForRole called once per role in order', () {
      const roles = [
        SurfaceVariantRole.endNorth,
        SurfaceVariantRole.teeWest,
        SurfaceVariantRole.isolated,
      ];
      final calls = <SurfaceVariantRole>[];
      createStandardProjectSurfacePreset(
        id: 'c',
        name: 'C',
        animationIdForRole: (role) {
          calls.add(role);
          return 'id-${role.name}';
        },
        roles: roles,
      );
      expect(calls, roles);
    });

    test('11. same animationId string for different roles is allowed', () {
      const roles = [
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
        SurfaceVariantRole.vertical,
      ];
      final preset = createStandardProjectSurfacePreset(
        id: 's',
        name: 'S',
        animationIdForRole: (_) => 'shared-loop',
        roles: roles,
      );
      for (final r in roles) {
        expect(preset.animationIdForRole(r), 'shared-loop');
      }
    });

    test('12. delegates rejection of empty id', () {
      void expectIdFail(String id) {
        expect(
          () => createStandardProjectSurfacePreset(
            id: id,
            name: 'N',
            animationIdForRole: _waterNamePattern,
            roles: [SurfaceVariantRole.isolated],
          ),
          throwsA(isA<ValidationException>()),
        );
      }

      expectIdFail('');
      expectIdFail('   ');
    });

    test('13. delegates rejection of empty name', () {
      void expectNameFail(String name) {
        expect(
          () => createStandardProjectSurfacePreset(
            id: 'i',
            name: name,
            animationIdForRole: _waterNamePattern,
            roles: [SurfaceVariantRole.isolated],
          ),
          throwsA(isA<ValidationException>()),
        );
      }

      expectNameFail('');
      expectNameFail('   ');
    });

    test('14. delegates rejection of empty roles', () {
      expect(
        () => createStandardProjectSurfacePreset(
          id: 'a',
          name: 'A',
          animationIdForRole: _waterNamePattern,
          roles: [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. delegates rejection of duplicate roles', () {
      expect(
        () => createStandardProjectSurfacePreset(
          id: 'a',
          name: 'A',
          animationIdForRole: _waterNamePattern,
          roles: [
            SurfaceVariantRole.isolated,
            SurfaceVariantRole.isolated,
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. delegates rejection of empty animationId from callback', () {
      for (final bad in ['', '   ']) {
        expect(
          () => createStandardProjectSurfacePreset(
            id: 'a',
            name: 'A',
            animationIdForRole: (_) => bad,
            roles: [SurfaceVariantRole.isolated],
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('17. does not resolve animationId to ProjectSurfaceAnimation (string only)', () {
      final animation = ProjectSurfaceAnimation(
        id: 'water-cross-loop',
        name: 'Water cross',
        timeline: _oneFrameTimeline(),
      );
      final preset = createStandardProjectSurfacePreset(
        id: 'p',
        name: 'P',
        animationIdForRole: (role) {
          if (role == SurfaceVariantRole.cross) {
            return animation.id;
          }
          return 'other';
        },
        roles: [SurfaceVariantRole.cross],
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.cross),
        animation.id,
      );
    });

    test('18. generated preset: delegation methods work', () {
      final preset = createStandardProjectSurfacePreset(
        id: 'd',
        name: 'D',
        animationIdForRole: (r) => 'a-${r.name}',
        roles: [
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.cross,
        ],
      );
      expect(preset.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(preset.containsRole(SurfaceVariantRole.teeWest), isFalse);
      expect(
        preset.refForRole(SurfaceVariantRole.isolated)!.animationId,
        'a-isolated',
      );
      expect(
        preset.coversAllRoles(
          [SurfaceVariantRole.isolated, SurfaceVariantRole.cross],
        ),
        isTrue,
      );
    });

    test('19. public export: createStandardProjectSurfacePreset via map_core', () {
      final preset = createStandardProjectSurfacePreset(
        id: 'e',
        name: 'E',
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.isolated],
      );
      expect(preset, isA<ProjectSurfacePreset>());
    });

    test('20. ProjectManifest toJson has no top-level surface* keys (Lot 32)', () {
      final manifest = ProjectManifest(
        name: 'L32',
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
      expect(map.containsKey('surfaceCatalog'), isTrue);
      const forbidden = <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ];
      for (final k in forbidden) {
        expect(map.containsKey(k), isFalse, reason: 'forbidden: $k');
      }
    });

    test(
        '21. V0: builder stays visual; preset has no kind / surfaceKind',
        () {
      final p = createStandardProjectSurfacePreset(
        id: 'k',
        name: 'K',
        animationIdForRole: _waterNamePattern,
        roles: [SurfaceVariantRole.isolated],
      );
      expect(p.id, 'k');
    });

    test('22. standard order has 20 roles; default preset matches that count', () {
      expect(standardSurfaceVariantRoleOrder.length, 20);
      final p = createStandardProjectSurfacePreset(
        id: 'a',
        name: 'A',
        animationIdForRole: _waterNamePattern,
      );
      expect(p.variantCount, 20);
      expect(p.variantCount, standardSurfaceVariantRoleOrder.length);
    });
  });
}
