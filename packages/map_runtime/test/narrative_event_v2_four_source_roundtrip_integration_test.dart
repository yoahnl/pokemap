import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:path/path.dart' as p;

const _mapId = 'map_roundtrip';
const _entityId = 'npc_roundtrip';
const _triggerId = 'zone_roundtrip';
const _mapEventId = 'evt_019abcde-7000-7000-8000-000000000001';
const _triggerEventId = 'evt_019abcde-7000-7000-8000-000000000002';
const _entityEventId = 'evt_019abcde-7000-7000-8000-000000000003';
const _outcomeEventId = 'evt_019abcde-7000-7000-8000-000000000004';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('editor-compatible disk wire reaches all four runtime sources once',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'nsc_45_four_source_roundtrip_',
    );
    addTearDown(() => root.delete(recursive: true));
    final fixture = _fixture();
    final projectPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'roundtrip.json');
    await File(mapPath).parent.create(recursive: true);

    // These are the exact JSON objects persisted by editor repositories. The
    // runtime reload below must consume the bytes, not the in-memory fixtures.
    await File(projectPath).writeAsString(jsonEncode(fixture.project.toJson()));
    await File(mapPath).writeAsString(jsonEncode(fixture.map.toJson()));

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: _mapId,
    );
    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: bundle.manifest,
      loadMap: (_) async {
        final reloaded = await loadRuntimeMapBundle(
          projectFilePath: projectPath,
          mapId: _mapId,
        );
        return (project: reloaded.manifest, map: reloaded.map);
      },
    );
    expect(bundle.map.toJson(), fixture.map.toJson());
    expect(
      bundle.manifest.eventRegistry!.records
          .map((record) => record.definitionOrNull!.source)
          .toSet(),
      fixture.sources.toSet(),
    );

    var currentState = const GameState(saveId: 'nsc_45_roundtrip');
    final transactions = NarrativeEventStateTransactions(currentState);
    final sceneCalls = <String, int>{};
    var legacyCalls = 0;
    var sequence = 0;
    String nextId(String prefix) => '${prefix}_019abcde-7000-7000-8000-'
        '${(++sequence).toString().padLeft(12, '0')}';

    Future<NarrativeEventDispatchAuthorityPreparation> prepare(
      NarrativeEventOccurrence occurrence,
    ) async {
      return NarrativeEventDispatchAuthority.prepare(
        registryResult: snapshot.registryResult,
        occurrence: occurrence,
        factResolver: snapshot.factResolver,
        legacyClaimIndex: snapshot.legacyClaimIndex,
        projectCatalog: snapshot.projectCatalog,
      );
    }

    Future<NarrativeSceneExecutionResult> executeScene(
      NarrativeSceneExecutionRequest request,
    ) async {
      sceneCalls.update(request.eventId, (count) => count + 1,
          ifAbsent: () => 1);
      return NarrativeSceneExecutionResult.completed(
        updatedGameState: request.gameState,
        qualifiedOutcomes: const [],
      );
    }

    final mapBridge = MapEnterProductionDispatchBridge(
      stateTransactions: transactions,
      currentGameState: () => currentState,
      onGameStateCommitted: (state) => currentState = state,
      prepareAuthority: (_, occurrence) => prepare(occurrence),
      executeScene: executeScene,
      legacyFallback: (_, __, ___) async => legacyCalls++,
      activityPort: NoopNarrativeEventActivityPort(),
      beforeSaveRestoreDispatch: (_) async {},
      isCurrentActivation: (_) => true,
      executionIdFactory: () => nextId('evx'),
      correlationIdFactory: () => nextId('corr'),
      deliveryIdFactory: () => nextId('outd'),
    );
    final mapResult = await mapBridge.dispatchCompletedActivation(
      MapActivation(
        activationId: 'activation-roundtrip',
        mapId: _mapId,
        reason: MapActivationReason.initialBoot,
      ),
    );
    if (mapResult
        case MapEnterProductionDispatchAuthorityBlocked(:final authority)) {
      fail('Map authority blocked: ${authority.reason} '
          '${authority.diagnostics}');
    }
    expect(mapResult, isA<MapEnterProductionDispatchV2Handled>());

    final spatialBridge = NarrativeSpatialProductionDispatchBridge(
      stateTransactions: transactions,
      currentGameState: () => currentState,
      onGameStateCommitted: (state) => currentState = state,
      prepareAuthority: (_, occurrence) => prepare(occurrence),
      executeScene: executeScene,
      legacyFallback: (_, __, ___) async => legacyCalls++,
      activityPort: NoopNarrativeEventActivityPort(),
      isCurrentOccurrence: (_) => true,
      executionIdFactory: () => nextId('evx'),
      correlationIdFactory: () => nextId('corr'),
      deliveryIdFactory: () => nextId('outd'),
    );
    final triggerResult = await spatialBridge.dispatch(
      occurrenceId: 'trigger-roundtrip',
      occurrence: NarrativeEventOccurrence(source: fixture.sources[1]),
    );
    final entityResult = await spatialBridge.dispatch(
      occurrenceId: 'entity-roundtrip',
      occurrence: NarrativeEventOccurrence(source: fixture.sources[2]),
    );
    expect(triggerResult, isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(entityResult, isA<NarrativeSpatialProductionDispatchV2Handled>());

    final pendingOutcome = NarrativeOutcomeDelivery(
      deliveryId: nextId('outd'),
      outcome: fixture.outcome,
      rootCorrelationId: nextId('corr'),
      depth: 0,
      attemptCount: 0,
    );
    currentState = currentState.copyWith(
      narrativeEventProgress: currentState.narrativeEventProgress.copyWith(
        pendingNarrativeOutcomeDeliveries: [pendingOutcome],
      ),
    );
    final outcomeTransactions = NarrativeEventStateTransactions(currentState);
    final outcomeProcessor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: outcomeTransactions,
      activityPort: NoopNarrativeEventActivityPort(),
      dispatcher: (request) async {
        final preparation = await prepare(request.occurrence);
        expect(preparation, isA<NarrativeEventDispatchAuthorityReady>());
        final coordinator = NarrativeEventExecutionCoordinator(
          stateTransactions: outcomeTransactions,
          planner: NarrativeEventDispatchPlanner(),
          executeScene: executeScene,
          activityPort: NoopNarrativeEventActivityPort(),
          executionIdFactory: () => nextId('evx'),
          correlationIdFactory: () => nextId('corr'),
          deliveryIdFactory: () => nextId('outd'),
        );
        final execution = await coordinator.execute(
          authority: preparation as NarrativeEventDispatchAuthorityReady,
        );
        expect(execution, isA<NarrativeEventExecutionSucceeded>());
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState:
              (execution as NarrativeEventExecutionSucceeded).updatedGameState,
        );
      },
      deliveryIdFactory: () => nextId('outd'),
    );
    final outcomeResult = await outcomeProcessor.processNext();
    expect(outcomeResult, isA<NarrativeOutcomeOutboxDelivered>());
    currentState = await outcomeTransactions.read();

    expect(
      sceneCalls,
      <String, int>{
        _mapEventId: 1,
        _triggerEventId: 1,
        _entityEventId: 1,
        _outcomeEventId: 1,
      },
    );
    expect(legacyCalls, 0);
    expect(
      currentState.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      contains(pendingOutcome.deliveryId),
    );

    final secondReload = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: _mapId,
    );
    expect(secondReload.manifest.toJson(), bundle.manifest.toJson());
    expect(secondReload.map.toJson(), bundle.map.toJson());
  });
}

({
  ProjectManifest project,
  MapData map,
  List<NarrativeEventSourceRef> sources,
  NarrativeOutcomeRef outcome,
}) _fixture() {
  final outcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'scene_roundtrip_2',
    outcomeId: 'completed',
  );
  final sources = <NarrativeEventSourceRef>[
    NarrativeEventSourceRef.mapEnter(_mapId),
    NarrativeEventSourceRef.triggerEnter(_mapId, _triggerId),
    NarrativeEventSourceRef.entityInteract(_mapId, _entityId),
    NarrativeEventSourceRef.outcomeReceived(outcome),
  ];
  final ids = <String>[
    _mapEventId,
    _triggerEventId,
    _entityEventId,
    _outcomeEventId,
  ];
  final records = <NarrativeEventRecord>[
    for (var index = 0; index < sources.length; index++)
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: ids[index],
          name: 'Round-trip ${sources[index].kind.name}',
          source: sources[index],
          conditions: const [],
          sceneId: 'scene_roundtrip_$index',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: sources.length - index,
          order: index,
        ),
        enabled: true,
      ),
  ];
  const map = MapData(
    id: _mapId,
    name: 'Round-trip',
    size: GridSize(width: 8, height: 8),
    layers: [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
      MapEntity(
        id: _entityId,
        name: 'PNJ round-trip',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
      ),
    ],
    triggers: [
      MapTrigger(
        id: _triggerId,
        name: 'Zone round-trip',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 4, y: 4),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'NSC-45 four-source fixture',
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'Round-trip',
        relativePath: 'maps/roundtrip.json',
      ),
    ],
    tilesets: const [],
    scenes: [for (var index = 0; index < 4; index++) _scene(index)],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: records,
      legacyClaims: const [],
    ),
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  return (project: project, map: map, sources: sources, outcome: outcome);
}

SceneAsset _scene(int index) => SceneAsset(
      id: 'scene_roundtrip_$index',
      name: 'Scene round-trip $index',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: index == 2
                ? SceneEndPayload(sceneOutcomeId: 'completed')
                : null,
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
      declaredOutcomes: index == 2
          ? [SceneOutcome(id: 'completed', label: 'Terminé')]
          : const [],
    );
