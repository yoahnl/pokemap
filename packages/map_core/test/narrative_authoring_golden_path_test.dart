import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _projectName = 'P4 Authoring Golden Path';
const _mapId = 'p4_authoring_map';
const _entityId = 'p4_authoring_npc';
const _triggerId = 'p4_authoring_trigger';
const _scenarioId = 'p4_authoring_scene';
const _receiverScenarioId = 'p4_authoring_outcome_receiver';
const _referenceScenarioId = 'p4_authoring_reference_scene';
const _storyScenarioId = 'p4_authoring_story';
const _outcomeId = 'p4.outcome.done';
const _flagName = 'p4.flag.visible';
const _stepId = 'p4.step.completed';
const _cutsceneId = 'p4_authoring_cutscene';
const _battleId = 'p4_battle';
const _trainerId = 'p4_trainer';
const _dialogueId = 'p4.dialogue.visible';

void main() {
  group('P4-07 minimal authoring golden path', () {
    test(
        'chains read models, drafts, operations, predicates, validation, and '
        'authoring diagnostics', () {
      final referenceMap = _map();
      final referenceManifest = _manifest(
        scenarios: [
          _referenceScenario(),
          _referenceOutcomeReceiverScenario(),
          _referenceStoryScenario(),
        ],
      );

      final scenarioOptions =
          buildNarrativeScenarioPickerOptions(referenceManifest);
      final eventSourceOptions = buildNarrativeEventSourcePickerOptions(
        referenceManifest,
        maps: [referenceMap],
      );
      final outcomeOptions =
          buildNarrativeOutcomePickerOptions(referenceManifest);
      final battleOptions =
          buildNarrativeBattleReferencePickerOptions(referenceManifest);
      final predicateOptions =
          buildNarrativePredicateReferencePickerOptions(referenceManifest);

      expect(scenarioOptions.map((option) => option.scenarioId),
          contains(_referenceScenarioId));
      final eventOption = _eventSourceOption(
        eventSourceOptions,
        NarrativeEventSourceKind.entityInteract,
      );
      expect(eventOption.sourceId, 'entityInteract:$_mapId:$_entityId');
      final outcomeOption = _outcomeOption(outcomeOptions, _outcomeId);
      expect(outcomeOption.isDeclared, isTrue);
      expect(outcomeOption.isEmitted, isTrue);
      expect(outcomeOption.isConsumed, isTrue);
      final battleOption = _battleOption(battleOptions, _battleId);
      expect(battleOption.trainerId, _trainerId);
      expect(battleOption.npcEntityId, _entityId);

      final sourceDraft =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        eventOption,
      );
      expect(sourceDraft.kind,
          NarrativeScenarioAuthoringSourceKind.entityInteract);
      expect(sourceDraft.mapId, _mapId);
      expect(sourceDraft.entityId, _entityId);
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(sourceDraft),
        eventOption.sourceId,
      );
      expect(
        findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
          sourceDraft,
          eventSourceOptions,
        ),
        eventOption,
      );
      expect(
        validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
          sourceDraft,
          eventSourceOptions,
        ),
        isEmpty,
      );

      var draft = NarrativeScenarioAuthoringDraft(
        scenarioId: _scenarioId,
        name: 'P4 Authoring Scene',
        description: 'Generic minimal authoring flow',
        scope: ScenarioScope.localEventFlow,
        source: sourceDraft,
        actions: const [
          NarrativeScenarioAuthoringActionDraft.setFlag(
            flagName: _flagName,
          ),
          NarrativeScenarioAuthoringActionDraft.completeStep(
            stepId: _stepId,
          ),
        ],
        declaredOutcomes: const [],
      );
      draft = addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
        draft,
        _outcomeId,
      );
      draft = addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
        draft,
        _outcomeId,
      );
      draft = addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        draft,
        battleOption,
        npcEntityId: _entityId,
      );

      expect(validateNarrativeScenarioAuthoringDraft(draft), isEmpty);
      expect(
        validateNarrativeOutcomeAuthoringDraft(
          draft,
          battleOptions: battleOptions,
        ),
        isEmpty,
      );
      expect(
        narrativeScenarioOutcomeFlagReference(_outcomeId),
        'scenario.outcome.$_outcomeId',
      );
      expect(
        narrativeBattleOutcomeFlagReference(
          _battleId,
          NarrativeBattleOutcomeKind.victory,
        ),
        'battle:$_battleId:victory',
      );

      final receiverSourceDraft =
          createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
        outcomeOption,
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(receiverSourceDraft),
        'outcomeReceived:$_outcomeId',
      );
      expect(
        validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
          receiverSourceDraft,
          eventSourceOptions,
        ),
        isEmpty,
      );

      final flagPredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.storyFlag,
          _flagName,
        ),
      );
      final stepPredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.storyStep,
          _stepId,
        ),
      );
      final scenarioOutcomePredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.scenarioOutcome,
          narrativeScenarioOutcomeFlagReference(_outcomeId),
        ),
      );
      final battleOutcomePredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.battleOutcome,
          narrativeBattleOutcomeFlagReference(
            _battleId,
            NarrativeBattleOutcomeKind.victory,
          ),
        ),
      );

      final runtimeScenarioOutcomePredicate =
          compileNarrativePredicateAuthoringDraftToRuntimePredicate(
        scenarioOutcomePredicate,
      );
      final runtimeBattleOutcomePredicate =
          compileNarrativePredicateAuthoringDraftToRuntimePredicate(
        battleOutcomePredicate,
      );
      expect(
        runtimeScenarioOutcomePredicate.kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(
        runtimeScenarioOutcomePredicate.refId,
        'scenario.outcome.$_outcomeId',
      );
      expect(
        runtimeBattleOutcomePredicate.kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(runtimeBattleOutcomePredicate.refId, 'battle:$_battleId:victory');

      final visibilityRule =
          compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
        NarrativeVisibilityRuleAuthoringDraft.visibleWhen(
          predicate: flagPredicate,
        ),
      );
      final conditionalDialogue =
          compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
        NarrativeConditionalDialogueAuthoringDraft(
          dialogueId: _dialogueId,
          predicate: stepPredicate,
        ),
      );
      expect(visibilityRule.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(visibilityRule.predicate?.refId, _flagName);
      expect(conditionalDialogue.when.kind,
          MapEntityRuntimePredicateKind.stepCompleted);
      expect(conditionalDialogue.when.refId, _stepId);
      expect(conditionalDialogue.dialogue.dialogueId, _dialogueId);

      final scenarioAsset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);
      final receiverAsset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        NarrativeScenarioAuthoringDraft(
          scenarioId: _receiverScenarioId,
          name: 'P4 Authoring Outcome Receiver',
          source: receiverSourceDraft,
          actions: const [],
          declaredOutcomes: const [],
        ),
      );

      expect(scenarioAsset.id, _scenarioId);
      expect(scenarioAsset.name, 'P4 Authoring Scene');
      expect(scenarioAsset.scope, ScenarioScope.localEventFlow);
      expect(scenarioAsset.entryNodeId, '${_scenarioId}__start');
      expect(scenarioAsset.declaredOutcomes, [_outcomeId]);
      expect(
        scenarioAsset.nodes
            .where((node) => node.type == ScenarioNodeType.start),
        hasLength(1),
      );
      expect(
        scenarioAsset.nodes.where((node) => node.type == ScenarioNodeType.end),
        hasLength(1),
      );
      expect(_node(scenarioAsset, '${_scenarioId}__source').payload.actionKind,
          'sourceEntityInteract');
      expect(
          _node(scenarioAsset, '${_scenarioId}__source').binding.mapId, _mapId);
      expect(_node(scenarioAsset, '${_scenarioId}__source').binding.entityId,
          _entityId);
      expect(_node(scenarioAsset, '${_scenarioId}__action_0').binding.flagName,
          _flagName);
      expect(
        _node(scenarioAsset, '${_scenarioId}__action_1')
            .payload
            .params['stepId'],
        _stepId,
      );
      expect(_node(scenarioAsset, '${_scenarioId}__action_2').binding.outcomeId,
          _outcomeId);
      expect(_node(scenarioAsset, '${_scenarioId}__action_3').binding.trainerId,
          _trainerId);
      expect(_node(scenarioAsset, '${_scenarioId}__action_3').binding.entityId,
          _entityId);
      expect(
        _node(scenarioAsset, '${_scenarioId}__action_3')
            .payload
            .params['battleId'],
        _battleId,
      );
      expect(scenarioAsset.edges.map((edge) => edge.id), [
        '${_scenarioId}__edge_start_to_source',
        '${_scenarioId}__edge_source_to_action_0',
        '${_scenarioId}__edge_action_0_to_action_1',
        '${_scenarioId}__edge_action_1_to_action_2',
        '${_scenarioId}__edge_action_2_to_action_3',
        '${_scenarioId}__edge_action_3_to_end',
      ]);
      expect(
        _node(receiverAsset, '${_receiverScenarioId}__source')
            .payload
            .actionKind,
        'sourceOutcome',
      );

      final authoredMap = _map(
        visibilityRule: visibilityRule,
        conditionalDialogues: [conditionalDialogue],
      );
      final validationReport = diagnoseNarrativeProject(
        _manifest(scenarios: [scenarioAsset, receiverAsset]),
        maps: [authoredMap],
      );

      expect(validationReport.hasErrors, isFalse);
      expect(
        validationReport
            .byKind(NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared),
        isEmpty,
      );
      expect(
        validationReport.byKind(
          NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted,
        ),
        isEmpty,
      );
      expect(
        validationReport.byKind(
          NarrativeValidationDiagnosticKind
              .sourceEntityInteractReferencesUnknownMap,
        ),
        isEmpty,
      );
      expect(
        validationReport.byKind(
          NarrativeValidationDiagnosticKind
              .sourceEntityInteractReferencesUnknownEntity,
        ),
        isEmpty,
      );
      final validationViews = buildNarrativeAuthoringDiagnosticViews(
        validationReport.diagnostics,
      );
      expect(validationViews, hasLength(validationReport.diagnostics.length));
      expect(validationViews.every((view) => !view.hasAutomaticFix), isTrue);
      expect(
        validationViews.map((view) => view.severity),
        validationReport.diagnostics.map((diagnostic) => diagnostic.severity),
      );

      final serializedEvidence = [
        scenarioOptions.map((option) => option.humanLabel).join('|'),
        eventSourceOptions
            .map((option) => option.debugTechnicalLabel)
            .join('|'),
        outcomeOptions.map((option) => option.debugTechnicalLabel).join('|'),
        battleOptions.map((option) => option.debugTechnicalLabel).join('|'),
        predicateOptions.map((option) => option.debugTechnicalLabel).join('|'),
        scenarioAsset.toJson().toString(),
        receiverAsset.toJson().toString(),
        authoredMap.toJson().toString(),
        validationViews.map((view) => view.debugTechnicalLabel).join('|'),
      ].join('\n').toLowerCase();
      expect(serializedEvidence, isNot(contains('selbrume')));
      expect(serializedEvidence, isNot(contains('lysa')));
      expect(serializedEvidence, isNot(contains('mael')));
      expect(serializedEvidence, isNot(contains('maël')));
      expect(serializedEvidence, isNot(contains('mado')));
      expect(serializedEvidence, isNot(contains('registry')));
      expect(serializedEvidence, isNot(contains('reward')));
      expect(serializedEvidence, isNot(contains('money')));
      expect(serializedEvidence, isNot(contains('level-up')));
    });

    test('adapts validator diagnostics into authoring views without auto-fix',
        () {
      final invalidMap = _map(
        visibilityRule: const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
        ),
      );
      final report = diagnoseNarrativeProject(
        _manifest(scenarios: const []),
        maps: [invalidMap],
      );

      final diagnostic = report
          .byKind(
            NarrativeValidationDiagnosticKind
                .visibilityRuleConditionalMissingPredicate,
          )
          .single;
      final views = buildNarrativeAuthoringDiagnosticViews(report.diagnostics);
      final view = views.singleWhere(
        (candidate) => candidate.technicalKind == diagnostic.kind,
      );

      expect(view.category,
          NarrativeAuthoringDiagnosticCategory.predicateAuthoring);
      expect(
          view.actionKind, NarrativeAuthoringDiagnosticActionKind.fixPredicate);
      expect(view.severity, diagnostic.severity);
      expect(view.path, diagnostic.path);
      expect(view.mapId, _mapId);
      expect(view.entityId, _entityId);
      expect(view.hasAutomaticFix, isFalse);
      expect(
        () => views.add(view),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

ProjectManifest _manifest({
  required List<ScenarioAsset> scenarios,
}) {
  return ProjectManifest(
    name: _projectName,
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'P4 Authoring Field',
        relativePath: 'maps/p4_authoring_field.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: _dialogueId,
        name: 'P4 Visible Dialogue',
        relativePath: 'dialogues/p4_visible.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'P4 Trainer',
        trainerClass: 'Authoring Tester',
      ),
    ],
    scenarios: scenarios,
  );
}

MapData _map({
  MapEntityNpcVisibilityRule? visibilityRule,
  List<MapEntityConditionalDialogue> conditionalDialogues = const [],
}) {
  return MapData(
    id: _mapId,
    name: 'P4 Authoring Field',
    size: const GridSize(width: 8, height: 8),
    entities: [
      MapEntity(
        id: _entityId,
        name: 'P4 Authoring NPC',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          displayName: 'P4 Authoring Guide',
          dialogue: const DialogueRef(dialogueId: _dialogueId),
          trainerId: _trainerId,
          visibilityRule: visibilityRule,
          conditionalDialogues: conditionalDialogues,
        ),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: _triggerId,
        name: 'P4 Authoring Trigger',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
        ),
      ),
    ],
  );
}

ScenarioAsset _referenceScenario() {
  return ScenarioAsset(
    id: _referenceScenarioId,
    name: 'P4 Authoring Reference Scene',
    entryNodeId: 'source',
    declaredOutcomes: const [_outcomeId],
    nodes: const [
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(mapId: _mapId, entityId: _entityId),
        payload: ScenarioNodePayload(actionKind: 'sourceEntityInteract'),
      ),
      ScenarioNode(
        id: 'set_flag',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(flagName: _flagName),
        payload: ScenarioNodePayload(actionKind: 'setFlag'),
      ),
      ScenarioNode(
        id: 'complete_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: 'completeStep',
          params: {'stepId': _stepId},
        ),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(outcomeId: _outcomeId),
        payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
      ),
      ScenarioNode(
        id: 'battle',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(
          trainerId: _trainerId,
          entityId: _entityId,
        ),
        payload: ScenarioNodePayload(
          actionKind: 'startTrainerBattle',
          params: {'battleId': _battleId},
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const [
      ScenarioEdge(
          id: 'source_to_flag', fromNodeId: 'source', toNodeId: 'set_flag'),
      ScenarioEdge(
        id: 'flag_to_step',
        fromNodeId: 'set_flag',
        toNodeId: 'complete_step',
      ),
      ScenarioEdge(
        id: 'step_to_emit',
        fromNodeId: 'complete_step',
        toNodeId: 'emit',
      ),
      ScenarioEdge(
          id: 'emit_to_battle', fromNodeId: 'emit', toNodeId: 'battle'),
      ScenarioEdge(id: 'battle_to_end', fromNodeId: 'battle', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _referenceOutcomeReceiverScenario() {
  return const ScenarioAsset(
    id: 'p4_authoring_reference_receiver',
    name: 'P4 Authoring Reference Receiver',
    entryNodeId: 'source',
    nodes: [
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(outcomeId: _outcomeId),
        payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(id: 'source_to_end', fromNodeId: 'source', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _referenceStoryScenario() {
  return const ScenarioAsset(
    id: _storyScenarioId,
    name: 'P4 Authoring Story',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: [
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(outcomeId: _outcomeId),
        payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(id: 'source_to_end', fromNodeId: 'source', toNodeId: 'end'),
    ],
    metadata: {
      'authoring.stepStudioDocument': '''
{
  "schemaVersion": "step_studio_v1",
  "globalStoryScenarioId": "$_storyScenarioId",
  "steps": [
    {
      "id": "$_stepId",
      "name": "P4 Step Completed",
      "description": "Generic authoring step",
      "order": 0,
      "activation": {"mode": "whenFlagTrue", "flagName": "$_flagName"},
      "completion": {
        "mode": "whenCutsceneEnds",
        "cutsceneId": "$_cutsceneId"
      },
      "cutscenes": [
        {"cutsceneId": "$_cutsceneId", "role": "main"}
      ],
      "outcomes": [
        {
          "label": "P4 Outcome Done",
          "scope": "progression",
          "outcomeId": "$_outcomeId"
        }
      ]
    }
  ]
}
''',
    },
  );
}

NarrativeEventSourcePickerOption _eventSourceOption(
  List<NarrativeEventSourcePickerOption> options,
  NarrativeEventSourceKind kind,
) {
  return options.singleWhere(
    (option) =>
        option.sourceKind == kind &&
        option.mapId == _mapId &&
        option.entityId == _entityId,
  );
}

NarrativeOutcomePickerOption _outcomeOption(
  List<NarrativeOutcomePickerOption> options,
  String outcomeId,
) {
  return options.singleWhere((option) => option.outcomeId == outcomeId);
}

NarrativeBattleReferencePickerOption _battleOption(
  List<NarrativeBattleReferencePickerOption> options,
  String battleId,
) {
  return options.singleWhere((option) => option.battleId == battleId);
}

NarrativePredicateReferencePickerOption _predicateOption(
  List<NarrativePredicateReferencePickerOption> options,
  NarrativePredicateReferenceKind kind,
  String referenceId,
) {
  return options.singleWhere(
    (option) =>
        option.referenceKind == kind && option.referenceId == referenceId,
  );
}

ScenarioNode _node(ScenarioAsset scenario, String nodeId) {
  return scenario.nodes.singleWhere((node) => node.id == nodeId);
}
