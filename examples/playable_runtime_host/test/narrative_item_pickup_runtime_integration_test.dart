import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_story/map_story.dart';

const _eventId = 'evt_019abcde-6000-7000-8000-000000000001';
const _sceneId = 'scene.item-pickup';
const _mapId = 'map_port';
const _objectId = 'object_potion';
const _itemId = 'potion';

void main() {
  test('an Event V2 pickup survives reload without double reward', () async {
    final authored = ProjectManifest(
      name: 'Item pickup runtime fixture',
      maps: const [
        ProjectMapEntry(
          id: _mapId,
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const [],
      scenes: [_itemPickupScene()],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: _eventId,
              name: 'Potion au sol',
              source: NarrativeEventSourceRef.entityInteract(_mapId, _objectId),
              conditions: const [],
              sceneId: _sceneId,
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
    final project = ProjectManifest.fromJson(
      jsonDecode(jsonEncode(authored.toJson())) as Map<String, dynamic>,
    );
    const map = MapData(
      id: _mapId,
      name: 'Port',
      size: GridSize(width: 4, height: 4),
      layers: [MapLayer.object(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: _objectId,
          name: 'Potion',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 1),
        ),
      ],
    );
    final catalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: [map],
    );
    final occurrence = NarrativeEventOccurrence(
      source: NarrativeEventSourceRef.entityInteract(_mapId, _objectId),
    );
    var state = const GameState(saveId: 'item-pickup-runtime');
    var sequence = 0;

    Future<NarrativeSpatialProductionDispatchResult> dispatch(
      String occurrenceId,
    ) async {
      final transactions = NarrativeEventStateTransactions(state);
      final bridge = NarrativeSpatialProductionDispatchBridge(
        stateTransactions: transactions,
        currentGameState: () => state,
        onGameStateCommitted: (next) => state = next,
        prepareAuthority: (_, currentOccurrence) async =>
            NarrativeEventDispatchAuthority.prepare(
              registryResult: EventRegistryDecodeResult.decoded(
                project.eventRegistry!,
              ),
              occurrence: currentOccurrence,
              factResolver: NarrativeFactRuntimeResolver.fromFacts(
                project.facts,
              ),
              projectCatalog: catalog,
            ),
        executeScene: (request) => executeNarrativeEventScene(
          request: request,
          project: project,
          mapsById: {_mapId: map},
          currentGameState: () => state,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'false',
            showDialogue: (_) => 'completed',
            startBattle: (_) => 'victory',
            playCinematic: (_) => 'completed',
          ),
        ),
        legacyFallback: (_, _, _) async =>
            fail('An Event V2 pickup must not use legacy fallback.'),
        activityPort: NoopNarrativeEventActivityPort(),
        isCurrentOccurrence: (_) => true,
        executionIdFactory: () => _runtimeId('evx', ++sequence),
        correlationIdFactory: () => _runtimeId('corr', ++sequence),
        deliveryIdFactory: () => _runtimeId('outd', ++sequence),
      );
      return bridge.dispatch(
        occurrenceId: occurrenceId,
        occurrence: occurrence,
      );
    }

    final first = await dispatch('item-pickup-1');
    expect(first, isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(_itemQuantity(state, _itemId), 2);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_eventId),
    );

    state = GameState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    final afterReload = await dispatch('item-pickup-2');
    expect(afterReload, isA<NarrativeSpatialProductionDispatchNoFallback>());
    expect(_itemQuantity(state, _itemId), 2);
  });
}

SceneAsset _itemPickupScene() => SceneAsset(
  id: _sceneId,
  name: 'Potion au sol',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'grant',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveItem(itemId: _itemId, quantity: 2),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'start-grant',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'grant',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'grant-end',
        fromNodeId: 'grant',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

int _itemQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

String _runtimeId(String prefix, int sequence) =>
    '${prefix}_019abcde-6000-7000-8000-${sequence.toString().padLeft(12, '0')}';
