import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/verification/verification_workspace_page.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';
import 'support/ui13_verification_harness.dart';
import 'support/ui13_widget_verification_port.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 12);
}

VerificationWorkspaceController opened(WidgetTester tester) => tester
    .widget<VerificationWorkspacePage>(find.byType(VerificationWorkspacePage))
    .controller;

void main() {
  testWidgets('a rule opened from the report comes back to that report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = (await tester.runAsync(Ui13VerificationHarness.create))!;
    final visuals = (await tester.runAsync(
      () => StudioMapResources.load(project.session, project.maps.project!),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(project.dispose);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: project.maps,
          loadVisuals: (_, _) async => visuals,
          narrativePort: Ui05NarrativePort(
            LocalNarrativeAdapter(
              session: project.session,
              mapAdapter: project.adapter,
            ),
            tester,
          ),
          worldPort: LocalWorldAdapter(
            session: project.session,
            mapAdapter: project.adapter,
          ),
          verificationPort: Ui13WidgetVerificationPort(project.port, tester),
          onClose: () async {},
          registerExitGuard: (_) {},
          runtimeBuilder: (_, _, _) => const SizedBox(),
        ),
      ),
    );
    await pumpIo(tester);

    await activate(
      tester,
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await activate(tester, find.text('Vérification narrative').first);
    expect(find.byType(VerificationWorkspacePage), findsOneWidget);

    final controller = opened(tester);
    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 40 && controller.report == null; i++) {
      await pumpIo(tester, frames: 3);
    }
    expect(controller.report, isNotNull, reason: controller.error);

    controller
      ..toggleSeverity(NarrativeProjectDiagnosticSeverity.error)
      ..setSearch('conducteur');
    final rule = controller.report!.diagnostics.firstWhere(
      (item) => item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
    );
    controller.select(rule.stableKey);
    await pumpIo(tester, frames: 8);
    expect(find.text('Destination : Règles du monde'), findsOneWidget);

    await activate(tester, find.text('Ouvrir dans l’éditeur'));
    expect(find.byType(WorldWorkspacePage), findsOneWidget);
    final world = tester
        .widget<WorldWorkspacePage>(find.byType(WorldWorkspacePage))
        .controller;
    expect(
      world.selectedRuleId,
      Ui13VerificationHarness.orphanRuleId,
      reason: 'the editor opens on the rule the diagnostic named',
    );
    expect(find.byTooltip('Retour à la vérification'), findsOneWidget);

    await activate(tester, find.byTooltip('Retour à la vérification'));
    expect(find.byType(VerificationWorkspacePage), findsOneWidget);
    expect(
      identical(opened(tester).report, controller.report),
      isTrue,
      reason: 'the return finds the same report, not a fresh page',
    );
    expect(opened(tester).selectedKey, rule.stableKey);
    expect(opened(tester).search, 'conducteur');
    expect(
      opened(tester).severities,
      {NarrativeProjectDiagnosticSeverity.error},
      reason: 'filters survive the detour like the selection does',
    );
    expect(tester.takeException(), isNull);
  });
}
