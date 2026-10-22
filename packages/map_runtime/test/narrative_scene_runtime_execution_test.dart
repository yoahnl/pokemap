import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

import 'scene_interactive_pokemon_gift_test.dart' show giftCatalog, giftCommand;

void main() {
  group('executeNarrativeEventScene', () {
    for (final sceneCount in [1, 3940]) {
      test(
        'presentation reads reuse pending projection with $sceneCount scenes',
        () async {
          const initial = GameState(saveId: 'presentation-cache');
          var host = initial;
          final scene = _presentationProjectionScene();
          final empty = SceneAsset(
            id: 'unused',
            name: 'Unused',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'finish',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow,
                ),
              ],
            ),
          );
          final project = ProjectManifest(
            name: 'Presentation projection',
            maps: const [],
            tilesets: const [],
            facts: [
              for (var i = 0; i < 855; i++)
                NarrativeFactDefinition(id: 'fact_$i', label: 'Fact $i'),
            ],
            scenes: [
              scene,
              for (var i = 1; i < sceneCount; i++)
                SceneAsset(
                  id: 'unused_$i',
                  name: empty.name,
                  graph: empty.graph,
                ),
            ],
            dialogues: const [
              ProjectDialogueEntry(
                id: 'observe',
                name: 'Observe',
                relativePath: 'dialogues/observe.yarn',
              ),
            ],
          );
          final mutations = _CountingPresentationMutations();
          GameState Function()? projection;
          final replayCounts = <int>[];
          final sameStates = <bool>[];
          final money = <int>[];
          final flags = <Set<String>>[];
          void observe() {
            final before = mutations.moneyWrites;
            final states = [for (var i = 0; i < 20; i++) projection!()];
            replayCounts.add(mutations.moneyWrites - before);
            sameStates.add(
              states.every((value) => identical(value, states.first)),
            );
            money.add(states.first.trainerProfile.money);
            flags.add(states.first.storyFlags.activeFlags.toSet());
          }

          var dialogues = 0;
          var writesAfterPresentation = 0;
          final result = await executeNarrativeEventScene(
            request: NarrativeSceneExecutionRequest(
              eventId: 'event',
              sceneId: scene.id,
              executionId: 'execution',
              gameState: initial,
            ),
            project: project,
            mapsById: const {},
            currentGameState: () => host,
            consequenceWriter: SceneConsequenceRuntimeWriter(
              project: project,
              mutations: mutations,
            ),
            onSceneStateProjection: (value) => projection = value,
            callbacks: SceneRuntimeHostCallbacks(
              evaluateCondition: (_) =>
                  throw StateError('Unexpected condition'),
              startBattle: (_) => throw StateError('Unexpected battle'),
              playCinematic: (_) => throw StateError('Unexpected cinematic'),
              showDialogue: (_) {
                observe();
                if (dialogues++ == 0) {
                  host = host.copyWith(
                    trainerProfile: host.trainerProfile.copyWith(money: 100),
                  );
                  observe();
                  host = GameState.fromJson(host.toJson());
                  observe();
                }
                writesAfterPresentation = mutations.moneyWrites;
                return 'completed';
              },
            ),
          );
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          final completed = result as NarrativeSceneExecutionCompleted;
          expect(money, [1, 101, 101, 103]);
          expect(
            flags[0],
            containsAll([for (var i = 0; i < 40; i++) 'fact_$i']),
          );
          expect(flags[3], isNot(contains('fact_0')));
          expect(completed.updatedGameState.trainerProfile.money, 103);
          expect(host.trainerProfile.money, 100);
          expect(host.storyFlags.activeFlags, isEmpty);
          expect(projection, isNull);
          expect(replayCounts, [1, 1, 1, 2]);
          expect(mutations.moneyWrites - writesAfterPresentation, 2);
          expect(sameStates, everyElement(isTrue));
        },
      );
    }

    test(
      'warmed presentation projection is released after callback failure',
      () async {
        const initial = GameState(saveId: 'presentation-failed');
        final scene = _presentationCheckpointScene([
          SceneNode(
            id: 'money',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.giveMoney(amount: 25),
            ),
          ),
          SceneNode(
            id: 'observe',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'observe',
              yarnNodeName: 'Start',
            ),
          ),
        ]);
        final project = ProjectManifest(
          name: 'Failed presentation',
          maps: const [],
          tilesets: const [],
          scenes: [scene],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'observe',
              name: 'Observe',
              relativePath: 'dialogues/observe.yarn',
            ),
          ],
        );
        GameState Function()? projection;
        GameState? warmedState;
        var reusedBeforeFailure = false;
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'failed',
            sceneId: scene.id,
            executionId: 'failed',
            gameState: initial,
          ),
          project: project,
          mapsById: const {},
          currentGameState: () => initial,
          onSceneStateProjection: (value) => projection = value,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
            showDialogue: (_) {
              warmedState = projection!();
              reusedBeforeFailure = identical(projection!(), warmedState);
              throw StateError('Host cancelled the dialogue');
            },
          ),
        );
        expect(result, isA<NarrativeSceneExecutionFailed>());
        expect(initial.trainerProfile.money, 0);
        expect(warmedState!.trainerProfile.money, 25);
        expect(reusedBeforeFailure, isTrue);
        expect(projection, isNull);
      },
    );

    test(
      'presentation projection invalidates after a prepared Pokemon gift',
      () async {
        const initial = GameState(
          saveId: 'presentation-gift',
          currentMapId: 'lab',
        );
        final scene = _presentationCheckpointScene(
          [
            SceneNode(
              id: 'receive',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                giftCommand(offer: false),
              ),
            ),
            SceneNode(
              id: 'observe',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'observe',
                yarnNodeName: 'Start',
              ),
            ),
          ],
          ports: const {
            'receive': ['party', 'pc', 'noCapacity'],
          },
        );
        final project = ProjectManifest(
          name: 'Prepared gift',
          maps: const [],
          tilesets: const [],
          scenes: [scene],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'observe',
              name: 'Observe',
              relativePath: 'dialogues/observe.yarn',
            ),
          ],
        );
        GameState Function()? projection;
        GameState? before;
        GameState? after;
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'gift',
            sceneId: scene.id,
            executionId: 'gift',
            gameState: initial,
          ),
          project: project,
          mapsById: const {},
          currentGameState: () => initial,
          consequenceWriter: SceneConsequenceRuntimeWriter(
            project: project,
            pokemonCatalog: giftCatalog(),
          ),
          onSceneStateProjection: (value) => projection = value,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
            presentPokemonGift: (request) async {
              before = projection!();
              return SceneInteractionResult.acknowledged(
                requestId: request.interaction.requestId,
                revision: request.interaction.revision,
              );
            },
            showDialogue: (_) {
              after = projection!();
              expect(projection!(), same(after));
              return 'completed';
            },
          ),
        );
        expect(result, isA<NarrativeSceneExecutionCompleted>());
        expect(before!.party.members, isEmpty);
        expect(after!.party.members, hasLength(1));
        expect(
          (result as NarrativeSceneExecutionCompleted).updatedGameState.party,
          after!.party,
        );
        expect(initial.party.members, isEmpty);
        expect(projection, isNull);
      },
    );

    test(
      'presentation projection retires buffered NPC poses after a route',
      () async {
        final scope = MapInstanceRef(mapId: 'room', instanceId: 'visit');
        final initial = GameState(
          saveId: 'presentation-pose',
          currentMapId: 'room',
          storyFlags: const StoryFlags(activeFlags: {'visible'}),
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              'room': MapInstanceRuntimeState(
                instanceId: 'visit',
                npcPoses: {
                  'actor': MapInstanceNpcPose(
                    position: const GridPos(x: 1, y: 1),
                    facing: EntityFacing.south,
                  ),
                },
              ),
            },
          ),
        );
        var host = initial;
        final map = MapData(
          id: 'room',
          name: 'Room',
          size: const GridSize(width: 5, height: 5),
          entities: [
            MapEntity(
              id: 'actor',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 1, y: 1),
              npc: const MapEntityNpcData(characterId: 'known'),
              presentation: MapEntityPresentation(
                variants: [
                  MapEntityPresentationVariant(
                    id: 'visible',
                    characterId: 'known',
                    blocksMovement: false,
                    condition: NarrativeEventConditionExpression.leaf(
                      NarrativeEventCondition.fact('visible', true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final scene = _presentationCheckpointScene(
          [
            SceneNode(
              id: 'pose',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setNpcPose(
                  mapId: 'room',
                  entityId: 'actor',
                  facing: EntityFacing.east,
                ),
              ),
            ),
            SceneNode(
              id: 'route',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.fromJson({
                  'kind': 'actorRoute',
                  'target': {
                    'kind': 'entity',
                    'mapId': 'room',
                    'entityId': 'actor',
                  },
                  'steps': [
                    {'kind': 'wait', 'durationMs': 1},
                  ],
                  'skippable': false,
                }),
              ),
            ),
            SceneNode(
              id: 'observe',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'observe',
                yarnNodeName: 'Start',
              ),
            ),
          ],
          ports: const {
            'route': ['completed', 'blocked'],
          },
        );
        final project = ProjectManifest(
          name: 'Retired pose',
          facts: [NarrativeFactDefinition(id: 'visible', label: 'Visible')],
          maps: const [
            ProjectMapEntry(
              id: 'room',
              name: 'Room',
              relativePath: 'room.json',
            ),
          ],
          tilesets: const [],
          characters: const [
            ProjectCharacterEntry(
              id: 'known',
              name: 'Known',
              tilesetId: 'sheet',
            ),
          ],
          scenes: [scene],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'observe',
              name: 'Observe',
              relativePath: 'dialogues/observe.yarn',
            ),
          ],
        );
        GameState Function()? projection;
        EntityFacing? before;
        EntityFacing? after;
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'pose',
            sceneId: scene.id,
            executionId: 'pose',
            gameState: initial,
          ),
          project: project,
          mapsById: {'room': map},
          currentGameState: () => host,
          consequenceWriter: SceneConsequenceRuntimeWriter(
            project: project,
            mapsById: {'room': map},
            mapInstanceScopes: {'room': scope},
          ),
          onSceneStateProjection: (value) => projection = value,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
            executeInteractiveCommand: (_) {
              before = projection!()
                  .mapInstanceWorldState
                  .instancesByMapId['room']!
                  .npcPoses['actor']!
                  .facing;
              host = host.copyWith(
                mapInstanceWorldState: host.mapInstanceWorldState.setNpcPoses(
                  scope,
                  {
                    'actor': MapInstanceNpcPose(
                      position: const GridPos(x: 1, y: 1),
                      facing: EntityFacing.west,
                    ),
                  },
                ),
              );
              return 'completed';
            },
            showDialogue: (_) {
              final first = projection!();
              expect(projection!(), same(first));
              after = first
                  .mapInstanceWorldState
                  .instancesByMapId['room']!
                  .npcPoses['actor']!
                  .facing;
              return 'completed';
            },
          ),
        );
        expect(
          result,
          isA<NarrativeSceneExecutionCompleted>(),
          reason: result is NarrativeSceneExecutionFailed
              ? '${result.failure}'
              : null,
        );
        expect(before, EntityFacing.east);
        expect(after, EntityFacing.west);
        expect(
          (result as NarrativeSceneExecutionCompleted)
              .updatedGameState
              .mapInstanceWorldState,
          host.mapInstanceWorldState,
        );
        expect(
          initial
              .mapInstanceWorldState
              .instancesByMapId['room']!
              .npcPoses['actor']!
              .facing,
          EntityFacing.south,
        );
      },
    );

    for (final mode in [
      'same',
      'retired',
      'recreated',
      'external',
      'blocked',
      'new-write',
      'roundtrip',
    ]) {
      test('local instance writes across a Scene Warp mode=$mode', () async {
        final source = _instanceWarpMap('source');
        final target = _instanceWarpMap('target');
        final scene = _instanceWarpScene(mode);
        final project = ProjectManifest(
          name: 'Scoped Warp',
          maps: [
            ProjectMapEntry(
              id: 'source',
              name: 'Source',
              relativePath: 'maps/source.json',
            ),
            ProjectMapEntry(
              id: 'target',
              name: 'Target',
              relativePath: 'maps/target.json',
            ),
          ],
          tilesets: const [],
          scenes: [scene],
        );
        final initial = GameState(
          saveId: 'instance-warp',
          currentMapId: 'source',
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              'source': MapInstanceRuntimeState(instanceId: 'old-source'),
            },
          ),
        );
        var host = initial;
        var warps = 0;
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'instance-event',
            sceneId: scene.id,
            executionId: 'instance-execution-$mode',
            gameState: initial,
          ),
          project: project,
          mapsById: {'source': source, 'target': target},
          currentGameState: () => host,
          consequenceWriter: SceneConsequenceRuntimeWriter(
            project: project,
            mapsById: {'source': source, 'target': target},
            mapInstanceScopes: {
              'source': initial.mapInstanceWorldState.instanceRef('source')!,
            },
          ),
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
            executeInteractiveCommand: (intent) {
              warps++;
              if (mode != 'same') {
                final command = intent.interactiveCommand;
                host = host.copyWith(
                  currentMapId: command is SceneWarpInteractiveCommand
                      ? command.destinationMapId
                      : 'source',
                  mapInstanceWorldState: MapInstanceWorldState(
                    instancesByMapId: {
                      if (mode == 'recreated' ||
                          mode == 'external' ||
                          (mode == 'roundtrip' && warps == 2))
                        'source': MapInstanceRuntimeState(
                          instanceId: 'new-source',
                        ),
                      'target': MapInstanceRuntimeState(
                        instanceId: 'target-instance',
                      ),
                    },
                  ),
                );
              }
              return mode == 'blocked' ? 'blocked' : 'completed';
            },
          ),
        );
        final success = !['external', 'blocked', 'new-write'].contains(mode);
        expect(
          result,
          success
              ? isA<NarrativeSceneExecutionCompleted>()
              : isA<NarrativeSceneExecutionFailed>(),
        );
        expect(warps, mode == 'roundtrip' ? 2 : 1);
        expect(
          initial.mapInstanceWorldState.eventBoolean(
            initial.mapInstanceWorldState.instanceRef('source')!,
            'owner',
            'A',
          ),
          isFalse,
        );
        if (result is NarrativeSceneExecutionCompleted) {
          final store = result.updatedGameState.mapInstanceWorldState;
          expect(
            result.updatedGameState.trainerProfile.money,
            initial.trainerProfile.money + 100,
          );
          if (store.instanceRef('source') != null) {
            expect(
              store.eventBoolean(store.instanceRef('source')!, 'owner', 'A'),
              mode == 'same',
            );
          }
        }
      });
    }

    for (final value in [
      const NarrativeValue.boolean(true),
      NarrativeValue.integer(2),
    ]) {
      test('fact condition observes buffered ${value.kind.name}', () async {
        const initial = GameState(saveId: 'fact_buffer');
        final fact = NarrativeFactDefinition(
          id: 'page_state',
          label: 'Page state',
          initialValue: value.kind == NarrativeValueKind.boolean
              ? const NarrativeValue.boolean(false)
              : NarrativeValue.integer(0),
        );
        final scene = _factScene(value: value);
        var staleCallbackReads = 0;
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'fact_event',
            sceneId: scene.id,
            executionId: 'fact_execution',
            gameState: initial,
          ),
          project: ProjectManifest(
            name: 'Buffered fact',
            maps: const [],
            tilesets: const [],
            facts: [fact],
            scenes: [scene],
          ),
          mapsById: const {},
          currentGameState: () => initial,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (intent) {
              staleCallbackReads++;
              return evaluateCanonicalNarrativeFactSceneCondition(
                source: intent.conditionSource!,
                gameState: initial,
                resolver: NarrativeFactRuntimeResolver.fromFacts([fact]),
              )
                  ? 'true'
                  : 'false';
            },
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        );

        expect(result, isA<NarrativeSceneExecutionCompleted>());
        final completed = result as NarrativeSceneExecutionCompleted;
        expect(completed.qualifiedOutcomes.single.outcomeId, 'present');
        expect(staleCallbackReads, 0);
        expect(initial.narrativeFactRuntimeState.valuesByFactId, isEmpty);
        final reloaded = GameState.fromJson(
          completed.updatedGameState.toJson(),
        );
        expect(
          evaluateCanonicalNarrativeFactSceneCondition(
            source: (scene.graph.nodes
                    .singleWhere((node) => node.id == 'condition')
                    .payload as SceneConditionPayload)
                .conditionSource!,
            gameState: reloaded,
            resolver: NarrativeFactRuntimeResolver.fromFacts([fact]),
          ),
          isTrue,
        );
      });
    }

    test('fact projection preserves the latest host writes', () async {
      const initial = GameState(saveId: 'fact_host');
      var host = initial;
      final facts = [
        NarrativeFactDefinition(id: 'page_state', label: 'Page state'),
        NarrativeFactDefinition(id: 'host_state', label: 'Host state'),
      ];
      final scene = _factScene(
        value: const NarrativeValue.boolean(true),
        withDialogue: true,
      );
      final project = ProjectManifest(
        name: 'Fact host',
        maps: const [],
        tilesets: const [],
        facts: facts,
        scenes: [scene],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'inventory_dialogue',
            name: 'Host write',
            relativePath: 'dialogues/host.yarn',
          ),
        ],
      );
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'fact_event',
          sceneId: scene.id,
          executionId: 'fact_host_execution',
          gameState: initial,
        ),
        project: project,
        mapsById: const {},
        currentGameState: () => host,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Stale fact callback'),
          showDialogue: (_) {
            expect(host.storyFlags.activeFlags, isEmpty);
            host = SceneConsequenceRuntimeWriter(project: project)
                .applyOne(
                  host,
                  SceneConsequence.setFact(factId: 'host_state', value: true),
                )
                .gameState;
            host = host.copyWith(
              trainerProfile: host.trainerProfile.copyWith(money: 1234),
            );
            return 'completed';
          },
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(completed.qualifiedOutcomes.single.outcomeId, 'present');
      expect(completed.updatedGameState.storyFlags.activeFlags,
          containsAll(['page_state', 'host_state']));
      expect(completed.updatedGameState.trainerProfile.money, 1234);
      expect(host.storyFlags.activeFlags, ['host_state']);
      expect(initial.storyFlags.activeFlags, isEmpty);
    });

    test('non-fact conditions keep their host callback with pending facts',
        () async {
      const initial = GameState(saveId: 'custom_condition');
      final scene = _factScene(
        value: const NarrativeValue.boolean(true),
        conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
          sourceId: 'custom_flag',
          operator: SceneConditionOperator.isTrue,
        ),
      );
      var callbackReads = 0;
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'fact_event',
          sceneId: scene.id,
          executionId: 'custom_execution',
          gameState: initial,
        ),
        project: ProjectManifest(
          name: 'Custom condition',
          maps: const [],
          tilesets: const [],
          facts: [
            NarrativeFactDefinition(id: 'page_state', label: 'Page state')
          ],
          scenes: [scene],
        ),
        mapsById: const {},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) {
            callbackReads++;
            expect(intent.conditionSource!.sourceId, 'custom_flag');
            return 'true';
          },
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionCompleted>());
      expect(callbackReads, 1);
      expect(
          (result as NarrativeSceneExecutionCompleted)
              .qualifiedOutcomes
              .single
              .outcomeId,
          'present');
    });

    test('fact projection never commits a scene that later fails', () async {
      const initial = GameState(saveId: 'fact_rollback');
      final scene = _factScene(
        value: const NarrativeValue.boolean(true),
        rejectAfterCondition: true,
      );
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'fact_event',
          sceneId: scene.id,
          executionId: 'fact_rollback_execution',
          gameState: initial,
        ),
        project: ProjectManifest(
          name: 'Fact rollback',
          maps: const [],
          tilesets: const [],
          facts: [
            NarrativeFactDefinition(id: 'page_state', label: 'Page state'),
          ],
          scenes: [scene],
        ),
        mapsById: const {},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => 'false',
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(initial.storyFlags.activeFlags, isEmpty);
      expect(initial.narrativeFactRuntimeState.valuesByFactId, isEmpty);
    });

    for (final hostFreesSpace in [true, false]) {
      test('consequence validates the latest host bag '
          '${hostFreesSpace ? 'release' : 'fill'}', () async {
        final initial = GameState(
          saveId: 'host_bag_capacity',
          bag: Bag(entries: [
            BagEntry(
              itemId: 'item_potion',
              quantity: maximumBagEntryQuantity - (hostFreesSpace ? 0 : 1),
            ),
          ]),
        );
        var host = initial;
        var dialogueCalls = 0;
        final scene = _hostPickupScene();
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'host_bag_event',
            sceneId: scene.id,
            executionId: 'host_bag_execution',
            gameState: initial,
          ),
          project: ProjectManifest(
            name: 'Host bag capacity',
            maps: const [],
            tilesets: const [],
            scenes: [scene],
            dialogues: const [
              ProjectDialogueEntry(
                id: 'inventory_dialogue',
                name: 'Host bag',
                relativePath: 'dialogues/host.yarn',
              ),
            ],
          ),
          mapsById: const {},
          currentGameState: () => host,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) {
              dialogueCalls++;
              if (dialogueCalls == 1) {
                host = hostFreesSpace
                    ? const GameStateMutations().removeItemForNarrativeConsequence(
                        host, itemId: 'item_potion', quantity: 1)
                    : const GameStateMutations().giveItem(host, 'item_potion', 1);
              }
              return 'completed';
            },
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        );

        if (hostFreesSpace) {
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          expect((result as NarrativeSceneExecutionCompleted)
              .updatedGameState.bag.entries.single.quantity,
              maximumBagEntryQuantity);
          expect(dialogueCalls, 2);
          expect(host.bag.entries.single.quantity, maximumBagEntryQuantity - 1);
        } else {
          expect(result, isA<NarrativeSceneExecutionFailed>());
          expect(dialogueCalls, 1);
          expect(host.bag.entries.single.quantity, maximumBagEntryQuantity);
        }
      });
    }

    for (final giving in [true, false]) {
      test('inventory condition observes buffered ${giving ? 'give' : 'take'}',
          () async {
        final initial = GameState(
            saveId: 'inventory',
            bag: Bag(
                entries: giving
                    ? const []
                    : const [BagEntry(itemId: 'item_potion', quantity: 1)]));
        final scene = _inventoryScene(giving: giving);
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
              eventId: 'inventory_event',
              sceneId: scene.id,
              executionId: 'inventory_execution',
              gameState: initial),
          project: ProjectManifest(
              name: 'Inventory condition',
              maps: const [],
              tilesets: const [],
              scenes: [scene]),
          mapsById: const {},
          currentGameState: () => initial,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                    source: intent.conditionSource!, gameState: initial)
                ? 'true'
                : 'false',
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        );
        expect(result, isA<NarrativeSceneExecutionCompleted>());
        final completed = result as NarrativeSceneExecutionCompleted;
        expect(completed.qualifiedOutcomes.single.outcomeId,
            giving ? 'present' : 'absent');
        expect(
            const GameStateMutations()
                .itemQuantity(completed.updatedGameState, 'item_potion'),
            giving ? 1 : 0);
        expect(const GameStateMutations().itemQuantity(initial, 'item_potion'),
            giving ? 0 : 1);
      });
    }

    test('inventory condition rebases pending gifts on the latest host state',
        () async {
      const initial = GameState(saveId: 'inventory_host');
      var host = initial;
      final scene = _inventoryScene(giving: true, withDialogue: true);
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
            eventId: 'inventory_event',
            sceneId: scene.id,
            executionId: 'inventory_host_execution',
            gameState: initial),
        project: ProjectManifest(
            name: 'Inventory host',
            maps: const [],
            tilesets: const [],
            scenes: [
              scene
            ],
            dialogues: const [
              ProjectDialogueEntry(
                  id: 'inventory_dialogue',
                  name: 'Inventory',
                  relativePath: 'dialogues/inventory.yarn')
            ]),
        mapsById: const {},
        currentGameState: () => host,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                  source: intent.conditionSource!, gameState: host)
              ? 'true'
              : 'false',
          showDialogue: (_) {
            expect(const GameStateMutations().itemQuantity(host, 'item_potion'),
                0);
            host = const GameStateMutations().giveItem(host, 'item_potion', 2);
            host = host.copyWith(
                trainerProfile: host.trainerProfile.copyWith(money: 1234));
            return 'completed';
          },
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(completed.qualifiedOutcomes.single.outcomeId, 'present');
      expect(
          const GameStateMutations()
              .itemQuantity(completed.updatedGameState, 'item_potion'),
          3);
      expect(completed.updatedGameState.trainerProfile.money, 1234);
      expect(const GameStateMutations().itemQuantity(host, 'item_potion'), 2);
      expect(
          const GameStateMutations().itemQuantity(initial, 'item_potion'), 0);
    });

    test('inventory projection never commits a scene that later fails',
        () async {
      const initial = GameState(saveId: 'inventory_rollback');
      final scene = _inventoryScene(giving: true, rejectAfterCondition: true);
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
            eventId: 'inventory_event',
            sceneId: scene.id,
            executionId: 'inventory_rollback_execution',
            gameState: initial),
        project: ProjectManifest(
            name: 'Inventory rollback',
            maps: const [],
            tilesets: const [],
            scenes: [scene]),
        mapsById: const {},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                  source: intent.conditionSource!, gameState: initial)
              ? 'true'
              : 'false',
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(
          const GameStateMutations().itemQuantity(initial, 'item_potion'), 0);
    });

    test('unique wild battle consumes one-shot only after victory or capture',
        () async {
      const state = GameState(saveId: 'save_unique');
      final project = _project().copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'unique',
            name: 'Rencontre unique',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 12,
                maxLevel: 12,
              ),
            ],
          ),
        ],
        scenes: [_uniqueWildScene()],
      );
      for (final (outcome, consumed) in const [
        ('defeat', false),
        ('runaway', false),
        ('victory', true),
        ('captured', true),
      ]) {
        final result = await executeNarrativeEventScene(
          request: const NarrativeSceneExecutionRequest(
            eventId: 'unique_event',
            sceneId: 'unique_scene',
            executionId: 'unique_execution',
            gameState: state,
          ),
          project: project,
          mapsById: const {},
          currentGameState: () => state,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (intent) {
              expect(intent.battleKind, 'wild');
              expect(intent.battleTemplateId, 'unique');
              return outcome;
            },
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        );
        expect(result, isA<NarrativeSceneExecutionCompleted>(),
            reason: result is NarrativeSceneExecutionFailed
                ? '${result.failure}'
                : null);
        expect((result as NarrativeSceneExecutionCompleted).consumeOneShot,
            consumed);
        expect(
          result.updatedGameState.storyFlags.activeFlags,
          consumed
              ? contains('studio:unique_encounter:unique:consumed')
              : isNot(contains('studio:unique_encounter:unique:consumed')),
        );
      }
    });
    test('one consumed table cannot replay through another scene after reload',
        () async {
      const state = GameState(saveId: 'save_shared_unique');
      final project = _project().copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'unique',
            name: 'Rencontre unique',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 12,
                maxLevel: 12,
              ),
            ],
          ),
        ],
        scenes: [_uniqueWildScene(), _uniqueWildScene('another_scene')],
      );
      var battles = 0;
      SceneRuntimeHostCallbacks callbacks(String outcome) =>
          SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) {
              battles++;
              return outcome;
            },
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          );
      Future<NarrativeSceneExecutionResult> play(
        String sceneId,
        GameState gameState,
        String outcome,
      ) =>
          executeNarrativeEventScene(
            request: NarrativeSceneExecutionRequest(
              eventId: sceneId,
              sceneId: sceneId,
              executionId: 'run_$sceneId',
              gameState: gameState,
            ),
            project: project,
            mapsById: const {},
            currentGameState: () => gameState,
            callbacks: callbacks(outcome),
          );

      final defeat = await play('unique_scene', state, 'defeat');
      expect(defeat, isA<NarrativeSceneExecutionCompleted>());
      expect(battles, 1);
      final victory = await play('unique_scene', state, 'victory');
      expect(victory, isA<NarrativeSceneExecutionCompleted>());
      expect(battles, 2);
      final saved = (victory as NarrativeSceneExecutionCompleted)
          .updatedGameState
          .toJson();
      final reloaded = GameState.fromJson(saved);
      final replay = await play('another_scene', reloaded, 'victory');
      expect(replay, isA<NarrativeSceneExecutionCancelled>());
      expect(battles, 2);
    });
    test('a consumed table on an unvisited branch does not block the scene',
        () async {
      const initial = GameState(saveId: 'save_branch_unique');
      final state = const GameStateMutations().setFlag(
        initial,
        uniqueEncounterConsumedFlag('unique'),
      );
      final scene = SceneAsset(
        id: 'branch_scene',
        name: 'Combat avec branche',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'common',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'wild',
                battleTemplateId: 'common',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(
              id: 'unique',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'wild',
                battleTemplateId: 'unique',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_common',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'common',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'common_victory',
              fromNodeId: 'common',
              fromPortId: 'victory',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleVictory,
            ),
            SceneEdge(
              id: 'common_defeat',
              fromNodeId: 'common',
              fromPortId: 'defeat',
              toNodeId: 'unique',
              kind: SceneEdgeKind.battleDefeat,
            ),
            SceneEdge(
              id: 'unique_victory',
              fromNodeId: 'unique',
              fromPortId: 'victory',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleVictory,
            ),
            SceneEdge(
              id: 'unique_defeat',
              fromNodeId: 'unique',
              fromPortId: 'defeat',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleDefeat,
            ),
          ],
        ),
      );
      final project = _project().copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'common',
            name: 'Rencontre libre',
            encounterKind: EncounterKind.special,
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 5,
                maxLevel: 5,
              ),
            ],
          ),
          ProjectEncounterTable(
            id: 'unique',
            name: 'Rencontre unique',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 12,
                maxLevel: 12,
              ),
            ],
          ),
        ],
        scenes: [scene],
      );
      final battles = <String?>[];
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'branch_event',
          sceneId: 'branch_scene',
          executionId: 'branch_run',
          gameState: state,
        ),
        project: project,
        mapsById: const {},
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (intent) {
            battles.add(intent.battleTemplateId);
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      expect(battles, ['common']);
    });
    test('rebases buffered consequences onto host battle write-back', () async {
      const requestGameState = GameState(
        saveId: 'save_scene_runtime',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 12,
            ),
          ],
        ),
      );
      var runtimeGameState = requestGameState;
      var battleCalls = 0;
      final hostedBattleOutcomes = <NarrativeOutcomeRef>[];

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        hostedBattleOutcomes: hostedBattleOutcomes,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (intent) {
            battleCalls++;
            expect(intent.trainerId, 'trainer_scene_runtime');
            runtimeGameState = runtimeGameState.copyWith(
              party: PlayerParty(
                members: <PlayerPokemon>[
                  runtimeGameState.party.members.single.copyWith(currentHp: 3),
                ],
              ),
              metadata: const <String, String>{
                'battleWriteBack': 'committed',
              },
            );
            hostedBattleOutcomes.add(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'trainer:trainer_scene_runtime',
                outcomeId: 'victory',
              ),
            );
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : null,
      );
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(battleCalls, 1);
      expect(completed.updatedGameState.party.members.single.currentHp, 3);
      expect(
        completed.updatedGameState.metadata['battleWriteBack'],
        'committed',
      );
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_scene_runtime_completed'),
      );
      expect(
        completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
        containsPair('fact_scene_runtime_completed', true),
      );
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.battle,
            producerId: 'trainer:trainer_scene_runtime',
            outcomeId: 'victory',
          ),
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_battle_then_fact',
            outcomeId: 'scene.completed',
          ),
        ],
      );
    });

    test('fails closed on an initial GameState conflict before host callbacks',
        () async {
      const requestGameState = GameState(saveId: 'save_scene_runtime');
      final runtimeGameState = requestGameState.copyWith(
        metadata: const <String, String>{'newerRuntimeState': 'true'},
      );
      var hostCallbackCalls = 0;
      String unexpectedCallback(SceneRuntimePlanIntent _) {
        hostCallbackCalls++;
        return 'victory';
      }

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: unexpectedCallback,
          showDialogue: unexpectedCallback,
          startBattle: unexpectedCallback,
          playCinematic: unexpectedCallback,
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      final failed = result as NarrativeSceneExecutionFailed;
      expect(failed.failure, isA<StateError>());
      expect(failed.failure.toString(), contains('initial GameState conflict'));
      expect(hostCallbackCalls, 0);
    });

    test('stops on the first rejected Action node before later callbacks',
        () async {
      const state = GameState(saveId: 'save_rejected_action');
      var battleCalls = 0;
      final project = _project().copyWith(
        scenes: [..._project().scenes, _rejectedActionScene()],
      );

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_rejected_action',
          sceneId: 'scene_rejected_action',
          executionId: 'execution_rejected_action',
          gameState: state,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (_) {
            battleCalls++;
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(
        (result as NarrativeSceneExecutionFailed).failure.toString(),
        contains('potion'),
      );
      expect(battleCalls, 0);
      expect(state.trainerProfile.money, 0);
      expect(state.bag.entries, isEmpty);
    });

    test('returns Finish Game only with its committed terminal state',
        () async {
      const state = GameState(saveId: 'save_finish_scene');
      final project = _project().copyWith(
        scenes: [..._project().scenes, _finishScene()],
      );

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_finish',
          sceneId: 'scene_finish',
          executionId: 'execution_finish',
          gameState: state,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (_) => throw StateError('Unexpected battle.'),
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(completed.gameCompletion?.endingId, 'ending.selbrume');
      expect(
        completed
            .updatedGameState.metadata[sceneGameCompletionEndingMetadataKey],
        'ending.selbrume',
      );
    });

    test('derives rail grant receipts from scene execution context', () async {
      const initial = GameState(saveId: 'save_rail_rewards');
      final project = _project().copyWith(
        scenes: <SceneAsset>[..._project().scenes, _railRewardScene()],
      );
      final callbacks = SceneRuntimeHostCallbacks(
        evaluateCondition: (_) => throw StateError('Unexpected condition.'),
        showDialogue: (_) => throw StateError('Unexpected dialogue.'),
        startBattle: (_) => throw StateError('Unexpected battle.'),
        playCinematic: (_) => throw StateError('Unexpected cinematic.'),
      );

      final first = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_rail_rewards',
          sceneId: 'scene_rail_rewards',
          executionId: 'execution_rail_rewards_1',
          gameState: initial,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => initial,
        callbacks: callbacks,
      ) as NarrativeSceneExecutionCompleted;
      final replay = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event_rail_rewards',
          sceneId: 'scene_rail_rewards',
          executionId: 'execution_rail_rewards_1',
          gameState: first.updatedGameState,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => first.updatedGameState,
        callbacks: callbacks,
      ) as NarrativeSceneExecutionCompleted;

      expect(
        first.updatedGameState.railJourneyProgress.semanticCurrencyBalances,
        <String, int>{'line_tokens': 3},
      );
      expect(first.updatedGameState.railJourneyProgress.earnedStampIds,
          <String>{'hanazuki_stamp'});
      expect(
        first.updatedGameState.railJourneyProgress.appliedProgressionOperations
            .keys,
        <String>{
          'scene:scene_rail_rewards:execution_rail_rewards_1:grant_currency',
          'scene:scene_rail_rewards:execution_rail_rewards_1:grant_stamp',
        },
      );
      expect(replay.updatedGameState, first.updatedGameState);
    });
  });
}

MapData _instanceWarpMap(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 3, height: 3),
  layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
  entities: const [
    MapEntity(
      id: 'owner',
      name: 'Owner',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
      blocksMovement: false,
    ),
  ],
  warps: [
    MapWarp(
      id: 'arrival',
      pos: const GridPos(x: 0, y: 0),
      targetMapId: id,
      targetPos: const GridPos(x: 0, y: 0),
      triggerMode: MapWarpTriggerMode.sceneOnly,
    ),
  ],
);

SceneAsset _instanceWarpScene(String mode) {
  final setter = SceneNode(
    id: 'set',
    kind: SceneNodeKind.action,
    payload: SceneActionPayload(
      consequence: SceneConsequence.setMapEventInstanceBoolean(
        mapId: 'source',
        eventId: 'owner',
        key: 'A',
        value: true,
      ),
    ),
  );
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (mode != 'new-write') setter,
    SceneNode(
      id: 'warp',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload(
        interactiveCommand: mode == 'external'
            ? SceneInteractiveCommand.fromJson({
                'kind': 'actorRoute',
                'target': {'kind': 'player', 'mapId': 'source'},
                'steps': [
                  {'kind': 'wait', 'durationMs': 1},
                ],
                'skippable': false,
              })
            : SceneInteractiveCommand.warp(
                destinationMapId: mode == 'same' ? 'source' : 'target',
                warpId: 'arrival',
                transition: SceneWarpTransition.none,
              ),
      ),
    ),
    if (mode == 'roundtrip')
      SceneNode(
        id: 'return',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          interactiveCommand: SceneInteractiveCommand.warp(
            destinationMapId: 'source',
            warpId: 'arrival',
            transition: SceneWarpTransition.none,
          ),
        ),
      ),
    if (mode == 'new-write') setter,
    SceneNode(
      id: 'reward',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload(
        consequence: SceneConsequence.giveMoney(amount: 100),
      ),
    ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'scoped-warp',
    name: 'Scoped Warp',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var i = 0; i < nodes.length - 1; i++)
          SceneEdge(
            id: 'edge-$i',
            fromNodeId: nodes[i].id,
            fromPortId: 'completed',
            toNodeId: nodes[i + 1].id,
            kind: i == 0
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.actionCompleted,
          ),
        SceneEdge(
          id: 'warp-blocked',
          fromNodeId: 'warp',
          fromPortId: 'blocked',
          toNodeId: 'reward',
          kind: SceneEdgeKind.actionCompleted,
        ),
        if (mode == 'roundtrip')
          SceneEdge(
            id: 'return-blocked',
            fromNodeId: 'return',
            fromPortId: 'blocked',
            toNodeId: 'reward',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}

SceneAsset _hostPickupScene() {
  final json = _inventoryScene(giving: true, withDialogue: true).toJson();
  final graph = json['graph'] as Map<String, dynamic>;
  final nodes = graph['nodes'] as List;
  nodes.add({
    'id': 'after_grant',
    'kind': 'yarnDialogue',
    'payload': {
      'kind': 'yarnDialogue',
      'dialogueId': 'inventory_dialogue',
      'yarnNodeName': 'Start',
    },
  });
  final edges = graph['edges'] as List;
  for (final edge in edges.cast<Map<String, dynamic>>()) {
    switch (edge['id']) {
      case 'start-change':
        edge['toNodeId'] = 'dialogue';
      case 'dialogue-condition':
        edge['toNodeId'] = 'change';
      case 'change-condition':
        edge['toNodeId'] = 'after_grant';
    }
  }
  edges.add({
    'id': 'after-grant-condition',
    'fromNodeId': 'after_grant',
    'fromPortId': 'completed',
    'toNodeId': 'condition',
    'kind': 'default',
  });
  return SceneAsset.fromJson(json);
}

SceneAsset _factScene({
  required NarrativeValue value,
  bool withDialogue = false,
  bool rejectAfterCondition = false,
  SceneConditionSource? conditionSource,
}) {
  final json = _inventoryScene(
    giving: true,
    withDialogue: withDialogue,
    rejectAfterCondition: rejectAfterCondition,
  ).toJson();
  json['id'] = 'fact_scene';
  json['name'] = 'Buffered fact condition';
  final nodes = (json['graph'] as Map<String, dynamic>)['nodes'] as List;
  for (final node in nodes.cast<Map<String, dynamic>>()) {
    if (node['id'] == 'change') {
      (node['payload'] as Map<String, dynamic>)['consequence'] =
          SceneConsequence.setFactValue(
        factId: 'page_state',
        value: value,
      ).toJson();
    }
    if (node['id'] == 'condition') {
      (node['payload'] as Map<String, dynamic>)['conditionSource'] =
          (conditionSource ??
                  SceneConditionSource.factValue(
                    factId: 'page_state',
                    operator: NarrativeFactOperator.equals,
                    expectedValue: value,
                  ))
              .toJson();
    }
  }
  return SceneAsset.fromJson(json);
}

SceneAsset _inventoryScene(
        {required bool giving,
        bool withDialogue = false,
        bool rejectAfterCondition = false}) =>
    SceneAsset.fromJson({
      'id': 'inventory_scene',
      'name': 'Buffered inventory condition',
      'declaredOutcomes': [
        {'id': 'present', 'label': 'Present'},
        {'id': 'absent', 'label': 'Absent'},
      ],
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {
            'id': 'change',
            'kind': 'action',
            'payload': {
              'kind': 'action',
              'parameters': {},
              'consequence': {
                'kind': giving ? 'giveItem' : 'takeItem',
                'itemId': 'item_potion',
                'quantity': 1
              }
            }
          },
          if (withDialogue)
            {
              'id': 'dialogue',
              'kind': 'yarnDialogue',
              'payload': {
                'kind': 'yarnDialogue',
                'dialogueId': 'inventory_dialogue',
                'yarnNodeName': 'Start'
              }
            },
          if (rejectAfterCondition)
            {
              'id': 'reject',
              'kind': 'action',
              'payload': {
                'kind': 'action',
                'parameters': {},
                'consequence': {
                  'kind': 'takeItem',
                  'itemId': 'item_potion',
                  'quantity': 2
                }
              }
            },
          {
            'id': 'condition',
            'kind': 'condition',
            'payload': {
              'kind': 'condition',
              'conditionSource': {
                'sourceKind': 'inventoryItem',
                'sourceId': 'item_potion',
                'operator': 'isTrue',
                'value': withDialogue ? '3' : '1',
              }
            }
          },
          for (final outcome in ['present', 'absent'])
            {
              'id': outcome,
              'kind': 'end',
              'payload': {'kind': 'end', 'sceneOutcomeId': outcome}
            },
        ],
        'edges': [
          {
            'id': 'start-change',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'change',
            'kind': 'default'
          },
          {
            'id': 'change-condition',
            'fromNodeId': 'change',
            'fromPortId': 'completed',
            'toNodeId': withDialogue ? 'dialogue' : 'condition',
            'kind': 'default'
          },
          {
            'id': 'condition-true',
            'fromNodeId': 'condition',
            'fromPortId': 'true',
            'toNodeId': rejectAfterCondition ? 'reject' : 'present',
            'kind': 'conditionTrue'
          },
          if (withDialogue)
            {
              'id': 'dialogue-condition',
              'fromNodeId': 'dialogue',
              'fromPortId': 'completed',
              'toNodeId': 'condition',
              'kind': 'default'
            },
          if (rejectAfterCondition)
            {
              'id': 'reject-present',
              'fromNodeId': 'reject',
              'fromPortId': 'completed',
              'toNodeId': 'present',
              'kind': 'default'
            },
          {
            'id': 'condition-false',
            'fromNodeId': 'condition',
            'fromPortId': 'false',
            'toNodeId': 'absent',
            'kind': 'conditionFalse'
          },
        ],
      },
    });

SceneAsset _railRewardScene() {
  return SceneAsset(
    id: 'scene_rail_rewards',
    name: 'Rail rewards',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'grant_currency',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.grantRailCurrency(
              semanticCurrencyId: 'line_tokens',
              amount: 3,
            ),
          ),
        ),
        SceneNode(
          id: 'grant_stamp',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.grantRailStamp(stampId: 'hanazuki_stamp'),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_currency',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'grant_currency',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'currency_stamp',
          fromNodeId: 'grant_currency',
          fromPortId: 'completed',
          toNodeId: 'grant_stamp',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'stamp_end',
          fromNodeId: 'grant_stamp',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _finishScene() {
  return SceneAsset(
    id: 'scene_finish',
    name: 'Finish',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'finish',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.finishGame(
              endingId: 'ending.selbrume',
              outcome: SceneGameCompletionOutcome.victory,
              result: SceneFinishGameResult(
                title: SceneLocalizedText(fallback: 'Victoire'),
                summary: SceneLocalizedText(
                  fallback: 'Selbrume est sauvée.',
                ),
              ),
              postGamePolicy: ScenePostGamePolicy.returnToTitle,
            ),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_finish',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'finish',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'finish_end',
          fromNodeId: 'finish',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _rejectedActionScene() {
  return SceneAsset(
    id: 'scene_rejected_action',
    name: 'Rejected Action',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'money',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.giveMoney(amount: 100),
          ),
        ),
        SceneNode(
          id: 'take_missing',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.takeItem(itemId: 'potion', quantity: 1),
          ),
        ),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_money',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'money',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'money_take',
          fromNodeId: 'money',
          fromPortId: 'completed',
          toNodeId: 'take_missing',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'take_battle',
          fromNodeId: 'take_missing',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_end',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Narrative Scene Runtime Execution Test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: 'trainer_scene_runtime',
        name: 'Runtime Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_scene_runtime_completed',
        label: 'Runtime scene completed',
      ),
    ],
    scenes: <SceneAsset>[_battleThenFactScene()],
  );
}

SceneAsset _uniqueWildScene([String id = 'unique_scene']) => SceneAsset(
      id: id,
      name: 'Rencontre unique',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'battle',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'wild',
              battleTemplateId: 'unique',
              declaredOutcomes: const [
                'victory',
                'captured',
                'defeat',
                'runaway',
              ],
            ),
          ),
          for (final outcome in const [
            'victory',
            'captured',
            'defeat',
            'runaway',
          ])
            SceneNode(id: 'end_$outcome', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_battle',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'battle',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final outcome in const [
            'victory',
            'captured',
            'defeat',
            'runaway',
          ])
            SceneEdge(
              id: 'battle_$outcome',
              fromNodeId: 'battle',
              fromPortId: outcome,
              toNodeId: 'end_$outcome',
              kind: switch (outcome) {
                'victory' => SceneEdgeKind.battleVictory,
                'defeat' => SceneEdgeKind.battleDefeat,
                _ => SceneEdgeKind.branchOutcome,
              },
            ),
        ],
      ),
    );

SceneAsset _battleThenFactScene() {
  return SceneAsset(
    id: 'scene_battle_then_fact',
    name: 'Battle then Fact',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: 'scene.completed', label: 'Scene completed'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_scene_runtime_completed',
              value: true,
            ),
          ),
        ),
        SceneNode(
          id: 'victory_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
        SceneNode(
          id: 'defeat_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory_to_fact',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'fact_to_victory_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_defeat_to_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

final class _CountingPresentationMutations extends GameStateMutations {
  int moneyWrites = 0;

  @override
  GameState addMoney(GameState state, int amount) {
    moneyWrites++;
    return super.addMoney(state, amount);
  }
}

SceneAsset _presentationProjectionScene() {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var i = 0; i < 40; i++)
      SceneNode(
        id: 'fact_$i',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          consequence: SceneConsequence.setFact(factId: 'fact_$i', value: true),
        ),
      ),
    SceneNode(
      id: 'money_1',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload(
        consequence: SceneConsequence.giveMoney(amount: 1),
      ),
    ),
    SceneNode(
      id: 'observe_1',
      kind: SceneNodeKind.yarnDialogue,
      payload: SceneYarnDialoguePayload(
        dialogueId: 'observe',
        yarnNodeName: 'Start',
      ),
    ),
    SceneNode(
      id: 'change_fact',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload(
        consequence: SceneConsequence.setFact(factId: 'fact_0', value: false),
      ),
    ),
    SceneNode(
      id: 'money_2',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload(
        consequence: SceneConsequence.giveMoney(amount: 2),
      ),
    ),
    SceneNode(
      id: 'observe_2',
      kind: SceneNodeKind.yarnDialogue,
      payload: SceneYarnDialoguePayload(
        dialogueId: 'observe',
        yarnNodeName: 'Start',
      ),
    ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'presentation',
    name: 'Presentation',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var i = 0; i < nodes.length - 1; i++)
          SceneEdge(
            id: 'next_$i',
            fromNodeId: nodes[i].id,
            fromPortId: 'completed',
            toNodeId: nodes[i + 1].id,
            kind: SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
}

SceneAsset _presentationCheckpointScene(
  List<SceneNode> body, {
  Map<String, List<String>> ports = const {},
}) {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    ...body,
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'checkpoint',
    name: 'Checkpoint',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var i = 0; i < nodes.length - 1; i++)
          for (final port in ports[nodes[i].id] ?? ['completed'])
            SceneEdge(
              id: 'next_${i}_$port',
              fromNodeId: nodes[i].id,
              fromPortId: port,
              toNodeId: nodes[i + 1].id,
              kind: SceneEdgeKind.defaultFlow,
            ),
      ],
    ),
  );
}
