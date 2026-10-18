import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

import 'scene_interactive_pokemon_gift_test.dart' show giftCatalog, giftCommand;

void main() {
  for (final v2 in [false, true]) {
    for (final dismissStage in <PokemonGiftInteractionStage?>[
      null,
      ...PokemonGiftInteractionStage.values,
    ]) {
      final dismiss = dismissStage != null;
      test(
        'V2=$v2 gift transaction dismiss=$dismissStage buffers gift and suffix',
        () async {
          const state = GameState(saveId: 'transaction', currentMapId: 'lab');
          final scene = SceneAsset(
            id: 'gift',
            name: 'Gift',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'money',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.consequence(
                    SceneConsequence.giveMoney(amount: 25),
                  ),
                ),
                SceneNode(
                  id: 'receive',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    giftCommand(dex: true),
                  ),
                ),
                SceneNode(
                  id: 'suffix',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.consequence(
                    SceneConsequence.giveMoney(amount: 50),
                  ),
                ),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'a',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'money',
                  kind: SceneEdgeKind.defaultFlow,
                ),
                SceneEdge(
                  id: 'b',
                  fromNodeId: 'money',
                  fromPortId: 'completed',
                  toNodeId: 'receive',
                  kind: SceneEdgeKind.actionCompleted,
                ),
                for (final port in ['party', 'pc', 'noCapacity'])
                  SceneEdge(
                    id: port,
                    fromNodeId: 'receive',
                    fromPortId: port,
                    toNodeId: 'suffix',
                    kind: SceneEdgeKind.actionCompleted,
                  ),
                SceneEdge(
                  id: 'c',
                  fromNodeId: 'suffix',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted,
                ),
              ],
            ),
          );
          final project = ProjectManifest(
            name: 'Gift',
            maps: [],
            tilesets: [],
            scenes: [scene],
          );
          final callbacks = SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) => 'completed',
            startBattle: (_) => 'victory',
            playCinematic: (_) => 'completed',
            presentPokemonGift: (request) async {
              expect(state.party.members, isEmpty);
              expect(
                request.projectedState.trainerProfile.money,
                state.trainerProfile.money + 25,
              );
              final interaction = request.interaction;
              return request.stage == dismissStage
                  ? SceneInteractionResult.cancelled(
                      requestId: interaction.requestId,
                      revision: interaction.revision,
                      reason: SceneInteractionCancellationReason.disposed,
                    )
                  : switch (interaction) {
                      SceneConfirmationInteractionRequest() =>
                        SceneInteractionResult.confirmed(
                          requestId: interaction.requestId,
                          revision: interaction.revision,
                          value: true,
                        ),
                      SceneTextInteractionRequest() =>
                        SceneInteractionResult.textSubmitted(
                          requestId: interaction.requestId,
                          revision: interaction.revision,
                          value: 'Pendule',
                        ),
                      _ => SceneInteractionResult.acknowledged(
                        requestId: interaction.requestId,
                        revision: interaction.revision,
                      ),
                    };
            },
          );
          final writer = SceneConsequenceRuntimeWriter(
            project: project,
            pokemonCatalog: giftCatalog(),
          );
          GameState? committed;
          if (v2) {
            final result = await executeNarrativeEventScene(
              request: NarrativeSceneExecutionRequest(
                eventId: 'event',
                sceneId: 'gift',
                executionId: 'run',
                gameState: state,
              ),
              project: project,
              mapsById: {},
              currentGameState: () => state,
              callbacks: callbacks,
              consequenceWriter: writer,
            );
            expect(
              result,
              dismiss
                  ? isA<NarrativeSceneExecutionFailed>()
                  : isA<NarrativeSceneExecutionCompleted>(),
            );
            if (result is NarrativeSceneExecutionCompleted) {
              committed = result.updatedGameState;
            }
          } else {
            const page = MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'gift'),
            );
            const event = MapEventDefinition(
              id: 'event',
              pages: [page],
              position: EventPosition(layerId: 'base', x: 0, y: 0),
            );
            final map = MapData(
              id: 'lab',
              name: 'Lab',
              size: GridSize(width: 1, height: 1),
              layers: [],
            );
            final result =
                await SceneEventRuntimeHook(
                  callbacks: callbacks,
                  consequenceWriter: writer,
                ).runForEventPage(
                  project: project,
                  map: map,
                  event: event,
                  page: page,
                  gameState: state,
                  executionId: 'run',
                );
            expect(result.success, !dismiss, reason: result.message);
            committed = result.updatedGameState;
          }
          if (dismiss) {
            expect(committed, isNull);
          } else {
            expect(committed!.party.members.single.speciesId, 'clockbird');
            expect(
              committed.trainerProfile.money,
              state.trainerProfile.money + 75,
            );
            expect(committed.appliedPokemonGrantOperationIds, {
              'scene:gift:run:receive',
            });
          }
        },
      );
    }
  }
}
