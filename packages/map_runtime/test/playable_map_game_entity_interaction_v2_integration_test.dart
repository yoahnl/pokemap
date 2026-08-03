import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

const _mapId = 'event_v2_entity_interaction_map';
const _legacyFlag = 'test.event_v2.entity.legacy_fallback';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame Event V2 entity interaction production hook', () {
    for (final fixture in _entityFixtures) {
      test(
        '${fixture.kind.name} executes its Scene once and suppresses legacy',
        () async {
          var nativeDialogueLoadCount = 0;
          final game = _TestPlayableMapGame(
            bundle: _v2Bundle(fixture),
            projectFilePath: '/tmp/event_v2_entity/project.json',
            dialogueSessionLoader: (_) async {
              nativeDialogueLoadCount++;
              return null;
            },
          );

          await _load(game);
          expect(_pressPrimary(game), isTrue);
          await _pumpUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[fixture.factId] ==
                true,
          );

          final state = game.gameStateSnapshot;
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            contains(fixture.eventId),
            reason: 'The selected one-shot Event must be committed.',
          );
          expect(
            state.storyFlags.activeFlags,
            isNot(contains(_legacyFlag)),
            reason: 'A V2-handled occurrence must not run Scenario fallback.',
          );
          expect(
            nativeDialogueLoadCount,
            0,
            reason: 'NPC/sign native dialogue fallback must stay suppressed.',
          );
          expect(
            game.debugNotificationText,
            isNull,
            reason: 'Item/custom native feedback must stay suppressed.',
          );
        },
      );
    }

    test('spawn entities never create an entityInteract occurrence', () async {
      var entityAuthorityPreparationCount = 0;
      final game = _TestPlayableMapGame(
        bundle: _spawnExclusionBundle(),
        projectFilePath: '/tmp/event_v2_spawn_exclusion/project.json',
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityInteract) {
            entityAuthorityPreparationCount++;
          }
        },
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);

      expect(entityAuthorityPreparationCount, 0);
    });

    test('legacyOnly noMatch keeps the matching Scenario fallback', () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(
          fixture.entity,
          scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
        ),
        projectFilePath: '/tmp/event_v2_legacy_scenario/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.storyFlags.activeFlags.contains(_legacyFlag),
      );

      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        contains(_legacyFlag),
      );
    });

    test('legacyOnly noMatch keeps native entity fallback', () async {
      const entity = MapEntity(
        id: 'custom_native_fallback',
        name: 'Native custom fallback',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 0),
      );
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(entity),
        projectFilePath: '/tmp/event_v2_legacy_native/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () => game.debugNotificationText == entity.name,
      );

      expect(game.debugNotificationText, entity.name);
    });

    test('dualRead claimed-ineligible occurrence suppresses all fallback',
        () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _claimedIneligibleBundle(fixture),
        projectFilePath: '/tmp/event_v2_claimed_ineligible/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);

      final state = game.gameStateSnapshot;
      expect(
        state.storyFlags.activeFlags,
        isNot(contains(_legacyFlag)),
        reason: 'A validated claim owns the occurrence even when disabled.',
      );
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[fixture.factId],
        isNot(true),
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(fixture.eventId)),
      );
      expect(game.debugNotificationText, isNull);
    });

    test('a second input during async authority preparation launches once',
        () async {
      final fixture = _entityFixtures.first;
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var entityAuthorityPreparationCount = 0;
      final gate = NarrativeRuntimeActivityGate();
      final repository = _CheckpointCountingRepository(gate);
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/event_v2_entity_interlock/project.json',
        narrativeRuntimeActivityGate: gate,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.entityInteract) {
            return;
          }
          entityAuthorityPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await preparationStarted.future;

      expect(gate.activity, NarrativeRuntimeActivity.dispatching);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.saveCount, 0);
      expect(repository.loadCount, 0);

      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);
      expect(
        entityAuthorityPreparationCount,
        1,
        reason: 'The in-flight spatial dispatch must absorb duplicate input.',
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[fixture.factId] ==
            true,
      );

      expect(entityAuthorityPreparationCount, 1);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(fixture.eventId),
      );
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
    });

    test(
      'entity outcome retry stays pending without escaping its detached task',
      () async {
        final fixture = _entityFixtures.first;
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var outcomePreparationCount = 0;
        final game = _TestPlayableMapGame(
          bundle: _retryOutcomeBundle(fixture),
          projectFilePath: '/tmp/event_v2_entity_retry/project.json',
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind !=
                NarrativeEventSourceKind.outcomeReceived) {
              return;
            }
            outcomePreparationCount++;
            throw StateError(
              'retryable entity outcome infrastructure failure',
            );
          },
        );

        await _load(game);
        final uncaughtErrors = await _captureDetachedErrors(() async {
          expect(_pressPrimary(game), isTrue);
          await _pumpUntil(
            game,
            () =>
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight &&
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isNotEmpty,
          );
          await Future<void>.delayed(Duration.zero);
        });

        final state = game.gameStateSnapshot;
        final pending =
            state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
        expect(uncaughtErrors, isEmpty);
        expect(outcomePreparationCount, 1);
        expect(pending, hasLength(1));
        expect(pending.single.outcome.outcomeId, _entityRetryOutcomeId);
        expect(pending.single.attemptCount, 1);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          contains(fixture.eventId),
        );
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(game.debugIsNarrativeOutcomeWorkInFlight, isFalse);
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries.single.attemptCount,
          1,
        );
      },
    );
  });
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

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.dialogueSessionLoader,
    super.beforeNarrativeAuthorityPreparation,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

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
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _EntityFixture {
  const _EntityFixture({
    required this.entity,
    required this.eventId,
    required this.sceneId,
    required this.factId,
  });

  final MapEntity entity;
  final String eventId;
  final String sceneId;
  final String factId;

  MapEntityKind get kind => entity.kind;
}

const _entityFixtures = <_EntityFixture>[
  _EntityFixture(
    entity: MapEntity(
      id: 'npc_v2',
      name: 'NPC V2',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 0),
      npc: MapEntityNpcData(
        displayName: 'NPC native fallback',
        dialogue: DialogueRef(dialogueId: 'native_dialogue'),
      ),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000001',
    sceneId: 'scene_entity_npc_v2',
    factId: 'fact.event_v2.entity.npc',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'sign_v2',
      name: 'Sign V2',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 1, y: 0),
      sign: MapEntitySignData(
        title: 'Sign native fallback',
        dialogue: DialogueRef(dialogueId: 'native_dialogue'),
      ),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000002',
    sceneId: 'scene_entity_sign_v2',
    factId: 'fact.event_v2.entity.sign',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'item_v2',
      name: 'Item native fallback',
      kind: MapEntityKind.item,
      pos: GridPos(x: 1, y: 0),
      item: MapEntityItemData(gameItemId: 'item_native_fallback'),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000003',
    sceneId: 'scene_entity_item_v2',
    factId: 'fact.event_v2.entity.item',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'custom_v2',
      name: 'Custom native fallback',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 0),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000004',
    sceneId: 'scene_entity_custom_v2',
    factId: 'fact.event_v2.entity.custom',
  ),
];

const _entityRetryOutcomeId = 'entity.retry';

RuntimeMapBundle _v2Bundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: true),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: fixture.factId, label: fixture.factId),
    ],
    scenes: <SceneAsset>[_scene(fixture)],
    scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
  );
}

RuntimeMapBundle _retryOutcomeBundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: true),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    scenes: <SceneAsset>[_outcomeScene(fixture)],
  );
}

RuntimeMapBundle _claimedIneligibleBundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final scenario = _legacyScenario(fixture.entity.id);
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: 'source',
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, <LegacySourceRef>[
    provenance,
  ]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: <LegacySourceClaimMember>[member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      <LegacySourceClaimMember>[member],
    ),
    targetEventIds: <String>[fixture.eventId],
    migrationReceiptId: 'receipt-entity-claimed-ineligible',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: false),
    ],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: fixture.factId, label: fixture.factId),
    ],
    scenes: <SceneAsset>[_scene(fixture)],
    scenarios: <ScenarioAsset>[scenario],
  );
}

RuntimeMapBundle _legacyOnlyBundle(
  MapEntity entity, {
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
}) {
  return _bundle(
    entity: entity,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenarios: scenarios,
  );
}

RuntimeMapBundle _spawnExclusionBundle() {
  const spawnTarget = MapEntity(
    id: 'spawn_event_target',
    name: 'Excluded spawn',
    kind: MapEntityKind.spawn,
    pos: GridPos(x: 1, y: 0),
    blocksMovement: false,
    spawn: MapEntitySpawnData(role: EntitySpawnRole.event),
  );
  return _bundle(
    entity: spawnTarget,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
}

RuntimeMapBundle _bundle({
  required MapEntity entity,
  required NarrativeEventRegistry eventRegistry,
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
}) {
  final project = ProjectManifest(
    name: 'Event V2 entity interaction integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Entity Map',
        relativePath: 'maps/event_v2_entity.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'native_dialogue',
        name: 'Native fallback dialogue',
        relativePath: 'dialogues/native.yarn',
      ),
    ],
    facts: facts,
    scenes: scenes,
    scenarios: scenarios,
    eventRegistry: eventRegistry,
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(entity),
    projectRootDirectory: '/tmp/event_v2_entity',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map(MapEntity entity) => MapData(
      id: _mapId,
      name: 'Event V2 Entity Map',
      size: const GridSize(width: 3, height: 2),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn_start',
          name: 'Player start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        entity,
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_start'),
    );

NarrativeEventRecord _eventRecord(
  _EntityFixture fixture, {
  required NarrativeEventSourceRef source,
  required bool enabled,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: fixture.eventId,
      name: 'Entity Event ${fixture.kind.name}',
      source: source,
      conditions: const <NarrativeEventCondition>[],
      sceneId: fixture.sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene(_EntityFixture fixture) {
  return SceneAsset(
    id: fixture.sceneId,
    name: 'Entity Scene ${fixture.kind.name}',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: fixture.factId, value: true),
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

SceneAsset _outcomeScene(_EntityFixture fixture) {
  return SceneAsset(
    id: fixture.sceneId,
    name: 'Entity retry Scene ${fixture.kind.name}',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: _entityRetryOutcomeId, label: 'Entity retry'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: _entityRetryOutcomeId),
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

ScenarioAsset _legacyScenario(String entityId) {
  return ScenarioAsset(
    id: 'legacy_entity_$entityId',
    name: 'Legacy entity fallback',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceEntityInteract,
        ),
        binding: ScenarioNodeBinding(mapId: _mapId, entityId: entityId),
      ),
      const ScenarioNode(
        id: 'set_legacy_flag',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyFlag),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
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
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

bool _pressPrimary(PlayableMapGame game) {
  return game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
}

Future<void> _pumpMicrotasks(PlayableMapGame game, {int ticks = 12}) async {
  for (var i = 0; i < ticks; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
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
  fail('Timed out waiting for the Event V2 entity interaction runtime.');
}
