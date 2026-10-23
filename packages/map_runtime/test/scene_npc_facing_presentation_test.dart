import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (remount, followRoute, baseNpc, nativeCommit) in [
    (false, false, false, false),
    (true, false, false, false),
    (false, true, false, false),
    (false, false, true, false),
    (true, false, true, false),
    (false, false, true, true),
  ]) {
    const phase = 0;
    testWidgets(
      'logical facing reaches a visible actor remount=$remount followRoute=$followRoute baseNpc=$baseNpc nativeCommit=$nativeCommit',
      (tester) async {
        await tester.runAsync(() async {
          final repository = _PoseRepository();
          PlayableMapGame create({SaveData? save}) => PlayableMapGame(
            bundle: _bundle(
              remount: remount,
              followRoute: followRoute,
              baseNpc: baseNpc, nativeEvent: nativeCommit,
            ),
            saveRepository: repository,
            runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async => _bundle(
              remount: remount,
              followRoute: followRoute,
              baseNpc: baseNpc, nativeEvent: nativeCommit,
            ),
            projectFilePath: '/tmp/conditional-actor/project.json',
            saveData: save,
            initialMapActivationReason: save == null
                ? MapActivationReason.initialBoot
                : MapActivationReason.saveRestore,
            initialGameState: save == null
                ? GameState(
                    saveId: 'conditional-actor-$phase',
                    currentMapId: 'room',
                    mapInstanceWorldState: MapInstanceWorldState(
                      instancesByMapId: {
                        'room': MapInstanceRuntimeState(instanceId: 'visit'),
                      },
                    ),
                    playerPosition: nativeCommit ? const GridPos(x: 2, y: 3) : const GridPos(x: 0, y: 0),
              playerFacing: EntityFacing.north,
                    narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
                      valuesByFactId: {'phase': NarrativeValue.integer(phase)},
                    ),
                  )
                : null,
            runtimeTilesetImageLoader:
                (paths, {transparentColorByTilesetId = const {}}) async {
                  final recorder = ui.PictureRecorder();
                  ui.Canvas(recorder).drawRect(
                    const ui.Rect.fromLTWH(0, 0, 128, 128),
                    ui.Paint()..color = const ui.Color(0xFF4060FF),
                  );
                  final picture = recorder.endRecording();
                  final image = await picture.toImage(128, 128);
                  picture.dispose();
                  return {
                    'actors': RuntimeTilesetImage(
                      images: [image],
                      chunks: const [
                        RuntimeTilesetChunk(top: 0, height: 128, width: 128),
                      ],
                      width: 128,
                      height: 128,
                    ),
                  };
                },
          );
          final game = create();
          PlayableMapGame? restored;
          try {
            game.onGameResize(Vector2(320, 240));
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: GameWidget<PlayableMapGame>(game: game),
              ),
            );
            await game.toBeLoaded();
            await game.ready();
            game.pauseEngine();
            for (var i = 0; i < 30; i++) {
              game.update(.05);
              await game.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            final actors = game.world.children
                .whereType<OverworldActorComponent>()
                .where((actor) => actor.isGameplayPresent)
                .toList();
            expect(actors, hasLength(phase < 2 ? 1 : 0));
            if (phase < 2) {
              expect(
                actors.single.character.id,
                phase == 0 ? 'first' : 'second',
              );
            }
            if (nativeCommit) {
              expect(game.overworldInteractionSnapshot.primaryAction?.request.targetId, 'actor');
              game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
              for (var tick = 0; tick < 1000; tick++) {
                game.update(.01);
                await game.ready();
                await Future<void>.delayed(const Duration(milliseconds: 1));
                if (game.companionGameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds.contains('evt_019abcde-3000-7000-8000-000000000001') &&
                    !game.debugIsNarrativeSpatialDispatchInFlight) {
                  break;
                }
              }
              expect(game.companionGameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
                contains('evt_019abcde-3000-7000-8000-000000000001'));
              expect(game.companionGameStateSnapshot.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['actor']!.facing, EntityFacing.east);
              expect(game.debugNpcVisualFacing('actor'), EntityFacing.east);
              expect(await game.saveGame(), isTrue);
              final checkpoint = (await repository.load())!;
              final savedPose = checkpoint.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['actor'];
              expect(savedPose?.facing, EntityFacing.east);
              expect(savedPose?.position, const GridPos(x: 2, y: 2));
              game.onRemove();
              await tester.pumpWidget(const SizedBox.shrink());
              await Future<void>.delayed(const Duration(milliseconds: 100));
              restored = create(save: saveDataFromGameState(checkpoint));
              restored.onGameResize(Vector2(320, 240));
              await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
                child: GameWidget<PlayableMapGame>(game: restored)));
              await restored.toBeLoaded();
              await restored.ready();
              restored.pauseEngine();
              expect(restored.debugNpcVisualFacing('actor'), EntityFacing.east);
              expect(restored.debugNpcGridPosition('actor'), savedPose!.position);
              return;
            }
            final execution = game.debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'conditional-actor-test',
                sceneId: 'route',
                executionId: 'phase-$phase',
                gameState: game.gameStateSnapshot,
              ),
            );
            var finished = false;
            var facingObserved = false;
            var identicalRefreshObserved = false;
            execution.then((_) => finished = true);
            for (var i = 0; i < 1000 && !finished; i++) {
              game.update(.01);
              await game.ready();
              final current = game.world.children
                  .whereType<OverworldActorComponent>()
                  .where((actor) => actor.isGameplayPresent)
                  .toList();
              if (current.length == 1 &&
                  current.single.character.id ==
                      (remount ? 'second' : 'first') &&
                  current.single.facing == EntityFacing.east &&
                  current.single.gridPos == const GridPos(x: 2, y: 2)) {
                facingObserved = true;
                if (remount && !baseNpc && !identicalRefreshObserved) {
                  const clip = CharacterCustomAnimationClip(
                    definitionId: 'scene-wave', sourceAssetId: 'scene-wave',
                    frames: [CharacterAnimationFrame(
                      source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                      durationMs: 100)],
                  );
                  current.single.playCustomAnimation(clip);
                  expect(current.single.debugCustomAnimationDefinitionId, 'scene-wave');
                  expect(await game.debugExecuteSceneInteractiveCommand(
                    SceneInteractiveCommand.wait(durationMs: 0)), 'completed');
                  expect(current.single.debugCustomAnimationDefinitionId, 'scene-wave',
                    reason: 'An unchanged provisional pose must preserve custom playback.');
                  expect(current.single.facing, EntityFacing.east);
                  identicalRefreshObserved = true;
                }
              }
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(finished, isTrue);
            final result = await execution;
            expect(
              result,
              isA<NarrativeSceneExecutionCompleted>(),
              reason: result is NarrativeSceneExecutionFailed
                  ? '${result.failure}'
                  : null,
            );
            final committed =
                (result as NarrativeSceneExecutionCompleted).updatedGameState;
            expect(
              committed.narrativeFactRuntimeState
                  .valueFor('route_completed')
                  ?.boolValue,
              isTrue,
            );
            expect(
              facingObserved,
              isTrue,
              reason: 'The active sprite must observe the logical facing inside the scene.',
            );
            if (remount && !baseNpc) expect(identicalRefreshObserved, isTrue);
            final saved = committed
                .mapInstanceWorldState
                .instancesByMapId['room']!
                .npcPoses['actor']!;
            expect(saved.position, const GridPos(x: 2, y: 2));
            expect(
              saved.facing,
              followRoute ? EntityFacing.west : EntityFacing.east,
            );
            game.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            await Future<void>.delayed(const Duration(milliseconds: 100));
            restored = create(
              save: SaveData.fromJson(
                saveDataFromGameState(committed).toJson(),
              ),
            );
            restored.onGameResize(Vector2(320, 240));
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: GameWidget<PlayableMapGame>(game: restored),
              ),
            );
            await restored.toBeLoaded();
            await restored.ready();
            restored.pauseEngine();
            final coldActor = restored.world.children
                .whereType<OverworldActorComponent>()
                .where((actor) => actor.isGameplayPresent)
                .single;
            expect(coldActor.character.id, remount ? 'second' : 'first');
            expect(coldActor.gridPos, saved.position);
            expect(coldActor.facing, saved.facing);
            if (baseNpc) {
              await repository.save(committed);
              restored.onRemove();
              await tester.pumpWidget(const SizedBox.shrink());
              await Future<void>.delayed(const Duration(milliseconds: 100));
              restored = create();
              restored.onGameResize(Vector2(320, 240));
              await tester.pumpWidget(
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: GameWidget<PlayableMapGame>(game: restored),
                ),
              );
              await restored.toBeLoaded();
              await restored.ready();
              restored.pauseEngine();
              for (var tick = 0; tick < 30; tick++) {
                restored.update(.01);
                await restored.ready();
                await Future<void>.delayed(const Duration(milliseconds: 1));
              }
              expect(await restored.loadGame(), isTrue);
              await restored.ready();
              final loadedActor = restored.world.children
                  .whereType<OverworldActorComponent>()
                  .where((actor) => actor.isGameplayPresent)
                  .single;
              expect(loadedActor.gridPos, saved.position);
              expect(loadedActor.facing, saved.facing);
            }
          } finally {
            if (restored == null) game.onRemove();
            restored?.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        });
      },
    );
  }
}

RuntimeMapBundle _bundle({
  required bool remount,
  required bool followRoute,
  required bool baseNpc,
  bool nativeEvent = false,
}) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/conditional-actor',
  tilesetAbsolutePathsById: const {
    'actors': '/tmp/conditional-actor/actors.png',
  },
  characterAnimationAbsolutePathsByAssetId: const {
    'scene-wave': '/tmp/conditional-actor/actors.png',
  },
  map: MapData(
    id: 'room',
    name: 'Room',
    size: const GridSize(width: 5, height: 5),
    entities: [
      MapEntity(
        id: 'actor',
        kind: baseNpc ? MapEntityKind.npc : MapEntityKind.custom,
        npc: baseNpc
            ? const MapEntityNpcData(
                characterId: 'first',
                facing: EntityFacing.north,
              )
            : null,
        pos: const GridPos(x: 2, y: 2),
        blocksMovement: false,
        presentation: MapEntityPresentation(
          variants: [
            for (final (index, character) in <String?>[
              'first',
              'second',
              null,
            ].indexed)
              MapEntityPresentationVariant(
                id: 'phase_$index',
                condition: NarrativeEventConditionExpression.leaf(
                  NarrativeEventCondition.factValue(
                    'phase',
                    operator: NarrativeFactOperator.equals,
                    expectedValue: NarrativeValue.integer(index),
                  ),
                ),
                characterId: character,
                blocksMovement: character != null,
              ),
          ],
        ),
      ),
    ],
  ),
  manifest: ProjectManifest(
    name: 'Conditional actor route',
    maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'room.json'),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'actors',
        name: 'Actors',
        relativePath: 'actors.png',
      ),
    ],
    characters: const [
      ProjectCharacterEntry(id: 'first', name: 'First', tilesetId: 'actors'),
      ProjectCharacterEntry(id: 'second', name: 'Second', tilesetId: 'actors'),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'phase',
        label: 'Phase',
        initialValue: NarrativeValue.integer(0),
      ),
      NarrativeFactDefinition(id: 'route_completed', label: 'Route completed'),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [if (nativeEvent) NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(id: 'evt_019abcde-3000-7000-8000-000000000001', name: 'Pose interaction',
          source: NarrativeEventSourceRef.entityInteract('room', 'actor'),
          conditions: const [], sceneId: 'route', reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0, order: 0), enabled: true)],
      legacyClaims: const [],
    ),
    scenes: [
      SceneAsset(
        id: 'route',
        name: 'Conditional route',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'move',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                remount
                    ? SceneConsequence.setFactValue(
                        factId: 'phase',
                        value: NarrativeValue.integer(1),
                      )
                    : SceneConsequence.setFact(
                        factId: 'route_completed',
                        value: false,
                      ),
              ),
            ),
            SceneNode(
              id: 'face',
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
              id: 'hold',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.wait(durationMs: 100),
              ),
            ),
            if (followRoute) ...[
              SceneNode(
                id: 'later_face',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.actorRoute(
                    target: SceneActorTarget.entity(
                      mapId: 'room',
                      entityId: 'actor',
                    ),
                    steps: [
                      SceneActorRouteStep.face(
                        direction: EntityFacing.west,
                        durationMs: 10,
                      ),
                    ],
                  ),
                ),
              ),
              SceneNode(
                id: 'later_hold',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.wait(durationMs: 100),
                ),
              ),
            ],
            SceneNode(
              id: 'mark',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(
                  factId: 'route_completed',
                  value: true,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_move',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'move',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'move_mark',
              fromNodeId: 'move',
              fromPortId: 'completed',
              toNodeId: 'face',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'face_mark',
              fromNodeId: 'face',
              fromPortId: 'completed',
              toNodeId: 'hold',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'hold_mark',
              fromNodeId: 'hold',
              fromPortId: 'completed',
              toNodeId: followRoute ? 'later_face' : 'mark',
              kind: SceneEdgeKind.actionCompleted,
            ),
            if (followRoute) ...[
              SceneEdge(
                id: 'later_face_hold',
                fromNodeId: 'later_face',
                fromPortId: 'completed',
                toNodeId: 'later_hold',
                kind: SceneEdgeKind.actionCompleted,
              ),
              SceneEdge(
                id: 'later_hold_mark',
                fromNodeId: 'later_hold',
                fromPortId: 'completed',
                toNodeId: 'mark',
                kind: SceneEdgeKind.actionCompleted,
              ),
              SceneEdge(
                id: 'later_face_blocked',
                fromNodeId: 'later_face',
                fromPortId: 'blocked',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
            SceneEdge(
              id: 'mark_end',
              fromNodeId: 'mark',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      ),
    ],
  ),
);

final class _PoseRepository implements GameSaveRepository {
  GameState? state;
  @override
  Future<void> save(GameState value) async {
    state = GameState.fromJson(value.toJson());
  }

  @override
  Future<GameState?> load() async => state;
  @override
  Future<bool> exists() async => state != null;
  @override
  Future<void> delete() async {
    state = null;
  }
}
