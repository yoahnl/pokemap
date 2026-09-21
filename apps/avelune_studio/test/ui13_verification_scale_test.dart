import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui13_page_harness.dart';

Future<void> launch(WidgetTester tester, Ui13PageHarness h) async {
  await tester.tap(find.text('Lancer la vérification').first);
  for (var i = 0; i < 40 && h.controller.report == null; i++) {
    await pumpIo(tester, frames: 3);
  }
  expect(h.controller.report, isNotNull, reason: h.controller.error);
}

/// A presentation stress fixture. It proves the list stays lazy; it proves
/// nothing about the validator, which never produced these lines.
VerificationReport inflate(VerificationReport real, int count) =>
    VerificationReport(
      requestId: real.requestId,
      sessionId: real.sessionId,
      generatedAt: real.generatedAt,
      validatorVersion: real.validatorVersion,
      inputFingerprint: real.inputFingerprint,
      freshnessKey: real.freshnessKey,
      project: NarrativeProjectValidationReport(
        diagnostics: [
          for (var index = 0; index < count; index++)
            NarrativeProjectDiagnostic(
              code: 'stressSynthetique',
              severity: index.isEven
                  ? NarrativeProjectDiagnosticSeverity.warning
                  : NarrativeProjectDiagnosticSeverity.error,
              domain: NarrativeProjectDiagnosticDomain.scene,
              message: 'Ligne de charge $index, sans valeur métier.',
              path: 'scenes.stress_$index',
              destination: NarrativeProjectDiagnosticDestination.overview,
              sceneId: 'stress_$index',
            ),
        ],
        mapEventViews: const [],
      ),
      dependencies: real.dependencies,
      dimensions: real.dimensions,
      runtime: real.runtime,
      scope: real.scope,
      limitations: real.limitations,
      blockers: real.blockers,
      labels: real.labels,
      includesDrafts: real.includesDrafts,
    );

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1440, 900),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    final width = size.width.toInt();
    testWidgets('UI13 stays usable at $width', (tester) async {
      final compact = width == 1024;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = (await tester.runAsync(() => Ui13PageHarness.create(tester)))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(h.dispose);
      });
      await tester.pumpWidget(h.app(textScale: compact ? 1.5 : 1));
      await pumpIo(tester, frames: 6);
      await launch(tester, h);

      // Launching, choosing a problem and reaching its editor stay in reach.
      expect(find.text('Lancer la vérification').hitTestable(), findsWidgets);
      final first = h.controller.visible.first;
      final row = find.byKey(ValueKey(first.stableKey));
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.tap(row, warnIfMissed: false);
      // A single click waits for the double-click window that opens the editor.
      await tester.pump(const Duration(milliseconds: 400));
      await pumpIo(tester, frames: 8);
      expect(h.controller.selectedKey, first.stableKey);

      if (compact) {
        expect(find.byTooltip('Graphe').hitTestable(), findsOneWidget);
        expect(find.byTooltip('Détail').hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Détail'));
        await pumpIo(tester, frames: 12);
        expect(
          find.text('Ouvrir dans l’éditeur').hitTestable(),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(4, 4));
        await pumpIo(tester, frames: 12);
      } else {
        expect(
          find.text('Ouvrir dans l’éditeur').hitTestable(),
          findsOneWidget,
        );
        expect(find.text('Vue d’ensemble'), findsOneWidget);
      }
      await h.capture(tester, 'ui13-04-taille-$width');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a few thousand lines stay lazy and start no control', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = (await tester.runAsync(() => Ui13PageHarness.create(tester)))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
    await tester.pumpWidget(h.app());
    await pumpIo(tester, frames: 6);
    await launch(tester, h);
    final runs = h.port.runs;

    h.controller.report = inflate(h.controller.report!, 4000);
    h.controller.changed();
    await pumpIo(tester, frames: 8);
    expect(h.controller.visible, hasLength(4000));
    expect(
      find.byKey(const ValueKey('stressSynthetique')),
      findsNothing,
      reason: 'only the visible window is built',
    );
    expect(
      tester.widgetList(find.byType(InkWell)).length,
      lessThan(200),
      reason: 'four thousand diagnostics must not build four thousand rows',
    );

    h.controller.setSearch('Ligne de charge 12');
    await pumpIo(tester, frames: 8);
    expect(h.controller.visible, isNotEmpty);
    h.controller.select(h.controller.visible.first.stableKey);
    await pumpIo(tester, frames: 8);
    expect(
      h.port.runs,
      runs,
      reason: 'filtering and selecting never re-run a control',
    );
    expect(tester.takeException(), isNull);
  });
}
