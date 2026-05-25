import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative reference picker read models', () {
    test('builds scenario picker options with stable labels and counts', () {
      final options = buildNarrativeScenarioPickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'zeta_scene',
              name: 'Zeta Scene',
              description: 'Late scene',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const ['zeta.done'],
            ),
            _scenario(
              id: 'alpha_scene',
              name: ' ',
              description: 'Fallback label scene',
              declaredOutcomes: const ['alpha.done', 'alpha.done', ' '],
            ),
          ],
        ),
      );

      expect(options.map((option) => option.scenarioId), [
        'alpha_scene',
        'zeta_scene',
      ]);

      final alpha = options.first;
      expect(alpha.humanLabel, 'alpha_scene');
      expect(alpha.description, 'Fallback label scene');
      expect(alpha.scope, ScenarioScope.localEventFlow);
      expect(alpha.entryNodeId, 'source');
      expect(alpha.declaredOutcomeIds, ['alpha.done']);
      expect(alpha.nodeCount, 3);
      expect(alpha.edgeCount, 2);
      expect(alpha.debugTechnicalLabel, 'alpha_scene');

      final zeta = options.last;
      expect(zeta.humanLabel, 'Zeta Scene');
      expect(zeta.scope, ScenarioScope.globalStory);
    });

    test('builds outcome picker options from declared emitted and consumed ids',
        () {
      final options = buildNarrativeOutcomePickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'local_scene',
              declaredOutcomes: const ['alpha.done', 'unused'],
              extraNodes: const [
                ScenarioNode(
                  id: 'emit_orphan',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(outcomeId: 'orphan.emit'),
                  payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                ),
              ],
            ),
            _scenario(
              id: 'global_scene',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const ['trigger.ready'],
              nodes: const [
                ScenarioNode(
                  id: 'source_alpha',
                  type: ScenarioNodeType.reference,
                  binding: ScenarioNodeBinding(outcomeId: 'alpha.done'),
                  payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
                ),
                ScenarioNode(
                  id: 'emit_trigger',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(outcomeId: 'trigger.ready'),
                  payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                ),
              ],
              edges: const [
                ScenarioEdge(
                  id: 'source_to_emit',
                  fromNodeId: 'source_alpha',
                  toNodeId: 'emit_trigger',
                ),
              ],
            ),
          ],
        ),
      );

      expect(options.map((option) => option.outcomeId), [
        'alpha.done',
        'orphan.emit',
        'trigger.ready',
        'unused',
      ]);

      final alpha = _byOutcomeId(options, 'alpha.done');
      expect(alpha.humanLabel, 'alpha done');
      expect(alpha.declaredByScenarioIds, ['local_scene']);
      expect(alpha.emittedByScenarioIds, ['local_scene']);
      expect(alpha.consumedByScenarioIds, ['global_scene']);
      expect(alpha.isDeclared, isTrue);
      expect(alpha.isEmitted, isTrue);
      expect(alpha.isConsumed, isTrue);
      expect(alpha.isOrphan, isFalse);
      expect(alpha.debugTechnicalLabel, 'alpha.done');

      final orphan = _byOutcomeId(options, 'orphan.emit');
      expect(orphan.isDeclared, isFalse);
      expect(orphan.isEmitted, isTrue);
      expect(orphan.isConsumed, isFalse);
      expect(orphan.isOrphan, isTrue);

      final unused = _byOutcomeId(options, 'unused');
      expect(unused.isDeclared, isTrue);
      expect(unused.isEmitted, isFalse);
      expect(unused.isConsumed, isFalse);
      expect(unused.isOrphan, isTrue);
    });

    test('builds battle reference picker options from trainer battle nodes',
        () {
      final options = buildNarrativeBattleReferencePickerOptions(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'rival',
              name: 'Karim',
              trainerClass: 'Rival',
            ),
          ],
          scenarios: [
            _scenario(
              id: 'duel_scene',
              nodes: const [
                ScenarioNode(
                  id: 'battle_node',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(
                    trainerId: 'rival',
                    entityId: 'rival_npc',
                  ),
                  payload: ScenarioNodePayload(
                    actionKind: 'startTrainerBattle',
                    params: {'battleId': 'port_duel'},
                  ),
                ),
              ],
              edges: const [],
            ),
            _scenario(
              id: 'unknown_scene',
              nodes: const [
                ScenarioNode(
                  id: 'unknown_battle',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(
                    trainerId: 'missing_trainer',
                    entityId: 'ghost_npc',
                  ),
                  payload: ScenarioNodePayload(
                    actionKind: 'startTrainerBattle',
                  ),
                ),
              ],
              edges: const [],
            ),
          ],
        ),
      );

      expect(options.map((option) => option.battleReferenceId), [
        'unknown_scene:unknown_battle',
        'duel_scene:battle_node',
      ]);

      final known = _byBattleReferenceId(options, 'duel_scene:battle_node');
      expect(known.battleId, 'port_duel');
      expect(known.humanLabel, 'Rival Karim');
      expect(known.sourceScenarioId, 'duel_scene');
      expect(known.sourceNodeId, 'battle_node');
      expect(known.trainerId, 'rival');
      expect(known.trainerLabel, 'Karim');
      expect(known.trainerClass, 'Rival');
      expect(known.npcEntityId, 'rival_npc');
      expect(known.isTrainerKnown, isTrue);
      expect(known.supportedOutcomeKinds, [
        NarrativeBattleOutcomeKind.victory,
        NarrativeBattleOutcomeKind.defeat,
      ]);
      expect(known.debugTechnicalLabel, 'duel_scene:battle_node -> port_duel');

      final unknown =
          _byBattleReferenceId(options, 'unknown_scene:unknown_battle');
      expect(unknown.battleId, 'missing_trainer');
      expect(unknown.humanLabel, 'missing_trainer');
      expect(unknown.isTrainerKnown, isFalse);
      expect(unknown.trainerLabel, isNull);
      expect(unknown.trainerClass, isNull);
    });

    test('builds story step picker options from Step Studio metadata', () {
      final options = buildNarrativeStoryStepPickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const [],
              metadata: {
                'authoring.stepStudioDocument': '''
{
  "schemaVersion": "step_studio_v1",
  "globalStoryScenarioId": "global_story",
  "steps": [
    {
      "id": "p4.step.second",
      "name": "Second Step",
      "description": "Follow-up",
      "order": 1,
      "activation": {"mode": "afterOutcome", "outcomeId": "p4.outcome.first.done"},
      "completion": {"mode": "whenOutcomeEmitted", "outcomeId": "p4.outcome.second.done"},
      "cutscenes": [{"cutsceneId": "p4_second_cutscene", "role": "main"}],
      "outcomes": [{"label": "Second done", "scope": "progression", "outcomeId": "p4.outcome.second.done"}]
    },
    {
      "id": "p4.step.first",
      "name": "First Step",
      "description": "Start here",
      "order": 0,
      "activation": {"mode": "atGameStart"},
      "completion": {"mode": "whenCutsceneEnds", "cutsceneId": "p4_first_cutscene"},
      "cutscenes": [{"cutsceneId": "p4_first_cutscene", "role": "main"}],
      "outcomes": [{"label": "First done", "scope": "progression", "outcomeId": "p4.outcome.first.done"}]
    }
  ]
}
''',
              },
            ),
          ],
        ),
      );

      expect(options.map((option) => option.stepId), [
        'p4.step.first',
        'p4.step.second',
      ]);

      final first = options.first;
      expect(first.humanLabel, 'First Step');
      expect(first.description, 'Start here');
      expect(first.sourceScenarioId, 'global_story');
      expect(first.sourceScenarioLabel, 'Global Story');
      expect(first.sourceKind, NarrativeStoryStepPickerSource.stepStudio);
      expect(first.order, 0);
      expect(first.linkedCutsceneIds, ['p4_first_cutscene']);
      expect(first.expectedOutcomeIds, isEmpty);
      expect(first.emittedOutcomeIds, ['p4.outcome.first.done']);
      expect(first.debugTechnicalLabel, 'global_story:p4.step.first');

      final second = options.last;
      expect(second.expectedOutcomeIds, ['p4.outcome.first.done']);
      expect(second.emittedOutcomeIds, ['p4.outcome.second.done']);
    });

    test('dedupes story steps and keeps legacy metadata as fallback', () {
      final options = buildNarrativeStoryStepPickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const [],
              metadata: {
                'step.id': 'p4.legacy.step',
                'step.name': 'Legacy Step',
                'step.description': 'Legacy description',
                'step.cutsceneIds': 'cutscene_a, cutscene_b, cutscene_a',
              },
            ),
            _scenario(
              id: 'broken_story',
              name: 'Broken Story',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const [],
              metadata: const {
                'authoring.stepStudioDocument': '{broken json',
              },
            ),
          ],
        ),
      );

      expect(options, hasLength(1));
      expect(options.single.stepId, 'p4.legacy.step');
      expect(options.single.humanLabel, 'Legacy Step');
      expect(options.single.description, 'Legacy description');
      expect(
        options.single.sourceKind,
        NarrativeStoryStepPickerSource.legacyMetadata,
      );
      expect(options.single.linkedCutsceneIds, [
        'cutscene_a',
        'cutscene_b',
      ]);
    });

    test('builds event source picker options from maps entities and outcomes',
        () {
      final options = buildNarrativeEventSourcePickerOptions(
        _manifest(
          maps: const [
            ProjectMapEntry(
              id: 'p4_map',
              name: 'P4 Test Map',
              relativePath: 'maps/p4_test_map.json',
            ),
          ],
          scenarios: [
            _scenario(
              id: 'source_scenario',
              declaredOutcomes: const ['p4.outcome.ready'],
              nodes: const [
                ScenarioNode(
                  id: 'emit',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(outcomeId: 'p4.outcome.ready'),
                  payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                ),
              ],
              edges: const [],
            ),
          ],
        ),
        maps: [
          _mapData(
            id: 'p4_map',
            name: 'P4 Test Map Runtime',
            entities: const [
              MapEntity(
                id: 'p4_npc',
                name: 'Technical NPC',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2, y: 3),
                npc: MapEntityNpcData(displayName: 'P4 Guide'),
              ),
            ],
            triggers: const [
              MapTrigger(
                id: 'p4_trigger',
                name: 'P4 Trigger',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 2, height: 2),
                ),
              ),
            ],
          ),
        ],
      );

      expect(options.map((option) => option.sourceKind), [
        NarrativeEventSourceKind.mapEnter,
        NarrativeEventSourceKind.triggerEnter,
        NarrativeEventSourceKind.entityInteract,
        NarrativeEventSourceKind.outcomeReceived,
      ]);

      final mapEnter = _byEventSourceKind(
        options,
        NarrativeEventSourceKind.mapEnter,
      );
      expect(mapEnter.sourceId, 'mapEnter:p4_map');
      expect(mapEnter.mapId, 'p4_map');
      expect(mapEnter.humanLabel, 'Map enter: P4 Test Map');

      final trigger = _byEventSourceKind(
        options,
        NarrativeEventSourceKind.triggerEnter,
      );
      expect(trigger.sourceId, 'triggerEnter:p4_map:p4_trigger');
      expect(trigger.triggerId, 'p4_trigger');
      expect(trigger.humanLabel, 'Trigger enter: P4 Trigger (P4 Test Map)');

      final entity = _byEventSourceKind(
        options,
        NarrativeEventSourceKind.entityInteract,
      );
      expect(entity.sourceId, 'entityInteract:p4_map:p4_npc');
      expect(entity.entityId, 'p4_npc');
      expect(entity.humanLabel, 'Entity interact: P4 Guide (P4 Test Map)');

      final outcome = _byEventSourceKind(
        options,
        NarrativeEventSourceKind.outcomeReceived,
      );
      expect(outcome.sourceId, 'outcomeReceived:p4.outcome.ready');
      expect(outcome.outcomeId, 'p4.outcome.ready');
      expect(outcome.humanLabel, 'Outcome received: p4 outcome ready');
    });

    test('builds predicate reference picker options from derived facts', () {
      final options = buildNarrativePredicateReferencePickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const [],
              activationCondition: ScriptConditionFactory.flagIsSet(
                'p4.flag.ready',
              ),
              metadata: {
                'authoring.stepStudioDocument': '''
{
  "schemaVersion": "step_studio_v1",
  "globalStoryScenarioId": "global_story",
  "steps": [
    {
      "id": "p4.step.ready",
      "name": "Ready Step",
      "description": "",
      "order": 0,
      "activation": {"mode": "whenFlagTrue", "flagName": "p4.flag.ready"},
      "completion": {"mode": "whenCutsceneEnds", "cutsceneId": "p4_cutscene"}
    }
  ]
}
''',
              },
              nodes: const [
                ScenarioNode(
                  id: 'set_flag',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(flagName: 'p4.flag.ready'),
                  payload: ScenarioNodePayload(actionKind: 'setFlag'),
                ),
              ],
              edges: const [],
            ),
            _scenario(
              id: 'p4_cutscene',
              name: 'P4 Cutscene',
              declaredOutcomes: const ['p4.outcome.done'],
              nodes: const [
                ScenarioNode(
                  id: 'emit',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(outcomeId: 'p4.outcome.done'),
                  payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                ),
                ScenarioNode(
                  id: 'battle',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(trainerId: 'p4_trainer'),
                  payload: ScenarioNodePayload(
                    actionKind: 'startTrainerBattle',
                    params: {'battleId': 'p4_battle'},
                  ),
                ),
              ],
              edges: const [],
            ),
          ],
        ),
      );

      expect(
        _byPredicateReference(
          options,
          NarrativePredicateReferenceKind.storyFlag,
          'p4.flag.ready',
        ).sourceScenarioIds,
        ['global_story'],
      );
      expect(
        _byPredicateReference(
          options,
          NarrativePredicateReferenceKind.storyStep,
          'p4.step.ready',
        ).humanLabel,
        'Ready Step',
      );
      expect(
        _byPredicateReference(
          options,
          NarrativePredicateReferenceKind.cutscene,
          'p4_cutscene',
        ).humanLabel,
        'P4 Cutscene',
      );
      expect(
        _byPredicateReference(
          options,
          NarrativePredicateReferenceKind.scenarioOutcome,
          'scenario.outcome.p4.outcome.done',
        ).sourceScenarioIds,
        ['p4_cutscene'],
      );
      expect(
        _byPredicateReference(
          options,
          NarrativePredicateReferenceKind.battleOutcome,
          'battle:p4_battle:victory',
        ).humanLabel,
        'P4 battle victory',
      );
      expect(
        _byPredicateReference(
          options,
          NarrativePredicateReferenceKind.battleOutcome,
          'battle:p4_battle:defeat',
        ).debugTechnicalLabel,
        'battle:p4_battle:defeat',
      );
    });

    test('returns empty missing read model options for empty sources', () {
      final emptyManifest = _manifest(scenarios: const []);

      expect(buildNarrativeStoryStepPickerOptions(emptyManifest), isEmpty);
      expect(buildNarrativeEventSourcePickerOptions(emptyManifest), isEmpty);
      expect(
        buildNarrativePredicateReferencePickerOptions(emptyManifest),
        isEmpty,
      );
    });
  });
}

ProjectManifest _manifest({
  List<ProjectMapEntry> maps = const [],
  List<ScenarioAsset>? scenarios,
  List<ProjectTrainerEntry> trainers = const [],
}) {
  return ProjectManifest(
    name: 'Picker Test Project',
    maps: maps,
    tilesets: const [],
    scenarios: scenarios ?? const [],
    trainers: trainers,
  );
}

ScenarioAsset _scenario({
  required String id,
  String name = 'Test Scene',
  String description = '',
  ScenarioScope scope = ScenarioScope.localEventFlow,
  List<String> declaredOutcomes = const ['alpha.done'],
  List<ScenarioNode>? nodes,
  List<ScenarioNode> extraNodes = const [],
  List<ScenarioEdge>? edges,
  Map<String, String> metadata = const {},
  ScriptCondition? activationCondition,
}) {
  return ScenarioAsset(
    id: id,
    name: name,
    description: description,
    scope: scope,
    entryNodeId: 'source',
    declaredOutcomes: declaredOutcomes,
    activationCondition: activationCondition,
    nodes: nodes ??
        [
          const ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            binding: ScenarioNodeBinding(outcomeId: 'trigger.ready'),
            payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
          ),
          const ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            binding: ScenarioNodeBinding(outcomeId: 'alpha.done'),
            payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
          ),
          const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
          ...extraNodes,
        ],
    edges: edges ??
        const [
          ScenarioEdge(
              id: 'source_to_emit', fromNodeId: 'source', toNodeId: 'emit'),
          ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
        ],
    metadata: metadata,
  );
}

MapData _mapData({
  required String id,
  required String name,
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    entities: entities,
    triggers: triggers,
  );
}

NarrativeOutcomePickerOption _byOutcomeId(
  List<NarrativeOutcomePickerOption> options,
  String outcomeId,
) {
  return options.singleWhere((option) => option.outcomeId == outcomeId);
}

NarrativeBattleReferencePickerOption _byBattleReferenceId(
  List<NarrativeBattleReferencePickerOption> options,
  String battleReferenceId,
) {
  return options.singleWhere(
    (option) => option.battleReferenceId == battleReferenceId,
  );
}

NarrativeEventSourcePickerOption _byEventSourceKind(
  List<NarrativeEventSourcePickerOption> options,
  NarrativeEventSourceKind sourceKind,
) {
  return options.singleWhere((option) => option.sourceKind == sourceKind);
}

NarrativePredicateReferencePickerOption _byPredicateReference(
  List<NarrativePredicateReferencePickerOption> options,
  NarrativePredicateReferenceKind referenceKind,
  String referenceId,
) {
  return options.singleWhere(
    (option) =>
        option.referenceKind == referenceKind &&
        option.referenceId == referenceId,
  );
}
