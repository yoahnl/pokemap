import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'dialogue_outcome_scene_map';
const _dialogueId = 'dialogue_outcome_scene_dialogue';
const _sceneId = 'dialogue_outcome_scene';
const _eventId = 'evt_019abcde-6200-7000-8000-000000000001';
const _entityId = 'dialogue_outcome_scene_entity';
const _acceptedFactId = 'fact.dialogue_outcome_scene.accepted';
const _acceptedOutcomeId = 'accepted';
const _refusedOutcomeId = 'refused';
const _acceptedSceneOutcomeId = 'route.accepted';
const _refusedSceneOutcomeId = 'route.refused';
const _completedSceneOutcomeId = 'route.completed';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame Yarn outcome to direct Scene port', () {
    test('routes a real Yarn choice outcome to its declared Scene port',
        () async {
      final result = await _executeDialogueScene('''
title: Start
---
-> Accepter
    <<outcome accepted>>
-> Refuser
    <<outcome refused>>
===
''');

      final completed = result as NarrativeSceneExecutionCompleted;
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: _sceneId,
            outcomeId: _acceptedSceneOutcomeId,
          ),
        ],
      );
    });

    test('routes a dialogue without an outcome through completed', () async {
      final result = await _executeDialogueScene('''
title: Start
---
Guide: Continuons.
===
''');

      final completed = result as NarrativeSceneExecutionCompleted;
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: _sceneId,
            outcomeId: _completedSceneOutcomeId,
          ),
        ],
      );
    });

    test('rejects an unknown Yarn outcome before Scene routing', () async {
      final result = await _executeDialogueScene('''
title: Start
---
-> Inconnu
    <<outcome unexpected>>
===
''');

      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(
        (result as NarrativeSceneExecutionFailed).failure.toString(),
        contains('unsupported outcome "unexpected"'),
      );
    });

    test(
      'persists a consumed one-shot Event and does not replay its Yarn branch',
      () async {
        final projectRoot = await Directory.systemTemp.createTemp(
          'dialogue_outcome_event_v2_',
        );
        try {
          final yarnFile = File.fromUri(
            projectRoot.uri.resolve('dialogues/dialogue_outcome_scene.yarn'),
          );
          await yarnFile.parent.create(recursive: true);
          await yarnFile.writeAsString('''
title: Start
---
-> Accepter
    <<outcome accepted>>
-> Refuser
    <<outcome refused>>
===
''');

          final bundle = RuntimeMapBundle(
            manifest: _eventProject(),
            map: _eventMap(),
            projectRootDirectory: projectRoot.path,
            tilesetAbsolutePathsById: const <String, String>{},
          );
          final repository = _MemoryGameSaveRepository();
          var entityInteractionPreparationCount = 0;
          final game = _DialogueOutcomeSceneTestGame(
            bundle: bundle,
            projectFilePath:
                File.fromUri(projectRoot.uri.resolve('project.json')).path,
            saveData: saveDataFromGameState(_initialState()),
            saveRepository: repository,
            runtimeMapBundleLoader: ({
              required String projectFilePath,
              required String mapId,
            }) async {
              expect(mapId, _mapId);
              return bundle;
            },
            beforeNarrativeAuthorityPreparation: (occurrence) async {
              if (occurrence.source ==
                  NarrativeEventSourceRef.entityInteract(
                    _mapId,
                    _entityId,
                  )) {
                entityInteractionPreparationCount++;
              }
            },
          );

          game.onGameResize(Vector2(320, 240));
          await game.onLoad();
          await _waitUntil(
            game,
            () => !game.debugIsMapActivationDispatchInFlight,
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .consumedNarrativeEventIds
                    .contains(_eventId) &&
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(entityInteractionPreparationCount, 1);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[_acceptedFactId],
            isTrue,
            reason: 'The selected Yarn outcome must traverse the accepted '
                'Scene branch before the Event is consumed.',
          );
          expect(await game.saveGame(), isTrue);
          expect(repository.storedState, isNotNull);

          expect(await game.loadGame(), isTrue);
          await _waitUntil(
            game,
            () => !game.debugIsMapActivationDispatchInFlight,
          );
          expect(
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds,
            contains(_eventId),
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                entityInteractionPreparationCount == 2 &&
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(game.debugFlowPhaseName, 'overworld');
          expect(game.debugHasPendingDialogueLoad, isFalse);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[_acceptedFactId],
            isTrue,
          );
        } finally {
          await projectRoot.delete(recursive: true);
        }
      },
    );
  });
}

Future<NarrativeSceneExecutionResult> _executeDialogueScene(
  String yarnSource,
) async {
  final projectRoot = await Directory.systemTemp.createTemp(
    'dialogue_outcome_scene_',
  );
  try {
    final yarnFile = File.fromUri(
      projectRoot.uri.resolve('dialogues/dialogue_outcome_scene.yarn'),
    );
    await yarnFile.parent.create(recursive: true);
    await yarnFile.writeAsString(yarnSource);

    final game = _DialogueOutcomeSceneTestGame(
      bundle: RuntimeMapBundle(
        manifest: _project(),
        map: _map(),
        projectRootDirectory: projectRoot.path,
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      projectFilePath:
          File.fromUri(projectRoot.uri.resolve('project.json')).path,
      saveData: saveDataFromGameState(_initialState()),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitUntil(
      game,
      () => !game.debugIsMapActivationDispatchInFlight,
    );

    final execution = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event_dialogue_outcome_scene',
        sceneId: _sceneId,
        executionId: 'execution_dialogue_outcome_scene',
        gameState: game.gameStateSnapshot,
      ),
    );
    await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );

    return await execution.timeout(const Duration(seconds: 2));
  } finally {
    await projectRoot.delete(recursive: true);
  }
}

ProjectManifest _project() => ProjectManifest(
      name: 'PlayableMapGame dialogue outcome Scene integration',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: _mapId,
          name: 'Dialogue Outcome Scene Map',
          relativePath: 'maps/dialogue_outcome_scene_map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: _dialogueId,
          name: 'Dialogue Outcome Scene Dialogue',
          relativePath: 'dialogues/dialogue_outcome_scene.yarn',
          declaredOutcomes: <DialogueDeclaredOutcome>[
            DialogueDeclaredOutcome(
              id: _acceptedOutcomeId,
              label: 'Accepté',
            ),
            DialogueDeclaredOutcome(
              id: _refusedOutcomeId,
              label: 'Refusé',
            ),
          ],
        ),
      ],
      scenes: <SceneAsset>[_scene()],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );

ProjectManifest _eventProject() => _project().copyWith(
      name: 'PlayableMapGame Event V2 dialogue outcome integration',
      facts: <NarrativeFactDefinition>[
        NarrativeFactDefinition(
          id: _acceptedFactId,
          label: 'Accepted branch reached',
        ),
      ],
      scenes: <SceneAsset>[_scene(recordAcceptedFact: true)],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: <NarrativeEventRecord>[
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: _eventId,
              name: 'One-shot dialogue outcome event',
              source: NarrativeEventSourceRef.entityInteract(
                _mapId,
                _entityId,
              ),
              conditions: const <NarrativeEventCondition>[],
              sceneId: _sceneId,
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const <LegacySourceClaim>[],
      ),
    );

SceneAsset _scene({bool recordAcceptedFact = false}) => SceneAsset(
      id: _sceneId,
      name: 'Dialogue Outcome Scene',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _acceptedSceneOutcomeId,
          label: 'Accepted route',
        ),
        SceneOutcome(
          id: _completedSceneOutcomeId,
          label: 'Completed route',
        ),
        SceneOutcome(
          id: _refusedSceneOutcomeId,
          label: 'Refused route',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: _dialogueId,
              yarnNodeName: 'Start',
              expectedOutcomes: const <String>[
                _acceptedOutcomeId,
                _refusedOutcomeId,
              ],
            ),
          ),
          if (recordAcceptedFact)
            SceneNode(
              id: 'accepted_fact',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(
                  factId: _acceptedFactId,
                  value: true,
                ),
              ),
            ),
          SceneNode(
            id: 'accepted_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _acceptedSceneOutcomeId,
            ),
          ),
          SceneNode(
            id: 'completed_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _completedSceneOutcomeId,
            ),
          ),
          SceneNode(
            id: 'refused_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _refusedSceneOutcomeId,
            ),
          ),
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
            id: 'dialogue_accepted',
            fromNodeId: 'dialogue',
            fromPortId: _acceptedOutcomeId,
            toNodeId: recordAcceptedFact ? 'accepted_fact' : 'accepted_end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
          if (recordAcceptedFact)
            SceneEdge(
              id: 'accepted_fact_to_end',
              fromNodeId: 'accepted_fact',
              fromPortId: 'completed',
              toNodeId: 'accepted_end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          SceneEdge(
            id: 'dialogue_completed',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'completed_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_refused',
            fromNodeId: 'dialogue',
            fromPortId: _refusedOutcomeId,
            toNodeId: 'refused_end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
        ],
      ),
    );

MapData _map() => const MapData(
      id: _mapId,
      name: 'Dialogue Outcome Scene Map',
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

MapData _eventMap() => const MapData(
      id: _mapId,
      name: 'Dialogue Outcome Event V2 Map',
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
        MapEntity(
          id: _entityId,
          name: 'Dialogue outcome target',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 2),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

GameState _initialState() => const GameState(
      saveId: 'dialogue-outcome-scene-save',
      currentMapId: _mapId,
      playerPosition: GridPos(x: 1, y: 1),
    );

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out waiting for PlayableMapGame dialogue outcome integration: '
    'phase=${game.debugFlowPhaseName} '
    'activation=${game.debugIsMapActivationDispatchInFlight}.',
  );
}

final class _DialogueOutcomeSceneTestGame extends PlayableMapGame {
  _DialogueOutcomeSceneTestGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.beforeNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  GameState? storedState;

  @override
  Future<void> save(GameState state) async {
    storedState = state;
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
