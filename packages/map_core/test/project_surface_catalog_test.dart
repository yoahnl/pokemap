import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(String id) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'name-$id',
    tilesetId: 'ts',
    geometry: _geometry(),
  );
}

SurfaceAnimationTimeline _timeline() {
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

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'anim-$id',
    timeline: _timeline(),
  );
}

SurfaceVariantAnimationRefSet _variantSet() {
  return SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'anim-1',
      ),
    ],
  );
}

ProjectSurfacePreset _preset(String id) {
  return ProjectSurfacePreset(
    id: id,
    name: 'preset-$id',
    variantAnimations: _variantSet(),
  );
}

void main() {
  group('ProjectSurfaceCatalog (Lot 33)', () {
    test('1. empty catalog: counts, isEmpty, unmodifiable empty lists', () {
      final catalog = ProjectSurfaceCatalog();
      expect(catalog.atlasCount, 0);
      expect(catalog.animationCount, 0);
      expect(catalog.presetCount, 0);
      expect(catalog.isEmpty, isTrue);
      expect(catalog.isNotEmpty, isFalse);
      expect(catalog.atlases, isEmpty);
      expect(catalog.animations, isEmpty);
      expect(catalog.presets, isEmpty);
    });

    test('2. catalog with 2 of each kind: counts, isNotEmpty', () {
      final catalog = ProjectSurfaceCatalog(
        atlases: [_atlas('a1'), _atlas('a2')],
        animations: [_animation('m1'), _animation('m2')],
        presets: [_preset('p1'), _preset('p2')],
      );
      expect(catalog.atlasCount, 2);
      expect(catalog.animationCount, 2);
      expect(catalog.presetCount, 2);
      expect(catalog.isEmpty, isFalse);
      expect(catalog.isNotEmpty, isTrue);
    });

    test('3. order of atlases preserved', () {
      final catalog = ProjectSurfaceCatalog(
        atlases: [
          _atlas('o1'),
          _atlas('o2'),
          _atlas('o3'),
        ],
      );
      expect(
        catalog.atlases.map((e) => e.id).toList(),
        ['o1', 'o2', 'o3'],
      );
    });

    test('4. order of animations preserved', () {
      final catalog = ProjectSurfaceCatalog(
        animations: [
          _animation('o1'),
          _animation('o2'),
          _animation('o3'),
        ],
      );
      expect(
        catalog.animations.map((e) => e.id).toList(),
        ['o1', 'o2', 'o3'],
      );
    });

    test('5. order of presets preserved', () {
      final catalog = ProjectSurfaceCatalog(
        presets: [
          _preset('o1'),
          _preset('o2'),
          _preset('o3'),
        ],
      );
      expect(
        catalog.presets.map((e) => e.id).toList(),
        ['o1', 'o2', 'o3'],
      );
    });

    test('6. exposed lists are unmodifiable: add throws', () {
      final catalog = ProjectSurfaceCatalog();
      expect(
        () => catalog.atlases.add(_atlas('x')),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => catalog.animations.add(_animation('x')),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => catalog.presets.add(_preset('x')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('7. defensive copy: atlases source mutated after build', () {
      final source = <ProjectSurfaceAtlas>[_atlas('only')];
      final catalog = ProjectSurfaceCatalog(atlases: source);
      source.add(_atlas('extra'));
      expect(catalog.atlasCount, 1);
      expect(catalog.atlases.map((e) => e.id), ['only']);
    });

    test('8. defensive copy: animations source mutated after build', () {
      final source = <ProjectSurfaceAnimation>[_animation('only')];
      final catalog = ProjectSurfaceCatalog(animations: source);
      source.add(_animation('extra'));
      expect(catalog.animationCount, 1);
      expect(catalog.animations.map((e) => e.id), ['only']);
    });

    test('9. defensive copy: presets source mutated after build', () {
      final source = <ProjectSurfacePreset>[_preset('only')];
      final catalog = ProjectSurfaceCatalog(presets: source);
      source.add(_preset('extra'));
      expect(catalog.presetCount, 1);
      expect(catalog.presets.map((e) => e.id), ['only']);
    });

    test('10. duplicate atlas id throws ValidationException', () {
      expect(
        () => ProjectSurfaceCatalog(
          atlases: [
            _atlas('dup'),
            _atlas('dup'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. duplicate animation id throws ValidationException', () {
      expect(
        () => ProjectSurfaceCatalog(
          animations: [
            _animation('dup'),
            _animation('dup'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. duplicate preset id throws ValidationException', () {
      expect(
        () => ProjectSurfaceCatalog(
          presets: [
            _preset('dup'),
            _preset('dup'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. same id string across collections is allowed; lookups', () {
      const shared = 'water';
      final a = _atlas(shared);
      final m = _animation(shared);
      final p = _preset(shared);
      final catalog = ProjectSurfaceCatalog(
        atlases: [a],
        animations: [m],
        presets: [p],
      );
      expect(catalog.atlasById(shared), same(a));
      expect(catalog.animationById(shared), same(m));
      expect(catalog.presetById(shared), same(p));
    });

    test('14. atlasById returns instance when present', () {
      final a = _atlas('known');
      final c = ProjectSurfaceCatalog(atlases: [a]);
      expect(c.atlasById('known'), same(a));
    });

    test('15. atlasById null when absent', () {
      final c = ProjectSurfaceCatalog(atlases: [_atlas('a')]);
      expect(c.atlasById('missing'), isNull);
    });

    test('16. animationById returns instance when present', () {
      final m = _animation('known');
      final c = ProjectSurfaceCatalog(animations: [m]);
      expect(c.animationById('known'), same(m));
    });

    test('17. animationById null when absent', () {
      final c = ProjectSurfaceCatalog(animations: [_animation('a')]);
      expect(c.animationById('missing'), isNull);
    });

    test('18. presetById returns instance when present', () {
      final p = _preset('known');
      final c = ProjectSurfaceCatalog(presets: [p]);
      expect(c.presetById('known'), same(p));
    });

    test('19. presetById null when absent', () {
      final c = ProjectSurfaceCatalog(presets: [_preset('a')]);
      expect(c.presetById('missing'), isNull);
    });

    test('20. containsAtlas delegates to lookup', () {
      final c = ProjectSurfaceCatalog(atlases: [_atlas('x')]);
      expect(c.containsAtlas('x'), isTrue);
      expect(c.containsAtlas('y'), isFalse);
    });

    test('21. containsAnimation delegates to lookup', () {
      final c = ProjectSurfaceCatalog(animations: [_animation('x')]);
      expect(c.containsAnimation('x'), isTrue);
      expect(c.containsAnimation('y'), isFalse);
    });

    test('22. containsPreset delegates to lookup', () {
      final c = ProjectSurfaceCatalog(presets: [_preset('x')]);
      expect(c.containsPreset('x'), isTrue);
      expect(c.containsPreset('y'), isFalse);
    });

    test('23. lookups use exact id string (no trim) — atlas', () {
      const spaced = '  water  ';
      final atlas = ProjectSurfaceAtlas(
        id: spaced,
        name: 'N',
        tilesetId: 't',
        geometry: _geometry(),
      );
      final c = ProjectSurfaceCatalog(atlases: [atlas]);
      expect(c.atlasById(spaced), same(atlas));
      expect(c.atlasById('water'), isNull);
    });

    test('24. does not resolve missing animationId on preset; no error', () {
      final preset = ProjectSurfacePreset(
        id: 'orphan-preset',
        name: 'O',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'missing-animation',
            ),
          ],
        ),
      );
      final catalog = ProjectSurfaceCatalog(presets: [preset]);
      expect(
        () => catalog.presetById('orphan-preset'),
        returnsNormally,
      );
      expect(catalog.presetById('orphan-preset'), same(preset));
      expect(
        catalog.animationById('missing-animation'),
        isNull,
      );
    });

    test('25. value equality: same content same order: == and hashCode', () {
      final a1 = _atlas('a1');
      final a2 = _atlas('a2');
      final m1 = _animation('m1');
      final p1 = _preset('p1');
      final c1 = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [m1],
        presets: [p1],
      );
      final c2 = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [m1],
        presets: [p1],
      );
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
    });

    test('26. value inequality: different atlas order', () {
      final x = _atlas('x');
      final y = _atlas('y');
      final c1 = ProjectSurfaceCatalog(atlases: [x, y]);
      final c2 = ProjectSurfaceCatalog(atlases: [y, x]);
      expect(c1, isNot(c2));
    });

    test('27. value inequality: different animation order', () {
      final x = _animation('x');
      final y = _animation('y');
      final c1 = ProjectSurfaceCatalog(animations: [x, y]);
      final c2 = ProjectSurfaceCatalog(animations: [y, x]);
      expect(c1, isNot(c2));
    });

    test('28. value inequality: different preset order', () {
      final x = _preset('x');
      final y = _preset('y');
      final c1 = ProjectSurfaceCatalog(presets: [x, y]);
      final c2 = ProjectSurfaceCatalog(presets: [y, x]);
      expect(c1, isNot(c2));
    });

    test('29. value inequality: different content', () {
      final c1 = ProjectSurfaceCatalog(atlases: [_atlas('a')]);
      final c2 = ProjectSurfaceCatalog(atlases: [_atlas('b')]);
      expect(c1, isNot(c2));
    });

    test('30. public surface export: ProjectSurfaceCatalog from map_core', () {
      final catalog = ProjectSurfaceCatalog();
      expect(catalog, isA<ProjectSurfaceCatalog>());
    });

    test('31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)', () {
      final manifest = ProjectManifest(
        name: 'L33',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
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
  });
}
