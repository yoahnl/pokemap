import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

const _mapId = 'event_v2_boot_map';
const _eventId = 'evt_019abcde-1000-7000-8000-000000000001';
const _sceneId = 'scene_event_v2_boot';
const _factId = 'fact.event_v2.boot_scene_completed';
const _legacyFlag = 'test.event_v2.legacy_fallback_must_not_run';
const _dialogueEventId = 'evt_019abcde-1000-7000-8000-000000000002';
const _dialogueSceneId = 'scene_event_v2_boot_dialogue';
const _dialogueId = 'dialogue_event_v2_boot';
const _dialogueFactId = 'fact.event_v2.boot_dialogue_completed';
const _retryEventId = 'evt_019abcde-1000-7000-8000-000000000003';
const _retrySceneId = 'scene_event_v2_boot_retry';
const _retryOutcomeId = 'boot.retry';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v2Only mapEnter executes the real Scene and suppresses legacy',
      () async {
    final bundle = _bundle();
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: '/tmp/event_v2_boot/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeFactRuntimeState.overridesByFactId[_factId], isTrue);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_eventId),
      reason: 'The one-shot Event must be committed by the F1 coordinator.',
    );
    expect(
      state.storyFlags.activeFlags,
      isNot(contains(_legacyFlag)),
      reason: 'v2Only authority must never invoke the legacy Scenario.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });

  test('dualRead validated ineligible claim suppresses legacy fallback',
      () async {
    final game = PlayableMapGame(
      bundle: _dualReadClaimedBundle(),
      projectFilePath: '/tmp/event_v2_dual_read/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(contains(_factId)),
      reason: 'The claimed Event is disabled and its Scene must not execute.',
    );
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_eventId)),
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
  });

  test('boot Scene dialogue starts after onLoad and remains interactive',
      () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _dialogueBundle(),
      projectFilePath: '/tmp/event_v2_boot_dialogue/project.json',
      dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad().timeout(const Duration(seconds: 2));

    expect(game.debugIsMapActivationDispatchInFlight, isTrue);
    await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(game.debugCompletedMapActivationDispatchCount, 0);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_dialogueEventId)),
    );

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_dialogueEventId));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId[_dialogueFactId],
      isTrue,
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });

  test(
    'boot outcome retry stays pending without escaping its detached task',
    () async {
      final gate = NarrativeRuntimeActivityGate();
      final repository = _CheckpointCountingRepository(gate);
      var outcomePreparationCount = 0;
      final game = PlayableMapGame(
        bundle: _retryBundle(),
        projectFilePath: '/tmp/event_v2_boot_retry/project.json',
        narrativeRuntimeActivityGate: gate,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.outcomeReceived) {
            return;
          }
          outcomePreparationCount++;
          throw StateError('retryable boot outcome infrastructure failure');
        },
      );

      final uncaughtErrors = await _captureDetachedErrors(() async {
        game.onGameResize(Vector2(320, 240));
        await game.onLoad();
        await _waitUntil(
          game,
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );
        await Future<void>.delayed(Duration.zero);
      });

      final state = game.gameStateSnapshot;
      final pending =
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
      expect(uncaughtErrors, isEmpty);
      expect(outcomePreparationCount, 1);
      expect(pending, hasLength(1));
      expect(pending.single.outcome.outcomeId, _retryOutcomeId);
      expect(pending.single.attemptCount, 1);
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_retryEventId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
      expect(
        repository.storedState!.narrativeEventProgress
            .pendingNarrativeOutcomeDeliveries.single.attemptCount,
        1,
        reason: 'Saving must preserve the durable retry for a later reload.',
      );
    },
  );
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.dialogueSessionLoader,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

RuntimeMapBundle _bundle() {
  final scene = _scene();
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _record(enabled: true),
    ],
    legacyClaims: const [],
  );
  return _bundleForRegistry(registry, scene);
}

RuntimeMapBundle _dialogueBundle() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _dialogueEventId,
          name: 'Boot dialogue Event V2',
          source: NarrativeEventSourceRef.mapEnter(_mapId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _dialogueSceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  final project = ProjectManifest(
    name: 'Event V2 boot dialogue integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: _dialogueId,
        name: 'Boot dialogue',
        relativePath: 'dialogues/boot.yarn',
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _dialogueFactId,
        label: 'Boot dialogue completed',
      ),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[_dialogueScene()],
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot_dialogue',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

RuntimeMapBundle _retryBundle() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _retryEventId,
          name: 'Boot retry producer',
          source: NarrativeEventSourceRef.mapEnter(_mapId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _retrySceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundleForRegistry(registry, _retryOutcomeScene());
}

SceneAsset _retryOutcomeScene() => SceneAsset(
      id: _retrySceneId,
      name: 'Event V2 boot retry producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(id: _retryOutcomeId, label: 'Boot retry'),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: _retryOutcomeId),
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

SceneAsset _dialogueScene() => SceneAsset(
      id: _dialogueSceneId,
      name: 'Event V2 boot dialogue Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: _dialogueId),
          ),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: _dialogueFactId,
                value: true,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_to_fact',
            fromNodeId: 'dialogue',
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

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Bienvenue.')],
      ),
    ],
    'Start',
  )!;
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) {
  return _waitUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime activation dispatch.');
}

RuntimeMapBundle _dualReadClaimedBundle() {
  final source = NarrativeEventSourceRef.mapEnter(_mapId);
  final provenance = LegacySourceRef.scenarioSourceNode(
    _legacyMapEnterScenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: _legacyMapEnterScenario.id,
      nodeId: 'source',
      scenario: _legacyMapEnterScenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt-event-v2-boot-dual-read',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[_record(enabled: false)],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundleForRegistry(registry, _scene());
}

NarrativeEventRecord _record({required bool enabled}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Boot Event V2',
      source: NarrativeEventSourceRef.mapEnter(_mapId),
      conditions: const <NarrativeEventCondition>[],
      sceneId: _sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: _sceneId,
    name: 'Event V2 boot Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
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

RuntimeMapBundle _bundleForRegistry(
  NarrativeEventRegistry registry,
  SceneAsset scene,
) {
  final project = ProjectManifest(
    name: 'Event V2 boot integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Boot Scene completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyMapEnterScenario],
    eventRegistry: registry,
    scenes: <SceneAsset>[scene],
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Event V2 Boot Map',
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

const _legacyMapEnterScenario = ScenarioAsset(
  id: 'legacy_map_enter_must_not_run',
  name: 'Legacy mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);
