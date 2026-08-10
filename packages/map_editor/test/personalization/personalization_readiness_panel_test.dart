import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

void main() {
  testWidgets('renders a quick readiness table for every category',
      (tester) async {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
      theme: safeProjectSemanticTheme,
    );
    final report = PersonalizationPublishReadiness.fromProfile(profile);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationReadinessPanel(
            report: report,
          ),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('personalization-readiness-panel'),
      ),
      findsOneWidget,
    );
    expect(find.text('Préparation à l’export'), findsOneWidget);
    expect(find.text('Export bloqué'), findsOneWidget);
    for (final category in ProjectPresentationCategory.values) {
      expect(
        find.byKey(
          ValueKey<String>('personalization-readiness-${category.name}'),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('À corriger'), findsOneWidget);
    expect(
      find.text('Prêt'),
      findsNWidgets(
        report.categories
            .where(
              (category) =>
                  category.status == PersonalizationReadinessStatus.ready,
            )
            .length,
      ),
    );
  });

  testWidgets('explains blockers and exposes a direct correction action',
      (tester) async {
    PersonalizationReadinessIssue? correctedIssue;
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationReadinessPanel(
            report: PersonalizationPublishReadiness.fromProfile(profile),
            onCorrectIssue: (issue) => correctedIssue = issue,
          ),
        ),
      ),
    );

    expect(find.text('Corrections recommandées'), findsOneWidget);
    expect(find.text('Couleur d’accent invalide'), findsOneWidget);
    expect(
      find.text(
        'La couleur d’accent doit utiliser une valeur hexadécimale, '
        'par exemple #6750A4.',
      ),
      findsOneWidget,
    );

    final correction = find.byKey(
      const ValueKey<String>('personalization-readiness-correction-0'),
    );
    await tester.ensureVisible(correction);
    expect(correction.hitTestable(), findsOneWidget);
    await tester.tap(correction);

    expect(correctedIssue?.category, ProjectPresentationCategory.branding);
  });

  testWidgets('runs preflight and distinguishes stale or unsaved results',
      (tester) async {
    var runCount = 0;
    var saveCount = 0;
    final report = PersonalizationPublishReadiness.fromProfile(
      const ProjectPresentationProfile(),
    );

    Future<void> pumpPanel({
      required bool completed,
      bool running = false,
      bool stale = false,
      bool dirty = false,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            theme: PokeMapTheme.light(),
            home: Scaffold(
              body: PersonalizationReadinessPanel(
                report: report,
                requiresPreflight: true,
                hasCompletedPreflight: completed,
                isPreflightRunning: running,
                isPreflightStale: stale,
                hasUnsavedChanges: dirty,
                onRunPreflight: () => runCount += 1,
                onSaveDraft: () => saveCount += 1,
              ),
            ),
          ),
        );

    await pumpPanel(completed: false);
    expect(find.text('Preflight requis'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-readiness-run-preflight'),
      ),
    );
    expect(runCount, 1);

    await pumpPanel(completed: false, running: true);
    expect(find.text('Vérification en cours…'), findsWidgets);

    await pumpPanel(completed: true, stale: true);
    expect(find.text('Preflight à relancer'), findsOneWidget);

    await pumpPanel(completed: true, dirty: true);
    expect(find.text('Brouillon à enregistrer'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-readiness-save-draft'),
      ),
    );
    expect(saveCount, 1);
  });

  testWidgets('gates the guided export transition on a certified clean report',
      (tester) async {
    var exportCount = 0;
    final report = PersonalizationPublishReadiness.fromProfile(
      const ProjectPresentationProfile(),
    );

    Future<void> pumpPanel({
      required bool completed,
      required bool canContinue,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            theme: PokeMapTheme.light(),
            home: Scaffold(
              body: PersonalizationReadinessPanel(
                report: report,
                requiresPreflight: true,
                hasCompletedPreflight: completed,
                canContinueToExport: canContinue,
                onRunPreflight: () {},
                onContinueToExport: () => exportCount += 1,
              ),
            ),
          ),
        );

    await pumpPanel(completed: false, canContinue: false);
    var exportButton = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-readiness-export'),
      ),
    );
    expect(exportButton.onPressed, isNull);

    await pumpPanel(completed: true, canContinue: true);
    exportButton = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-readiness-export'),
      ),
    );
    expect(exportButton.onPressed, isNotNull);
    final export = find.byKey(
      const ValueKey<String>('personalization-readiness-export'),
    );
    await tester.ensureVisible(export);
    expect(export.hitTestable(), findsOneWidget);
    await tester.tap(export);
    expect(exportCount, 1);
  });
}
