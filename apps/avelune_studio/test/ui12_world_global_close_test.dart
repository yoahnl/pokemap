import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui12_held_world_port.dart';
import 'support/ui12_world_harness.dart';
import 'support/world_authoring_workflow_fixture.dart';

void main() {
  test('global close saves new world states with Stories connected', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final world = h.world;
    final factId = createWorldFact(world, 'Départ confirmé');
    final independentId = createWorldFact(world, 'Signal reçu');
    final ruleId = composeWorldRule(world, factId);
    world.narrative.pendingStories['close_story'] = StorylineAsset(
      id: 'close_story',
      type: StorylineType.main,
      title: 'Départ en préparation',
    );
    world.changed();
    expect(world.narrative.saveStoryDrafts, isNotNull);
    expect(world.project.facts.any((fact) => fact.id == factId), isFalse);
    expect(world.pendingRules, contains(ruleId));
    expect(await h.workspace.allowClose(), isTrue, reason: world.error);
    expect(world.narrative.pendingFacts, isEmpty);
    expect(world.narrative.pendingStories, isEmpty);
    expect(world.pendingRules, isEmpty);

    final reopened = await Ui12WorldHarness.open(h.harness.directory);
    addTearDown(() => reopened.dispose(deleteDirectory: false));
    final project = reopened.world.project;
    final savedFact = project.facts.singleWhere(
      (fact) => fact.label == 'Départ confirmé',
    );
    final independent = project.facts.singleWhere(
      (fact) => fact.label == 'Signal reçu',
    );
    expect(savedFact.id, isNot(factId));
    expect(independent.id, isNot(independentId));
    expect(project.worldRules.single.source.sourceId, savedFact.id);
    expect(
      project.storylines
          .singleWhere((story) => story.id == 'close_story')
          .title,
      'Départ en préparation',
    );
  });

  test(
    'invalid input on a clean rule still requires an explicit choice',
    () async {
      final h = await WorldAuthoringWorkflowFixture.create();
      addTearDown(h.dispose);
      final world = h.world;
      expect(
        await world.saveFact(createWorldFact(world, 'Train arrivé')),
        isTrue,
      );
      final ruleId = composeWorldRule(world, world.selectedFactId!);
      expect(await world.saveRule(ruleId), isTrue);
      expect(world.dirty, isFalse);
      final published = world.project.worldRules.single;
      expect(h.editor.commitRuleLabel(world.selectedRuleId!, ''), isFalse);
      expect(world.hasRuleDraft, isFalse);
      expect(h.inputs.invalidFields, isNotEmpty);
      expect(await h.workspace.allowClose(), isFalse);
      expect(h.closeQuestions, 1);
      expect(world.error, contains('Corrigez les champs invalides'));
      expect(world.project.worldRules.single, published);

      h.closeChoice = WorkspaceCloseChoice.discard;
      expect(await h.workspace.allowClose(), isTrue);
      expect(h.closeQuestions, 2);
      final reopened = await Ui12WorldHarness.open(h.harness.directory);
      addTearDown(() => reopened.dispose(deleteDirectory: false));
      expect(reopened.world.project.worldRules.single, published);
    },
  );

  test(
    'a failed rule keeps close blocked after its new state is saved',
    () async {
      late Ui12HeldWorldPort held;
      final h = await WorldAuthoringWorkflowFixture.create(
        wrap: (port) => held = Ui12HeldWorldPort(port),
      );
      addTearDown(h.dispose);
      final world = h.world;
      final factId = createWorldFact(world, 'Passage autorisé');
      composeWorldRule(world, factId);
      held.ruleFailure = const WorldFailure('Publication de règle refusée');
      expect(await h.workspace.allowClose(), isFalse);
      expect(world.error, contains('Publication de règle refusée'));
      expect(world.pendingRules, hasLength(1));
      expect(world.project.worldRules, isEmpty);
      final saved = world.project.facts.singleWhere(
        (fact) => fact.label == 'Passage autorisé',
      );
      expect(saved.id, isNot(factId));
      expect(world.pendingRules.values.single.source!.sourceId, saved.id);

      held.ruleFailure = null;
      expect(await h.workspace.allowClose(), isTrue, reason: world.error);
      final reopened = await Ui12WorldHarness.open(h.harness.directory);
      addTearDown(() => reopened.dispose(deleteDirectory: false));
      expect(
        reopened.world.project.worldRules.single.source.sourceId,
        saved.id,
      );
      expect(world.pendingRules, isEmpty);
    },
  );
}
