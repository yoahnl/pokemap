import 'package:avelune_studio/features/world/application/world_editor_workflow.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/world_authoring_workflow_fixture.dart';

void main() {
  test('source selection keeps the fact type and initial value', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final factId = createWorldFact(h.world, 'Compteur');
    h.world.editFact(
      NarrativeFactDefinition(
        id: factId,
        label: 'Compteur',
        initialValue: NarrativeValue.integer(7),
      ),
    );
    final ruleId = composeWorldRule(h.world, factId);
    h.editor.applySource(
      ruleId,
      WorldRuleSourcePickerOption(
        kind: WorldRuleSourceKind.fact,
        sourceId: factId,
        predicate: WorldRuleSourcePredicate.isTrue,
        label: 'Compteur',
        subtitle: '',
        debugTechnicalLabel: factId,
      ),
    );
    expect(
      h.world.ruleDraft(ruleId)!.source!.expectedFactValue,
      NarrativeValue.integer(7),
    );
    expect(h.world.ruleDraft(ruleId)!.source!.label, 'Compteur');
    h.editor.applySource(
      ruleId,
      const WorldRuleSourcePickerOption(
        kind: WorldRuleSourceKind.storyStepCompletion,
        sourceId: 'departure_step',
        predicate: WorldRuleSourcePredicate.notCompleted,
        label: 'Départ',
        subtitle: '',
        debugTechnicalLabel: 'departure_step',
      ),
    );
    expect(
      h.world.ruleDraft(ruleId)!.source!.kind,
      WorldRuleSourceKind.storyStepCompletion,
    );
    expect(
      h.world.ruleDraft(ruleId)!.source!.predicate,
      WorldRuleSourcePredicate.notCompleted,
    );
  });

  test(
    'target change retains compatible effects and clears incompatible ones',
    () async {
      final h = await WorldAuthoringWorkflowFixture.create();
      addTearDown(h.dispose);
      final factId = createWorldFact(h.world, 'Départ');
      final ruleId = composeWorldRule(h.world, factId);
      final original = h.world.ruleDraft(ruleId)!;
      final target = original.target!;
      final effect = original.effect;
      h.editor.applyTarget(
        ruleId,
        WorldRuleTargetPickerOption(
          kind: target.kind,
          mapId: target.mapId,
          entityId: target.entityId,
          label: 'Conducteur',
          subtitle: '',
          debugTechnicalLabel: '',
        ),
      );
      expect(h.world.ruleDraft(ruleId)!.effect, effect);
      h.editor.applyTarget(
        ruleId,
        WorldRuleTargetPickerOption(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: target.mapId,
          eventId: 'arrival',
          label: 'Arrivée',
          subtitle: '',
          debugTechnicalLabel: '',
        ),
      );
      expect(h.world.ruleDraft(ruleId)!.effect, isNull);
      expect(h.world.ruleDraft(ruleId)!.target!.eventId, 'arrival');
      expect(h.world.project.worldRules, isEmpty);
    },
  );

  test('effect choices preserve dialogue and atmosphere payloads', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final ruleId = composeWorldRule(
      h.world,
      createWorldFact(h.world, 'Départ'),
    );
    h.editor.applyEffect(
      ruleId,
      WorldRuleEffectKind.npcDialogueOverride,
      dialogueId: 'after_departure',
    );
    expect(h.world.ruleDraft(ruleId)!.effect!.dialogueId, 'after_departure');
    expect(h.world.ruleDraft(ruleId)!.effect!.visualSettings, isNull);
    final mapId = h.world.maps.first.id;
    h.editor.applyAtmosphereTarget(ruleId, mapId);
    expect(h.world.ruleDraft(ruleId)!.target!.mapId, mapId);
    expect(
      h.world.ruleDraft(ruleId)!.target!.kind,
      WorldRuleTargetKind.atmosphere,
    );
    expect(
      h.world.ruleDraft(ruleId)!.effect!.kind,
      WorldRuleEffectKind.atmosphere,
    );
    expect(
      h.world.ruleDraft(ruleId)!.effect!.visualSettings,
      SpatialVisualPatch({SpatialVisualParameter.depthOfFieldEnabled: true}),
    );
    expect(h.world.project.worldRules, isEmpty);
  });

  test(
    'simulation preview hides entities without mutating the authored map',
    () async {
      final h = await WorldAuthoringWorkflowFixture.create();
      addTearDown(h.dispose);
      final factId = createWorldFact(h.world, 'Départ');
      final ruleId = composeWorldRule(h.world, factId);
      final target = h.world.ruleDraft(ruleId)!.target!;
      final map = h.world.maps.firstWhere((map) => map.id == target.mapId);
      expect(identical(h.editor.previewMap(map), map), isTrue);
      h.world.setSimulationValue(factId, const NarrativeValue.boolean(true));
      await h.world.simulateComplete();
      expect(h.world.report, isNotNull);
      final preview = h.editor.previewMap(map);
      expect(
        preview.entities.any((entity) => entity.id == target.entityId),
        isFalse,
      );
      expect(
        map.entities.any((entity) => entity.id == target.entityId),
        isTrue,
      );
      expect(h.world.project.worldRules, isEmpty);
    },
  );

  test('raw fact name and integer parsing preserve rejected input until correction', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final factId = h.world.createFact();
    final fact = h.world.fact(factId)!;
    await h.editor.changeFactKind(fact, NarrativeValueKind.integer);
    expect(h.editor.commitFactLabel(factId, '   '), isFalse);
    expect(h.editor.commitFactInteger(factId, '12.5'), isFalse);
    expect(
      h.inputs.invalidFields,
      containsAll(['$factId.label', '$factId.value']),
    );
    await h.editor.save(rules: false);
    expect(h.world.project.facts, isEmpty);
    expect(h.world.fact(factId)!.initialValue, NarrativeValue.integer(0));
    expect(h.editor.commitFactLabel(factId, '  Compteur  '), isTrue);
    expect(h.world.fact(factId)!.label, 'Compteur');
    expect(h.editor.commitFactLabel(factId, 'Compteur'), isTrue);
    expect(h.editor.commitFactInteger(factId, ' 42 '), isTrue);
    expect(h.inputs.valid, isTrue);
    await h.editor.save(rules: false);
    expect(h.world.project.facts.single.label, 'Compteur');
    expect(
      h.world.project.facts.single.initialValue,
      NarrativeValue.integer(42),
    );
  });

  test(
    'invalid rule label preserves draft and blocks publication until corrected',
    () async {
      final h = await WorldAuthoringWorkflowFixture.create();
      addTearDown(h.dispose);
      final factId = createWorldFact(h.world, 'Départ');
      final ruleId = composeWorldRule(h.world, factId);
      final before = h.world.ruleDraft(ruleId)!.label;
      expect(h.editor.commitRuleLabel(ruleId, '  '), isFalse);
      expect(h.world.ruleDraft(ruleId)!.label, before);
      await h.editor.save(rules: true);
      expect(h.dependencyQuestions, 0);
      expect(h.world.project.worldRules, isEmpty);
      expect(h.inputs.invalidFields, contains('$ruleId.label'));
      expect(h.editor.commitRuleLabel(ruleId, 'Départ confirmé'), isTrue);
      expect(h.inputs.valid, isTrue);
      await h.editor.save(rules: true);
      expect(h.world.project.worldRules.single.label, 'Départ confirmé');
      expect(h.world.pendingRules, isEmpty);
    },
  );

  test(
    'invalid integer preserves its source and blocks save until corrected',
    () async {
      final h = await WorldAuthoringWorkflowFixture.create();
      addTearDown(h.dispose);
      final factId = h.world.createFact();
      h.world.editFact(
        NarrativeFactDefinition(
          id: factId,
          label: 'Compteur',
          initialValue: NarrativeValue.integer(0),
        ),
      );
      final ruleId = composeWorldRule(h.world, factId);
      final source = WorldRuleSource.factValue(
        factId: factId,
        operator: NarrativeFactOperator.equals,
        expectedValue: NarrativeValue.integer(0),
      );
      h.world.editRule(ruleId, (draft) => draft.source = source);
      expect(
        h.editor.commitExpectedInteger(
          ruleId: ruleId,
          factId: factId,
          operator: NarrativeFactOperator.equals,
          raw: 'douze',
        ),
        isFalse,
      );
      expect(h.world.ruleDraft(ruleId)!.source, source);
      await h.editor.save(rules: true);
      expect(h.world.project.worldRules, isEmpty);
      expect(
        h.editor.commitExpectedInteger(
          ruleId: ruleId,
          factId: factId,
          operator: NarrativeFactOperator.equals,
          raw: ' 42 ',
        ),
        isTrue,
      );
      expect(h.inputs.valid, isTrue);
      expect(
        h.world.ruleDraft(ruleId)!.source,
        WorldRuleSource.factValue(
          factId: factId,
          operator: NarrativeFactOperator.equals,
          expectedValue: NarrativeValue.integer(42),
        ),
      );
      await h.editor.save(rules: true);
      expect(h.world.error, isNull);
      expect(h.world.project.worldRules, hasLength(1));
    },
  );

  test('invalid fact field never discards metadata or publishes its previous value', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final factId = h.world.createFact();
    final before = NarrativeFactDefinition(
      id: factId,
      label: 'Départ',
      description: 'Le départ du train',
      category: 'gare',
      tags: const ['rail'],
      initialValue: const NarrativeValue.boolean(false),
    );
    h.world.editFact(before);
    expect(h.editor.commitFact(factId, 'initial', null), isFalse);
    await h.editor.save(rules: false);
    expect(h.world.fact(factId), before);
    expect(
      h.world.project.facts.any((fact) => fact.label == before.label),
      isFalse,
    );
    expect(
      h.editor.commitFact(
        factId,
        'initial',
        (fact) => copyWorldFact(
          fact,
          initialValue: const NarrativeValue.boolean(true),
        ),
      ),
      isTrue,
    );
    await h.editor.save(rules: false);
    final saved = h.world.project.facts.singleWhere(
      (fact) => fact.label == 'Départ',
    );
    expect(saved.description, before.description);
    expect(saved.category, before.category);
    expect(saved.tags, before.tags);
    expect(saved.initialValue, const NarrativeValue.boolean(true));
  });

  test('fact type change keeps a legacy boolean binding protected', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final factId = h.world.createFact();
    final fact = NarrativeFactDefinition(
      id: factId,
      label: 'Historique',
      legacyFlagName: 'legacy_departure',
      initialValue: const NarrativeValue.boolean(false),
    );
    h.world.editFact(fact);
    await h.editor.changeFactKind(fact, NarrativeValueKind.integer);
    expect(h.world.fact(factId), fact);
    expect(h.inputs.actionError, contains('liaison historique'));
    expect(h.world.project.facts.any((value) => value.id == factId), isFalse);
    expect(
      copyWorldFact(fact, label: 'Renommé').legacyFlagName,
      fact.legacyFlagName,
    );
  });
}
