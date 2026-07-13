import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventId = 'evt_00000000-0000-7000-8000-000000000001';

void main() {
  group('NS-EVENT-V2 Phase D D4 navigation intents', () {
    test('focuses entity sources with exact 1x1 and multi-cell bounds', () {
      final index = _index();

      final single = index.navigationForSource(
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
      );
      final large = index.navigationForSource(
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_guard'),
      );

      expect(
          single.destination?.kind, NarrativeEditorDestinationKind.focusEntity);
      expect(single.destination?.mapId, 'map_port');
      expect(single.destination?.entityId, 'npc_lysa');
      expect(single.focusTarget?.kind, NarrativeEditorFocusTargetKind.entity);
      expect(
        single.focusTarget?.bounds,
        const MapRect(
          pos: GridPos(x: 2, y: 3),
          size: GridSize(width: 1, height: 1),
        ),
      );
      expect(
        large.focusTarget?.bounds,
        const MapRect(
          pos: GridPos(x: 7, y: 4),
          size: GridSize(width: 2, height: 3),
        ),
      );
    });

    test('focuses trigger area and opens map without a fake tile', () {
      final index = _index();
      final trigger = index.navigationForSource(
        NarrativeEventSourceRef.triggerEnter('map_port', 'zone_quay'),
      );
      final map = index.navigationForSource(
        NarrativeEventSourceRef.mapEnter('map_port'),
      );

      expect(trigger.destination?.kind,
          NarrativeEditorDestinationKind.focusTrigger);
      expect(
        trigger.focusTarget?.bounds,
        const MapRect(
          pos: GridPos(x: 4, y: 5),
          size: GridSize(width: 3, height: 2),
        ),
      );
      expect(map.destination?.kind, NarrativeEditorDestinationKind.openMap);
      expect(map.focusTarget?.kind, NarrativeEditorFocusTargetKind.map);
      expect(map.focusTarget?.bounds, isNull);
    });

    test('refuses to choose between duplicate map data', () {
      final index = _index(maps: [_map(), _map()]);

      final intent = index.navigationForSource(
        NarrativeEventSourceRef.mapEnter('map_port'),
      );

      expect(intent.destination, isNull);
      expect(
          intent.absenceReason, 'Plusieurs fichiers décrivent cette même map.');
    });

    test('opens Scene, Fact, and Narrative Event destinations', () {
      final index = _index();

      final scene = index.navigationForScene('scene_action');
      final fact = index.navigationForFact('fact_ready');
      final event = index.navigationForNarrativeEvent(_eventId);

      expect(scene.destination?.kind, NarrativeEditorDestinationKind.openScene);
      expect(scene.destination?.sceneId, 'scene_action');
      expect(fact.destination?.kind, NarrativeEditorDestinationKind.openFact);
      expect(fact.destination?.factId, 'fact_ready');
      expect(event.destination?.kind,
          NarrativeEditorDestinationKind.openNarrativeEvent);
      expect(event.destination?.eventId, _eventId);
      expect(index.navigationForScene('scene_missing').absenceReason,
          'La Scene référencée n’existe plus.');
      expect(index.navigationForFact('fact_missing').destination, isNull);
      expect(
          index
              .navigationForNarrativeEvent(
                  'evt_00000000-0000-7000-8000-000000000099')
              .destination,
          isNull);
    });

    test('opens Scene and Battle outcome producers without map geometry', () {
      final index = _index();
      final outcomes = [
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_outcome',
          outcomeId: 'victory',
        ),
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: 'trainer:rival',
          outcomeId: 'victory',
        ),
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_outcome',
          outcomeId: 'not_declared',
        ),
      ];

      for (final outcome in outcomes) {
        final intent = index.navigationForOutcomeProducer(outcome);
        expect(intent.destination?.kind,
            NarrativeEditorDestinationKind.openOutcomeProducer);
        expect(intent.destination?.outcome, outcome);
        expect(intent.focusTarget, isNull);

        final mapIntent = index.mapNavigationForSource(
          NarrativeEventSourceRef.outcomeReceived(outcome),
        );
        expect(mapIntent.destination, isNull);
        expect(
          mapIntent.absenceReason,
          'Ce résultat n’a pas de position sur une carte.',
        );
      }
    });

    test('keeps map-backed Scene outcome diagnostics tied to exact map data',
        () {
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_map_backed',
        outcomeId: 'victory',
      );
      final source = NarrativeEventSourceRef.outcomeReceived(outcome);
      final project = _project(
        scenes: [
          _mapBackedScene(
            sceneId: 'scene_map_backed',
            mapId: 'map_port',
            eventId: 'event_gate',
            outcomeId: 'victory',
          ),
        ],
      );

      final unloaded =
          _index(project: project, maps: const []).diagnosticForSource(source);
      final missingEvent = _index(
        project: project,
        maps: [_map(events: const [])],
      ).diagnosticForSource(source);
      final available = _index(
        project: project,
        maps: [
          _map(events: [_mapEvent('event_gate')]),
        ],
      ).diagnosticForSource(source);

      expect(unloaded.code, 'outcomeNeedsAttention');
      expect(unloaded.severity,
          NarrativeEventNavigationDiagnosticSeverity.warning);
      expect(missingEvent.code, 'outcomeNeedsAttention');
      expect(available.code, 'outcomeNavigationAvailable');
      expect(
          available.severity, NarrativeEventNavigationDiagnosticSeverity.info);
      expect(available.destination?.kind,
          NarrativeEditorDestinationKind.openOutcomeProducer);
      expect(available.destination?.outcome, outcome);
    });

    test('opens legacy Scenario and migration review destinations', () {
      final index = _index();
      final mapProvenance = LegacySourceRef.mapEvent(
        'map_port',
        'legacy_event',
      );
      final scenarioProvenance = LegacySourceRef.scenarioSourceNode(
        'scenario_old',
        'source',
      );

      final scenario = index.navigationForLegacyScenario(
        'scenario_old',
        'source',
      );
      expect(scenario.destination?.kind,
          NarrativeEditorDestinationKind.openLegacyScenario);
      expect(scenario.destination?.scenarioId, 'scenario_old');
      expect(scenario.destination?.nodeId, 'source');

      for (final provenance in [mapProvenance, scenarioProvenance]) {
        final migration = index.navigationForMigrationReview(provenance);
        expect(migration.destination?.kind,
            NarrativeEditorDestinationKind.openMigrationReview);
        expect(migration.destination?.provenance, provenance);
      }
      expect(
        index
            .navigationForMigrationReview(
              LegacySourceRef.mapEvent('map_port', 'legacy_missing'),
            )
            .absenceReason,
        'La donnée existante référencée n’existe plus.',
      );
      expect(
        index
            .navigationForMigrationReview(
              LegacySourceRef.scenarioSourceNode(
                'scenario_old',
                'ordinary_action',
              ),
            )
            .destination,
        isNull,
      );
    });

    test('explains missing and unavailable sources without fake repair', () {
      final index = _index();
      final missingSource = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_missing',
      );
      final unavailableSource = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'spawn_player',
      );

      final missing = index.diagnosticForSource(missingSource);
      expect(missing.destination, isNull);
      expect(missing.absenceReason, 'L’entité référencée n’existe plus.');
      expect(
          missing.severity, NarrativeEventNavigationDiagnosticSeverity.error);
      expect(missing.recommendedAction,
          NarrativeEventRecommendedAction.repairReference);

      final unavailable = index.diagnosticForSource(unavailableSource);
      expect(unavailable.destination?.kind,
          NarrativeEditorDestinationKind.focusEntity);
      expect(unavailable.focusTarget?.bounds, isNotNull);
      expect(unavailable.severity,
          NarrativeEventNavigationDiagnosticSeverity.warning);
      expect(unavailable.recommendedAction,
          NarrativeEventRecommendedAction.changeSource);
      expect(unavailable.message, isNot(contains('réparé automatiquement')));
    });

    test('enforces destination XOR absence reason and immutable debug refs',
        () {
      final index = _index();
      final available = index.diagnosticForSource(
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
      );
      final missing = index.diagnosticForSource(
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_missing'),
      );

      for (final diagnostic in [available, missing]) {
        expect(
          (diagnostic.destination != null) !=
              (diagnostic.absenceReason != null),
          isTrue,
        );
      }
      expect(
        () => available.debugReferences['mapId'] = 'changed',
        throwsUnsupportedError,
      );
      expect(
        () => NarrativeEventNavigationIntent.navigate(
          NarrativeEditorDestination.focusEntity('map_port', 'npc_lysa'),
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventNavigationIntent.navigate(
          NarrativeEditorDestination.openMap('map_port'),
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventNavigationIntent.navigate(
          NarrativeEditorDestination.focusEntity('map_port', 'npc_lysa'),
          focusTarget: NarrativeEditorFocusTarget.trigger(
            'map_port',
            'zone_quay',
            const MapRect(
              pos: GridPos(x: 4, y: 5),
              size: GridSize(width: 3, height: 2),
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('enriches every reference diagnostic with destination XOR reason', () {
      final index = _index();
      final sceneOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_outcome',
        outcomeId: 'victory',
      );
      final diagnostics = [
        index.diagnosticForScene('scene_action'),
        index.diagnosticForScene('scene_missing'),
        index.diagnosticForFact('fact_ready'),
        index.diagnosticForFact('fact_missing'),
        index.diagnosticForNarrativeEvent(_eventId),
        index.diagnosticForNarrativeEvent(
          'evt_00000000-0000-7000-8000-000000000099',
        ),
        index.diagnosticForOutcomeProducer(sceneOutcome),
        index.diagnosticForLegacyScenario('scenario_old', 'source'),
        index.diagnosticForLegacyScenario('scenario_old', 'missing'),
        index.diagnosticForMigrationReview(
          LegacySourceRef.mapEvent('map_port', 'legacy_event'),
        ),
        index.diagnosticForMigrationReview(
          LegacySourceRef.mapEvent('map_port', 'legacy_missing'),
        ),
      ];

      for (final diagnostic in diagnostics) {
        expect(
          (diagnostic.destination != null) !=
              (diagnostic.absenceReason != null),
          isTrue,
          reason: diagnostic.code,
        );
        expect(diagnostic.message, isNot(contains('scene_action')));
        expect(diagnostic.debugReferences, isNotNull);
      }
      expect(
        diagnostics.last.recommendedAction,
        NarrativeEventRecommendedAction.examineMigration,
      );
    });

    test('keeps a literal deterministic diagnostic snapshot', () {
      final diagnostic = _index().diagnosticForSource(
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
      );

      expect(diagnostic.toDebugJson(), {
        'code': 'sourceNavigationAvailable',
        'severity': 'info',
        'message': 'La source est disponible sur la carte.',
        'recommendedAction': {
          'kind': 'viewOnMap',
          'humanLabel': 'Voir sur la carte',
        },
        'destination': {
          'kind': 'focusEntity',
          'mapId': 'map_port',
          'entityId': 'npc_lysa',
        },
        'focusTarget': {
          'kind': 'entity',
          'mapId': 'map_port',
          'ownerId': 'npc_lysa',
          'bounds': {
            'pos': {'x': 2, 'y': 3},
            'size': {'width': 1, 'height': 1},
          },
        },
        'debugReferences': {
          'sourceKind': 'entityInteract',
          'mapId': 'map_port',
          'entityId': 'npc_lysa',
        },
      });

      final forward = NarrativeEventDiagnosticDestination(
        code: 'stableDebug',
        severity: NarrativeEventNavigationDiagnosticSeverity.info,
        message: 'Références debug stables.',
        recommendedAction: NarrativeEventRecommendedAction.none,
        navigation: NarrativeEventNavigationIntent.noDestination(
          'Aucune cible pour ce contrôle.',
        ),
        debugReferences: const {'z': 'last', 'a': 'first'},
      );
      final reversed = NarrativeEventDiagnosticDestination(
        code: 'stableDebug',
        severity: NarrativeEventNavigationDiagnosticSeverity.info,
        message: 'Références debug stables.',
        recommendedAction: NarrativeEventRecommendedAction.none,
        navigation: NarrativeEventNavigationIntent.noDestination(
          'Aucune cible pour ce contrôle.',
        ),
        debugReferences: const {'a': 'first', 'z': 'last'},
      );
      expect(
        jsonEncode(forward.toDebugJson()),
        jsonEncode(reversed.toDebugJson()),
      );
    });

    test('keeps map_core navigation free of Flutter and UI callbacks', () {
      final source = File(
        'lib/src/read_models/narrative_event_navigation_intent.dart',
      ).readAsStringSync();

      for (final forbidden in [
        'package:flutter',
        'package:flame',
        'BuildContext',
        'Widget',
        'Navigator',
        'Route',
        'GlobalKey',
        'VoidCallback',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
    });
  });
}

NarrativeEventNavigationIndex _index({
  ProjectManifest? project,
  List<MapData>? maps,
}) {
  return buildNarrativeEventNavigationIndex(
    project: project ?? _project(),
    maps: maps ?? [_map()],
  );
}

ProjectManifest _project({List<SceneAsset>? scenes}) {
  return ProjectManifest(
    name: 'Selbrume synthétique',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port des Brisants',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    facts: [NarrativeFactDefinition(id: 'fact_ready', label: 'Prêt')],
    scenes: scenes ??
        [
          _scene('scene_action', 'Réaction'),
          _scene('scene_outcome', 'Combat au port', outcomeId: 'victory'),
        ],
    scenarios: const [
      ScenarioAsset(
        id: 'scenario_old',
        name: 'Ancien parcours',
        entryNodeId: 'source',
        declaredOutcomes: ['completed'],
        nodes: [
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            binding: ScenarioNodeBinding(mapId: 'map_port'),
            payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
          ),
          ScenarioNode(
            id: 'ordinary_action',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: 'showMessage'),
          ),
        ],
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'rival',
        name: 'Rival',
        trainerClass: 'Rival',
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Rencontre au port',
            source: NarrativeEventSourceRef.entityInteract(
              'map_port',
              'npc_lysa',
            ),
            conditions: const [],
            sceneId: 'scene_action',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _map({List<MapEventDefinition>? events}) {
  return MapData(
    id: 'map_port',
    name: 'Port des Brisants',
    size: const GridSize(width: 20, height: 20),
    layers: const [MapLayer.object(id: 'events', name: 'Événements')],
    entities: const [
      MapEntity(
        id: 'npc_lysa',
        name: 'Lysa',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
      ),
      MapEntity(
        id: 'npc_guard',
        name: 'Garde',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 7, y: 4),
        size: GridSize(width: 2, height: 3),
      ),
      MapEntity(
        id: 'spawn_player',
        name: 'Départ joueur',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: 'zone_quay',
        name: 'Zone du quai',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 4, y: 5),
          size: GridSize(width: 3, height: 2),
        ),
      ),
    ],
    events: events ?? [_mapEvent('legacy_event', title: 'Ancienne rencontre')],
  );
}

MapEventDefinition _mapEvent(String id, {String? title}) => MapEventDefinition(
      id: id,
      title: title ?? id,
      pages: const [MapEventPage(pageNumber: 0)],
      position: const EventPosition(layerId: 'events', x: 2, y: 3),
    );

SceneAsset _mapBackedScene({
  required String sceneId,
  required String mapId,
  required String eventId,
  required String outcomeId,
}) {
  return SceneAsset(
    id: sceneId,
    name: 'Scene liée à la map',
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
    declaredOutcomes: [SceneOutcome(id: outcomeId, label: 'Victoire')],
  );
}

SceneAsset _scene(String id, String name, {String? outcomeId}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: outcomeId == null
        ? const []
        : [SceneOutcome(id: outcomeId, label: 'Victoire')],
  );
}
