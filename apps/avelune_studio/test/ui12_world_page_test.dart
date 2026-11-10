import 'package:avelune_studio/features/world/application/world_editor_workflow.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/world_authoring_workflow_fixture.dart';

void main() {
  test('a state and its rule are composed without an old page', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final world = h.world;
    h.editor.create(rules: false);
    final draftFactId = world.selectedFactId!;
    expect(draftFactId, isNotNull);
    h.editor.commitFact(
      draftFactId,
      'label',
      (fact) => copyWorldFact(fact, label: 'Train parti'),
    );
    expect(world.activeFact!.label, 'Train parti');
    await h.editor.save(rules: false);
    final factId = world.selectedFactId!;
    expect(world.isFactDirty(factId), isFalse);
    final ruleId = world.createRule(factId: factId);
    expect(world.ruleDraft(ruleId)!.source, isNotNull);
    expect(world.ruleDraft(ruleId)!.missing, contains('la cible'));
    final target = world.model.targetOptions.firstWhere(
      (option) => option.kind == WorldRuleTargetKind.mapEntity,
    );
    world.editRule(ruleId, (draft) {
      draft.target = WorldRuleTarget(
        kind: target.kind,
        mapId: target.mapId,
        entityId: target.entityId,
        label: target.label,
      );
      draft.effect = const WorldRuleEffect(
        kind: WorldRuleEffectKind.entityHidden,
      );
    });
    expect(world.ruleDraft(ruleId)!.target?.entityId, target.entityId);
    final draft = world.ruleDraft(ruleId)!;
    expect(
      isWorldRuleEffectCompatibleWithTarget(
        draft.target!.kind,
        draft.effect!.kind,
      ),
      isTrue,
    );
    expect(draft.missing, isEmpty);
    await h.editor.save(rules: true);
    expect(world.error, isNull);
    world.simulate();
    expect(world.report, isNotNull);
    bool visible() => world.report!.entityStates
        .firstWhere(
          (state) =>
              state.mapId == target.mapId && state.entityId == target.entityId,
        )
        .visible;
    expect(visible(), isTrue);
    world.setSimulationValue(factId, const NarrativeValue.boolean(true));
    world.simulate();
    expect(world.isHypothetical(factId), isTrue);
    expect(visible(), isFalse);
    expect(
      world.fact(factId)!.initialValue,
      const NarrativeValue.boolean(false),
    );
  });

  test('a rule refuses to outrun the state it reads, and offers it', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final world = h.world;
    final factId = createWorldFact(world, 'Train parti');
    final ruleId = composeWorldRule(world, factId);
    h.approveDependency = false;
    await h.editor.save(rules: true);
    expect(h.dependencyQuestions, 1);
    expect(world.project.worldRules, isEmpty);
    expect(world.isRuleDirty(ruleId), isTrue);
    h.approveDependency = true;
    await h.editor.save(rules: true);
    expect(h.dependencyQuestions, 2);
    expect(world.error, isNull);
    final rule = world.project.worldRules.single;
    expect(
      world.project.facts.any((fact) => fact.id == rule.source.sourceId),
      isTrue,
    );
    expect(world.pendingRules, isEmpty);
  });
}
