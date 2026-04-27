import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface Studio read model (Lot 51)', () {
    test('1. empty catalog: summary, lists, clean diagnostics', () {
      final c = _emptyCatalog();
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(identical(m.catalog, c), isTrue);
      expect(m.summary.atlasCount, 0);
      expect(m.summary.animationCount, 0);
      expect(m.summary.presetCount, 0);
      expect(m.summary.isEmpty, isTrue);
      expect(m.isEmpty, isTrue);
      expect(m.atlases, isEmpty);
      expect(m.animations, isEmpty);
      expect(m.presets, isEmpty);
      expect(m.diagnostics.isClean, isTrue);
    });

    test('2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation',
        () {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(surfaceCatalog: cat);
      final before = manifest.surfaceCatalog;
      final model = buildSurfaceStudioReadModel(manifest);
      expect(identical(model.catalog, before), isTrue);
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    test('3. minimal water — summary counts and non-empty', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      expect(m.summary.atlasCount, 1);
      expect(m.summary.animationCount, 1);
      expect(m.summary.presetCount, 1);
      expect(m.summary.isEmpty, isFalse);
      expect(m.summary.isNotEmpty, isTrue);
    });

    test('4. minimal water — atlas row main fields', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      final row = m.atlases.single;
      expect(row.id, 'water-atlas');
      expect(row.name, 'Water Atlas');
      expect(row.tilesetId, 'nature-tileset');
      expect(row.tileWidth, 32);
      expect(row.tileHeight, 32);
      expect(row.columns, 23);
      expect(row.rows, 32);
      expect(row.tileCount, 23 * 32);
      expect(row.layout, SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames);
    });

    test('5. atlas rows preserve catalog order', () {
      final g = _geom();
      final c = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'water-atlas',
            name: 'W',
            tilesetId: 't',
            geometry: g,
          ),
          ProjectSurfaceAtlas(
            id: 'lava-atlas',
            name: 'L',
            tilesetId: 't',
            geometry: g,
          ),
          ProjectSurfaceAtlas(
            id: 'grass-atlas',
            name: 'G',
            tilesetId: 't',
            geometry: g,
          ),
        ],
        animations: const [],
        presets: const [],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.atlases.map((e) => e.id).toList(), [
        'water-atlas',
        'lava-atlas',
        'grass-atlas',
      ]);
    });

    test('6. atlas usedByAnimationIds — two animations, one atlas', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'W',
        tilesetId: 't',
        geometry: g,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      );
      final tl = SurfaceAnimationTimeline(frames: [frame]);
      final waterA = ProjectSurfaceAnimation(
        id: 'water-a',
        name: 'A',
        timeline: tl,
      );
      final waterB = ProjectSurfaceAnimation(
        id: 'water-b',
        name: 'B',
        timeline: tl,
      );
      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [waterA, waterB],
        presets: const [],
      );
      final row = buildSurfaceStudioReadModelFromCatalog(c).atlases.single;
      expect(row.usedByAnimationIds, ['water-a', 'water-b']);
      expect(row.isUsedByAnimation, isTrue);
    });

    test('7. atlas usedByAnimationIds — one animation twice same atlas', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'W',
        tilesetId: 't',
        geometry: g,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      );
      final tl = SurfaceAnimationTimeline(frames: [frame, frame]);
      final anim = ProjectSurfaceAnimation(
        id: 'water-isolated',
        name: 'One',
        timeline: tl,
      );
      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [anim],
        presets: const [],
      );
      final row = buildSurfaceStudioReadModelFromCatalog(c).atlases.single;
      expect(row.usedByAnimationIds, ['water-isolated']);
    });

    test('8. minimal water — animation row main fields', () {
      final row = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog())
          .animations
          .single;
      expect(row.id, 'water-isolated-loop');
      expect(row.name, 'Water Isolated Loop');
      expect(row.frameCount, 1);
      expect(row.totalDurationMs, 120);
      expect(row.hasFrames, isTrue);
      expect(row.categoryId, isNull);
      expect(row.syncGroupId, isNull);
      expect(row.sortOrder, 0);
    });

    test('9. animation rows preserve catalog order', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'a',
        name: 'a',
        tilesetId: 't',
        geometry: g,
      );
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
        durationMs: 10,
      );
      final t = SurfaceAnimationTimeline(frames: [f]);
      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [
          ProjectSurfaceAnimation(id: 'z', name: 'z', timeline: t),
          ProjectSurfaceAnimation(id: 'y', name: 'y', timeline: t),
          ProjectSurfaceAnimation(id: 'x', name: 'x', timeline: t),
        ],
        presets: const [],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.animations.map((e) => e.id).toList(), ['z', 'y', 'x']);
    });

    test('10. animation referencedAtlasIds — first appearance order', () {
      final f1 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-b',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final f2 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-a',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final f3 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-b',
          column: 0,
          row: 1,
        ),
        durationMs: 10,
      );
      final f4 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-c',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final anim = ProjectSurfaceAnimation(
        id: 'multi',
        name: 'm',
        timeline: SurfaceAnimationTimeline(
          frames: [f1, f2, f3, f4],
        ),
      );
      final m = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: [anim],
          presets: const [],
        ),
      );
      expect(m.animations.single.referencedAtlasIds, [
        'atlas-b',
        'atlas-a',
        'atlas-c',
      ]);
    });

    test('11. animation read model does not validate atlas existence', () {
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'missing-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final anim = ProjectSurfaceAnimation(
        id: 'bad',
        name: 'b',
        timeline: SurfaceAnimationTimeline(frames: [f]),
      );
      final m = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: [anim],
          presets: const [],
        ),
      );
      expect(m.animations.single.referencedAtlasIds, contains('missing-atlas'));
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        ),
        isTrue,
      );
    });

    test('12. minimal water — preset row main fields', () {
      final row = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog())
          .presets
          .single;
      expect(row.id, 'water-surface');
      expect(row.name, 'Water Surface');
      expect(row.variantCount, 1);
      expect(row.roles, [SurfaceVariantRole.isolated]);
      expect(row.referencedAnimationIds, ['water-isolated-loop']);
      expect(row.coversStandardRoles, isFalse);
      expect(row.categoryId, isNull);
      expect(row.sortOrder, 0);
    });

    test('13. preset rows preserve catalog order', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'a',
        name: 'a',
        tilesetId: 't',
        geometry: g,
      );
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
        durationMs: 10,
      );
      final t = SurfaceAnimationTimeline(frames: [f]);
      final anim = ProjectSurfaceAnimation(
        id: 'anim',
        name: 'anim',
        timeline: t,
      );
      SurfaceVariantAnimationRefSet presetRefs(String id) {
        return SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: id,
            ),
          ],
        );
      }

      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [anim],
        presets: [
          ProjectSurfacePreset(
            id: 'p-c',
            name: 'c',
            variantAnimations: presetRefs('anim'),
          ),
          ProjectSurfacePreset(
            id: 'p-b',
            name: 'b',
            variantAnimations: presetRefs('anim'),
          ),
          ProjectSurfacePreset(
            id: 'p-a',
            name: 'a',
            variantAnimations: presetRefs('anim'),
          ),
        ],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.presets.map((e) => e.id).toList(), ['p-c', 'p-b', 'p-a']);
    });

    test('14. preset referencedAnimationIds — dedupe keeps order', () {
      final refs = SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'anim-b',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endNorth,
            animationId: 'anim-a',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endEast,
            animationId: 'anim-b',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endSouth,
            animationId: 'anim-c',
          ),
        ],
      );
      final p = ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      );
      final row = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: const [],
          presets: [p],
        ),
      ).presets.single;
      expect(row.referencedAnimationIds, ['anim-b', 'anim-a', 'anim-c']);
    });

    test('15. preset read model does not validate animation existence', () {
      final refs = SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'missing-animation',
          ),
        ],
      );
      final p = ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      );
      final m = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: const [],
          presets: [p],
        ),
      );
      expect(
        m.presets.single.referencedAnimationIds,
        contains('missing-animation'),
      );
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        isTrue,
      );
    });

    test('16. full water — preset role order cross, isolated, horizontal', () {
      final row = buildSurfaceStudioReadModelFromCatalog(_fullWaterCatalog())
          .presets
          .single;
      expect(row.roles, [
        SurfaceVariantRole.cross,
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
      ]);
    });

    test('17. minimal water — diagnostics clean flags on read model', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      expect(m.diagnostics.isClean, isTrue);
      expect(m.hasDiagnostics, isFalse);
      expect(m.hasErrors, isFalse);
      expect(m.hasWarnings, isFalse);
    });

    test('18. diagnostics error — missing animation atlas', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithMissingAtlasReference(),
      );
      expect(m.hasErrors, isTrue);
      expect(m.diagnostics.errors, isNotEmpty);
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        ),
        isTrue,
      );
    });

    test('19. diagnostics error — missing preset animation', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithMissingAnimationReference(),
      );
      expect(m.hasErrors, isTrue);
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        isTrue,
      );
    });

    test('20. diagnostics warning — unused atlas', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithUnusedAtlas(),
      );
      expect(m.hasWarnings, isTrue);
      expect(
        m.diagnostics.warnings.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.unusedAtlas,
        ),
        isTrue,
      );
    });

    test('21. root lists are unmodifiable', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _minimalWaterCatalog(),
      );
      expect(() => m.atlases.add(m.atlases[0]), throwsUnsupportedError);
      expect(() => m.animations.add(m.animations[0]), throwsUnsupportedError);
      expect(() => m.presets.add(m.presets[0]), throwsUnsupportedError);
    });

    test('22. nested lists are unmodifiable', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      final a = m.atlases.single;
      final anim = m.animations.single;
      final p = m.presets.single;
      expect(() => a.usedByAnimationIds.add('x'), throwsUnsupportedError);
      expect(
        () => anim.referencedAtlasIds.add('x'),
        throwsUnsupportedError,
      );
      expect(() => p.roles.add(SurfaceVariantRole.cross), throwsUnsupportedError);
      expect(
        () => p.referencedAnimationIds.add('x'),
        throwsUnsupportedError,
      );
    });

    test('23. builder does not order by sortOrder — source list order', () {
      final g = _geom();
      final a = [
        ProjectSurfaceAtlas(
          id: 'a1',
          name: 'a1',
          tilesetId: 't',
          geometry: g,
          sortOrder: 99,
        ),
        ProjectSurfaceAtlas(
          id: 'a2',
          name: 'a2',
          tilesetId: 't',
          geometry: g,
          sortOrder: 0,
        ),
        ProjectSurfaceAtlas(
          id: 'a3',
          name: 'a3',
          tilesetId: 't',
          geometry: g,
          sortOrder: 1,
        ),
      ];
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'a1', column: 0, row: 0),
        durationMs: 10,
      );
      final t = SurfaceAnimationTimeline(frames: [f]);
      final anims = [
        ProjectSurfaceAnimation(
          id: 'n0',
          name: 'n0',
          timeline: t,
          sortOrder: 50,
        ),
        ProjectSurfaceAnimation(
          id: 'n1',
          name: 'n1',
          timeline: t,
          sortOrder: 10,
        ),
        ProjectSurfaceAnimation(
          id: 'n2',
          name: 'n2',
          timeline: t,
          sortOrder: 0,
        ),
      ];
      final c = ProjectSurfaceCatalog(
        atlases: a,
        animations: anims,
        presets: [
          ProjectSurfacePreset(
            id: 'p0',
            name: 'p0',
            sortOrder: 2,
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'n0',
                ),
              ],
            ),
          ),
          ProjectSurfacePreset(
            id: 'p1',
            name: 'p1',
            sortOrder: 0,
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'n1',
                ),
              ],
            ),
          ),
          ProjectSurfacePreset(
            id: 'p2',
            name: 'p2',
            sortOrder: 1,
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'n2',
                ),
              ],
            ),
          ),
        ],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.atlases.map((e) => e.id).toList(), ['a1', 'a2', 'a3']);
      expect(m.animations.map((e) => e.id).toList(), ['n0', 'n1', 'n2']);
      expect(m.presets.map((e) => e.id).toList(), ['p0', 'p1', 'p2']);
    });

    test('24. builder does not mutate the source catalog', () {
      final c = _minimalWaterCatalog();
      final atlasCount = c.atlases.length;
      final animCount = c.animations.length;
      final presetCount = c.presets.length;
      final firstAtlasId = c.atlases.isNotEmpty ? c.atlases.first.id : null;
      final firstAnimId = c.animations.isNotEmpty
          ? c.animations.first.id
          : null;
      final firstPresetId = c.presets.isNotEmpty ? c.presets.first.id : null;
      buildSurfaceStudioReadModelFromCatalog(c);
      expect(c.atlases.length, atlasCount);
      expect(c.animations.length, animCount);
      expect(c.presets.length, presetCount);
      if (firstAtlasId != null) {
        expect(c.atlases.first.id, firstAtlasId);
      }
      if (firstAnimId != null) {
        expect(c.animations.first.id, firstAnimId);
      }
      if (firstPresetId != null) {
        expect(c.presets.first.id, firstPresetId);
      }
    });

    test('25. value equality of read models for equivalent catalogs', () {
      final j = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final c1 = decodeProjectSurfaceCatalog(
        Map<String, Object?>.from(j),
      );
      final c2 = decodeProjectSurfaceCatalog(
        Map<String, Object?>.from(j),
      );
      final modelA = buildSurfaceStudioReadModelFromCatalog(c1);
      final modelB = buildSurfaceStudioReadModelFromCatalog(c2);
      expect(modelA == modelB, isTrue);
      expect(modelA.hashCode, modelB.hashCode);
    });

    test('26. inequality when content differs', () {
      final a = buildSurfaceStudioReadModelFromCatalog(_emptyCatalog());
      final b = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      expect(a == b, isFalse);
    });

    test('27. public export — map_core', () {
      expect(
        buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
        isA<SurfaceStudioReadModel>(),
      );
    });

    test('28. ProjectManifest toJson still Lot 49 — surfaceCatalog only', () {
      final m = _manifest(surfaceCatalog: _minimalWaterCatalog());
      final j = m.toJson();
      expect(j.containsKey('surfaceCatalog'), isTrue);
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

    test('29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog', () {
      for (final n in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readFixtureJson(n);
        expect(o, isA<Map<String, Object?>>());
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: n);
      }
    });

    test('30. no Flutter / Riverpod in surface read model public API', () {
      final m = buildSurfaceStudioReadModel(
        _manifest(surfaceCatalog: _emptyCatalog()),
      );
      expect(m, isA<SurfaceStudioReadModel>());
      // Imports are verified statically: this file only uses dart:convert,
      // dart:io, map_core, test.
    });
  });
}

// --- helpers ---

ProjectManifest _manifest({
  String name = 'Surface Read Model',
  ProjectSurfaceCatalog? surfaceCatalog,
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    surfaceCatalog: surfaceCatalog ?? ProjectSurfaceCatalog(),
  );
}

ProjectSurfaceCatalog _emptyCatalog() => ProjectSurfaceCatalog();

ProjectSurfaceCatalog _minimalWaterCatalog() {
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(
      _readFixtureJson('minimal_water_surface_catalog_v0.json'),
    ),
  );
}

ProjectSurfaceCatalog _fullWaterCatalog() {
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(
      _readFixtureJson('full_water_surface_catalog_v0.json'),
    ),
  );
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = _geom();
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'used-atlas',
      column: 0,
      row: 0,
    ),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'the-anim',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAtlasReference() {
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'nope',
      column: 0,
      row: 0,
    ),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'x',
    name: 'x',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAnimationReference() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'ghost-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'preset-ghost',
        name: 'ghost',
        variantAnimations: refs,
      ),
    ],
  );
}

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(
    File('test/fixtures/surface_catalog_json/$name').readAsStringSync(),
  ) as Map<String, Object?>;
}
