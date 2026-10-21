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
  for (final phase in [0, 1, 2]) {
    testWidgets('native route resolves conditional actor phase $phase', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final game = PlayableMapGame(
          bundle: _bundle(),
          projectFilePath: '/tmp/conditional-actor/project.json',
          initialGameState: GameState(
            saveId: 'conditional-actor-$phase',
            currentMapId: 'room',
            playerPosition: const GridPos(x: 0, y: 0),
            narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
              valuesByFactId: {'phase': NarrativeValue.integer(phase)},
            ),
          ),
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
            expect(actors.single.character.id, phase == 0 ? 'first' : 'second');
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
          execution.then((_) => finished = true);
          for (var i = 0; i < 500 && !finished; i++) {
            game.update(.05);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          expect(finished, isTrue);
          final result = await execution;
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          final committed =
              (result as NarrativeSceneExecutionCompleted).updatedGameState;
          expect(
            committed.narrativeFactRuntimeState
                    .valueFor('route_completed')
                    ?.boolValue ??
                false,
            phase < 2,
          );
          if (phase < 2) {
            expect(actors.single.gridPos, const GridPos(x: 3, y: 2));
            expect(actors.single.facing, EntityFacing.east);
          } else {
            expect(
              committed
                  .mapInstanceWorldState
                  .instancesByMapId['room']
                  ?.npcPoses['actor'],
              isNull,
            );
          }
        } finally {
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
    });
  }
}

RuntimeMapBundle _bundle() => RuntimeMapBundle(
  projectRootDirectory: '/tmp/conditional-actor',
  tilesetAbsolutePathsById: const {
    'actors': '/tmp/conditional-actor/actors.png',
  },
  map: MapData(
    id: 'room',
    name: 'Room',
    size: const GridSize(width: 5, height: 5),
    entities: [
      MapEntity(
        id: 'actor',
        kind: MapEntityKind.custom,
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
      records: const [],
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
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.actorRoute(
                  target: SceneActorTarget.entity(
                    mapId: 'room',
                    entityId: 'actor',
                  ),
                  steps: [
                    SceneActorRouteStep.move(
                      direction: EntityFacing.east,
                      durationMs: 50,
                    ),
                  ],
                ),
              ),
            ),
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
              toNodeId: 'mark',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'move_blocked',
              fromNodeId: 'move',
              fromPortId: 'blocked',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
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
