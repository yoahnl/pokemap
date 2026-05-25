import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative outcome authoring operations', () {
    test('adds and dedupes declared outcomes without mutating the original',
        () {
      final original = _draft();

      final withOutcome = addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
        original,
        ' p4.outcome.done ',
      );
      final deduped = addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
        withOutcome,
        'p4.outcome.done',
      );

      expect(original.declaredOutcomes, isEmpty);
      expect(withOutcome.declaredOutcomes, ['p4.outcome.done']);
      expect(deduped.declaredOutcomes, ['p4.outcome.done']);
      expect(identical(withOutcome, original), isFalse);
    });

    test('adds emitOutcome action without auto-declaring by default', () {
      final original = _draft();

      final updated = addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
        original,
        ' p4.outcome.done ',
      );

      expect(original.actions, hasLength(1));
      expect(updated.actions, hasLength(2));
      expect(updated.actions.last.kind,
          NarrativeScenarioAuthoringActionKind.emitOutcome);
      expect(updated.actions.last.outcomeId, 'p4.outcome.done');
      expect(updated.declaredOutcomes, isEmpty);
    });

    test('diagnoses undeclared emits and declared outcomes never emitted', () {
      final undeclared = validateNarrativeOutcomeAuthoringDraft(
        addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
          _draft(),
          'p4.outcome.undeclared',
        ),
      );
      expect(
        _outcomeDiagnosticKinds(undeclared),
        contains(NarrativeOutcomeAuthoringDiagnosticKind.outcomeNotDeclared),
      );
      expect(undeclared.single.referencedId, 'p4.outcome.undeclared');

      final declaredOnly = validateNarrativeOutcomeAuthoringDraft(
        addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
          _draft(),
          'p4.outcome.never_emitted',
        ),
      );
      expect(
        _outcomeDiagnosticKinds(declaredOnly),
        contains(
          NarrativeOutcomeAuthoringDiagnosticKind.declaredOutcomeNeverEmitted,
        ),
      );
      expect(declaredOnly.single.referencedId, 'p4.outcome.never_emitted');
    });

    test('creates outcomeReceived source from outcome picker option', () {
      final option = _outcomeOption('p4.outcome.done');

      final source = createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
        option,
      );

      expect(source.kind, NarrativeScenarioAuthoringSourceKind.outcomeReceived);
      expect(source.outcomeId, 'p4.outcome.done');
    });

    test('compiles outcomeReceived source with setFlag into sourceOutcome', () {
      final source = createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
        _outcomeOption('p4.outcome.done'),
      );

      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _draft(source: source),
      );
      final sourceNode = asset.nodes.singleWhere(
        (node) => node.id == 'p4_authoring_outcome__source',
      );

      expect(sourceNode.payload.actionKind, 'sourceOutcome');
      expect(sourceNode.binding.outcomeId, 'p4.outcome.done');
      expect(asset.nodes.last.type, ScenarioNodeType.end);
    });

    test('adds startTrainerBattle action from battle reference option', () {
      final original = _draft(
        source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );
      final option = _battleOption();

      final updated =
          addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        original,
        option,
      );

      expect(original.actions, hasLength(1));
      expect(updated.actions, hasLength(2));
      final action = updated.actions.last;
      expect(
          action.kind, NarrativeScenarioAuthoringActionKind.startTrainerBattle);
      expect(action.battleId, 'p4_battle');
      expect(action.trainerId, 'p4_trainer');
      expect(action.npcEntityId, 'p4_npc');
    });

    test('compiles entityInteract with startTrainerBattle bindings', () {
      final draft =
          addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        _draft(
          source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: 'p4_map',
            entityId: 'p4_npc',
          ),
        ),
        _battleOption(),
      );

      final asset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);
      final battleNode = asset.nodes.singleWhere(
        (node) => node.id == 'p4_authoring_outcome__action_1',
      );

      expect(battleNode.payload.actionKind, 'startTrainerBattle');
      expect(battleNode.payload.params['battleId'], 'p4_battle');
      expect(battleNode.binding.trainerId, 'p4_trainer');
      expect(battleNode.binding.entityId, 'p4_npc');
    });

    test('builds scenario and battle outcome flag references separately', () {
      final scenarioOutcome =
          narrativeScenarioOutcomeFlagReference(' p4.outcome.done ');
      final battleVictory = narrativeBattleOutcomeFlagReference(
        ' p4_battle ',
        NarrativeBattleOutcomeKind.victory,
      );
      final battleDefeat = narrativeBattleOutcomeFlagReference(
        'p4_battle',
        NarrativeBattleOutcomeKind.defeat,
      );

      expect(scenarioOutcome, 'scenario.outcome.p4.outcome.done');
      expect(battleVictory, 'battle:p4_battle:victory');
      expect(battleDefeat, 'battle:p4_battle:defeat');
      expect(scenarioOutcome.startsWith('battle:'), isFalse);
      expect(battleVictory.startsWith('scenario.outcome.'), isFalse);
      expect(battleDefeat.startsWith('scenario.outcome.'), isFalse);
    });

    test('diagnoses battle option and battle reference problems', () {
      final diagnostics = validateNarrativeOutcomeAuthoringDraft(
        _draft(
          source: const NarrativeScenarioAuthoringSourceDraft.mapEnter(
            mapId: 'p4_map',
          ),
          actions: const [
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              battleId: ' ',
              trainerId: ' ',
            ),
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              battleId: 'missing_battle',
              trainerId: 'p4_trainer',
              npcEntityId: 'p4_npc',
            ),
          ],
        ),
        battleOptions: [_battleOption()],
      );

      expect(
        _outcomeDiagnosticKinds(diagnostics),
        containsAll([
          NarrativeOutcomeAuthoringDiagnosticKind.emptyBattleId,
          NarrativeOutcomeAuthoringDiagnosticKind.missingTrainerReference,
          NarrativeOutcomeAuthoringDiagnosticKind.missingNpcEntityReference,
          NarrativeOutcomeAuthoringDiagnosticKind.battleOptionNotFound,
        ]),
      );
    });

    test('diagnoses scenario outcome and battle outcome confusion', () {
      final diagnostics = validateNarrativeOutcomeAuthoringDraft(
        _draft(
          declaredOutcomes: const ['battle:p4_battle:victory'],
          actions: const [
            NarrativeScenarioAuthoringActionDraft.emitOutcome(
              outcomeId: 'scenario.outcome.p4.already_prefixed',
            ),
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              battleId: 'scenario.outcome.p4_battle',
              trainerId: 'p4_trainer',
              npcEntityId: 'p4_npc',
            ),
          ],
        ),
        battleOptions: [_battleOption()],
      );

      expect(
        _outcomeDiagnosticKinds(diagnostics),
        contains(
          NarrativeOutcomeAuthoringDiagnosticKind
              .scenarioOutcomeBattleOutcomeConfusion,
        ),
      );
    });

    test('throws for empty direct flag references', () {
      expect(
        () => narrativeScenarioOutcomeFlagReference(' '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => narrativeBattleOutcomeFlagReference(
          ' ',
          NarrativeBattleOutcomeKind.victory,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not hardcode Selbrume identifiers', () {
      final draft =
          addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
          addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
            _draft(),
            'p4.outcome.done',
          ),
          'p4.outcome.done',
        ),
        _battleOption(),
        npcEntityId: 'p4_npc',
      );
      final serialized = {
        narrativeScenarioOutcomeFlagReference('p4.outcome.done'),
        narrativeBattleOutcomeFlagReference(
          'p4_battle',
          NarrativeBattleOutcomeKind.victory,
        ),
        compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft)
            .toJson()
            .toString(),
      }.join('\n').toLowerCase();

      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativeScenarioAuthoringDraft _draft({
  NarrativeScenarioAuthoringSourceDraft source =
      const NarrativeScenarioAuthoringSourceDraft.mapEnter(mapId: 'p4_map'),
  List<NarrativeScenarioAuthoringActionDraft> actions = const [
    NarrativeScenarioAuthoringActionDraft.setFlag(
      flagName: 'p4.outcome.authoring.executed',
    ),
  ],
  List<String> declaredOutcomes = const [],
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: 'p4_authoring_outcome',
    name: 'P4 Authoring Outcome',
    description: 'Technical outcome authoring draft.',
    scope: source.kind == NarrativeScenarioAuthoringSourceKind.outcomeReceived
        ? ScenarioScope.globalStory
        : ScenarioScope.localEventFlow,
    source: source,
    actions: actions,
    declaredOutcomes: declaredOutcomes,
    metadata: const {'authoring.test': 'p4-04'},
  );
}

NarrativeOutcomePickerOption _outcomeOption(String outcomeId) {
  return buildNarrativeOutcomePickerOptions(
    ProjectManifest(
      name: 'P4 Outcome Authoring Test',
      maps: const [],
      tilesets: const [],
      scenarios: [
        ScenarioAsset(
          id: 'p4_outcome_source',
          name: 'P4 Outcome Source',
          entryNodeId: 'source',
          declaredOutcomes: [outcomeId],
          nodes: [
            ScenarioNode(
              id: 'source',
              type: ScenarioNodeType.reference,
              payload: const ScenarioNodePayload(actionKind: 'sourceMapEnter'),
            ),
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(outcomeId: outcomeId),
              payload: const ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
          ],
          edges: const [],
        ),
      ],
    ),
  ).singleWhere((option) => option.outcomeId == outcomeId);
}

NarrativeBattleReferencePickerOption _battleOption() {
  return buildNarrativeBattleReferencePickerOptions(
    ProjectManifest(
      name: 'P4 Battle Authoring Test',
      maps: const [],
      tilesets: const [],
      trainers: const [
        ProjectTrainerEntry(
          id: 'p4_trainer',
          name: 'P4 Trainer',
          trainerClass: 'Tester',
        ),
      ],
      scenarios: const [
        ScenarioAsset(
          id: 'p4_battle_provider',
          name: 'P4 Battle Provider',
          entryNodeId: 'source',
          nodes: [
            ScenarioNode(
              id: 'battle',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(
                trainerId: 'p4_trainer',
                entityId: 'p4_npc',
              ),
              payload: ScenarioNodePayload(
                actionKind: 'startTrainerBattle',
                params: {'battleId': 'p4_battle'},
              ),
            ),
          ],
          edges: [],
        ),
      ],
    ),
  ).single;
}

List<NarrativeOutcomeAuthoringDiagnosticKind> _outcomeDiagnosticKinds(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}
