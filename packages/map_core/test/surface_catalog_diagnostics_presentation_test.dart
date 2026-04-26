import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceCatalogDiagnostic _diagnostic({
  required SurfaceCatalogDiagnosticSeverity severity,
  required SurfaceCatalogDiagnosticKind kind,
  String message = 'message',
  String? presetId,
  String? animationId,
  String? atlasId,
  SurfaceVariantRole? role,
  int? frameIndex,
}) {
  return SurfaceCatalogDiagnostic(
    severity: severity,
    kind: kind,
    message: message,
    presetId: presetId,
    animationId: animationId,
    atlasId: atlasId,
    role: role,
    frameIndex: frameIndex,
  );
}

SurfaceCatalogDiagnosticsReport _report(
  List<SurfaceCatalogDiagnostic> diagnostics,
) {
  return SurfaceCatalogDiagnosticsReport(diagnostics: diagnostics);
}

// --- Catalog helpers (même recette que les lots Surface) ---

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
  group('buildSurfaceCatalogDiagnosticsPresentation (Lot 38)', () {
    test('1. empty report → clean presentation', () {
      final report = _report([]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(identical(p.report, report), isTrue);
      expect(p.summary.isClean, isTrue);
      expect(p.errors, isEmpty);
      expect(p.warnings, isEmpty);
      expect(p.sections, isEmpty);
      expect(p.isClean, isTrue);
      expect(p.hasDiagnostics, isFalse);
      expect(p.hasErrors, isFalse);
      expect(p.hasWarnings, isFalse);
      expect(p.hasOnlyWarnings, isFalse);
    });

    test('2. one error: missingPresetAnimation', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final d = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
      );
      final report = _report([d]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors.length, 1);
      expect(p.warnings, isEmpty);
      expect(p.sections.length, 1);
      expect(
        p.sections.first.kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
      );
      expect(p.sections.first.severity, e);
      expect(p.sections.first.count, 1);
      expect(p.hasErrors, isTrue);
    });

    test('3. one warning: unusedAtlas', () {
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final d = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        atlasId: 'a1',
      );
      final report = _report([d]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors, isEmpty);
      expect(p.warnings.length, 1);
      expect(p.sections.length, 1);
      expect(
        p.sections.first.kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
      expect(p.sections.first.severity, w);
      expect(p.sections.first.count, 1);
      expect(p.hasOnlyWarnings, isTrue);
    });

    test('4. mix ordered: 2 err then 2 warn', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final report = _report([
        _diagnostic(
          severity: e,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        _diagnostic(
          severity: e,
          kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
          atlasId: 'x',
        ),
        _diagnostic(
          severity: w,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
          atlasId: 'u1',
        ),
        _diagnostic(
          severity: w,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          animationId: 'a1',
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors.length, 2);
      expect(p.warnings.length, 2);
      expect(p.sections.length, 2);
      expect(
        p.sections[0].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
      );
      expect(
        p.sections[1].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
      final s2 = summarizeSurfaceCatalogDiagnostics(report);
      expect(p.summary.totalCount, 4);
      expect(s2, p.summary);
    });

    test('5. interleaved w,e,w,e: stable relative order in buckets', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final w1 = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        message: 'w1',
        atlasId: 'A',
      );
      final e1 = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'e1',
      );
      final w2 = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        message: 'w2',
        animationId: 'Z',
      );
      final e2 = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        message: 'e2',
        animationId: 'a',
        atlasId: 'b',
      );
      final report = _report([w1, e1, w2, e2]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(
        p.errors.map((x) => x.message).toList(),
        ['e1', 'e2'],
      );
      expect(
        p.warnings.map((x) => x.message).toList(),
        ['w1', 'w2'],
      );
      expect(
        p.sections[0].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
      );
      expect(
        p.sections[1].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
    });

    test('6. error kinds not alphabetically sorted (order preserved)', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final first = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
        message: 'a',
        frameIndex: 0,
      );
      final second = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'b',
      );
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([first, second]),
      );
      expect(p.errors[0].kind,
          SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry);
      expect(p.errors[1].kind,
          SurfaceCatalogDiagnosticKind.missingPresetAnimation);
    });

    test('7. warnings: message / id order preserved (not sorted)', () {
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final a = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        message: 'z-last',
        animationId: 'id-b',
      );
      final b = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        message: 'a-first',
        animationId: 'id-a',
      );
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([a, b]),
      );
      expect(p.warnings[0].message, 'z-last');
      expect(p.warnings[0].animationId, 'id-b');
      expect(p.warnings[1].message, 'a-first');
    });

    test('8. summary == summarizeSurfaceCatalogDiagnostics(report)', () {
      final report = _report([
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(
        p.summary,
        summarizeSurfaceCatalogDiagnostics(report),
      );
    });

    test('9. bool helpers delegate to summary (mixed)', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final report = _report([
        _diagnostic(
            severity: w, kind: SurfaceCatalogDiagnosticKind.unusedAtlas),
        _diagnostic(
          severity: e,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      final sm = p.summary;
      expect(p.isClean, sm.isClean);
      expect(p.hasDiagnostics, sm.hasDiagnostics);
      expect(p.hasErrors, sm.hasErrors);
      expect(p.hasWarnings, sm.hasWarnings);
      expect(p.hasOnlyWarnings, sm.hasOnlyWarnings);
    });

    test('10. errors, warnings, sections are unmodifiable', () {
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'x',
          ),
        ]),
      );
      final e = _diagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        atlasId: 'y',
      );
      final fakeSection = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
        severity: SurfaceCatalogDiagnosticSeverity.warning,
        diagnostics: [
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          ),
        ],
      );
      expect(() => p.errors.add(e), throwsA(isA<UnsupportedError>()));
      expect(
        () => p.warnings.add(
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'a',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => p.sections.add(fakeSection),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('11. section.diagnostics is unmodifiable', () {
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      final extra = _diagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        atlasId: 'z',
      );
      expect(
        () => p.sections.first.diagnostics.add(extra),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('12. section count / isEmpty / isNotEmpty (two in section)', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: e,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
          _diagnostic(
            severity: e,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            atlasId: 'q',
          ),
        ]),
      );
      final s = p.sections.first;
      expect(s.count, 2);
      expect(s.isEmpty, isFalse);
      expect(s.isNotEmpty, isTrue);
    });

    test('13. presentation stable when source list mutated after build', () {
      final list = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ];
      final report = _report(list);
      final p0 = buildSurfaceCatalogDiagnosticsPresentation(report);
      list.add(
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        ),
      );
      final p1 = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(report.count, 1);
      expect(p0, p1);
    });

    test('14. from diagnoseProjectSurfaceCatalogForAuthoring', () {
      final used = _atlas('used-atlas');
      final unusedA = _atlas('unused-atlas');
      final uAnim = _animation('unused-animation', atlasId: 'used-atlas');
      final c = _catalog(
        atlases: [used, unusedA],
        animations: [uAnim],
        presets: [
          _preset('broken', [
            _ref(SurfaceVariantRole.isolated, 'missing-animation'),
          ]),
        ],
      );
      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors.length, 1);
      expect(p.warnings.length, 2);
      expect(p.sections.length, 2);
      expect(
        p.summary,
        summarizeSurfaceCatalogDiagnostics(report),
      );
    });

    test('15. warnings-only from authoring', () {
      final c = _catalog(
        atlases: [_atlas('orphan')],
        animations: [
          _animation('a1', atlasId: 'orphan'),
        ],
        presets: const [],
      );
      final r = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final p = buildSurfaceCatalogDiagnosticsPresentation(r);
      expect(p.errors, isEmpty);
      expect(p.warnings.isNotEmpty, isTrue);
      expect(p.sections.length, 1);
      expect(
        p.sections.first.kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
      expect(p.hasOnlyWarnings, isTrue);
    });

    test('16. no new diagnostics: counts match', () {
      final report = _report([
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(
        p.report.diagnostics.length,
        report.diagnostics.length,
      );
      expect(
        p.errors.length + p.warnings.length,
        report.diagnostics.length,
      );
    });

    test('17. section value equality: same==hash', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final a = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
      );
      final s1 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [a],
      );
      final s2 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [a],
      );
      expect(s1, s2);
      expect(s1.hashCode, s2.hashCode);
    });

    test('18. section inequality: different diagnostic order', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final x = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: '1',
      );
      final y = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        message: '2',
        atlasId: 'z',
      );
      final s1 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [x, y],
      );
      final s2 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [y, x],
      );
      expect(s1, isNot(s2));
    });

    test('19. presentation equality: equivalent reports', () {
      final a = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ];
      final r1 = _report(a);
      final r2 = _report(List<SurfaceCatalogDiagnostic>.from(a));
      final p1 = buildSurfaceCatalogDiagnosticsPresentation(r1);
      final p2 = buildSurfaceCatalogDiagnosticsPresentation(r2);
      expect(p1, p2);
      expect(p1.hashCode, p2.hashCode);
    });

    test('20. presentation inequality when content differs', () {
      final p1 = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
            message: 'a',
          ),
        ]),
      );
      final p2 = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
            message: 'b',
          ),
        ]),
      );
      expect(p1, isNot(p2));
    });

    test('21. public API types via map_core', () {
      final p = buildSurfaceCatalogDiagnosticsPresentation(_report([]));
      expect(p, isA<SurfaceCatalogDiagnosticsPresentation>());
      expect(
        p.sections,
        isA<List<SurfaceCatalogDiagnosticsPresentationSection>>(),
      );
      expect(
        SurfaceCatalogDiagnosticsPresentationSectionKind.values.isNotEmpty,
        isTrue,
      );
    });

    test('22. ProjectManifest: no Surface keys (Lot 38)', () {
      const manifest = ProjectManifest(
        name: 'L38',
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

    test('23. no unusedPreset kind; severities are error, warning', () {
      final names =
          SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
      expect(names.contains('unusedPreset'), isFalse);
      final sev = SurfaceCatalogDiagnosticSeverity.values
          .map((e) => e.name)
          .toList()
        ..sort();
      expect(sev, ['error', 'warning']);
    });
  });
}
