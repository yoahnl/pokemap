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

// --- Minimale cohérence catalog (reprise style Lot 36) ---

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
  group('summarizeSurfaceCatalogDiagnostics (Lot 37)', () {
    test('1. empty report → clean summary', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        SurfaceCatalogDiagnosticsReport(diagnostics: const []),
      );
      expect(s.totalCount, 0);
      expect(s.errorCount, 0);
      expect(s.warningCount, 0);
      expect(s.isClean, isTrue);
      expect(s.hasDiagnostics, isFalse);
      expect(s.hasErrors, isFalse);
      expect(s.hasWarnings, isFalse);
      expect(s.hasOnlyWarnings, isFalse);
      expect(s.countByKind.isEmpty, isTrue);
      for (final k in SurfaceCatalogDiagnosticKind.values) {
        expect(s.countForKind(k), 0);
      }
    });

    test('2. one error missingPresetAnimation', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      expect(s.totalCount, 1);
      expect(s.errorCount, 1);
      expect(s.warningCount, 0);
      expect(s.hasDiagnostics, isTrue);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isFalse);
      expect(s.hasOnlyWarnings, isFalse);
      expect(
        s.countForKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        1,
      );
    });

    test('3. one warning unusedAtlas', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'a1',
          ),
        ]),
      );
      expect(s.totalCount, 1);
      expect(s.errorCount, 0);
      expect(s.warningCount, 1);
      expect(s.hasDiagnostics, isTrue);
      expect(s.hasErrors, isFalse);
      expect(s.hasWarnings, isTrue);
      expect(s.hasOnlyWarnings, isTrue);
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAtlas), 1);
    });

    test('4. mixed: 2+1 errors, 1+3 warnings, counts by kind', () {
      const err = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
              severity: err,
              kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          _diagnostic(
              severity: err,
              kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          _diagnostic(
            severity: err,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            animationId: 'an',
            atlasId: 'bad',
          ),
          _diagnostic(
              severity: w,
              kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
              atlasId: 'u1'),
          _diagnostic(
            severity: w,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'x1',
          ),
          _diagnostic(
            severity: w,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'x2',
          ),
          _diagnostic(
            severity: w,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'x3',
          ),
        ]),
      );
      expect(s.totalCount, 7);
      expect(s.errorCount, 3);
      expect(s.warningCount, 4);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isTrue);
      expect(s.hasOnlyWarnings, isFalse);
      expect(
          s.countForKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          2);
      expect(
        s.countForKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
        1,
      );
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAtlas), 1);
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAnimation), 3);
    });

    test('5. countByKind only present kinds; countForKind 0 for absent', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'at',
          ),
        ]),
      );
      expect(
          s.countByKind.containsKey(SurfaceCatalogDiagnosticKind.unusedAtlas),
          isTrue);
      expect(
        s.countByKind.containsKey(SurfaceCatalogDiagnosticKind.unusedAnimation),
        isFalse,
      );
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAnimation), 0);
    });

    test('6. countByKind is unmodifiable', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'a',
          ),
        ]),
      );
      expect(
        () {
          s.countByKind[SurfaceCatalogDiagnosticKind.unusedAtlas] = 99;
        },
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
        '7. summary does not mutate report; list mutation does not change stored report or prior summary',
        () {
      final list = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          presetId: 'p1',
        ),
      ];
      final report = _report(list);
      final sBefore = summarizeSurfaceCatalogDiagnostics(report);
      list.add(
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        ),
      );
      final after = summarizeSurfaceCatalogDiagnostics(report);
      expect(report.count, 1);
      expect(after.totalCount, 1);
      expect(sBefore, after);
    });

    test(
        '8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)',
        () {
      const err = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final report = _report([
        _diagnostic(
            severity: err,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        _diagnostic(
          severity: w,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          animationId: 'a',
        ),
      ]);
      final s = summarizeSurfaceCatalogDiagnostics(report);
      expect(s.hasErrors, report.hasErrors);
    });

    test('9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn',
        () {
      final used = _atlas('used-atlas');
      final unusedA = _atlas('unused-atlas');
      final uAnim = _animation('unused-animation', atlasId: 'used-atlas');
      final c = _catalog(
        atlases: [used, unusedA],
        animations: [uAnim],
        presets: [
          _preset('broken-preset', [
            _ref(SurfaceVariantRole.isolated, 'missing-animation'),
          ]),
        ],
      );
      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final s = summarizeSurfaceCatalogDiagnostics(report);
      expect(report.diagnostics[0].kind,
          SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(s.totalCount, 3);
      expect(s.errorCount, 1);
      expect(s.warningCount, 2);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isTrue);
      expect(s.hasOnlyWarnings, isFalse);
    });

    test('10. from authoring: warnings-only (unused) → hasOnlyWarnings', () {
      final c = _catalog(
        atlases: [_atlas('orphan')],
        animations: [
          _animation('orphan-anim', atlasId: 'orphan'),
        ],
        presets: const [],
      );
      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final s = summarizeSurfaceCatalogDiagnostics(report);
      expect(s.hasOnlyWarnings, isTrue);
      expect(s.hasErrors, isFalse);
    });

    test('11. value equality: equivalent reports → same summary hash/==', () {
      final a = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          message: 'm',
        ),
      ];
      final s1 = summarizeSurfaceCatalogDiagnostics(_report(a));
      final s2 = summarizeSurfaceCatalogDiagnostics(_report(List.from(a)));
      expect(s1, s2);
      expect(s1.hashCode, s2.hashCode);
    });

    test('12. value inequality: different error/warning split (same total)',
        () {
      final sErr = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      final sWarn = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'x',
          ),
        ]),
      );
      expect(sErr.totalCount, sWarn.totalCount);
      expect(sErr, isNot(sWarn));
    });

    test('13. value inequality: same severity totals, different byKind', () {
      final s1 = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      final s2 = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            atlasId: 'x',
            animationId: 'a',
          ),
        ]),
      );
      expect(s1.totalCount, s2.totalCount);
      expect(s1.errorCount, s2.errorCount);
      expect(s1, isNot(s2));
    });

    test('14. public API via map_core', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        SurfaceCatalogDiagnosticsReport(diagnostics: const []),
      );
      expect(s, isA<SurfaceCatalogDiagnosticsSummary>());
    });

    test('15. ProjectManifest still has no Surface keys (Lot 37)', () {
      const manifest = ProjectManifest(
        name: 'L37',
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

    test('16. no unusedPreset kind; severities are error and warning only', () {
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
