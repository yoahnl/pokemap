import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui06_scene_fixture.dart';
import 'support/ui13_verification_harness.dart';
import 'support/verification_report_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<(Ui13VerificationHarness, WorkspaceNavigationSession)> open() async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await root.create(recursive: true);
    final h = await Ui13VerificationHarness.create(parent: root);
    addTearDown(h.dispose);
    final stories = StoryWorkspaceController(
      h.narrative,
      LocalStoryAdapter(session: h.session, mapAdapter: h.adapter),
      changed: () {},
    );
    addTearDown(stories.dispose);
    final navigation = WorkspaceNavigationSession(
      controller: h.maps,
      isActive: () => true,
      changed: () {},
      scenes: () => h.scenes,
      dialogues: () => h.dialogues,
      world: () => h.world,
      stories: () => stories,
      verification: () => h.verification,
    );
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    navigation.show(WorkspaceSpace.verification);
    return (h, navigation);
  }

  test(
    'a rule opened from the report comes back to that same report and filters',
    () async {
      final (h, navigation) = await open();
      final controller = h.verification;
      controller
        ..toggleSeverity(NarrativeProjectDiagnosticSeverity.error)
        ..setSearch('conducteur');
      final report = controller.report;
      final rule = report!.diagnostics.firstWhere(
        (item) => item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
      );
      controller.select(rule.stableKey);
      await navigation.openDiagnostic(rule);
      expect(navigation.space, WorkspaceSpace.world);
      expect(h.world.selectedRuleId, Ui13VerificationHarness.orphanRuleId);
      expect(navigation.worldRules, isTrue);
      expect(navigation.worldOrigin.space, WorkspaceSpace.verification);
      navigation.returnFromWorld();
      expect(navigation.space, WorkspaceSpace.verification);
      expect(controller.report, same(report));
      expect(controller.selectedKey, rule.stableKey);
      expect(controller.search, 'conducteur');
      expect(controller.severities, {NarrativeProjectDiagnosticSeverity.error});
    },
  );

  test('a story diagnostic opens its own step and returns without rebuilding its report', () async {
    final (h, navigation) = await open();
    final controller = h.verification;
    final report = controller.report;
    final step = report!.diagnostics.firstWhere(
      (item) =>
          item.destination == NarrativeProjectDiagnosticDestination.storyline &&
          (item.stepId ?? '').isNotEmpty,
    );
    controller
      ..setSearch('étape')
      ..select(step.stableKey);
    await navigation.openDiagnostic(step);
    expect(navigation.space, WorkspaceSpace.progression);
    expect(navigation.stories!.call()!.activeId, step.storylineId);
    expect(navigation.progressionNodes[step.storylineId]?.stepId, step.stepId);
    navigation.returnFromProgression();
    expect(navigation.space, WorkspaceSpace.verification);
    expect(controller.report, same(report));
    expect(controller.selectedKey, step.stableKey);
    expect(controller.search, 'étape');
  });

  test('verification, scene, dialogue, scene and back preserve the original diagnostic', () async {
    final (h, navigation) = await open();
    final controller = h.verification;
    final diagnostic = NarrativeProjectDiagnostic(
      code: 'sceneSynthetique',
      severity: NarrativeProjectDiagnosticSeverity.warning,
      domain: NarrativeProjectDiagnosticDomain.scene,
      message: 'Cas de destination.',
      path: 'scenes.${Ui06SceneFixture.sceneId}',
      destination: NarrativeProjectDiagnosticDestination.scene,
      sceneId: Ui06SceneFixture.sceneId,
    );
    controller
      ..report = withExtra(controller.report!, diagnostic)
      ..select(diagnostic.stableKey);
    final report = controller.report;
    await navigation.openDiagnostic(diagnostic);
    expect(navigation.space, WorkspaceSpace.scene);
    expect(h.scenes.active!.current.id, Ui06SceneFixture.sceneId);
    navigation.selectSceneNode(h.scenes.active!.current, 'welcome');
    final node = h.scenes.active!.current.graph.nodes.firstWhere(
      (node) => node.id == 'welcome',
    );
    final payload = node.payload as SceneYarnDialoguePayload;
    expect(
      await navigation.openDialogue(
        payload.dialogueId,
        WorkspaceSpace.scene,
        startNode: payload.yarnNodeName,
      ),
      isNull,
    );
    expect(navigation.space, WorkspaceSpace.dialogue);
    expect(h.dialogues.active!.entry.id, payload.dialogueId);
    navigation.returnFromDialogue();
    expect(navigation.space, WorkspaceSpace.scene);
    expect(navigation.sceneNodes[Ui06SceneFixture.sceneId], 'welcome');
    expect(navigation.sceneOrigin.space, WorkspaceSpace.verification);
    navigation.show(navigation.sceneOrigin.space);
    expect(navigation.space, WorkspaceSpace.verification);
    expect(controller.report, same(report));
    expect(controller.selectedKey, diagnostic.stableKey);
  });

  test(
    'a map diagnostic opens its map and retains its report on return',
    () async {
      final (h, navigation) = await open();
      final controller = h.verification;
      final mapId = h.maps.project!.maps.first.id;
      final diagnostic = NarrativeProjectDiagnostic(
        code: 'carteSynthetique',
        severity: NarrativeProjectDiagnosticSeverity.warning,
        domain: NarrativeProjectDiagnosticDomain.map,
        message: 'Cas de destination.',
        path: 'maps.$mapId',
        destination: NarrativeProjectDiagnosticDestination.map,
        mapId: mapId,
      );
      controller
        ..report = withExtra(controller.report!, diagnostic)
        ..select(diagnostic.stableKey);
      final report = controller.report;
      await navigation.openDiagnostic(diagnostic);
      expect(navigation.space, WorkspaceSpace.map);
      expect(navigation.verificationMapReturn, isTrue);
      for (var i = 0; i < 1000 && h.maps.loading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(h.maps.loading, isFalse);
      expect(h.maps.active!.current.id, mapId);
      navigation.returnFromDiagnosticMap();
      expect(navigation.space, WorkspaceSpace.verification);
      expect(navigation.verificationMapReturn, isFalse);
      expect(controller.report, same(report));
      expect(controller.selectedKey, diagnostic.stableKey);
    },
  );
}
