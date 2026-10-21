import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  for (final v2 in [false, true]) {
    for (final absolute in [false, true]) {
      for (final outcome in ['published', 'blocked', 'abort']) {
        test(
          'ordered pose and route V2=$v2 absolute=$absolute outcome=$outcome',
          () async {
            final scope = MapInstanceRef(mapId: 'room', instanceId: 'visit');
            final initial = GameState(
              saveId: 'pose-order',
              currentMapId: 'room',
              storyFlags: const StoryFlags(activeFlags: {'hidden'}),
              mapInstanceWorldState: MapInstanceWorldState(
                instancesByMapId: {
                  'room': MapInstanceRuntimeState(
                    instanceId: 'visit',
                    npcPoses: {
                      'actor': MapInstanceNpcPose(
                        position: const GridPos(x: 4, y: 4),
                        facing: EntityFacing.south,
                      ),
                    },
                  ),
                },
              ),
            );
            var host = initial;
            final scene = _scene(absolute);
            final event = MapEventDefinition(
              id: 'event',
              title: 'Pose order',
              position: const EventPosition(layerId: 'base', x: 0, y: 0),
              pages: [
                MapEventPage(
                  pageNumber: 0,
                  sceneTarget: const MapEventSceneTarget(sceneId: 'pose-order'),
                ),
              ],
            );
            final map = MapData(
              id: 'room',
              name: 'Room',
              size: const GridSize(width: 16, height: 12),
              events: [event],
              entities: [
                for (final id in ['actor', 'other'])
                  MapEntity(
                    id: id,
                    kind: MapEntityKind.custom,
                    pos: GridPos(x: id == 'actor' ? 2 : 8, y: 2),
                    presentation: MapEntityPresentation(
                      variants: [
                        MapEntityPresentationVariant(
                          id: 'hidden',
                          condition: NarrativeEventConditionExpression.leaf(
                            NarrativeEventCondition.fact('hidden', true),
                          ),
                          blocksMovement: false,
                        ),
                        MapEntityPresentationVariant(
                          id: 'visible',
                          characterId: 'known',
                          condition: NarrativeEventConditionExpression.leaf(
                            NarrativeEventCondition.fact('hidden', false),
                          ),
                          blocksMovement: false,
                        ),
                      ],
                    ),
                  ),
              ],
            );
            final project = ProjectManifest(
              name: 'Pose order',
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
              facts: [
                NarrativeFactDefinition(id: 'hidden', label: 'Hidden'),
                NarrativeFactDefinition(id: 'kept', label: 'Kept'),
              ],
              scenes: [scene],
            );
            final writer = SceneConsequenceRuntimeWriter(
              project: project,
              mapsById: {'room': map},
              mapInstanceScopes: {'room': scope},
            );
            final callbacks = SceneRuntimeHostCallbacks(
              evaluateCondition: (_) =>
                  throw StateError('Unexpected condition'),
              showDialogue: (_) => throw StateError('Unexpected dialogue'),
              startBattle: (_) => throw StateError('Unexpected battle'),
              playCinematic: (_) => throw StateError('Unexpected cinematic'),
              executeInteractiveCommand: (intent) {
                expect(
                  intent.interactiveCommand,
                  isA<SceneActorRouteInteractiveCommand>(),
                );
                if (outcome == 'abort') {
                  throw StateError('Isolated host cancellation before publication');
                }
                if (outcome == 'blocked') return 'blocked';
                host = host.copyWith(
                  mapInstanceWorldState: host.mapInstanceWorldState.setNpcPoses(
                    scope,
                    {
                      ...host
                          .mapInstanceWorldState
                          .instancesByMapId['room']!
                          .npcPoses,
                      'actor': MapInstanceNpcPose(
                        position: absolute
                            ? const GridPos(x: 9, y: 3)
                            : const GridPos(x: 4, y: 4),
                        facing: EntityFacing.west,
                      ),
                    },
                  ),
                );
                return 'completed';
              },
            );
            GameState? resultState;
            if (v2) {
              final result = await executeNarrativeEventScene(
                request: NarrativeSceneExecutionRequest(
                  eventId: 'event',
                  sceneId: scene.id,
                  executionId: 'isolated-order',
                  gameState: initial,
                ),
                project: project,
                mapsById: {'room': map},
                currentGameState: () => host,
                callbacks: callbacks,
                consequenceWriter: writer,
              );
              if (outcome == 'abort') {
                expect(result, isA<NarrativeSceneExecutionFailed>());
              } else {
                expect(result, isA<NarrativeSceneExecutionCompleted>());
                resultState = (result as NarrativeSceneExecutionCompleted)
                    .updatedGameState;
              }
            } else {
              final result =
                  await SceneEventRuntimeHook(
                    callbacks: callbacks,
                    consequenceWriter: writer,
                  ).runForEventPage(
                    project: project,
                    map: map,
                    event: event,
                    page: event.pages.single,
                    gameState: initial,
                    currentGameState: () => host,
                    executionId: 'isolated-order',
                  );
              expect(
                result.status,
                outcome == 'abort'
                    ? SceneEventRuntimeHookStatus.failed
                    : SceneEventRuntimeHookStatus.completed,
                reason: result.message,
              );
              resultState = result.updatedGameState;
            }
            if (outcome == 'abort') {
              expect(resultState, isNull);
              expect(identical(host, initial), isTrue);
            } else {
              expect(resultState!.storyFlags.activeFlags, contains('kept'));
              final poses = resultState
                  .mapInstanceWorldState
                  .instancesByMapId['room']!
                  .npcPoses;
              expect(
                poses['actor']!.position,
                absolute
                    ? const GridPos(x: 9, y: 3)
                    : const GridPos(x: 4, y: 4),
              );
              expect(
                poses['actor']!.facing,
                outcome == 'published' ? EntityFacing.west : EntityFacing.east,
              );
              expect(poses['other']!.facing, EntityFacing.north);
              expect(
                GameState.fromJson(resultState.toJson()).mapInstanceWorldState,
                resultState.mapInstanceWorldState,
              );
            }
            expect(initial.storyFlags.activeFlags, isNot(contains('kept')));
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
      }
    }
  }
}

SceneAsset _scene(bool absolute) {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(
      id: 'pose',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.setNpcPose(
          mapId: 'room',
          entityId: 'actor',
          x: absolute ? 9 : null,
          y: absolute ? 3 : null,
          facing: EntityFacing.east,
        ),
      ),
    ),
    SceneNode(
      id: 'other',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.setNpcPose(
          mapId: 'room',
          entityId: 'other',
          facing: EntityFacing.north,
        ),
      ),
    ),
    SceneNode(
      id: 'fact',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.setFact(factId: 'kept', value: true),
      ),
    ),
    SceneNode(
      id: 'route',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.actorRoute(
          target: SceneActorTarget.entity(mapId: 'room', entityId: 'actor'),
          steps: [SceneActorRouteStep.face(direction: EntityFacing.west)],
        ),
      ),
    ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'pose-order',
    name: 'Pose order',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: index == 0
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.actionCompleted,
          ),
        SceneEdge(
          id: 'blocked',
          fromNodeId: 'route',
          fromPortId: 'blocked',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}
