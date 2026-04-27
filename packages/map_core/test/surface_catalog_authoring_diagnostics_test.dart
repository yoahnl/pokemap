import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

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
  group('diagnoseProjectSurfaceCatalogForAuthoring (Lot 36)', () {
    test('1. empty catalog: no diagnostics', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(_catalog());
      expect(r.count, 0);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.diagnostics, isEmpty);
    });

    test('2. minimal coherent: no diagnostics', () {
      final atlas = _atlas('atlas');
      final anim = _animation('anim', atlasId: 'atlas');
      final preset = _preset('preset', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final c = _catalog(
        atlases: [atlas],
        animations: [anim],
        presets: [preset],
      );
      final r = diagnoseProjectSurfaceCatalogForAuthoring(c);
      expect(r.diagnostics, isEmpty);
      expect(r.hasErrors, isFalse);
    });

    test('3. error only: missing preset animation', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'missing-animation'),
            ]),
          ],
        ),
      );
      expect(r.count, 1);
      expect(r.diagnostics.first.kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.error);
      expect(r.hasErrors, isTrue);
    });

    test('4. warning only: unused atlas', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [_atlas('orphan')],
        ),
      );
      expect(r.count, 1);
      expect(r.diagnostics.first.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.warning);
      expect(r.hasErrors, isFalse);
    });

    test('5. warning only: unused animation, no unusedAtlas', () {
      final atlas = _atlas('atlas');
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [atlas],
          animations: [_animation('anim', atlasId: 'atlas')],
        ),
      );
      final kinds = r.diagnostics.map((d) => d.kind).toList();
      expect(kinds, [SurfaceCatalogDiagnosticKind.unusedAnimation]);
      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.warning);
      expect(r.hasErrors, isFalse);
    });

    test('6. error + warnings: order errors then unusedAtlas then unusedAnimation', () {
      final usedAtlas = _atlas('used-atlas');
      final unusedAtlas = _atlas('unused-atlas');
      final anim = _animation('unused-animation', atlasId: 'used-atlas');
      final preset = _preset('broken-preset', [
        _ref(SurfaceVariantRole.isolated, 'missing-animation'),
      ]);
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [usedAtlas, unusedAtlas],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(r.diagnostics.length, 3);
      expect(r.diagnostics[0].kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(r.diagnostics[1].kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(r.diagnostics[1].atlasId, 'unused-atlas');
      expect(r.diagnostics[2].kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
      expect(r.diagnostics[2].animationId, 'unused-animation');
      expect(r.hasErrors, isTrue);
    });

    test('7. two preset errors: Lot 34 order preserved at start of report', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('first', [
              _ref(SurfaceVariantRole.isolated, 'm1'),
            ]),
            _preset('second', [
              _ref(SurfaceVariantRole.isolated, 'm2'),
            ]),
          ],
        ),
      );
      expect(r.diagnostics.length, 2);
      expect(r.diagnostics[0].presetId, 'first');
      expect(r.diagnostics[0].animationId, 'm1');
      expect(r.diagnostics[1].presetId, 'second');
      expect(r.diagnostics[1].animationId, 'm2');
    });

    test('8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail', () {
      final forFrames = _atlas('for-frames');
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [
            _atlas('u1'),
            _atlas('u2'),
            _atlas('u3'),
            forFrames,
          ],
          animations: [
            _animation('a1', atlasId: 'for-frames'),
            _animation('a2', atlasId: 'for-frames'),
            _animation('a3', atlasId: 'for-frames'),
          ],
        ),
      );
      final kinds = r.diagnostics.map((d) => d.kind).toList();
      expect(
        kinds,
        [
          ...List.filled(3, SurfaceCatalogDiagnosticKind.unusedAtlas),
          ...List.filled(3, SurfaceCatalogDiagnosticKind.unusedAnimation),
        ],
      );
      expect(r.diagnostics[0].atlasId, 'u1');
      expect(r.diagnostics[1].atlasId, 'u2');
      expect(r.diagnostics[2].atlasId, 'u3');
      expect(r.diagnostics[3].animationId, 'a1');
      expect(r.diagnostics[4].animationId, 'a2');
      expect(r.diagnostics[5].animationId, 'a3');
    });

    test('9. no dedup: missingAnimationAtlas + unusedAnimation same anim', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          animations: [
            _animation('ghost', atlasId: 'no-such-atlas'),
          ],
        ),
      );
      expect(r.diagnostics.length, 2);
      expect(
        r.diagnostics[0].kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
      expect(
        r.diagnostics[1].kind,
        SurfaceCatalogDiagnosticKind.unusedAnimation,
      );
      expect(r.diagnostics[1].animationId, 'ghost');
    });

    test('10. warnings only: hasErrors false', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(atlases: [_atlas('x')]),
      );
      expect(r.hasDiagnostics, isTrue);
      expect(r.hasErrors, isFalse);
    });

    test('11. errors + warnings: hasErrors true', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'absent'),
            ]),
          ],
          atlases: [_atlas('only-atlas')],
        ),
      );
      expect(r.hasErrors, isTrue);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        isNotEmpty,
      );
    });

    test('12. byKind on combined report', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'miss'),
            ]),
          ],
          atlases: [
            _atlas('a'),
            _atlas('b'),
          ],
          animations: [
            _animation('u', atlasId: 'a'),
          ],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation).length,
        1,
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas).map((d) => d.atlasId).toList(),
        ['b'],
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).map((d) => d.animationId).toList(),
        ['u'],
      );
    });

    test('13. diagnostics list is unmodifiable', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(atlases: [_atlas('z')]),
      );
      expect(
        () => r.diagnostics.add(r.diagnostics.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('14. catalog lists unchanged after call', () {
      final a = _atlas('a');
      final c = _catalog(atlases: [a], animations: const [], presets: const []);
      expect(c.atlases.length, 1);
      final beforeAtlases = c.atlases;
      diagnoseProjectSurfaceCatalogForAuthoring(c);
      expect(c.atlases.length, 1);
      expect(identical(c.atlases, beforeAtlases), isTrue);
    });

    test('15. Lot 34 alone: no unusedAtlas for orphan atlas', () {
      final onlyErrors = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [_atlas('only')]),
      );
      expect(
        onlyErrors.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
        isEmpty,
      );
    });

    test('16. Lot 35 alone: no missingPresetAnimation for broken ref', () {
      final onlyUnused = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'nope'),
            ]),
          ],
        ),
      );
      expect(
        onlyUnused.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        isEmpty,
      );
    });

    test('17. V0: coherent preset, no spurious preset-targeted unused rule', () {
      const id = 'coherent-preset';
      final anim = _animation('linked', atlasId: 'A');
      final preset = _preset(id, [
        _ref(SurfaceVariantRole.isolated, 'linked'),
      ]);
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [_atlas('A')],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(
        r.diagnostics.where((d) => d.presetId == id),
        isEmpty,
        reason: 'V0: no unusedPreset — preset not targeted when catalog coherent',
      );
    });

    test('18. public API via map_core', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(_catalog());
      expect(r, isA<SurfaceCatalogDiagnosticsReport>());
    });

    test('19. ProjectManifest still has no Surface keys (Lot 36)', () {
      final manifest = ProjectManifest(
        name: 'L36',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),);
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

    test('20. no unusedPreset kind; severities are error and warning only', () {
      final names = SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
      expect(names.contains('unusedPreset'), isFalse);
      final sev = SurfaceCatalogDiagnosticSeverity.values.map((e) => e.name).toList()..sort();
      expect(sev, ['error', 'warning']);
    });
  });
}
