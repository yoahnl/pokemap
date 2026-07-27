import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('renders a quick readiness table for every category',
      (tester) async {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
      theme: safeProjectSemanticTheme,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationReadinessPanel(
            report: PersonalizationPublishReadiness.fromProfile(profile),
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
    expect(find.text('Prêt'), findsNWidgets(3));
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

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-readiness-correction-0'),
      ),
    );

    expect(correctedIssue?.category, ProjectPresentationCategory.branding);
  });
}
