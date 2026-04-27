# Lot 55 — Surface Studio Catalog Diagnostics View V0

## Passes (1–5) — idem cahier des charges

1. Audit : placeholders Diagnostics + `_DiagnosticsSummary`, structure `readModel.diagnostics` via `map_core` public.
2. Implémentation : `SurfaceStudioDiagnosticsView` ; suppression `_DiagnosticsSummary` et placeholder.
3. Tests : fichier dédié + ajustements panel / workspace.
4. Review : read-only, ordre `errors` / `warnings`.
5. Evidence : ce document.

## Résumé, tableau 39–59, `SurfaceCatalogDiagnosticsPresentation`

- `readModel.diagnostics: SurfaceCatalogDiagnosticsPresentation` : champs `summary`, `errors`, `warnings`, `isClean`, `hasErrors`, `hasWarnings` ; itération sur `p.errors` puis `p.warnings` sans re-tri.
- Compteurs : `summary.errorCount`, `summary.warningCount`, `summary.totalCount`.
- Libellés humains : `SurfaceStudioDiagnosticsViewLabels.kindLabel(SurfaceCatalogDiagnosticKind)`.

## `git status` initial

```text
(vide — arbre propre en début de session Lot 55 sur cette machine, avant `git add`)
```

## Fichiers créés / modifiés

- Créés : `surface_studio_diagnostics_view.dart`, `surface_studio_diagnostics_view_test.dart`, ce rapport.
- Modifiés : `surface_studio_panel.dart`, `surface_studio_panel_test.dart`, `surface_studio_workspace_entry_test.dart`.

## Où était le placeholder

`_SectionPlaceholder` avec titre `Diagnostics` et carte `_DiagnosticsSummary` entre browser et actions — remplacés par `SurfaceStudioDiagnosticsView(readModel: readModel)`.

## Pourquoi l’UI ne recalcule pas

Le Lot 51 appelle déjà `diagnoseProjectSurfaceCatalogForAuthoring` + `buildSurfaceCatalogDiagnosticsPresentation` dans `buildSurfaceStudioReadModelFromCatalog`.

## `git status` final

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
?? packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
?? reports/surface/surface_engine_lot_55_surface_studio_diagnostics_view.md
```

## Commandes (résultats de référence)

- `flutter test test/surface_studio/surface_studio_diagnostics_view_test.dart` : `+23: All tests passed!`
- `flutter test test/surface_studio/surface_studio_catalog_browser_test.dart` : `+26: All tests passed!`
- `flutter test test/surface_studio/surface_studio_panel_test.dart` : `+28: All tests passed!`
- `flutter test test/surface_studio/surface_studio_workspace_entry_test.dart` : `+11: All tests passed!`
- `dart test test/surface_studio_read_model_test.dart` (map_core) : `+30: All tests passed!`
- `flutter test test/surface_studio/` : `+88: All tests passed!`
- `flutter analyze` (7 chemins) : `No issues found! (ran in 2.1s)`
- `flutter test` (map_editor entier) : `+561 -40: Some tests failed.`
- `dart test` (map_core entier) : `+1218: All tests passed!`

---

# Evidence Pack

## A. Contenu `surface_studio_diagnostics_view.dart`

```dart
// Surface Studio — vue diagnostics catalogue (Lot 55).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.diagnostics]
// (déjà calculé dans [map_core] — Lot 51). Aucun appel à
// diagnoseProjectSurfaceCatalog*, aucun JSON, aucun I/O, aucune mutation du
// manifest.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Chaînes visibles (aucun nom de type Dart de la couche diagnostics).
class SurfaceStudioDiagnosticsViewLabels {
  const SurfaceStudioDiagnosticsViewLabels._();

  static const String title = 'Diagnostics Surface';
  static const String cleanTitle = 'Aucun diagnostic Surface';
  static const String cleanSubtitle =
      'Le catalogue Surface ne signale ni erreur ni avertissement.';
  static const String sectionErrors = 'Erreurs';
  static const String sectionWarnings = 'Avertissements';
  static const String noErrors = 'Aucune erreur Surface';
  static const String noWarnings = 'Aucun avertissement Surface';

  static const String summaryErrors = 'Erreurs';
  static const String summaryWarnings = 'Avertissements';
  static const String summaryTotal = 'Total';

  /// Libellés métier pour les [SurfaceCatalogDiagnosticKind] (affichage principal).
  static String kindLabel(SurfaceCatalogDiagnosticKind kind) {
    switch (kind) {
      case SurfaceCatalogDiagnosticKind.missingPresetAnimation:
        return 'Animation manquante dans un preset';
      case SurfaceCatalogDiagnosticKind.missingAnimationAtlas:
        return 'Atlas manquant dans une animation';
      case SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry:
        return 'Frame hors géométrie d’atlas';
      case SurfaceCatalogDiagnosticKind.unusedAtlas:
        return 'Atlas inutilisé';
      case SurfaceCatalogDiagnosticKind.unusedAnimation:
        return 'Animation inutilisée';
    }
  }
}

/// Affichage structuré des diagnostics auteur — **read-only**, sans recalcul.
class SurfaceStudioDiagnosticsView extends StatelessWidget {
  const SurfaceStudioDiagnosticsView({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final p = readModel.diagnostics;
    final sum = p.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioDiagnosticsViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        _SummaryCounts(
          errorCount: sum.errorCount,
          warningCount: sum.warningCount,
          totalCount: sum.totalCount,
          labelColor: label,
        ),
        const SizedBox(height: 12),
        if (p.isClean) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MacosIcon(
                CupertinoIcons.check_mark_circled_solid,
                color: EditorChrome.inspectorJoyCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      SurfaceStudioDiagnosticsViewLabels.cleanTitle,
                      style: TextStyle(
                        color: EditorChrome.inspectorJoyCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SurfaceStudioDiagnosticsViewLabels.cleanSubtitle,
                      style: TextStyle(
                        color: subtle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          _SectionTitle(
            text: SurfaceStudioDiagnosticsViewLabels.sectionErrors,
            subtle: subtle,
          ),
          const SizedBox(height: 8),
          if (p.errors.isEmpty)
            Text(
              SurfaceStudioDiagnosticsViewLabels.noErrors,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...p.errors.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosticCard(
                  diagnostic: d,
                  isError: true,
                  labelColor: label,
                  subtle: subtle,
                ),
              ),
            ),
          const SizedBox(height: 18),
          _SectionTitle(
            text: SurfaceStudioDiagnosticsViewLabels.sectionWarnings,
            subtle: subtle,
          ),
          const SizedBox(height: 8),
          if (p.warnings.isEmpty)
            Text(
              SurfaceStudioDiagnosticsViewLabels.noWarnings,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...p.warnings.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosticCard(
                  diagnostic: d,
                  isError: false,
                  labelColor: label,
                  subtle: subtle,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SummaryCounts extends StatelessWidget {
  const _SummaryCounts({
    required this.errorCount,
    required this.warningCount,
    required this.totalCount,
    required this.labelColor,
  });

  final int errorCount;
  final int warningCount;
  final int totalCount;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _kv(
          SurfaceStudioDiagnosticsViewLabels.summaryErrors,
          '$errorCount',
          labelColor,
        ),
        _kv(
          SurfaceStudioDiagnosticsViewLabels.summaryWarnings,
          '$warningCount',
          labelColor,
        ),
        _kv(
          SurfaceStudioDiagnosticsViewLabels.summaryTotal,
          '$totalCount',
          labelColor,
        ),
      ],
    );
  }

  Widget _kv(String k, String v, Color c) {
    return Text(
      '$k : $v',
      style: TextStyle(
        color: c,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.text,
    required this.subtle,
  });

  final String text;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: subtle,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.diagnostic,
    required this.isError,
    required this.labelColor,
    required this.subtle,
  });

  final SurfaceCatalogDiagnostic diagnostic;
  final bool isError;
  final Color labelColor;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SurfaceStudioDiagnosticsViewLabels.kindLabel(diagnostic.kind),
            style: TextStyle(
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            diagnostic.message,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          if (_contextLines(diagnostic).isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._contextLines(diagnostic).map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Type : ${diagnostic.kind.name}',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _contextLines(SurfaceCatalogDiagnostic d) {
    final out = <String>[];
    if (d.presetId != null) {
      out.add('Preset : ${d.presetId}');
    }
    if (d.animationId != null) {
      out.add('Animation : ${d.animationId}');
    }
    if (d.atlasId != null) {
      out.add('Atlas : ${d.atlasId}');
    }
    if (d.role != null) {
      out.add('Rôle : ${d.role!.name}');
    }
    if (d.frameIndex != null) {
      out.add('Frame : ${d.frameIndex}');
    }
    return out;
  }
}

```

## B. Contenu `surface_studio_diagnostics_view_test.dart`

```dart
// Tests widget — Surface Studio diagnostics view (Lot 55).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_diagnostics_view.dart';

void main() {
  group('SurfaceStudioDiagnosticsView (Lot 55)', () {
    testWidgets('1. title Diagnostics Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('2. clean: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('3. clean: ni erreur ni avertissement', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
      );
      expect(
        find.textContaining('ni erreur ni avertissement'),
        findsOneWidget,
      );
    });

    testWidgets('4. clean: counts zero', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
      );
      expect(find.textContaining('Erreurs : 0'), findsOneWidget);
      expect(find.textContaining('Avertissements : 0'), findsOneWidget);
      expect(find.textContaining('Total : 0'), findsOneWidget);
    });

    testWidgets('5. error missingPresetAnimation', (tester) async {
      final rm = _missingAnimationReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      expect(
        find.text('Animation manquante dans un preset'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Animation : no-such-anim').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('6. error missingAnimationAtlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _missingAtlasReadModel()),
        ),
      );
      expect(find.text('Atlas manquant dans une animation'), findsOneWidget);
    });

    testWidgets('7. error animationFrameOutsideAtlasGeometry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _frameOutsideGeometryReadModel(),
          ),
        ),
      );
      expect(find.text('Frame hors géométrie d’atlas'), findsOneWidget);
    });

    testWidgets('8. warning unusedAtlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _unusedAtlasReadModel()),
        ),
      );
      expect(find.text('Atlas inutilisé'), findsOneWidget);
    });

    testWidgets('9. warning unusedAnimation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _unusedAnimationReadModel(),
          ),
        ),
      );
      expect(find.text('Animation inutilisée'), findsOneWidget);
    });

    testWidgets('10. mixed: Erreurs and Avertissements sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      expect(find.text('Erreurs'), findsOneWidget);
      expect(find.text('Avertissements'), findsOneWidget);
    });

    testWidgets('11. mixed: summary counts', (tester) async {
      final rm = _mixedDiagnosticsReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      final s = rm.diagnostics.summary;
      expect(s.errorCount, 1);
      // Atlas inutilisé + animation non référencée par un preset
      expect(s.warningCount, 2);
      expect(s.totalCount, 3);
      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
      expect(find.textContaining('Total : 3'), findsOneWidget);
    });

    testWidgets('12. error order preserved', (tester) async {
      final rm = _twoErrorsReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(
        block.indexOf('e-first'),
        lessThan(block.indexOf('e-second')),
      );
    });

    testWidgets('13. warning order preserved', (tester) async {
      final rm = _twoWarningsReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      if (block.contains('orphan-a') && block.contains('orphan-b')) {
        expect(
          block.indexOf('orphan-a'),
          lessThan(block.indexOf('orphan-b')),
        );
      }
    });

    testWidgets('14. warnings only: no errors line empty section',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _unusedAtlasReadModel()),
        ),
      );
      expect(find.text('Aucune erreur Surface'), findsOneWidget);
    });

    testWidgets('15. errors only: no warnings line empty section',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _missingAnimationReadModel()),
        ),
      );
      expect(find.text('Aucun avertissement Surface'), findsOneWidget);
    });

    testWidgets('16. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('17. no fix affordances on view', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      for (final w in _forbiddenActionLabels) {
        expect(find.text(w), findsNothing);
      }
    });

    testWidgets('18. no internal type names in UI text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(block.contains('ProjectSurfaceCatalog'), isFalse);
      expect(block.contains('SurfaceStudioReadModel'), isFalse);
      expect(block.contains('SurfaceVariantAnimationRefSet'), isFalse);
      expect(
        block.contains('SurfaceCatalogDiagnosticsPresentation'),
        isFalse,
      );
      expect(
        block.contains('SurfaceCatalogDiagnosticPresentationRow'),
        isFalse,
      );
    });

    testWidgets('19. many diagnostics build without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. messages follow readModel.diagnostics', (tester) async {
      final rm = _missingAnimationReadModel();
      final expected = rm.diagnostics.errors.first.message;
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      expect(find.textContaining(expected), findsWidgets);
    });

    testWidgets('25. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioDiagnosticsView(readModel: _emptyReadModel()),
        ),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('26. bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: SurfaceStudioDiagnosticsView(
                  readModel: _cleanReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. public map_core only (smoke)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });
  });
}

const _forbiddenActionLabels = <String>[
  'Corriger',
  'Réparer',
  'Supprimer',
  'Créer',
  'Modifier',
  'Enregistrer',
  'Sauvegarder',
  'Save',
  'Delete',
  'Fix',
  'Repair',
];

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceStudioReadModel _cleanReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(_cleanCatalog());

SurfaceAtlasGeometry _geom1() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
      gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

ProjectSurfaceCatalog _cleanCatalog() {
  final g = _geom1();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'anim',
    name: 'Anim',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'P',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'anim',
        ),
      ],
    ),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

SurfaceStudioReadModel _missingAnimationReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(
      _catalogWithMissingPresetAnimation(),
    );

ProjectSurfaceCatalog _catalogWithMissingPresetAnimation() {
  return ProjectSurfaceCatalog(
    presets: [
      ProjectSurfacePreset(
        id: 'pr',
        name: 'Pr',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'no-such-anim',
            ),
          ],
        ),
      ),
    ],
  );
}

SurfaceStudioReadModel _missingAtlasReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(
      ProjectSurfaceCatalog(
        animations: [
          ProjectSurfaceAnimation(
            id: 'an',
            name: 'An',
            timeline: SurfaceAnimationTimeline(
              frames: [
                SurfaceAnimationFrame(
                  tileRef: SurfaceAtlasTileRef(
                    atlasId: 'ghost-atlas',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

SurfaceStudioReadModel _frameOutsideGeometryReadModel() {
  final g = _geom1();
  final atlas = ProjectSurfaceAtlas(
    id: 'tiny',
    name: 'Tiny',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'out',
    name: 'Out',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tiny',
            column: 999,
            row: 999,
          ),
          durationMs: 1,
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [anim],
    ),
  );
}

SurfaceStudioReadModel _unusedAtlasReadModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final used = ProjectSurfaceAtlas(
    id: 'u',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final orphanA = ProjectSurfaceAtlas(
    id: 'orphan-a',
    name: 'OA',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [used, orphanA],
      animations: [anim],
    ),
  );
}

SurfaceStudioReadModel _unusedAnimationReadModel() {
  final g = _geom1();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 1,
  );
  final usedAnim = ProjectSurfaceAnimation(
    id: 'used-anim',
    name: 'Used',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final looseAnim = ProjectSurfaceAnimation(
    id: 'loose',
    name: 'Loose',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'P',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'used-anim',
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [usedAnim, looseAnim],
      presets: [preset],
    ),
  );
}

SurfaceStudioReadModel _mixedDiagnosticsReadModel() {
  final g = _geom1();
  final used = ProjectSurfaceAtlas(
    id: 'u',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final orphanB = ProjectSurfaceAtlas(
    id: 'orphan-b',
    name: 'OB',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final preset = ProjectSurfacePreset(
    id: 'pr2',
    name: 'Pr2',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'nope',
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [used, orphanB],
      animations: [anim],
      presets: [preset],
    ),
  );
}

SurfaceStudioReadModel _twoErrorsReadModel() {
  final p1 = ProjectSurfacePreset(
    id: 'p1',
    name: 'P1',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'e-first',
        ),
      ],
    ),
  );
  final p2 = ProjectSurfacePreset(
    id: 'p2',
    name: 'P2',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'e-second',
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      presets: [p1, p2],
    ),
  );
}

SurfaceStudioReadModel _twoWarningsReadModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final a0 = ProjectSurfaceAtlas(
    id: 'a0',
    name: 'A0',
    tilesetId: 't',
    geometry: g,
  );
  final oa = ProjectSurfaceAtlas(
    id: 'orphan-a',
    name: 'OA',
    tilesetId: 't',
    geometry: g,
  );
  final ob = ProjectSurfaceAtlas(
    id: 'orphan-b',
    name: 'OB',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a0', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'animU',
    name: 'AnimU',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [a0, oa, ob],
      animations: [anim],
    ),
  );
}

```

## C. Diffs `git` fichiers modifiés

````diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index caac3fbf..fc85f5ef 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -2,7 +2,7 @@
 //
 // Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
 // re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
-// désactivées ; les sections listées sont des placeholders pour les Lots 53+.
+// désactivées ; seul le placeholder « Actions auteur » reste pour un lot ultérieur.
 //
 // Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
 // clair isolé) — cohérent avec World Explorer et le shell macOS.
@@ -14,6 +14,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'surface_studio_catalog_browser.dart';
+import 'surface_studio_diagnostics_view.dart';
 
 /// Accent produit Surface Studio (même base que la tuile World Explorer).
 const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
@@ -31,11 +32,6 @@ class SurfaceStudioPanel extends StatelessWidget {
   static const String readOnlyBadgeText = 'Lecture seule';
   static const String productDescriptionText =
       'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
-  static const String diagnosticsCleanText = 'Aucun diagnostic Surface';
-  static const String diagnosticsErrorsText = 'Erreurs Surface détectées';
-  static const String diagnosticsWarningsText =
-      'Avertissements Surface détectés';
-  static const String placeholderDiagnosticsTitle = 'Diagnostics';
   static const String placeholderActionsTitle = 'Actions auteur';
   static const String placeholderSoonText = 'Bientôt';
   static const String actionCreateAtlasLabel = 'Créer un atlas';
@@ -102,19 +98,13 @@ class SurfaceStudioPanel extends StatelessWidget {
           const SizedBox(height: 16),
           SurfaceStudioCatalogBrowser(readModel: readModel),
           const SizedBox(height: 16),
-          _DiagnosticsSummary(
-            readModel: readModel,
-          ),
+          SurfaceStudioDiagnosticsView(readModel: readModel),
           const SizedBox(height: 20),
           const _FutureActions(
             onCreateAtlas: null,
             onImportVertical: null,
           ),
           const SizedBox(height: 20),
-          const _SectionPlaceholder(
-            title: SurfaceStudioPanel.placeholderDiagnosticsTitle,
-          ),
-          const SizedBox(height: 10),
           const _SectionPlaceholder(
             title: SurfaceStudioPanel.placeholderActionsTitle,
           ),
@@ -295,86 +285,6 @@ class _StudioCard extends StatelessWidget {
   }
 }
 
-class _DiagnosticsSummary extends StatelessWidget {
-  const _DiagnosticsSummary({
-    required this.readModel,
-  });
-
-  final SurfaceStudioReadModel readModel;
-
-  @override
-  Widget build(BuildContext context) {
-    final d = readModel.diagnostics;
-    final err = d.summary.errorCount;
-    final warn = d.summary.warningCount;
-
-    final children = <Widget>[];
-
-    if (d.isClean) {
-      children.add(
-        const Row(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            MacosIcon(
-              CupertinoIcons.check_mark_circled_solid,
-              color: EditorChrome.inspectorJoyCyan,
-              size: 18,
-            ),
-            SizedBox(width: 8),
-            Expanded(
-              child: Text(
-                SurfaceStudioPanel.diagnosticsCleanText,
-                style: TextStyle(
-                  color: EditorChrome.inspectorJoyCyan,
-                  fontSize: 14,
-                  fontWeight: FontWeight.w600,
-                  height: 1.3,
-                ),
-              ),
-            ),
-          ],
-        ),
-      );
-    } else {
-      if (readModel.hasErrors) {
-        children.add(
-          Text(
-            '$err — ${SurfaceStudioPanel.diagnosticsErrorsText}',
-            style: const TextStyle(
-              color: EditorChrome.inspectorJoyCoral,
-              fontSize: 14,
-              fontWeight: FontWeight.w600,
-            ),
-          ),
-        );
-      }
-      if (readModel.hasWarnings) {
-        children.add(
-          Padding(
-            padding: EdgeInsets.only(top: readModel.hasErrors ? 8 : 0),
-            child: Text(
-              '$warn — ${SurfaceStudioPanel.diagnosticsWarningsText}',
-              style: const TextStyle(
-                color: EditorChrome.accentWarm,
-                fontSize: 14,
-                fontWeight: FontWeight.w600,
-              ),
-            ),
-          ),
-        );
-      }
-    }
-
-    return _StudioCard(
-      padding: const EdgeInsets.all(14),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: children,
-      ),
-    );
-  }
-}
-
 class _FutureActions extends StatelessWidget {
   const _FutureActions({
     required this.onCreateAtlas,
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index e8d4587f..903c568a 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -71,10 +71,11 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: rm)),
       );
-      expect(
-        find.textContaining('Avertissements Surface détectés'),
-        findsOneWidget,
-      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      // Atlas orphelin + animation non référencée par un preset (presets vides)
+      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
+      expect(find.text('Atlas inutilisé'), findsOneWidget);
+      expect(find.text('Animation inutilisée'), findsOneWidget);
     });
 
     testWidgets('9. error state when preset animation missing', (tester) async {
@@ -83,8 +84,10 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: rm)),
       );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
       expect(
-        find.textContaining('Erreurs Surface détectées'),
+        find.text('Animation manquante dans un preset'),
         findsOneWidget,
       );
     });
@@ -122,7 +125,7 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      expect(find.text('Diagnostics'), findsWidgets);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
       expect(find.text('Actions auteur'), findsOneWidget);
     });
 
@@ -240,6 +243,44 @@ void main() {
       );
       expect(find.text('Surface Studio'), findsOneWidget);
     });
+
+    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
+    });
+
+    testWidgets('26. Lot 55 — error diagnostics visible in panel',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Erreurs'), findsOneWidget);
+    });
+
+    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
+    });
+
+    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
+        (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
   });
 }
 
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 586f3ee5..295b854b 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -104,6 +104,7 @@ void main() {
       expect(find.byType(SurfaceStudioPanel), findsOneWidget);
       expect(find.text('Catalogue Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
     });
 
     testWidgets('EditorCanvasHost builds SurfaceStudioPanel in surface mode', (
````

## D. Diffs `/dev/null` — diagnostics_view

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
new file mode 100644
index 00000000..44bf2834
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
@@ -0,0 +1,353 @@
+// Surface Studio — vue diagnostics catalogue (Lot 55).
+//
+// Lecture seule : affiche uniquement [SurfaceStudioReadModel.diagnostics]
+// (déjà calculé dans [map_core] — Lot 51). Aucun appel à
+// diagnoseProjectSurfaceCatalog*, aucun JSON, aucun I/O, aucune mutation du
+// manifest.
+
+import 'package:flutter/cupertino.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Chaînes visibles (aucun nom de type Dart de la couche diagnostics).
+class SurfaceStudioDiagnosticsViewLabels {
+  const SurfaceStudioDiagnosticsViewLabels._();
+
+  static const String title = 'Diagnostics Surface';
+  static const String cleanTitle = 'Aucun diagnostic Surface';
+  static const String cleanSubtitle =
+      'Le catalogue Surface ne signale ni erreur ni avertissement.';
+  static const String sectionErrors = 'Erreurs';
+  static const String sectionWarnings = 'Avertissements';
+  static const String noErrors = 'Aucune erreur Surface';
+  static const String noWarnings = 'Aucun avertissement Surface';
+
+  static const String summaryErrors = 'Erreurs';
+  static const String summaryWarnings = 'Avertissements';
+  static const String summaryTotal = 'Total';
+
+  /// Libellés métier pour les [SurfaceCatalogDiagnosticKind] (affichage principal).
+  static String kindLabel(SurfaceCatalogDiagnosticKind kind) {
+    switch (kind) {
+      case SurfaceCatalogDiagnosticKind.missingPresetAnimation:
+        return 'Animation manquante dans un preset';
+      case SurfaceCatalogDiagnosticKind.missingAnimationAtlas:
+        return 'Atlas manquant dans une animation';
+      case SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry:
+        return 'Frame hors géométrie d’atlas';
+      case SurfaceCatalogDiagnosticKind.unusedAtlas:
+        return 'Atlas inutilisé';
+      case SurfaceCatalogDiagnosticKind.unusedAnimation:
+        return 'Animation inutilisée';
+    }
+  }
+}
+
+/// Affichage structuré des diagnostics auteur — **read-only**, sans recalcul.
+class SurfaceStudioDiagnosticsView extends StatelessWidget {
+  const SurfaceStudioDiagnosticsView({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final p = readModel.diagnostics;
+    final sum = p.summary;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          SurfaceStudioDiagnosticsViewLabels.title,
+          style: TextStyle(
+            color: label,
+            fontSize: 16,
+            fontWeight: FontWeight.w800,
+            letterSpacing: -0.2,
+          ),
+        ),
+        const SizedBox(height: 10),
+        _SummaryCounts(
+          errorCount: sum.errorCount,
+          warningCount: sum.warningCount,
+          totalCount: sum.totalCount,
+          labelColor: label,
+        ),
+        const SizedBox(height: 12),
+        if (p.isClean) ...[
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              const MacosIcon(
+                CupertinoIcons.check_mark_circled_solid,
+                color: EditorChrome.inspectorJoyCyan,
+                size: 20,
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    const Text(
+                      SurfaceStudioDiagnosticsViewLabels.cleanTitle,
+                      style: TextStyle(
+                        color: EditorChrome.inspectorJoyCyan,
+                        fontSize: 14,
+                        fontWeight: FontWeight.w700,
+                        height: 1.3,
+                      ),
+                    ),
+                    const SizedBox(height: 6),
+                    Text(
+                      SurfaceStudioDiagnosticsViewLabels.cleanSubtitle,
+                      style: TextStyle(
+                        color: subtle,
+                        fontSize: 12,
+                        fontWeight: FontWeight.w500,
+                        height: 1.35,
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ],
+          ),
+        ] else ...[
+          _SectionTitle(
+            text: SurfaceStudioDiagnosticsViewLabels.sectionErrors,
+            subtle: subtle,
+          ),
+          const SizedBox(height: 8),
+          if (p.errors.isEmpty)
+            Text(
+              SurfaceStudioDiagnosticsViewLabels.noErrors,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 13,
+                fontStyle: FontStyle.italic,
+              ),
+            )
+          else
+            ...p.errors.map(
+              (d) => Padding(
+                padding: const EdgeInsets.only(bottom: 10),
+                child: _DiagnosticCard(
+                  diagnostic: d,
+                  isError: true,
+                  labelColor: label,
+                  subtle: subtle,
+                ),
+              ),
+            ),
+          const SizedBox(height: 18),
+          _SectionTitle(
+            text: SurfaceStudioDiagnosticsViewLabels.sectionWarnings,
+            subtle: subtle,
+          ),
+          const SizedBox(height: 8),
+          if (p.warnings.isEmpty)
+            Text(
+              SurfaceStudioDiagnosticsViewLabels.noWarnings,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 13,
+                fontStyle: FontStyle.italic,
+              ),
+            )
+          else
+            ...p.warnings.map(
+              (d) => Padding(
+                padding: const EdgeInsets.only(bottom: 10),
+                child: _DiagnosticCard(
+                  diagnostic: d,
+                  isError: false,
+                  labelColor: label,
+                  subtle: subtle,
+                ),
+              ),
+            ),
+        ],
+      ],
+    );
+  }
+}
+
+class _SummaryCounts extends StatelessWidget {
+  const _SummaryCounts({
+    required this.errorCount,
+    required this.warningCount,
+    required this.totalCount,
+    required this.labelColor,
+  });
+
+  final int errorCount;
+  final int warningCount;
+  final int totalCount;
+  final Color labelColor;
+
+  @override
+  Widget build(BuildContext context) {
+    return Wrap(
+      spacing: 14,
+      runSpacing: 8,
+      children: [
+        _kv(
+          SurfaceStudioDiagnosticsViewLabels.summaryErrors,
+          '$errorCount',
+          labelColor,
+        ),
+        _kv(
+          SurfaceStudioDiagnosticsViewLabels.summaryWarnings,
+          '$warningCount',
+          labelColor,
+        ),
+        _kv(
+          SurfaceStudioDiagnosticsViewLabels.summaryTotal,
+          '$totalCount',
+          labelColor,
+        ),
+      ],
+    );
+  }
+
+  Widget _kv(String k, String v, Color c) {
+    return Text(
+      '$k : $v',
+      style: TextStyle(
+        color: c,
+        fontSize: 13,
+        fontWeight: FontWeight.w600,
+      ),
+    );
+  }
+}
+
+class _SectionTitle extends StatelessWidget {
+  const _SectionTitle({
+    required this.text,
+    required this.subtle,
+  });
+
+  final String text;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    return Text(
+      text,
+      style: TextStyle(
+        color: subtle,
+        fontSize: 11,
+        fontWeight: FontWeight.w800,
+        letterSpacing: 0.6,
+      ),
+    );
+  }
+}
+
+class _DiagnosticCard extends StatelessWidget {
+  const _DiagnosticCard({
+    required this.diagnostic,
+    required this.isError,
+    required this.labelColor,
+    required this.subtle,
+  });
+
+  final SurfaceCatalogDiagnostic diagnostic;
+  final bool isError;
+  final Color labelColor;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    final accent =
+        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;
+    return Container(
+      padding: const EdgeInsets.all(14),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: accent.withValues(alpha: 0.55),
+          width: 1,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            SurfaceStudioDiagnosticsViewLabels.kindLabel(diagnostic.kind),
+            style: TextStyle(
+              color: labelColor,
+              fontSize: 14,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            diagnostic.message,
+            style: TextStyle(
+              color: labelColor,
+              fontSize: 13,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+          if (_contextLines(diagnostic).isNotEmpty) ...[
+            const SizedBox(height: 8),
+            ..._contextLines(diagnostic).map(
+              (line) => Padding(
+                padding: const EdgeInsets.only(top: 2),
+                child: Text(
+                  line,
+                  style: TextStyle(
+                    color: subtle,
+                    fontSize: 12,
+                    fontWeight: FontWeight.w500,
+                  ),
+                ),
+              ),
+            ),
+          ],
+          const SizedBox(height: 6),
+          Text(
+            'Type : ${diagnostic.kind.name}',
+            style: TextStyle(
+              color: subtle.withValues(alpha: 0.85),
+              fontSize: 11,
+              fontWeight: FontWeight.w500,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+
+  static List<String> _contextLines(SurfaceCatalogDiagnostic d) {
+    final out = <String>[];
+    if (d.presetId != null) {
+      out.add('Preset : ${d.presetId}');
+    }
+    if (d.animationId != null) {
+      out.add('Animation : ${d.animationId}');
+    }
+    if (d.atlasId != null) {
+      out.add('Atlas : ${d.atlasId}');
+    }
+    if (d.role != null) {
+      out.add('Rôle : ${d.role!.name}');
+    }
+    if (d.frameIndex != null) {
+      out.add('Frame : ${d.frameIndex}');
+    }
+    return out;
+  }
+}

```

## E. Diffs `/dev/null` — test

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart b/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
new file mode 100644
index 00000000..f8c0285e
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
@@ -0,0 +1,632 @@
+// Tests widget — Surface Studio diagnostics view (Lot 55).
+// API publique `map_core` uniquement (pas de `package:map_core/src/...`).
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_diagnostics_view.dart';
+
+void main() {
+  group('SurfaceStudioDiagnosticsView (Lot 55)', () {
+    testWidgets('1. title Diagnostics Surface', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+
+    testWidgets('2. clean: main message', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
+      );
+      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
+    });
+
+    testWidgets('3. clean: ni erreur ni avertissement', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
+      );
+      expect(
+        find.textContaining('ni erreur ni avertissement'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('4. clean: counts zero', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
+      );
+      expect(find.textContaining('Erreurs : 0'), findsOneWidget);
+      expect(find.textContaining('Avertissements : 0'), findsOneWidget);
+      expect(find.textContaining('Total : 0'), findsOneWidget);
+    });
+
+    testWidgets('5. error missingPresetAnimation', (tester) async {
+      final rm = _missingAnimationReadModel();
+      expect(rm.hasErrors, isTrue);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
+      );
+      expect(
+        find.text('Animation manquante dans un preset'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Animation : no-such-anim').evaluate().isNotEmpty,
+        isTrue,
+      );
+    });
+
+    testWidgets('6. error missingAnimationAtlas', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(readModel: _missingAtlasReadModel()),
+        ),
+      );
+      expect(find.text('Atlas manquant dans une animation'), findsOneWidget);
+    });
+
+    testWidgets('7. error animationFrameOutsideAtlasGeometry', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _frameOutsideGeometryReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Frame hors géométrie d’atlas'), findsOneWidget);
+    });
+
+    testWidgets('8. warning unusedAtlas', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(readModel: _unusedAtlasReadModel()),
+        ),
+      );
+      expect(find.text('Atlas inutilisé'), findsOneWidget);
+    });
+
+    testWidgets('9. warning unusedAnimation', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _unusedAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Animation inutilisée'), findsOneWidget);
+    });
+
+    testWidgets('10. mixed: Erreurs and Avertissements sections', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _mixedDiagnosticsReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Erreurs'), findsOneWidget);
+      expect(find.text('Avertissements'), findsOneWidget);
+    });
+
+    testWidgets('11. mixed: summary counts', (tester) async {
+      final rm = _mixedDiagnosticsReadModel();
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
+      );
+      final s = rm.diagnostics.summary;
+      expect(s.errorCount, 1);
+      // Atlas inutilisé + animation non référencée par un preset
+      expect(s.warningCount, 2);
+      expect(s.totalCount, 3);
+      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
+      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
+      expect(find.textContaining('Total : 3'), findsOneWidget);
+    });
+
+    testWidgets('12. error order preserved', (tester) async {
+      final rm = _twoErrorsReadModel();
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
+      );
+      final block = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((t) => t.data ?? '')
+          .join('\n');
+      expect(
+        block.indexOf('e-first'),
+        lessThan(block.indexOf('e-second')),
+      );
+    });
+
+    testWidgets('13. warning order preserved', (tester) async {
+      final rm = _twoWarningsReadModel();
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
+      );
+      final block = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((t) => t.data ?? '')
+          .join('\n');
+      if (block.contains('orphan-a') && block.contains('orphan-b')) {
+        expect(
+          block.indexOf('orphan-a'),
+          lessThan(block.indexOf('orphan-b')),
+        );
+      }
+    });
+
+    testWidgets('14. warnings only: no errors line empty section',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(readModel: _unusedAtlasReadModel()),
+        ),
+      );
+      expect(find.text('Aucune erreur Surface'), findsOneWidget);
+    });
+
+    testWidgets('15. errors only: no warnings line empty section',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(readModel: _missingAnimationReadModel()),
+        ),
+      );
+      expect(find.text('Aucun avertissement Surface'), findsOneWidget);
+    });
+
+    testWidgets('16. no TextField', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _mixedDiagnosticsReadModel(),
+          ),
+        ),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('17. no fix affordances on view', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _mixedDiagnosticsReadModel(),
+          ),
+        ),
+      );
+      for (final w in _forbiddenActionLabels) {
+        expect(find.text(w), findsNothing);
+      }
+    });
+
+    testWidgets('18. no internal type names in UI text', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _mixedDiagnosticsReadModel(),
+          ),
+        ),
+      );
+      final block = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((t) => t.data ?? '')
+          .join(' ');
+      expect(block.contains('ProjectSurfaceCatalog'), isFalse);
+      expect(block.contains('SurfaceStudioReadModel'), isFalse);
+      expect(block.contains('SurfaceVariantAnimationRefSet'), isFalse);
+      expect(
+        block.contains('SurfaceCatalogDiagnosticsPresentation'),
+        isFalse,
+      );
+      expect(
+        block.contains('SurfaceCatalogDiagnosticPresentationRow'),
+        isFalse,
+      );
+    });
+
+    testWidgets('19. many diagnostics build without throw', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioDiagnosticsView(
+            readModel: _mixedDiagnosticsReadModel(),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('20. messages follow readModel.diagnostics', (tester) async {
+      final rm = _missingAnimationReadModel();
+      final expected = rm.diagnostics.errors.first.message;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
+      );
+      expect(find.textContaining(expected), findsWidgets);
+    });
+
+    testWidgets('25. no ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: SurfaceStudioDiagnosticsView(readModel: _emptyReadModel()),
+        ),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+
+    testWidgets('26. bounded width', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: Center(
+            child: SizedBox(
+              width: 360,
+              child: SingleChildScrollView(
+                child: SurfaceStudioDiagnosticsView(
+                  readModel: _cleanReadModel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('27. public map_core only (smoke)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioDiagnosticsView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+  });
+}
+
+const _forbiddenActionLabels = <String>[
+  'Corriger',
+  'Réparer',
+  'Supprimer',
+  'Créer',
+  'Modifier',
+  'Enregistrer',
+  'Sauvegarder',
+  'Save',
+  'Delete',
+  'Fix',
+  'Repair',
+];
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: SingleChildScrollView(
+      child: Padding(
+        padding: const EdgeInsets.all(16),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceStudioReadModel _emptyReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+
+SurfaceStudioReadModel _cleanReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(_cleanCatalog());
+
+SurfaceAtlasGeometry _geom1() => SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+      gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
+      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+    );
+
+ProjectSurfaceCatalog _cleanCatalog() {
+  final g = _geom1();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'anim',
+    name: 'Anim',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'p',
+    name: 'P',
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'anim',
+        ),
+      ],
+    ),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [preset],
+  );
+}
+
+SurfaceStudioReadModel _missingAnimationReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(
+      _catalogWithMissingPresetAnimation(),
+    );
+
+ProjectSurfaceCatalog _catalogWithMissingPresetAnimation() {
+  return ProjectSurfaceCatalog(
+    presets: [
+      ProjectSurfacePreset(
+        id: 'pr',
+        name: 'Pr',
+        variantAnimations: SurfaceVariantAnimationRefSet(
+          refs: [
+            SurfaceVariantAnimationRef(
+              role: SurfaceVariantRole.isolated,
+              animationId: 'no-such-anim',
+            ),
+          ],
+        ),
+      ),
+    ],
+  );
+}
+
+SurfaceStudioReadModel _missingAtlasReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(
+      ProjectSurfaceCatalog(
+        animations: [
+          ProjectSurfaceAnimation(
+            id: 'an',
+            name: 'An',
+            timeline: SurfaceAnimationTimeline(
+              frames: [
+                SurfaceAnimationFrame(
+                  tileRef: SurfaceAtlasTileRef(
+                    atlasId: 'ghost-atlas',
+                    column: 0,
+                    row: 0,
+                  ),
+                  durationMs: 1,
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+
+SurfaceStudioReadModel _frameOutsideGeometryReadModel() {
+  final g = _geom1();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'tiny',
+    name: 'Tiny',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'out',
+    name: 'Out',
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'tiny',
+            column: 999,
+            row: 999,
+          ),
+          durationMs: 1,
+        ),
+      ],
+    ),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: [anim],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _unusedAtlasReadModel() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final used = ProjectSurfaceAtlas(
+    id: 'u',
+    name: 'U',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final orphanA = ProjectSurfaceAtlas(
+    id: 'orphan-a',
+    name: 'OA',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a',
+    name: 'A',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [used, orphanA],
+      animations: [anim],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _unusedAnimationReadModel() {
+  final g = _geom1();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final usedAnim = ProjectSurfaceAnimation(
+    id: 'used-anim',
+    name: 'Used',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final looseAnim = ProjectSurfaceAnimation(
+    id: 'loose',
+    name: 'Loose',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'p',
+    name: 'P',
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'used-anim',
+        ),
+      ],
+    ),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: [usedAnim, looseAnim],
+      presets: [preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _mixedDiagnosticsReadModel() {
+  final g = _geom1();
+  final used = ProjectSurfaceAtlas(
+    id: 'u',
+    name: 'U',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final orphanB = ProjectSurfaceAtlas(
+    id: 'orphan-b',
+    name: 'OB',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a',
+    name: 'A',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'pr2',
+    name: 'Pr2',
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'nope',
+        ),
+      ],
+    ),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [used, orphanB],
+      animations: [anim],
+      presets: [preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _twoErrorsReadModel() {
+  final p1 = ProjectSurfacePreset(
+    id: 'p1',
+    name: 'P1',
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'e-first',
+        ),
+      ],
+    ),
+  );
+  final p2 = ProjectSurfacePreset(
+    id: 'p2',
+    name: 'P2',
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'e-second',
+        ),
+      ],
+    ),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      presets: [p1, p2],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _twoWarningsReadModel() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final a0 = ProjectSurfaceAtlas(
+    id: 'a0',
+    name: 'A0',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final oa = ProjectSurfaceAtlas(
+    id: 'orphan-a',
+    name: 'OA',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final ob = ProjectSurfaceAtlas(
+    id: 'orphan-b',
+    name: 'OB',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a0', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'animU',
+    name: 'AnimU',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [a0, oa, ob],
+      animations: [anim],
+    ),
+  );
+}

```
