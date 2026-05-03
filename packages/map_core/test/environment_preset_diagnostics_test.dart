import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'diag_test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: environmentPresets,
    elements: elements,
  );
}

EnvironmentPreset _preset({
  required String id,
  required String templateId,
  List<EnvironmentPaletteItem>? palette,
}) {
  return EnvironmentPreset(
    id: id,
    name: 'n_$id',
    templateId: templateId,
    palette: palette ??
        [
          EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
        ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({
  required String id,
  ElementCollisionProfile? collisionProfile,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'name_$id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    collisionProfile: collisionProfile,
  );
}

void main() {
  group('EnvironmentPresetDiagnosticsReport', () {
    test('vide : pas de diagnostics', () {
      final r = EnvironmentPresetDiagnosticsReport(diagnostics: []);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.hasWarnings, isFalse);
      expect(r.diagnosticCount, 0);
      expect(r.errorCount, 0);
      expect(r.warningCount, 0);
    });

    test('copie défensive et liste immuable exposée', () {
      final raw = <EnvironmentPresetDiagnostic>[
        EnvironmentPresetDiagnostic(
          severity: EnvironmentPresetDiagnosticSeverity.error,
          kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
          presetId: 'x',
          message: 'm',
        ),
      ];
      final r = EnvironmentPresetDiagnosticsReport(diagnostics: raw);
      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
      raw.clear();
      expect(r.diagnosticCount, 1);
    });

    test('errorCount / warningCount / diagnosticCount', () {
      final r = EnvironmentPresetDiagnosticsReport(
        diagnostics: [
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.error,
            kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
            presetId: 'p',
            elementId: 'e',
            message: 'm1',
          ),
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.warning,
            kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
            presetId: 'p',
            templateId: 't',
            message: 'm2',
          ),
        ],
      );
      expect(r.diagnosticCount, 2);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
    });

    test('diagnosticsForPreset trim et vide/inconnu => []', () {
      final r = EnvironmentPresetDiagnosticsReport(
        diagnostics: [
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.error,
            kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
            presetId: 'ab',
            message: 'dup',
          ),
        ],
      );
      expect(r.diagnosticsForPreset('  ab  ').length, 1);
      expect(r.diagnosticsForPreset(''), isEmpty);
      expect(r.diagnosticsForPreset('zz'), isEmpty);
    });

    test('diagnosticsForKind retourne liste immuable', () {
      final d = EnvironmentPresetDiagnostic(
        severity: EnvironmentPresetDiagnosticSeverity.error,
        kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
        presetId: 'p',
        elementId: 'e',
        message: 'm',
      );
      final r = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
      final list = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.missingPaletteElement,
      );
      expect(list.length, 1);
      expect(() => list.add(d), throwsUnsupportedError);
    });

    test('égalité de valeur report et diagnostic', () {
      final d = EnvironmentPresetDiagnostic(
        severity: EnvironmentPresetDiagnosticSeverity.warning,
        kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
        presetId: 'p',
        templateId: 't',
        message: 'msg',
      );
      final r1 = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
      final r2 = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
      expect(r1, equals(r2));
      expect(d == d, isTrue);
    });
  });

  group('diagnoseProjectEnvironmentPresets duplicatePresetId', () {
    test('aucun doublon => rien', () {
      final m = _manifest(
        environmentPresets: [
          _preset(id: 'a', templateId: 't'),
          _preset(id: 'b', templateId: 't'),
        ],
        elements: [_element(id: 'elm_ok')],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      expect(
        r.diagnosticsForKind(EnvironmentPresetDiagnosticKind.duplicatePresetId),
        isEmpty,
      );
    });

    test('deux presets même id => un diagnostic', () {
      final dup = _preset(id: 'forest_dense', templateId: 'tpl');
      final m = _manifest(
        environmentPresets: [dup, dup],
        elements: [_element(id: 'elm_ok')],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      final dups = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.duplicatePresetId,
      );
      expect(dups.length, 1);
      expect(dups.single.presetId, 'forest_dense');
      expect(dups.single.severity, EnvironmentPresetDiagnosticSeverity.error);
      expect(
        dups.single.message,
        'Environment preset "forest_dense" is declared more than once.',
      );
    });

    test('trois presets même id => un seul diagnostic pour cet id', () {
      final p = _preset(id: 'x', templateId: 't');
      final m = _manifest(
        environmentPresets: [p, p, p],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m)
            .diagnosticsForKind(
              EnvironmentPresetDiagnosticKind.duplicatePresetId,
            )
            .length,
        1,
      );
    });

    test('deux ids dupliqués distincts => deux diagnostics ordre stable', () {
      final a = _preset(id: 'a', templateId: 't');
      final b = _preset(id: 'b', templateId: 't');
      final m = _manifest(
        environmentPresets: [a, a, b, b],
        elements: [_element(id: 'elm_ok')],
      );
      final kinds = diagnoseProjectEnvironmentPresets(m)
          .diagnostics
          .map((e) => e.kind)
          .toList();
      expect(
        kinds
            .where(
                (k) => k == EnvironmentPresetDiagnosticKind.duplicatePresetId)
            .length,
        2,
      );
      final dupMsgs = diagnoseProjectEnvironmentPresets(m)
          .diagnosticsForKind(
            EnvironmentPresetDiagnosticKind.duplicatePresetId,
          )
          .map((e) => e.presetId)
          .toList();
      expect(dupMsgs, ['a', 'b']);
    });
  });

  group('missingPaletteElement', () {
    test('element présent => pas missing', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 't')],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.missingPaletteElement,
        ),
        isEmpty,
      );
    });

    test('element absent => error', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'forest_dense',
            name: 'F',
            templateId: 'tpl',
            palette: [
              EnvironmentPaletteItem(elementId: 'oak_tree_large', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      final miss = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.missingPaletteElement,
      );
      expect(miss.length, 1);
      expect(miss.single.elementId, 'oak_tree_large');
      expect(
        miss.single.message,
        'Environment preset "forest_dense" references missing element "oak_tree_large".',
      );
    });

    test('deux presets référencent même absent => un diagnostic par preset',
        () {
      final palette = [
        EnvironmentPaletteItem(elementId: 'ghost', weight: 1),
      ];
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p1',
            name: 'A',
            templateId: 't',
            palette: palette,
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
          EnvironmentPreset(
            id: 'p2',
            name: 'B',
            templateId: 't',
            palette: palette,
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 1,
          ),
        ],
        elements: [],
      );
      final miss = diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.missingPaletteElement,
      );
      expect(miss.length, 2);
      expect(miss.map((e) => e.presetId).toList(), ['p1', 'p2']);
    });
  });

  group('unknownTemplateId', () {
    test('knownTemplateIds vide => aucun unknownTemplateId', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'anything')],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
        ),
        isEmpty,
      );
    });

    test('template connu => rien', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'forest_dense')],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(
          m,
          knownTemplateIds: {'forest_dense'},
        ).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
        ),
        isEmpty,
      );
    });

    test('template inconnu => warning', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'forest_dense_v9')],
        elements: [_element(id: 'elm_ok')],
      );
      final r = diagnoseProjectEnvironmentPresets(
        m,
        knownTemplateIds: {'other'},
      );
      final w = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.unknownTemplateId,
      );
      expect(w.length, 1);
      expect(w.single.templateId, 'forest_dense_v9');
      expect(w.single.severity, EnvironmentPresetDiagnosticSeverity.warning);
      expect(
        w.single.message,
        'Environment preset "p" uses unknown template "forest_dense_v9".',
      );
    });
  });

  group('forcedCollisionWithoutProfile', () {
    test('forceEnabled + collisionProfile non-null => rien', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [
          _element(
            id: 'oak',
            collisionProfile: const ElementCollisionProfile(),
          ),
        ],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });

    test('forceEnabled + collisionProfile null => warning', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'forest_dense',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak_tree_large',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [
          _element(id: 'oak_tree_large', collisionProfile: null),
        ],
      );
      final w = diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
      );
      expect(w.length, 1);
      expect(w.single.elementId, 'oak_tree_large');
      expect(
        w.single.message,
        'Environment preset "forest_dense" forces collision for element "oak_tree_large", but this element has no collision profile.',
      );
    });

    test('useElementDefault + collisionProfile null => rien', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.useElementDefault,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [_element(id: 'oak')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });

    test('forceDisabled + collisionProfile null => rien', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceDisabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [_element(id: 'oak')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });

    test('element absent + forceEnabled => seulement missingPaletteElement',
        () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'missing_el',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      expect(
        r
            .diagnosticsForKind(
              EnvironmentPresetDiagnosticKind.missingPaletteElement,
            )
            .length,
        1,
      );
      expect(
        r.diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });
  });

  group('ordre stable des diagnostics', () {
    test('duplicate puis missing puis forced puis unknown', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'dup',
            name: 'A',
            templateId: 'bad_tpl',
            palette: [
              EnvironmentPaletteItem(elementId: 'missing', weight: 1),
              EnvironmentPaletteItem(
                elementId: 'no_profile',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
          EnvironmentPreset(
            id: 'dup',
            name: 'B',
            templateId: 'bad_tpl',
            palette: [
              EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 1,
          ),
        ],
        elements: [
          _element(id: 'elm_ok'),
          _element(id: 'no_profile', collisionProfile: null),
        ],
      );
      final r = diagnoseProjectEnvironmentPresets(
        m,
        knownTemplateIds: {'known_only'},
      );
      final kinds = r.diagnostics.map((e) => e.kind).toList();
      // duplicatePresetId, puis 1er preset: missing, forced, unknown ; 2e preset: unknown seulement
      expect(
        kinds,
        [
          EnvironmentPresetDiagnosticKind.duplicatePresetId,
          EnvironmentPresetDiagnosticKind.missingPaletteElement,
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
        ],
      );
    });
  });
}
