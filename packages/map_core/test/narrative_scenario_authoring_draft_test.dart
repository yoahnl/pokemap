import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeScenarioAuthoringDraft validation', () {
    test('accepts a minimal authoring draft', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(),
      );

      expect(diagnostics, isEmpty);
    });

    test('rejects empty scenario id and name', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(scenarioId: ' ', name: ' '),
      );

      expect(
          _kinds(diagnostics),
          containsAll([
            NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioId,
            NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioName,
          ]));
      expect(
        diagnostics.every((diagnostic) =>
            diagnostic.severity ==
            NarrativeScenarioAuthoringDraftDiagnosticSeverity.error),
        isTrue,
      );
    });

    test('rejects missing source and required source references', () {
      final missingSource = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(source: null),
      );
      expect(
          _kinds(missingSource),
          contains(
            NarrativeScenarioAuthoringDraftDiagnosticKind.missingSource,
          ));

      final incompleteTrigger = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(
          source: const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
            mapId: 'p4_test_map',
            triggerId: ' ',
          ),
        ),
      );
      expect(
          _kinds(incompleteTrigger),
          contains(
            NarrativeScenarioAuthoringDraftDiagnosticKind
                .missingSourceReference,
          ));
      expect(incompleteTrigger.single.path, 'source.triggerId');
    });

    test('rejects actions with missing required references', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(
          declaredOutcomes: const [],
          actions: const [
            NarrativeScenarioAuthoringActionDraft.setFlag(flagName: ' '),
            NarrativeScenarioAuthoringActionDraft.completeStep(stepId: ' '),
            NarrativeScenarioAuthoringActionDraft.emitOutcome(outcomeId: ' '),
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              trainerId: ' ',
              battleId: ' ',
            ),
          ],
        ),
      );

      expect(
        diagnostics
            .where((diagnostic) =>
                diagnostic.kind ==
                NarrativeScenarioAuthoringDraftDiagnosticKind
                    .emptyActionReference)
            .length,
        6,
      );
      expect(
        diagnostics.every((diagnostic) =>
            diagnostic.severity ==
            NarrativeScenarioAuthoringDraftDiagnosticSeverity.error),
        isTrue,
      );
    });

    test('detects emitted and declared outcome drift', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(
          declaredOutcomes: const ['p4.outcome.declared_only'],
          actions: const [
            NarrativeScenarioAuthoringActionDraft.emitOutcome(
              outcomeId: 'p4.outcome.emitted_only',
            ),
          ],
        ),
      );

      expect(
          _kinds(diagnostics),
          containsAll([
            NarrativeScenarioAuthoringDraftDiagnosticKind
                .emitOutcomeNotDeclared,
            NarrativeScenarioAuthoringDraftDiagnosticKind
                .declaredOutcomeNeverEmitted,
          ]));
      expect(
        diagnostics.every((diagnostic) =>
            diagnostic.severity ==
            NarrativeScenarioAuthoringDraftDiagnosticSeverity.warning),
        isTrue,
      );
    });
  });

  group('compileNarrativeScenarioAuthoringDraftToScenarioAsset', () {
    test('compiles mapEnter with linear actions into a deterministic asset',
        () {
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _minimalDraft(),
      );

      expect(asset.id, 'p4_test_scenario');
      expect(asset.name, 'P4 Test Scenario');
      expect(asset.description, 'Technical authoring draft test.');
      expect(asset.scope, ScenarioScope.localEventFlow);
      expect(asset.entryNodeId, 'p4_test_scenario__start');
      expect(asset.declaredOutcomes, ['p4.outcome.done']);

      expect(asset.nodes.map((node) => node.id), [
        'p4_test_scenario__start',
        'p4_test_scenario__source',
        'p4_test_scenario__action_0',
        'p4_test_scenario__action_1',
        'p4_test_scenario__action_2',
        'p4_test_scenario__end',
      ]);
      expect(asset.edges.map((edge) => edge.id), [
        'p4_test_scenario__edge_start_to_source',
        'p4_test_scenario__edge_source_to_action_0',
        'p4_test_scenario__edge_action_0_to_action_1',
        'p4_test_scenario__edge_action_1_to_action_2',
        'p4_test_scenario__edge_action_2_to_end',
      ]);

      final source = asset.nodes[1];
      expect(source.type, ScenarioNodeType.reference);
      expect(source.payload.actionKind, 'sourceMapEnter');
      expect(source.binding.mapId, 'p4_test_map');

      final setFlag = asset.nodes[2];
      expect(setFlag.type, ScenarioNodeType.action);
      expect(setFlag.payload.actionKind, 'setFlag');
      expect(setFlag.binding.flagName, 'p4.flag.executed');

      final completeStep = asset.nodes[3];
      expect(completeStep.payload.actionKind, 'completeStep');
      expect(completeStep.payload.params['stepId'], 'p4.step.completed');

      final emitOutcome = asset.nodes[4];
      expect(emitOutcome.payload.actionKind, 'emitOutcome');
      expect(emitOutcome.binding.outcomeId, 'p4.outcome.done');

      expect(
        asset.nodes.where((node) => node.type == ScenarioNodeType.start),
        hasLength(1),
      );
      expect(
        asset.nodes.where((node) => node.type == ScenarioNodeType.end),
        hasLength(1),
      );
    });

    test('compiles entityInteract with startTrainerBattle using source entity',
        () {
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _minimalDraft(
          source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: 'p4_battle_map',
            entityId: 'p4_npc',
          ),
          actions: const [
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              trainerId: 'p4_trainer',
              battleId: 'p4_battle',
            ),
          ],
          declaredOutcomes: const [],
        ),
      );

      final source = asset.nodes[1];
      expect(source.payload.actionKind, 'sourceEntityInteract');
      expect(source.binding.mapId, 'p4_battle_map');
      expect(source.binding.entityId, 'p4_npc');

      final battle = asset.nodes[2];
      expect(battle.payload.actionKind, 'startTrainerBattle');
      expect(battle.binding.trainerId, 'p4_trainer');
      expect(battle.binding.entityId, 'p4_npc');
      expect(battle.payload.params['battleId'], 'p4_battle');
    });

    test('does not mutate input lists and exposes immutable lists', () {
      final actions = [
        const NarrativeScenarioAuthoringActionDraft.setFlag(
          flagName: 'p4.flag.original',
        ),
      ];
      final declaredOutcomes = ['p4.outcome.original'];
      final draft = _minimalDraft(
        actions: actions,
        declaredOutcomes: declaredOutcomes,
      );

      actions.add(
        const NarrativeScenarioAuthoringActionDraft.setFlag(
          flagName: 'p4.flag.mutated',
        ),
      );
      declaredOutcomes.add('p4.outcome.mutated');

      final asset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);

      expect(
        asset.nodes
            .where((node) => node.payload.actionKind == 'setFlag')
            .map((node) => node.binding.flagName),
        ['p4.flag.original'],
      );
      expect(asset.declaredOutcomes, ['p4.outcome.original']);
      expect(
        () => draft.actions.add(
          const NarrativeScenarioAuthoringActionDraft.setFlag(
            flagName: 'p4.flag.illegal',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(() => draft.declaredOutcomes.add('p4.outcome.illegal'),
          throwsUnsupportedError);
    });

    test('does not hardcode Selbrume identifiers', () {
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _minimalDraft(),
      );

      final serialized = asset.toJson().toString().toLowerCase();
      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativeScenarioAuthoringDraft _minimalDraft({
  String scenarioId = 'p4_test_scenario',
  String name = 'P4 Test Scenario',
  NarrativeScenarioAuthoringSourceDraft? source =
      const NarrativeScenarioAuthoringSourceDraft.mapEnter(
    mapId: 'p4_test_map',
  ),
  List<NarrativeScenarioAuthoringActionDraft> actions = const [
    NarrativeScenarioAuthoringActionDraft.setFlag(
      flagName: 'p4.flag.executed',
    ),
    NarrativeScenarioAuthoringActionDraft.completeStep(
      stepId: 'p4.step.completed',
    ),
    NarrativeScenarioAuthoringActionDraft.emitOutcome(
      outcomeId: 'p4.outcome.done',
    ),
  ],
  List<String> declaredOutcomes = const ['p4.outcome.done'],
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: scenarioId,
    name: name,
    description: 'Technical authoring draft test.',
    scope: ScenarioScope.localEventFlow,
    source: source,
    actions: actions,
    declaredOutcomes: declaredOutcomes,
  );
}

List<NarrativeScenarioAuthoringDraftDiagnosticKind> _kinds(
  List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}
