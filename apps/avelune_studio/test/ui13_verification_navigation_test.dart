import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/features/verification/verification_workspace_page.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';
import 'support/ui06_scene_fixture.dart';
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

/// The real host with the ports the application wires, opened on the report.
Future<Ui13VerificationHarness> host(WidgetTester tester) async {
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
        scenePort: LocalSceneAdapter(
          session: project.session,
          mapAdapter: project.adapter,
        ),
        storyPort: LocalStoryAdapter(
          session: project.session,
          mapAdapter: project.adapter,
        ),
        dialoguePort: LocalDialogueAdapter(
          session: project.session,
          mapAdapter: project.adapter,
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
  return project;
}

/// The same report plus one diagnostic. The validators produce none for this
/// destination on this fixture; the opening and the return are the real ones.
VerificationReport withExtra(
  VerificationReport report,
  NarrativeProjectDiagnostic extra,
) => VerificationReport(
  requestId: report.requestId,
  savedRevision: report.savedRevision,
  generatedAt: report.generatedAt,
  validatorVersion: report.validatorVersion,
  inputFingerprint: report.inputFingerprint,
  freshnessKey: report.freshnessKey,
  isolateName: report.isolateName,
  project: NarrativeProjectValidationReport(
    diagnostics: [...report.diagnostics, extra],
    mapEventViews: const [],
  ),
  dependencies: report.dependencies,
  dimensions: report.dimensions,
  runtime: report.runtime,
  scope: report.scope,
  limitations: report.limitations,
  blockers: report.blockers,
  exclusions: report.exclusions,
  labels: report.labels,
  drafted: report.drafted,
);

Future<void> openSelected(WidgetTester tester) async {
  await pumpIo(tester, frames: 6);
  await activate(tester, find.text('Ouvrir dans l’éditeur'));
}

void main() {
  testWidgets('a rule opened from the report comes back to that report', (
    tester,
  ) async {
    await host(tester);
    final controller = opened(tester);
    controller
      ..toggleSeverity(NarrativeProjectDiagnosticSeverity.error)
      ..setSearch('conducteur');
    final rule = controller.report!.diagnostics.firstWhere(
      (item) => item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
    );
    controller.select(rule.stableKey);
    await openSelected(tester);

    expect(find.byType(WorldWorkspacePage), findsOneWidget);
    expect(
      tester
          .widget<WorldWorkspacePage>(find.byType(WorldWorkspacePage))
          .controller
          .selectedRuleId,
      Ui13VerificationHarness.orphanRuleId,
    );

    await activate(tester, find.byTooltip('Retour à la vérification'));
    expect(find.byType(VerificationWorkspacePage), findsOneWidget);
    expect(identical(opened(tester).report, controller.report), isTrue);
    expect(opened(tester).selectedKey, rule.stableKey);
    expect(opened(tester).search, 'conducteur');
    expect(opened(tester).severities, {
      NarrativeProjectDiagnosticSeverity.error,
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('a story diagnostic opens its own step and comes back', (
    tester,
  ) async {
    await host(tester);
    final controller = opened(tester);
    final step = controller.report!.diagnostics.firstWhere(
      (item) =>
          item.destination == NarrativeProjectDiagnosticDestination.storyline &&
          (item.stepId ?? '').isNotEmpty,
    );
    controller
      ..setSearch('étape')
      ..select(step.stableKey);
    await pumpIo(tester, frames: 6);
    expect(
      find.textContaining('étape ciblée'),
      findsOneWidget,
      reason: 'the page only promises the precision it has',
    );

    await openSelected(tester);
    expect(find.byType(StoryProgressionPage), findsOneWidget);
    final page = tester.widget<StoryProgressionPage>(
      find.byType(StoryProgressionPage),
    );
    expect(page.controller.activeId, step.storylineId);
    final view = page.views.forStory(
      page.controller.project,
      step.storylineId!,
    );
    expect(
      view.selection?.node?.stepId,
      step.stepId,
      reason: 'the diagnostic named a step, so that step is selected',
    );

    await activate(tester, find.text('Vérification'));
    expect(
      find.byType(VerificationWorkspacePage),
      findsOneWidget,
      reason: 'the return finds the report, not the Histoire hub',
    );
    expect(identical(opened(tester).report, controller.report), isTrue);
    expect(opened(tester).selectedKey, step.stableKey);
    expect(opened(tester).search, 'étape');
    expect(tester.takeException(), isNull);
  });

  testWidgets('verification, scene, dialogue, scene and back again', (
    tester,
  ) async {
    await host(tester);
    final controller = opened(tester);
    final scene = NarrativeProjectDiagnostic(
      code: 'sceneSynthetique',
      severity: NarrativeProjectDiagnosticSeverity.warning,
      domain: NarrativeProjectDiagnosticDomain.scene,
      message: 'Cas de destination.',
      path: 'scenes.${Ui06SceneFixture.sceneId}',
      destination: NarrativeProjectDiagnosticDestination.scene,
      sceneId: Ui06SceneFixture.sceneId,
    );
    controller
      ..report = withExtra(controller.report!, scene)
      ..select(scene.stableKey);
    final kept = controller.report;
    await openSelected(tester);
    expect(find.byType(SceneBuilderPage), findsOneWidget);

    final scenePage = tester.widget<SceneBuilderPage>(
      find.byType(SceneBuilderPage),
    );
    scenePage.views.forScene(Ui06SceneFixture.sceneId).nodeId = 'welcome';
    scenePage.controller.changed();
    await pumpIo(tester, frames: 8);
    await activate(tester, find.text('Ouvrir le dialogue'));
    expect(find.byType(DialogueWorkspacePage), findsOneWidget);

    await activate(tester, find.text('Retour à la scène'));
    expect(
      find.byType(SceneBuilderPage),
      findsOneWidget,
      reason: 'the dialogue returns to the scene it came from',
    );

    await activate(tester, find.text('Vérification'));
    expect(
      find.byType(VerificationWorkspacePage),
      findsOneWidget,
      reason: 'the second detour did not overwrite where the scene came from',
    );
    expect(identical(opened(tester).report, kept), isTrue);
    expect(opened(tester).selectedKey, scene.stableKey);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a map diagnostic opens its map and offers the way back', (
    tester,
  ) async {
    final project = await host(tester);
    final controller = opened(tester);
    final report = controller.report!;
    final mapId = project.maps.project!.maps.first.id;
    // The validators produce no map diagnostic on this fixture; the
    // destination, the opening and the return are the real ones.
    final diagnostic = NarrativeProjectDiagnostic(
      code: 'carteSynthetique',
      severity: NarrativeProjectDiagnosticSeverity.warning,
      domain: NarrativeProjectDiagnosticDomain.map,
      message: 'Cas de destination.',
      path: 'maps.$mapId',
      destination: NarrativeProjectDiagnosticDestination.map,
      mapId: mapId,
    );
    controller.report = withExtra(report, diagnostic);
    final kept = controller.report;
    controller.select(diagnostic.stableKey);
    await openSelected(tester);

    expect(find.byType(VerificationWorkspacePage), findsNothing);
    await activate(tester, find.text('Retour à la vérification'));
    expect(find.byType(VerificationWorkspacePage), findsOneWidget);
    expect(identical(opened(tester).report, kept), isTrue);
    expect(opened(tester).selectedKey, diagnostic.stableKey);
    expect(tester.takeException(), isNull);
  });
}
