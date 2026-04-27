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
  group('diagnoseProjectSurfaceCatalog (Lot 34)', () {
    test('1. empty catalog: no diagnostics', () {
      final r = diagnoseProjectSurfaceCatalog(_catalog());
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
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(
          atlases: [atlas],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(r.diagnostics, isEmpty);
    });

    test('3. missing preset animation', () {
      final p = _preset('p1', [
        _ref(SurfaceVariantRole.isolated, 'missing-animation'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(_catalog(presets: [p]));
      expect(r.count, 1);
      final d = r.diagnostics.single;
      expect(d.kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.error);
      expect(d.presetId, 'p1');
      expect(d.animationId, 'missing-animation');
      expect(d.role, SurfaceVariantRole.isolated);
      expect(d.atlasId, isNull);
      expect(d.frameIndex, isNull);
      expect(d.message, contains('p1'));
      expect(d.message, contains('missing-animation'));
    });

    test('4. two missing refs: order follows refs', () {
      final p = _preset('p1', [
        _ref(SurfaceVariantRole.isolated, 'miss-a'),
        _ref(SurfaceVariantRole.horizontal, 'miss-b'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(_catalog(presets: [p]));
      expect(r.count, 2);
      expect(r.diagnostics[0].animationId, 'miss-a');
      expect(r.diagnostics[1].animationId, 'miss-b');
    });

    test('5. two presets: order follows catalog.presets', () {
      final a = _preset('first', [
        _ref(SurfaceVariantRole.isolated, 'x'),
      ]);
      final b = _preset('second', [
        _ref(SurfaceVariantRole.isolated, 'y'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [a, b]),
      );
      expect(r.diagnostics[0].presetId, 'first');
      expect(r.diagnostics[1].presetId, 'second');
    });

    test('6. missing animation atlas', () {
      final anim = _animation('anim', atlasId: 'missing-atlas');
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(animations: [anim]),
      );
      final d = r.diagnostics.single;
      expect(d.kind, SurfaceCatalogDiagnosticKind.missingAnimationAtlas);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.error);
      expect(d.animationId, 'anim');
      expect(d.atlasId, 'missing-atlas');
      expect(d.frameIndex, 0);
      expect(d.presetId, isNull);
      expect(d.role, isNull);
      expect(d.message, contains('anim'));
      expect(d.message, contains('missing-atlas'));
    });

    test('7. two frames to missing atlas: frameIndex 0 and 1', () {
      final anim = _animation(
        'anim',
        frames: [
          _frame('m1', 0, 0),
          _frame('m2', 0, 0),
        ],
      );
      final r = diagnoseProjectSurfaceCatalog(_catalog(animations: [anim]));
      expect(r.count, 2);
      expect(r.diagnostics[0].frameIndex, 0);
      expect(r.diagnostics[0].atlasId, 'm1');
      expect(r.diagnostics[1].frameIndex, 1);
      expect(r.diagnostics[1].atlasId, 'm2');
    });

    test('8. frame outside geometry: column', () {
      final atlas = _atlas('atlas', columns: 2, rows: 2);
      final anim = _animation(
        'anim',
        frames: [
          _frame('atlas', 2, 0),
        ],
        atlasId: 'atlas',
      );
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim]),
      );
      final d = r.diagnostics.single;
      expect(d.kind, SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry);
      expect(d.animationId, 'anim');
      expect(d.atlasId, 'atlas');
      expect(d.frameIndex, 0);
    });

    test('9. frame outside geometry: row', () {
      final atlas = _atlas('atlas', columns: 2, rows: 2);
      final anim = ProjectSurfaceAnimation(
        id: 'anim2',
        name: 'a',
        timeline: SurfaceAnimationTimeline(
          frames: [_frame('atlas', 0, 2)],
        ),
      );
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim]),
      );
      expect(
        r.diagnostics.single.kind,
        SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
      );
    });

    test('10. missing atlas only: not also outside geometry', () {
      final anim = _animation(
        'anim',
        frames: [
          _frame('missing-atlas', 99, 99),
        ],
        atlasId: 'missing-atlas',
      );
      final r = diagnoseProjectSurfaceCatalog(_catalog(animations: [anim]));
      expect(r.count, 1);
      expect(
        r.diagnostics.single.kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
    });

    test('11. preset diagnostics then animation diagnostics', () {
      final preset = _preset('pr', [
        _ref(SurfaceVariantRole.isolated, 'no-such-anim'),
      ]);
      final anim = _animation('badA', atlasId: 'missing');
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [preset], animations: [anim]),
      );
      expect(r.count, 2);
      expect(
        r.diagnostics[0].kind,
        SurfaceCatalogDiagnosticKind.missingPresetAnimation,
      );
      expect(
        r.diagnostics[1].kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
    });

    test('12. exact atlas id: no trim', () {
      final atlas = _atlas('  atlas  ');
      final anim = _animation('anim', frames: [
        _frame('atlas', 0, 0),
      ], atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim]),
      );
      final d = r.diagnostics.single;
      expect(
        d.kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
      expect(d.atlasId, 'atlas');
    });

    test('13. byKind filters', () {
      final atlas = _atlas('a', columns: 2, rows: 2);
      final animO = _animation('o', frames: [
        _frame('a', 0, 3),
      ], atlasId: 'a');
      final preset = _preset('p', [
        _ref(SurfaceVariantRole.isolated, 'miss'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(
          atlases: [atlas],
          animations: [animO],
          presets: [preset],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation).length,
        1,
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry)
            .length,
        1,
      );
    });

    test('14. byKind list is unmodifiable', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [
          _preset('p', [
            _ref(SurfaceVariantRole.isolated, 'm'),
          ]),
        ]),
      );
      final list = r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(
        () => list.add(
          r.diagnostics.first,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('15. diagnostics list on report is unmodifiable', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(animations: [
          _animation('o', atlasId: 'x'),
        ]),
      );
      expect(
        () => r.diagnostics.add(r.diagnostics.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('16. defensive copy: mutating source list does not change report', () {
      final d = <SurfaceCatalogDiagnostic>[];
      final report = SurfaceCatalogDiagnosticsReport(diagnostics: d);
      d.add(
        SurfaceCatalogDiagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          message: 'm',
        ),
      );
      expect(report.count, 0);
    });

    test('17. hasErrors false on empty report', () {
      final r = SurfaceCatalogDiagnosticsReport(diagnostics: const []);
      expect(r.hasErrors, isFalse);
    });

    test('18. hasErrors true when error diagnostic', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [
          _preset('p', [
            _ref(SurfaceVariantRole.isolated, 'miss'),
          ]),
        ]),
      );
      expect(r.hasErrors, isTrue);
    });

    test('19. diagnostic equality: same', () {
      final a = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'p',
      );
      final b = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'p',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('20. diagnostic equality: different kind', () {
      final a = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
      );
      final b = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        message: 'm',
      );
      expect(a, isNot(b));
    });

    test('21. diagnostic equality: different metadata', () {
      final a = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'a',
      );
      final b = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'b',
      );
      expect(a, isNot(b));
    });

    test('22. report equality: same order', () {
      final d1 = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'p',
      );
      final a = SurfaceCatalogDiagnosticsReport(diagnostics: [d1]);
      final b = SurfaceCatalogDiagnosticsReport(diagnostics: [d1]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('23. report equality: order matters', () {
      final d1 = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: '1',
        presetId: 'a',
      );
      final d2 = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: '2',
        presetId: 'b',
      );
      final x = SurfaceCatalogDiagnosticsReport(diagnostics: [d1, d2]);
      final y = SurfaceCatalogDiagnosticsReport(diagnostics: [d2, d1]);
      expect(x, isNot(y));
    });

    test('24. public API via map_core', () {
      final r = diagnoseProjectSurfaceCatalog(_catalog());
      expect(r, isA<SurfaceCatalogDiagnosticsReport>());
      expect(
        SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        isA<SurfaceCatalogDiagnosticKind>(),
      );
    });

    test('25. ProjectManifest still has no Surface keys (Lot 34)', () {
      final manifest = ProjectManifest(
        name: 'L34',
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
  });
}
