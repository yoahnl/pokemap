import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'save_restore_outbox_map';

const _outcomeOneProducerSceneId = 'scene_restore_producer_one';
const _outcomeTwoProducerSceneId = 'scene_restore_producer_two';
const _outcomeOneId = 'restore_outcome_one';
const _outcomeTwoId = 'restore_outcome_two';

const _outcomeOneEventId = 'evt_019abcde-3000-7000-8000-000000000001';
const _outcomeTwoEventId = 'evt_019abcde-3000-7000-8000-000000000002';
const _mapEnterEventId = 'evt_019abcde-3000-7000-8000-000000000003';

const _outcomeOneConsumerSceneId = 'scene_restore_sets_fact_a';
const _outcomeTwoConsumerSceneId = 'scene_restore_sets_fact_b';
const _mapEnterConsumerSceneId = 'scene_restore_sets_fact_c';

const _factA = 'fact.restore.outcome_one_processed';
const _factB = 'fact.restore.outcome_two_processed_after_a';
const _factC = 'fact.restore.map_enter_processed_after_b';

const _deliveryOneId = 'outd_019abcde-3000-7000-8000-000000000011';
const _deliveryTwoId = 'outd_019abcde-3000-7000-8000-000000000012';
const _causationExecutionId = 'evx_019abcde-3000-7000-8000-000000000013';
const _rootCorrelationId = 'corr_019abcde-3000-7000-8000-000000000014';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveRestore drains pending outcomes FIFO before mapEnter', () async {
    final project = _project();
    final game = PlayableMapGame(
      bundle: RuntimeMapBundle(
        manifest: project,
        map: _map(),
        projectRootDirectory: '/tmp/save_restore_outbox',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      projectFilePath: '/tmp/save_restore_outbox/project.json',
      saveData: SaveData(
        saveId: 'save-restore-outbox',
        currentMapId: _mapId,
        playerPosition: const GridPos(x: 1, y: 1),
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
            _delivery(
              deliveryId: _deliveryOneId,
              outcome: _outcomeOne,
            ),
            _delivery(
              deliveryId: _deliveryTwoId,
              outcome: _outcomeTwo,
            ),
          ],
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factA, true),
      reason: 'The FIFO head must execute the first outcome Event.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factB, true),
      reason: 'The second outcome is eligible only after fact A is committed.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factC, true),
      reason: 'mapEnter is eligible only after fact B is committed.',
    );
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      isEmpty,
    );
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryOneId, _deliveryTwoId},
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore outbox dispatch.');
}

final NarrativeOutcomeRef _outcomeOne = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeOneProducerSceneId,
  outcomeId: _outcomeOneId,
);

final NarrativeOutcomeRef _outcomeTwo = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeTwoProducerSceneId,
  outcomeId: _outcomeTwoId,
);

ProjectManifest _project() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(
        id: _outcomeOneEventId,
        name: 'Restore outcome one',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeOne),
        sceneId: _outcomeOneConsumerSceneId,
      ),
      _eventRecord(
        id: _outcomeTwoEventId,
        name: 'Restore outcome two after A',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeTwo),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factA, true),
        ],
        sceneId: _outcomeTwoConsumerSceneId,
      ),
      _eventRecord(
        id: _mapEnterEventId,
        name: 'Map enter after restored outcomes',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factB, true),
        ],
        sceneId: _mapEnterConsumerSceneId,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );

  return ProjectManifest(
    name: 'Save restore outbox integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Save Restore Outbox Map',
        relativePath: 'maps/save_restore_outbox_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: _factA, label: 'Outcome one processed'),
      NarrativeFactDefinition(id: _factB, label: 'Outcome two processed'),
      NarrativeFactDefinition(id: _factC, label: 'Map enter processed'),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[
      _outcomeProducerScene(
        id: _outcomeOneProducerSceneId,
        outcomeId: _outcomeOneId,
      ),
      _outcomeProducerScene(
        id: _outcomeTwoProducerSceneId,
        outcomeId: _outcomeTwoId,
      ),
      _factScene(id: _outcomeOneConsumerSceneId, factId: _factA),
      _factScene(id: _outcomeTwoConsumerSceneId, factId: _factB),
      _factScene(id: _mapEnterConsumerSceneId, factId: _factC),
    ],
  );
}

NarrativeEventRecord _eventRecord({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

SceneAsset _outcomeProducerScene({
  required String id,
  required String outcomeId,
}) {
  return SceneAsset(
    id: id,
    name: 'Outcome producer $outcomeId',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({required String id, required String factId}) {
  return SceneAsset(
    id: id,
    name: 'Set $factId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

NarrativeOutcomeDelivery _delivery({
  required String deliveryId,
  required NarrativeOutcomeRef outcome,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: outcome,
    causationExecutionId: _causationExecutionId,
    rootCorrelationId: _rootCorrelationId,
    depth: 0,
    attemptCount: 0,
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Save Restore Outbox Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );
