import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const approaches = [
    (GridPos(x: 3, y: 4), EntityFacing.north, EntityFacing.south),
    (GridPos(x: 3, y: 2), EntityFacing.south, EntityFacing.north),
    (GridPos(x: 2, y: 3), EntityFacing.east, EntityFacing.west),
    (GridPos(x: 4, y: 3), EntityFacing.west, EntityFacing.east),
  ];
  for (final (position, playerFacing, actorFacing) in approaches) {
    testWidgets(
      'adjacent interaction faces NPC $actorFacing before Scene condition',
      (tester) async {
        await tester.runAsync(() async {
          EntityFacing? preparedActorFacing;
          EntityFacing? preparedPlayerFacing;
          late final PlayableMapGame game;
          game = PlayableMapGame(
            bundle: _bundle(position, EntityFacing.south),
            projectFilePath: '/tmp/npc-facing/project.json',
            beforeNarrativeAuthorityPreparation: (occurrence) async {
              if (occurrence.source.kind ==
                  NarrativeEventSourceKind.entityInteract) {
                preparedActorFacing = game.debugNpcVisualFacing('oak');
                preparedPlayerFacing = game.gameStateSnapshot.playerFacing;
              }
            },
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
          addTearDown(game.onRemove);
          game.onGameResize(Vector2(320, 240));
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: GameWidget(game: game),
            ),
          );
          await game.loaded;
          await tester.pump();
          await _until(
            game,
            () =>
                !game.debugIsMapActivationDispatchInFlight &&
                game.debugNpcVisualFacing('oak') != null,
          );
          expect(game.gameStateSnapshot.playerPosition, position);
          final turn = switch (playerFacing) {
            EntityFacing.north => RuntimeInputControl.up,
            EntityFacing.south => RuntimeInputControl.down,
            EntityFacing.east => RuntimeInputControl.right,
            EntityFacing.west => RuntimeInputControl.left,
          };
          game.handleRuntimeInputEvent(RuntimeInputEvent.press(turn));
          game.update(.3);
          game.handleRuntimeInputEvent(RuntimeInputEvent.release(turn));
          await _until(
            game,
            () => game.gameStateSnapshot.playerFacing == playerFacing,
          );
          expect(game.gameStateSnapshot.playerPosition, position);
          expect(game.gameStateSnapshot.playerFacing, playerFacing);
          expect(
            game.overworldInteractionSnapshot.primaryAction!.request.targetId,
            'oak',
          );
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _until(
            game,
            () => game
                .gameStateSnapshot
                .narrativeEventProgress
                .consumedNarrativeEventIds
                .contains('evt_019abcde-2000-7000-8000-000000000051'),
          );
          expect(preparedActorFacing, actorFacing);
          expect(preparedPlayerFacing, playerFacing);
          expect(game.debugNpcVisualFacing('oak'), actorFacing);
          for (final direction in EntityFacing.values) {
            expect(
              game.gameStateSnapshot.narrativeFactRuntimeState
                  .valueFor('branch-${direction.name}')
                  ?.boolValue,
              direction == playerFacing ? isTrue : isNot(isTrue),
            );
          }
          expect(game.gameStateSnapshot.playerPosition, position);
          expect(game.gameStateSnapshot.playerFacing, playerFacing);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      },
    );
  }
}

Future<void> _until(PlayableMapGame game, bool Function() condition) async {
  for (var i = 0; i < 400; i++) {
    if (condition()) return;
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('NPC interaction did not settle.');
}

RuntimeMapBundle _bundle(GridPos spawnPosition, EntityFacing playerFacing) =>
    RuntimeMapBundle(
      projectRootDirectory: '/tmp/npc-facing',
      tilesetAbsolutePathsById: const {'actors': '/tmp/npc-facing/actors.png'},
      map: MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: spawnPosition,
            blocksMovement: false,
            spawn: MapEntitySpawnData(
              role: EntitySpawnRole.playerStart,
              facing: playerFacing,
            ),
          ),
          const MapEntity(
            id: 'oak',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 3),
            blocksMovement: true,
            npc: MapEntityNpcData(
              displayName: 'Oak',
              characterId: 'oak-character',
              facing: EntityFacing.north,
            ),
          ),
        ],
      ),
      manifest: ProjectManifest(
        name: 'Adjacent NPC facing',
        maps: const [
          ProjectMapEntry(
            id: 'room',
            name: 'Room',
            relativePath: 'maps/room.json',
          ),
        ],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'actors',
            name: 'Actors',
            relativePath: 'actors.png',
          ),
        ],
        settings: const ProjectSettings(
          tileWidth: 16,
          tileHeight: 16,
          displayScale: 1,
        ),
        characters: [
          ProjectCharacterEntry(
            id: 'oak-character',
            name: 'Oak',
            tilesetId: 'actors',
          ),
        ],
        facts: [
          for (final direction in EntityFacing.values)
            NarrativeFactDefinition(
              id: 'branch-${direction.name}',
              label: direction.name,
            ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-2000-7000-8000-000000000051',
                name: 'Oak interaction',
                source: NarrativeEventSourceRef.entityInteract('room', 'oak'),
                conditions: [],
                sceneId: 'oak-facing',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        scenes: [
          SceneAsset(
            id: 'oak-facing',
            name: 'Oak facing',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                for (final direction in EntityFacing.values) ...[
                  SceneNode(
                    id: 'condition-${direction.name}',
                    kind: SceneNodeKind.condition,
                    payload: SceneConditionPayload(
                      conditionSource: SceneConditionSource.playerFacing(
                        direction: direction,
                      ),
                    ),
                  ),
                  SceneNode(
                    id: 'set-${direction.name}',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.consequence(
                      SceneConsequence.setFact(
                        factId: 'branch-${direction.name}',
                        value: true,
                      ),
                    ),
                  ),
                ],
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                _edge(
                  'begin',
                  'start',
                  'completed',
                  'condition-${EntityFacing.values.first.name}',
                ),
                for (final (i, direction) in EntityFacing.values.indexed) ...[
                  _edge(
                    'true-${direction.name}',
                    'condition-${direction.name}',
                    'true',
                    'set-${direction.name}',
                  ),
                  _edge(
                    'false-${direction.name}',
                    'condition-${direction.name}',
                    'false',
                    i + 1 == EntityFacing.values.length
                        ? 'end'
                        : 'condition-${EntityFacing.values[i + 1].name}',
                  ),
                  _edge(
                    'set-${direction.name}',
                    'set-${direction.name}',
                    'completed',
                    'end',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

SceneEdge _edge(String id, String from, String port, String to) => SceneEdge(
  id: id,
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: switch (port) {
    'true' => SceneEdgeKind.conditionTrue,
    'false' => SceneEdgeKind.conditionFalse,
    _ => SceneEdgeKind.defaultFlow,
  },
);
