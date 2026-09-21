import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/features/verification/verification_workspace_page.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui06_scene_fixture.dart';
import 'support/ui13_host_harness.dart';
import 'support/ui13_verification_harness.dart';

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
