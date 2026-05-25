import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative Validator Minimal V0', () {
    test('valid minimal golden slice returns no diagnostics', () {
      final report = diagnoseNarrativeProject(
        _manifest(),
        maps: [_map()],
      );

      expect(report.diagnostics, isEmpty);
      expect(report.hasErrors, isFalse);
    });

    test('unknown edge target produces error', () {
      final scenario = _localScenario(
        edges: [
          _edge('test_edge_source_flag', 'test_source', 'test_set_flag'),
          _edge('test_edge_missing', 'test_set_flag', 'test_missing_node'),
        ],
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.scenarioNodeReferencesUnknownNode,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_missing_node');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.error);
    });

    test('unreachable node produces warning', () {
      final scenario = _localScenario(
        extraNodes: [
          const ScenarioNode(
            id: 'test_unreachable',
            type: ScenarioNodeType.action,
          ),
        ],
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.scenarioGraphHasUnreachableNode,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.nodeId, 'test_unreachable');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.warning);
    });

    test('scenario without source produces error', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_without_source',
        name: 'Test Scene Without Source',
        entryNodeId: 'test_start',
        nodes: const [
          ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
          ScenarioNode(id: 'test_end', type: ScenarioNodeType.end),
        ],
        edges: [_edge('test_edge_start_end', 'test_start', 'test_end')],
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.severity, NarrativeValidationSeverity.error);
    });

    test('openDialogue with unknown dialogue produces error', () {
      final scenario = _localScenario(
        nodes: [
          _sourceNode(),
          const ScenarioNode(
            id: 'test_dialogue_node',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'test_missing_dialogue'),
          ),
          _endNode(),
        ],
        edges: [
          _edge(
              'test_edge_source_dialogue', 'test_source', 'test_dialogue_node'),
          _edge('test_edge_dialogue_end', 'test_dialogue_node', 'test_end'),
        ],
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_missing_dialogue');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.error);
    });

    test('startTrainerBattle with unknown trainer produces error', () {
      final scenario = _globalBattleScenario(
        trainerId: 'test_missing_trainer',
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind
            .startTrainerBattleReferencesUnknownTrainer,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_missing_trainer');
    });

    test('startTrainerBattle with blank trainerId produces error', () {
      final scenario = _globalBattleScenario(trainerId: ' ');

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      expect(
        report.byKind(
          NarrativeValidationDiagnosticKind.startTrainerBattleMissingTrainerId,
        ),
        hasLength(1),
      );
    });

    test('startTrainerBattle with blank npcEntityId produces error', () {
      final scenario = _globalBattleScenario(npcEntityId: ' ');

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      expect(
        report.byKind(
          NarrativeValidationDiagnosticKind
              .startTrainerBattleMissingNpcEntityId,
        ),
        hasLength(1),
      );
    });

    test('startTrainerBattle with explicit blank battleId produces error', () {
      final scenario = _globalBattleScenario(battleId: ' ');

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      expect(
        report.byKind(
          NarrativeValidationDiagnosticKind.startTrainerBattleBlankBattleId,
        ),
        hasLength(1),
      );
    });

    test('source entityInteract with unknown map produces error', () {
      final scenario = _localScenario(
        source: _sourceNode(mapId: 'test_missing_map'),
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind
            .sourceEntityInteractReferencesUnknownMap,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_missing_map');
    });

    test('source entityInteract with unknown entity produces error', () {
      final scenario = _localScenario(
        source: _sourceNode(entityId: 'test_missing_entity'),
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind
            .sourceEntityInteractReferencesUnknownEntity,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_missing_entity');
    });

    test('sourceOutcome without matching emitOutcome produces warning', () {
      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [_globalBattleScenario()]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind
            .sourceOutcomeWithoutMatchingEmitOutcome,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_outcome');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.warning);
    });

    test('emitOutcome without matching sourceOutcome produces warning', () {
      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [_localScenario()]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind
            .emitOutcomeWithoutMatchingSourceOutcome,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_outcome');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.warning);
    });

    test('declared outcome never emitted produces warning', () {
      final scenario = _localScenario(
        declaredOutcomes: const ['test_outcome', 'unused_outcome'],
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'unused_outcome');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.warning);
    });

    test('emitOutcome not declared by scenario produces warning', () {
      final scenario = _localScenario(declaredOutcomes: const []);

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.referencedId, 'test_outcome');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.warning);
    });

    test('conditional visibility rule without predicate produces error', () {
      final report = diagnoseNarrativeProject(
        _manifest(),
        maps: [
          _map(
            visibilityRule: const MapEntityNpcVisibilityRule(
              mode: MapEntityNpcVisibilityMode.visibleWhen,
            ),
          ),
        ],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind
            .visibilityRuleConditionalMissingPredicate,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.mapId, 'test_map');
      expect(diagnostics.single.entityId, 'test_entity');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.error);
    });

    test('world rule predicate with empty refId produces error', () {
      final report = diagnoseNarrativeProject(
        _manifest(),
        maps: [
          _map(
            visibilityRule: const MapEntityNpcVisibilityRule(
              mode: MapEntityNpcVisibilityMode.hiddenWhen,
              predicate: MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.stepCompleted,
                refId: ' ',
              ),
            ),
          ),
        ],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.path,
          'maps.test_map.entities.test_entity.visibilityRule.predicate.refId');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.error);
    });

    test('choice node produces runtime unsupported warning', () {
      final scenario = _localScenario(
        nodes: [
          _sourceNode(),
          const ScenarioNode(id: 'test_choice', type: ScenarioNodeType.choice),
          _setFlagNode(),
          _completeStepNode(),
          _emitOutcomeNode(),
          _endNode(),
        ],
        edges: [
          _edge('test_edge_source_choice', 'test_source', 'test_choice'),
          _edge('test_edge_choice_flag', 'test_choice', 'test_set_flag'),
          _edge('test_edge_choice_end', 'test_choice', 'test_end'),
          _edge('test_edge_flag_step', 'test_set_flag', 'test_complete_step'),
          _edge(
            'test_edge_step_outcome',
            'test_complete_step',
            'test_emit_outcome',
          ),
          _edge('test_edge_outcome_end', 'test_emit_outcome', 'test_end'),
        ],
      );

      final report = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
        maps: [_map()],
      );

      final diagnostics = report.byKind(
        NarrativeValidationDiagnosticKind.scenarioChoiceNodeRuntimeUnsupported,
      );
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.nodeId, 'test_choice');
      expect(diagnostics.single.severity, NarrativeValidationSeverity.warning);
    });

    test('setFlag used by condition does not warn as unused', () {
      final report = diagnoseNarrativeProject(
        _manifest(),
        maps: [_map()],
      );

      expect(
        report.byKind(NarrativeValidationDiagnosticKind.setFlagNeverRead),
        isEmpty,
      );
      expect(
        report.byKind(NarrativeValidationDiagnosticKind.flagReadNeverProduced),
        isEmpty,
      );
    });

    test('completeStep used by world rule does not warn as unused', () {
      final report = diagnoseNarrativeProject(
        _manifest(),
        maps: [_map()],
      );

      expect(
        report.byKind(NarrativeValidationDiagnosticKind.completeStepNeverRead),
        isEmpty,
      );
      expect(
        report.byKind(NarrativeValidationDiagnosticKind.stepReadNeverCompleted),
        isEmpty,
      );
    });

    test('diagnostics are stable and sorted deterministically', () {
      final scenario = _globalBattleScenario(
        trainerId: 'test_missing_trainer',
      );

      final first = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
      );
      final second = diagnoseNarrativeProject(
        _manifest(scenarios: [scenario]),
      );

      expect(first, second);
      expect(
        first.diagnostics.map((d) => d.kind).toList(),
        [
          NarrativeValidationDiagnosticKind
              .startTrainerBattleReferencesUnknownTrainer,
          NarrativeValidationDiagnosticKind
              .sourceOutcomeWithoutMatchingEmitOutcome,
        ],
      );
    });
  });
}

ProjectManifest _manifest({
  List<ScenarioAsset>? scenarios,
}) {
  return ProjectManifest(
    name: 'Test Project',
    maps: const [
      ProjectMapEntry(
        id: 'test_map',
        name: 'Test Map',
        relativePath: 'maps/test_map.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'test_dialogue',
        name: 'Test Dialogue',
        relativePath: 'dialogues/test_dialogue.yarn',
      ),
      ProjectDialogueEntry(
        id: 'test_step_dialogue',
        name: 'Test Step Dialogue',
        relativePath: 'dialogues/test_step_dialogue.yarn',
      ),
    ],
    scenarios: scenarios ?? [_localScenario(), _globalBattleScenario()],
    trainers: const [
      ProjectTrainerEntry(
        id: 'test_trainer',
        name: 'Test Trainer',
        trainerClass: 'Test Class',
      ),
    ],
  );
}

MapData _map({
  MapEntityNpcVisibilityRule? visibilityRule,
}) {
  return MapData(
    id: 'test_map',
    name: 'Test Map',
    size: const GridSize(width: 10, height: 10),
    entities: [
      MapEntity(
        id: 'test_entity',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Test Entity',
          dialogue: const DialogueRef(dialogueId: 'test_dialogue'),
          visibilityRule: visibilityRule ??
              const MapEntityNpcVisibilityRule(
                mode: MapEntityNpcVisibilityMode.visibleWhen,
                predicate: MapEntityRuntimePredicate(
                  kind: MapEntityRuntimePredicateKind.storyFlagSet,
                  refId: 'test_fact',
                ),
              ),
          conditionalDialogues: [
            MapEntityConditionalDialogue(
              when: MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.stepCompleted,
                refId: 'test_step',
              ),
              dialogue: DialogueRef(dialogueId: 'test_step_dialogue'),
            ),
          ],
        ),
      ),
    ],
  );
}

ScenarioAsset _localScenario({
  List<String> declaredOutcomes = const ['test_outcome'],
  ScenarioNode? source,
  List<ScenarioNode>? nodes,
  List<ScenarioNode> extraNodes = const [],
  List<ScenarioEdge>? edges,
}) {
  return ScenarioAsset(
    id: 'test_scene_local',
    name: 'Test Local Scene',
    entryNodeId: 'test_source',
    declaredOutcomes: declaredOutcomes,
    nodes: nodes ??
        [
          source ?? _sourceNode(),
          _setFlagNode(),
          _completeStepNode(),
          _emitOutcomeNode(),
          _endNode(),
          ...extraNodes,
        ],
    edges: edges ??
        [
          _edge('test_edge_source_flag', 'test_source', 'test_set_flag'),
          _edge('test_edge_flag_step', 'test_set_flag', 'test_complete_step'),
          _edge(
            'test_edge_step_outcome',
            'test_complete_step',
            'test_emit_outcome',
          ),
          _edge('test_edge_outcome_end', 'test_emit_outcome', 'test_end'),
        ],
  );
}

ScenarioAsset _globalBattleScenario({
  String outcomeId = 'test_outcome',
  String trainerId = 'test_trainer',
  String npcEntityId = 'test_entity',
  String? battleId = 'test_battle',
}) {
  return ScenarioAsset(
    id: 'test_scene_global',
    name: 'Test Global Scene',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'test_source_outcome',
    nodes: [
      ScenarioNode(
        id: 'test_source_outcome',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(outcomeId: outcomeId),
        payload: const ScenarioNodePayload(actionKind: 'sourceOutcome'),
      ),
      ScenarioNode(
        id: 'test_battle_node',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(
          trainerId: trainerId,
          entityId: npcEntityId,
        ),
        payload: ScenarioNodePayload(
          actionKind: 'startTrainerBattle',
          params: battleId == null ? const {} : {'battleId': battleId},
        ),
      ),
      _endNode(),
    ],
    edges: [
      _edge(
        'test_edge_source_battle',
        'test_source_outcome',
        'test_battle_node',
      ),
      _edge('test_edge_battle_end', 'test_battle_node', 'test_end'),
    ],
  );
}

ScenarioNode _sourceNode({
  String mapId = 'test_map',
  String entityId = 'test_entity',
}) {
  return ScenarioNode(
    id: 'test_source',
    type: ScenarioNodeType.reference,
    binding: ScenarioNodeBinding(mapId: mapId, entityId: entityId),
    payload: const ScenarioNodePayload(actionKind: 'sourceEntityInteract'),
  );
}

ScenarioNode _setFlagNode() {
  return const ScenarioNode(
    id: 'test_set_flag',
    type: ScenarioNodeType.action,
    binding: ScenarioNodeBinding(flagName: 'test_fact'),
    payload: ScenarioNodePayload(actionKind: 'setFlag'),
  );
}

ScenarioNode _completeStepNode() {
  return const ScenarioNode(
    id: 'test_complete_step',
    type: ScenarioNodeType.action,
    payload: ScenarioNodePayload(
      actionKind: 'completeStep',
      params: {'stepId': 'test_step'},
    ),
  );
}

ScenarioNode _emitOutcomeNode() {
  return const ScenarioNode(
    id: 'test_emit_outcome',
    type: ScenarioNodeType.action,
    binding: ScenarioNodeBinding(outcomeId: 'test_outcome'),
    payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
  );
}

ScenarioNode _endNode() {
  return const ScenarioNode(id: 'test_end', type: ScenarioNodeType.end);
}

ScenarioEdge _edge(String id, String fromNodeId, String toNodeId) {
  return ScenarioEdge(
    id: id,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
  );
}
