import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('localizes the publication surface in French and English',
      (tester) async {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
    );

    await _pumpReadiness(
      tester,
      locale: const Locale('fr'),
      profile: profile,
    );
    expect(find.text('Préparation à l’export'), findsOneWidget);
    expect(find.text('Preflight requis'), findsOneWidget);
    expect(find.text('Couleur d’accent invalide'), findsOneWidget);

    await _pumpReadiness(
      tester,
      locale: const Locale('en'),
      profile: profile,
    );
    expect(find.text('Export readiness'), findsOneWidget);
    expect(find.text('Preflight required'), findsOneWidget);
    expect(find.text('Invalid accent color'), findsOneWidget);
    expect(find.text('Run preflight'), findsOneWidget);
    expect(find.text('Continue to export'), findsOneWidget);
  });

  testWidgets('supports keyboard, gamepad activation, and directional focus',
      (tester) async {
    var preflightCount = 0;
    var exportCount = 0;

    await _pumpReadiness(
      tester,
      locale: const Locale('fr'),
      onRunPreflight: () => preflightCount += 1,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(preflightCount, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
    expect(preflightCount, 2);

    await _pumpReadiness(
      tester,
      locale: const Locale('fr'),
      hasCompletedPreflight: true,
      canContinueToExport: true,
      onRunPreflight: () => preflightCount += 1,
      onContinueToExport: () => exportCount += 1,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final focusBeforeDirection = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus, isNot(focusBeforeDirection));
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
    expect(exportCount, 1);
  });

  testWidgets('exposes a live semantic publication status', (tester) async {
    final semantics = tester.ensureSemantics();

    await _pumpReadiness(
      tester,
      locale: const Locale('fr'),
      hasCompletedPreflight: true,
      canContinueToExport: true,
    );

    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>(
                'personalization-readiness-semantics',
              ),
            ),
          )
          .label,
      contains('Préparation à l’export du Personalization Studio'),
    );
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>(
                'personalization-readiness-overall-semantics',
              ),
            ),
          )
          .label,
      contains('Prêt à exporter'),
    );
    semantics.dispose();
  });

  testWidgets('adapts to a narrow window with 200 percent text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpReadiness(
      tester,
      locale: const Locale('en'),
      textScale: 2,
      wrapInScrollView: true,
    );

    expect(tester.takeException(), isNull);
    for (final category in ProjectPresentationCategory.values) {
      expect(
        find.byKey(
          ValueKey<String>('personalization-readiness-${category.name}'),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(
        const ValueKey<String>('personalization-readiness-export'),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpReadiness(
  WidgetTester tester, {
  required Locale locale,
  ProjectPresentationProfile profile = const ProjectPresentationProfile(),
  bool hasCompletedPreflight = false,
  bool canContinueToExport = false,
  VoidCallback? onRunPreflight,
  VoidCallback? onContinueToExport,
  double textScale = 1,
  bool wrapInScrollView = false,
}) {
  final panel = PersonalizationReadinessPanel(
    report: PersonalizationPublishReadiness.fromProfile(profile),
    requiresPreflight: true,
    hasCompletedPreflight: hasCompletedPreflight,
    canContinueToExport: canContinueToExport,
    onRunPreflight: onRunPreflight ?? () {},
    onContinueToExport: onContinueToExport,
  );
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: wrapInScrollView ? SingleChildScrollView(child: panel) : panel,
      ),
    ),
  );
}
