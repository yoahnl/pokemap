import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

// --- Helpers (alignés sur surface_catalog_diagnostics_test) ---

SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(
  String id, {
  int columns = 2,
  int rows = 2,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'n-$id',
    tilesetId: 'ts',
    geometry: _geom(columns: columns, rows: rows),
  );
}

SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: 1,
  );
}

ProjectSurfaceAnimation _animation(
  String id, {
  String atlasId = 'atlas',
  List<SurfaceAnimationFrame>? frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'a-$id',
    timeline: SurfaceAnimationTimeline(
      frames: frames ?? [_frame(atlasId, 0, 0)],
    ),
  );
}

SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
  return ProjectSurfacePreset(
    id: id,
    name: 'p-$id',
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas>? atlases,
  List<ProjectSurfaceAnimation>? animations,
  List<ProjectSurfacePreset>? presets,
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases ?? const [],
    animations: animations ?? const [],
    presets: presets ?? const [],
  );
}

void main() {
  group('diagnoseProjectSurfaceCatalogUnusedResources (Lot 35)', () {
    test('1. empty catalog: no unused diagnostics', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(_catalog());
      expect(r.count, 0);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.diagnostics, isEmpty);
    });

    test('2. minimal coherent: no unused diagnostics', () {
      final atlas = _atlas('atlas');
      final anim = _animation('anim', atlasId: 'atlas');
      final preset = _preset('preset', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(r.diagnostics, isEmpty);
      expect(r.hasErrors, isFalse);
    });

    test('3. unreferenced atlas → unusedAtlas warning and metadata', () {
      final a = _atlas('unused-atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(atlases: [a], animations: const [], presets: const []),
      );
      expect(r.count, 1);
      final d = r.diagnostics.first;
      expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.warning);
      expect(d.atlasId, 'unused-atlas');
      expect(d.animationId, isNull);
      expect(d.presetId, isNull);
      expect(d.role, isNull);
      expect(d.frameIndex, isNull);
      expect(d.message, contains('unused-atlas'));
      expect(
        d.message.toLowerCase(),
        contains('not referenced by any animation'),
      );
      expect(r.hasDiagnostics, isTrue);
      expect(r.hasErrors, isFalse);
    });

    test('4. multiple unused atlases: order follows catalog.atlases a,b,c', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a'), _atlas('b'), _atlas('c')],
        ),
      );
      expect(r.diagnostics.length, 3);
      expect(r.diagnostics[0].atlasId, 'a');
      expect(r.diagnostics[1].atlasId, 'b');
      expect(r.diagnostics[2].atlasId, 'c');
    });

    test('5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)', () {
      final atlas = _atlas('atlas');
      final anim = _animation('ani', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
        isEmpty,
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).length,
        1,
      );
    });

    test('6. atlas id exact: spaced atlas not matched by frame atlasId', () {
      const spaced = '  atlas  ';
      final atlas = _atlas(spaced);
      final anim = _animation('x', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
        ),
      );
      final ua = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(ua, hasLength(1));
      expect(ua.first.atlasId, spaced);
    });

    test('7. animation not referenced by preset → unusedAnimation', () {
      final atlas = _atlas('atlas');
      final anim = _animation('unused-animation', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
        ),
      );
      final u = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
      expect(u, hasLength(1));
      final d = u.first;
      expect(d.animationId, 'unused-animation');
      expect(d.atlasId, isNull);
      expect(d.presetId, isNull);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.warning);
    });

    test('8. multiple unused animations: order follows catalog.animations a,b,c',
        () {
      final atlas = _atlas('atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [
            _animation('a', atlasId: 'atlas'),
            _animation('b', atlasId: 'atlas'),
            _animation('c', atlasId: 'atlas'),
          ],
        ),
      );
      final u = r.diagnostics
          .where(
            (d) => d.kind == SurfaceCatalogDiagnosticKind.unusedAnimation,
          )
          .toList();
      expect(u.length, 3);
      expect(u[0].animationId, 'a');
      expect(u[1].animationId, 'b');
      expect(u[2].animationId, 'c');
    });

    test('9. animation referenced by a preset: not unused', () {
      final anim = _animation('anim', atlasId: 'a');
      final preset = _preset('p1', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a')],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation),
        isEmpty,
      );
    });

    test('10. animationId exact: spaced id not matched by preset ref', () {
      const spaced = '  anim  ';
      final anim = _animation(spaced, atlasId: 'a');
      final preset = _preset('p', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a')],
          animations: [anim],
          presets: [preset],
        ),
      );
      final u = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
      expect(u, hasLength(1));
      expect(u.first.animationId, spaced);
    });

    test('11. same animation referenced by two presets: not unused', () {
      final anim = _animation('anim', atlasId: 'a');
      final p1 = _preset('p1', [
        _ref(SurfaceVariantRole.endNorth, 'anim'),
      ]);
      final p2 = _preset('p2', [
        _ref(SurfaceVariantRole.endSouth, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a')],
          animations: [anim],
          presets: [p1, p2],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation),
        isEmpty,
      );
    });

    test('12. same atlas referenced by two animations: atlas not unused', () {
      final atlas = _atlas('atlas');
      final a1 = _animation('a1', atlasId: 'atlas');
      final a2 = _animation('a2', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [a1, a2],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
        isEmpty,
      );
    });

    test('13. global order: unusedAtlas before unusedAnimation', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('unused-atlas')],
          animations: [_animation('unused-animation', atlasId: 'x')],
        ),
      );
      expect(r.diagnostics.length, 2);
      expect(r.diagnostics[0].kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(r.diagnostics[1].kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
    });

    test('14. warnings only: hasErrors false, hasDiagnostics true', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('orphan')],
        ),
      );
      expect(r.hasDiagnostics, isTrue);
      expect(r.hasErrors, isFalse);
    });

    test('15. byKind(unusedAtlas) only atlas warnings', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('u')],
          animations: [_animation('a', atlasId: 'm')],
        ),
      );
      final only = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
      for (final d in only) {
        expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
        expect(d.atlasId, isNotNull);
      }
    });

    test('16. byKind(unusedAnimation) only animation warnings', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('at')],
          animations: [_animation('a', atlasId: 'at')],
        ),
      );
      final only = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
      for (final d in only) {
        expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
        expect(d.animationId, isNotNull);
      }
    });

    test('17. byKind returns an unmodifiable list (add → UnsupportedError)', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('x')],
        ),
      );
      final list = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(
        () => list.add(
          r.diagnostics.first,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('18. diagnostics list is unmodifiable (add → UnsupportedError)', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('x')],
        ),
      );
      expect(
        () => r.diagnostics.add(r.diagnostics.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      '19. unused function does not emit Lot 34 error kinds',
      () {
        final r = diagnoseProjectSurfaceCatalogUnusedResources(
          _catalog(
            animations: [
              _animation('anim', atlasId: 'missing-atlas'),
            ],
          ),
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
          isEmpty,
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          isEmpty,
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry),
          isEmpty,
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).length,
          1,
        );
      },
    );

    test('20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'missing-anim'),
            ]),
          ],
        ),
      );
      expect(r.hasErrors, isTrue);
      final k = r.diagnostics.map((d) => d.kind).toSet();
      expect(
        k,
        contains(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
      );
    });

    test('21. warning severity exists and differs from error', () {
      expect(
        SurfaceCatalogDiagnosticSeverity.warning,
        isNot(equals(SurfaceCatalogDiagnosticSeverity.error)),
      );
    });

    test(
      'V0 does not diagnose unused presets yet: isolated preset, no false presetId',
      () {
        final p = _preset('lonely', [
          _ref(SurfaceVariantRole.isolated, 'ghost-anim'),
        ]);
        final r = diagnoseProjectSurfaceCatalogUnusedResources(
          _catalog(
            presets: [p],
          ),
        );
        for (final d in r.diagnostics) {
          expect(
            d.presetId,
            isNot('lonely'),
            reason: 'Lot 35 must not target preset id for unused V0',
          );
        }
      },
    );

    test('23. public API: unused + kinds via map_core only', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(_catalog());
      expect(
        r,
        isA<SurfaceCatalogDiagnosticsReport>(),
      );
      expect(
        SurfaceCatalogDiagnosticKind.unusedAtlas,
        isA<SurfaceCatalogDiagnosticKind>(),
      );
      expect(
        SurfaceCatalogDiagnosticKind.unusedAnimation,
        isA<SurfaceCatalogDiagnosticKind>(),
      );
      expect(
        SurfaceCatalogDiagnosticSeverity.warning,
        isA<SurfaceCatalogDiagnosticSeverity>(),
      );
    });

    test('24. ProjectManifest still has no Surface keys (Lot 35)', () {
      const manifest = ProjectManifest(
        name: 'L35',
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
  });
}
