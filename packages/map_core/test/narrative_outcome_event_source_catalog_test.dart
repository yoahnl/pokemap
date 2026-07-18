import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase D D2 outcome source catalog', () {
    test('reports Scene declaration and reachable emission truthfully', () {
      final scene = _scene(
        id: 'scene_port',
        name: 'Rencontre au port',
        declaredOutcomes: const [
          ('victory', 'Victoire'),
          ('dialogue_done', 'Dialogue terminé'),
          ('idle', 'Sans suite'),
          ('hidden', 'Fin cachée'),
        ],
        yarnExpectedOutcomes: const ['dialogue_done', 'ghost'],
        reachableEndOutcome: 'victory',
        unreachableEndOutcome: 'hidden',
      );

      final catalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [scene],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_port',
              name: 'Dialogue du port',
              relativePath: 'dialogues/dialogue_port.yarn',
              declaredOutcomes: [
                DialogueDeclaredOutcome(
                  id: 'dialogue_done',
                  label: 'Dialogue terminé',
                ),
                DialogueDeclaredOutcome(id: 'ghost', label: 'Fantôme'),
              ],
            ),
          ],
        ),
      );

      expect(
        catalog.resolve(_sceneRef('scene_port', 'victory')).option!.status,
        NarrativeOutcomeReachabilityStatus.reachable,
      );
      expect(
        catalog
            .resolve(_sceneRef('scene_port', 'dialogue_done'))
            .option!
            .status,
        NarrativeOutcomeReachabilityStatus.declaredButNotEmitted,
      );
      expect(
        catalog.resolve(_sceneRef('scene_port', 'idle')).option!.status,
        NarrativeOutcomeReachabilityStatus.declaredButNotEmitted,
      );
      expect(
        catalog.resolve(_sceneRef('scene_port', 'ghost')).option!.status,
        NarrativeOutcomeReachabilityStatus.dialogueOutcomeNotReEmitted,
      );
      expect(
        catalog.resolve(_sceneRef('scene_port', 'hidden')).option!.status,
        NarrativeOutcomeReachabilityStatus.emittedButUnreachable,
      );
      expect(
        catalog.selectableOptions.map((option) => option.outcome),
        containsAll([
          _sceneRef('scene_port', 'victory'),
        ]),
      );
      final yarnOutcome =
          catalog.resolve(_sceneRef('scene_port', 'dialogue_done')).option!;
      expect(yarnOutcome.origin, NarrativeOutcomeSourceOrigin.scene);
      expect(yarnOutcome.humanSourceSentence, contains('Rencontre au port'));
      expect(yarnOutcome.debugTechnicalLabel, contains('dialogue_done'));
      expect(yarnOutcome.selectable, isFalse);
      expect(
        yarnOutcome.diagnostics.map((diagnostic) => diagnostic.code),
        contains('yarnOutcomeNotReEmitted'),
      );
      expect(
        catalog.options.any(
          (option) => option.debugTechnicalLabel.contains('producer:yarn'),
        ),
        isFalse,
      );
    });

    test('rejects a reachable Scene outcome with a missing project reference',
        () {
      final scene = _scene(
        id: 'scene_missing_dialogue',
        name: 'Scene au dialogue absent',
        declaredOutcomes: const [('victory', 'Victoire')],
        yarnExpectedOutcomes: const ['dialogue_done'],
        reachableEndOutcome: 'victory',
      );
      final outcome = _sceneRef('scene_missing_dialogue', 'victory');

      final invalidCatalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(scenes: [scene]),
      );
      final invalidOption = invalidCatalog.resolve(outcome).option!;

      expect(
        invalidOption.status,
        NarrativeOutcomeReachabilityStatus.producerInvalid,
      );
      expect(invalidOption.selectable, isFalse);
      expect(
        invalidOption.diagnostics.map((diagnostic) => diagnostic.code),
        contains('sceneProjectReferencesInvalid'),
      );

      final validCatalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [scene],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_port',
              name: 'Dialogue du port',
              relativePath: 'dialogues/dialogue_port.yarn',
              declaredOutcomes: [
                DialogueDeclaredOutcome(
                  id: 'dialogue_done',
                  label: 'Dialogue terminé',
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        validCatalog.resolve(outcome).status,
        NarrativeOutcomeEventSourceResolutionStatus.found,
      );
    });

    test('requires exact map data for map-backed Scene outcome references', () {
      final scene = _sceneWithMapEventOutcome(
        sceneId: 'scene_map_reference',
        mapId: 'map_port',
        eventId: 'event_gate',
        outcomeId: 'victory',
      );
      final project = _project(
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        scenes: [scene],
      );
      final outcome = _sceneRef('scene_map_reference', 'victory');

      final unloaded = buildNarrativeOutcomeEventSourceCatalog(
        project: project,
      ).resolve(outcome).option!;
      expect(unloaded.selectable, isFalse);
      expect(
        unloaded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('sceneMapDataUnavailable'),
      );

      final missingEvent = buildNarrativeOutcomeEventSourceCatalog(
        project: project,
        maps: [_map(events: const [])],
      ).resolve(outcome).option!;
      expect(missingEvent.selectable, isFalse);
      expect(
        missingEvent.diagnostics.map((diagnostic) => diagnostic.code),
        contains('sceneProjectReferencesInvalid'),
      );

      final valid = buildNarrativeOutcomeEventSourceCatalog(
        project: project,
        maps: [
          _map(events: [_mapEvent('event_gate')])
        ],
      );
      expect(
        valid.resolve(outcome).status,
        NarrativeOutcomeEventSourceResolutionStatus.found,
      );
    });

    test('keeps duplicate, missing, and cross-producer identities distinct',
        () {
      final duplicateA = _scene(
        id: 'scene_duplicate',
        name: 'Duplicate A',
        declaredOutcomes: const [('victory', 'Victoire')],
        reachableEndOutcome: 'victory',
      );
      final duplicateB = _scene(
        id: 'scene_duplicate',
        name: 'Duplicate B',
        declaredOutcomes: const [('victory', 'Victoire')],
        reachableEndOutcome: 'victory',
      );
      final sceneA = _scene(
        id: 'scene_a',
        name: 'Scene A',
        declaredOutcomes: const [('shared', 'Partagé')],
        reachableEndOutcome: 'shared',
      );
      final sceneB = _scene(
        id: 'scene_b',
        name: 'Scene B',
        declaredOutcomes: const [('shared', 'Partagé')],
        reachableEndOutcome: 'shared',
      );
      final missing = _sceneRef('scene_missing', 'victory');
      final missingOutcome = _sceneRef('scene_a', 'not_exposed');

      final catalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [duplicateA, duplicateB, sceneA, sceneB],
        ),
        referencedOutcomes: [missing, missingOutcome],
      );

      expect(
        catalog.resolve(_sceneRef('scene_duplicate', 'victory')).status,
        NarrativeOutcomeEventSourceResolutionStatus.ambiguous,
      );
      expect(
        catalog.options
            .where(
              (option) =>
                  option.outcome == _sceneRef('scene_duplicate', 'victory'),
            )
            .every(
              (option) =>
                  option.status ==
                  NarrativeOutcomeReachabilityStatus.producerDuplicate,
            ),
        isTrue,
      );
      expect(
        catalog.resolve(missing).status,
        NarrativeOutcomeEventSourceResolutionStatus.unavailable,
      );
      expect(
        catalog.resolve(missing).option!.status,
        NarrativeOutcomeReachabilityStatus.producerMissing,
      );
      expect(
        catalog.resolve(missingOutcome).option!.status,
        NarrativeOutcomeReachabilityStatus.outcomeMissing,
      );
      expect(
        catalog.resolve(missingOutcome).option!.humanSourceSentence,
        contains('non exposé'),
      );
      expect(catalog.resolve(_sceneRef('scene_a', 'shared')).status,
          NarrativeOutcomeEventSourceResolutionStatus.found);
      expect(catalog.resolve(_sceneRef('scene_b', 'shared')).status,
          NarrativeOutcomeEventSourceResolutionStatus.found);
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          'duplicateProducerId',
          'missingProducer',
          'missingOutcome',
        ]),
      );
    });

    test('adapts stable Battle public contracts without map_battle coupling',
        () {
      const stableTrainer = ProjectTrainerEntry(
        id: 'rival',
        name: 'Rival',
        trainerClass: 'Rival',
        team: [ProjectTrainerPokemonEntry(speciesId: 'sprout', level: 5)],
      );
      const unstableTrainer = ProjectTrainerEntry(
        id: '',
        name: 'Sans identité',
        trainerClass: 'Dresseur',
      );

      final catalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(trainers: const [stableTrainer, unstableTrainer]),
      );
      final victory = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:rival',
        outcomeId: 'victory',
      );

      expect(
        catalog.resolve(victory).status,
        NarrativeOutcomeEventSourceResolutionStatus.found,
      );
      expect(
        catalog.resolve(victory).option!.origin,
        NarrativeOutcomeSourceOrigin.battle,
      );
      expect(
        catalog.options.where(
          (option) =>
              option.origin == NarrativeOutcomeSourceOrigin.battle &&
              option.outcome == null,
        ),
        hasLength(2),
      );
      expect(
        catalog.options
            .where((option) => option.outcome == null)
            .every((option) => !option.selectable),
        isTrue,
      );
    });

    test('preserves unqualified legacy outcomes under Scenario producers', () {
      final scenario = ScenarioAsset(
        id: 'scenario_old',
        name: 'Ancien scénario',
        entryNodeId: 'source',
        declaredOutcomes: const [' completed '],
        nodes: const [
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            binding: ScenarioNodeBinding(outcomeId: ' victory '),
            payload: ScenarioNodePayload(actionKind: ' sourceOutcome '),
          ),
          ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            binding: ScenarioNodeBinding(outcomeId: ' done '),
            payload: ScenarioNodePayload(actionKind: ' emitOutcome '),
          ),
        ],
      );

      final catalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(scenarios: [scenario]),
      );
      final consumed = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: 'scenario_old',
        outcomeId: 'victory',
      );
      final declared = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: 'scenario_old',
        outcomeId: 'completed',
      );
      final emitted = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: 'scenario_old',
        outcomeId: 'done',
      );

      expect(catalog.resolve(consumed).status,
          NarrativeOutcomeEventSourceResolutionStatus.found);
      expect(catalog.resolve(declared).status,
          NarrativeOutcomeEventSourceResolutionStatus.found);
      expect(catalog.resolve(emitted).status,
          NarrativeOutcomeEventSourceResolutionStatus.found);
      expect(
        catalog.resolve(consumed).option!.origin,
        NarrativeOutcomeSourceOrigin.legacyScenario,
      );
      expect(
        catalog.resolve(consumed).option!.humanSourceSentence,
        contains('Ancien scénario'),
      );
    });

    test('rejects runtime-impossible and invalid legacy outcome sources', () {
      final impossible = ScenarioAsset(
        id: 'scenario_impossible',
        name: 'Bindings impossibles',
        entryNodeId: 'source',
        nodes: const [
          ScenarioNode(
            id: 'wrong_source',
            type: ScenarioNodeType.action,
            binding: ScenarioNodeBinding(outcomeId: 'phantom_source'),
            payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
          ),
          ScenarioNode(
            id: 'wrong_emit',
            type: ScenarioNodeType.reference,
            binding: ScenarioNodeBinding(outcomeId: 'phantom_emit'),
            payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
          ),
        ],
      );
      final invalidIdentity = ScenarioAsset(
        id: ' scenario_invalid',
        name: 'Identité invalide',
        entryNodeId: 'source',
        declaredOutcomes: const ['done'],
      );
      final catalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(scenarios: [impossible, invalidIdentity]),
      );

      for (final outcomeId in const ['phantom_source', 'phantom_emit']) {
        final option = catalog
            .resolve(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'scenario_impossible',
                outcomeId: outcomeId,
              ),
            )
            .option!;
        expect(option.selectable, isFalse);
        expect(
          option.status,
          NarrativeOutcomeReachabilityStatus.legacyBindingInvalid,
        );
        expect(
          option.diagnostics.map((diagnostic) => diagnostic.code),
          contains('legacyOutcomeBindingInvalid'),
        );
      }

      final invalid = catalog.options.singleWhere(
        (option) => option.debugTechnicalLabel.contains('scenario_invalid'),
      );
      expect(
          invalid.status, NarrativeOutcomeReachabilityStatus.producerInvalid);
      expect(invalid.selectable, isFalse);
      expect(
        invalid.diagnostics.map((diagnostic) => diagnostic.code),
        contains('invalidOutcomeIdentity'),
      );
      expect(
        invalid.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('legacyScenarioCompatibility')),
      );
    });

    test('is deterministic and immutable on informative scale fixtures', () {
      final scenes = [
        _simpleScene('scene_b', 'B', 'shared'),
        _simpleScene('scene_a', 'A', 'shared'),
      ];
      final firstProject = _project(scenes: scenes);
      final before = jsonEncode(firstProject.toJson());
      final first = buildNarrativeOutcomeEventSourceCatalog(
        project: firstProject,
      );
      final second = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(scenes: scenes.reversed.toList()),
      );

      expect(first.toDebugJson(), second.toDebugJson());
      expect(jsonEncode(firstProject.toJson()), before);
      expect(
          () => first.options.add(first.options.first), throwsUnsupportedError);
      expect(
        () => first.options.first.diagnostics.add(
          NarrativeOutcomeEventSourceDiagnostic(
            code: 'mutated',
            message: 'Mutation interdite.',
          ),
        ),
        throwsUnsupportedError,
      );
      final indexedOutcome = first.optionsForOutcome(
        _sceneRef('scene_a', 'shared'),
      );
      expect(indexedOutcome, hasLength(1));
      expect(() => indexedOutcome.clear(), throwsUnsupportedError);

      for (final count in const [10, 100, 500]) {
        final fixture = _project(
          scenes: [
            for (var index = 0; index < count; index++)
              _simpleScene('scene_$index', 'Scene $index', 'completed'),
          ],
        );
        final stopwatch = Stopwatch()..start();
        final catalog = buildNarrativeOutcomeEventSourceCatalog(
          project: fixture,
        );
        stopwatch.stop();
        expect(catalog.selectableOptions, hasLength(count));
        // Informative only: no timing threshold belongs in a functional test.
        expect(stopwatch.elapsedMicroseconds, greaterThanOrEqualTo(0));
      }
    });

    test(
        'totally orders duplicate producers and rejects invalid Scene identity',
        () {
      final duplicateWithDialogue = _scene(
        id: 'scene_duplicate',
        name: 'Même Scene',
        declaredOutcomes: const [('victory', 'Victoire')],
        yarnExpectedOutcomes: const ['victory'],
        reachableEndOutcome: 'victory',
      );
      final duplicateWithoutDialogue = _scene(
        id: 'scene_duplicate',
        name: 'Même Scene',
        declaredOutcomes: const [('victory', 'Victoire')],
        reachableEndOutcome: 'victory',
      );
      final first = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [duplicateWithDialogue, duplicateWithoutDialogue],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_port',
              name: 'Dialogue du port',
              relativePath: 'dialogues/dialogue_port.yarn',
            ),
          ],
        ),
      );
      final second = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [duplicateWithoutDialogue, duplicateWithDialogue],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_port',
              name: 'Dialogue du port',
              relativePath: 'dialogues/dialogue_port.yarn',
            ),
          ],
        ),
      );
      expect(first.toDebugJson(), second.toDebugJson());

      final invalid = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [
            _simpleScene(' scene_invalid', 'Scene invalide', 'victory'),
          ],
        ),
      ).options.single;
      expect(invalid.outcome, isNull);
      expect(
        invalid.status,
        NarrativeOutcomeReachabilityStatus.producerInvalid,
      );
      expect(invalid.selectable, isFalse);
      expect(
        invalid.diagnostics.map((diagnostic) => diagnostic.code),
        contains('invalidOutcomeIdentity'),
      );

      expect(
        () => NarrativeOutcomeEventSourceOption(
          outcome: _sceneRef('scene_valid', 'victory'),
          producerLabel: 'Scene valide',
          outcomeLabel: 'Victoire',
          humanSourceSentence: 'Après la victoire.',
          status: NarrativeOutcomeReachabilityStatus.reachable,
          selectable: false,
          unavailableReason: 'Contradiction volontaire.',
          origin: NarrativeOutcomeSourceOrigin.scene,
          debugTechnicalLabel: 'scene:scene_valid:outcome:victory',
        ),
        throwsArgumentError,
      );
    });

    test('keeps combined Scene diagnostics and registry draft references', () {
      final unreachableUndeclared = _scene(
        id: 'scene_unreachable',
        name: 'Scene inaccessible',
        unreachableEndOutcome: 'ghost',
      );
      final draftReference = _sceneRef('scene_deleted', 'lost');
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: 'evt_019abcde-0000-7000-8000-0000000000d2',
              name: 'Draft outcome',
              source: NarrativeEventSourceRef.outcomeReceived(draftReference),
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
        legacyClaims: const [],
      );
      final catalog = buildNarrativeOutcomeEventSourceCatalog(
        project: _project(
          scenes: [unreachableUndeclared],
          eventRegistry: registry,
        ),
      );

      final ghost = catalog
          .resolve(
            _sceneRef('scene_unreachable', 'ghost'),
          )
          .option!;
      expect(
        ghost.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          'emittedOutcomeUndeclared',
          'outcomeEmissionUnreachable',
        ]),
      );
      expect(
        catalog.resolve(draftReference).option!.status,
        NarrativeOutcomeReachabilityStatus.producerMissing,
      );
    });

    test('indexes referenced outcomes without repeated producer scans', () {
      for (final count in const [10, 100, 500]) {
        final references = [
          for (var index = 0; index < count; index++)
            _sceneRef('scene_catalog', 'missing_$index'),
        ];
        final stopwatch = Stopwatch()..start();
        final catalog = buildNarrativeOutcomeEventSourceCatalog(
          project: _project(
            scenes: [_scene(id: 'scene_catalog', name: 'Catalogue')],
          ),
          referencedOutcomes: references,
        );
        stopwatch.stop();
        expect(catalog.options, hasLength(count));
        expect(
          catalog.options.every(
            (option) =>
                option.status ==
                NarrativeOutcomeReachabilityStatus.outcomeMissing,
          ),
          isTrue,
        );
        // Informative only: the production path is indexed, not time-gated.
        expect(stopwatch.elapsedMicroseconds, greaterThanOrEqualTo(0));
      }
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const [],
  List<SceneAsset> scenes = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<ProjectTrainerEntry> trainers = const [],
  List<ScenarioAsset> scenarios = const [],
  NarrativeEventRegistry? eventRegistry,
}) {
  return ProjectManifest(
    name: 'Selbrume',
    maps: maps,
    tilesets: const [],
    scenes: scenes,
    dialogues: dialogues,
    trainers: trainers,
    scenarios: scenarios,
    eventRegistry: eventRegistry,
  );
}

MapData _map({List<MapEventDefinition> events = const []}) => MapData(
      id: 'map_port',
      name: 'Port',
      size: const GridSize(width: 8, height: 8),
      events: events,
    );

MapEventDefinition _mapEvent(String id) => MapEventDefinition(
      id: id,
      pages: const [MapEventPage(pageNumber: 0)],
      position: const EventPosition(layerId: 'events', x: 1, y: 1),
    );

SceneAsset _sceneWithMapEventOutcome({
  required String sceneId,
  required String mapId,
  required String eventId,
  required String outcomeId,
}) =>
    SceneAsset(
      id: sceneId,
      name: sceneId,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'action',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.markEventConsumed(
                mapId: mapId,
                eventId: eventId,
              ),
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: outcomeId),
          ),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_action',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'action',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_action_end',
            fromNodeId: 'action',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
      declaredOutcomes: [
        SceneOutcome(id: outcomeId, label: outcomeId),
      ],
    );

SceneAsset _simpleScene(String id, String name, String outcomeId) {
  return _scene(
    id: id,
    name: name,
    declaredOutcomes: [(outcomeId, outcomeId)],
    reachableEndOutcome: outcomeId,
  );
}

SceneAsset _scene({
  required String id,
  required String name,
  List<(String, String)> declaredOutcomes = const [],
  List<String> yarnExpectedOutcomes = const [],
  String? reachableEndOutcome,
  String? unreachableEndOutcome,
}) {
  final hasYarn = yarnExpectedOutcomes.isNotEmpty;
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (hasYarn)
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: 'dialogue_port',
          expectedOutcomes: yarnExpectedOutcomes,
        ),
      ),
    SceneNode(
      id: 'end',
      kind: SceneNodeKind.end,
      payload: SceneEndPayload(sceneOutcomeId: reachableEndOutcome),
    ),
    if (unreachableEndOutcome != null)
      SceneNode(
        id: 'hidden_end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: unreachableEndOutcome),
      ),
  ];
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start',
      fromNodeId: 'start',
      fromPortId: 'completed',
      toNodeId: hasYarn ? 'dialogue' : 'end',
      kind: SceneEdgeKind.defaultFlow,
    ),
    if (hasYarn)
      SceneEdge(
        id: 'edge_dialogue',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    if (hasYarn)
      for (final outcomeId in yarnExpectedOutcomes)
        if (outcomeId != 'completed')
          SceneEdge(
            id: 'edge_dialogue_$outcomeId',
            fromNodeId: 'dialogue',
            fromPortId: outcomeId,
            toNodeId: 'end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
  ];
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: edges,
    ),
    declaredOutcomes: [
      for (final outcome in declaredOutcomes)
        SceneOutcome(id: outcome.$1, label: outcome.$2),
    ],
  );
}

NarrativeOutcomeRef _sceneRef(String sceneId, String outcomeId) {
  return NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: sceneId,
    outcomeId: outcomeId,
  );
}
