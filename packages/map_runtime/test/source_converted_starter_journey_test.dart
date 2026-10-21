import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        installConvertedQaHeadlessAudio,
        mountConvertedQaGame,
        waitConvertedQaIdle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installConvertedQaHeadlessAudio);
  final root = Platform.environment['AVELUNE_STARTER_PROJECT'];
  for (final scenario in [
    (4, 'bulbasaur', 1, 'yes'),
    (5, 'squirtle', 3, 'yes'),
    (6, 'charmander', 2, 'yes'),
    (4, 'bulbasaur', 1, 'no'),
    (4, 'bulbasaur', 1, 'cancel'),
  ]) {
    testWidgets(
      'converted starter ${scenario.$1} ${scenario.$4} commits native gift and cold save',
      (tester) async {
        await tester.runAsync(() async {
          final projectFile = path.join(root!, 'project.json');
          final manifest = await loadProjectManifestFromFile(projectFile);
          final mapEntry = manifest.maps.single;
          final map = MapData.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(
                await File(path.join(root, mapEntry.relativePath))
                    .readAsString(),
              ) as Map,
            ),
          );
          final offer = manifest.scenes.singleWhere(
            (scene) =>
                scene.metadata['sourcePageIndex'] == '1' &&
                scene.graph.nodes.any(
                  (node) =>
                      node.payload is SceneActionPayload &&
                      (node.payload as SceneActionPayload).interactiveCommand
                          is SceneReceivePokemonFromCatalogInteractiveCommand &&
                      ((node.payload as SceneActionPayload).interactiveCommand
                                  as SceneReceivePokemonFromCatalogInteractiveCommand)
                              .speciesId ==
                          scenario.$2,
                ),
          );
          final rivalRoute = offer.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>()
              .map((action) => action.interactiveCommand)
              .whereType<SceneActorRouteInteractiveCommand>()
              .singleWhere(
                (route) => route.steps.any(
                  (step) => step.kind == SceneActorRouteStepKind.move,
                ),
              );

          final ball = map.entities.singleWhere(
            (entity) =>
                entity.properties['sourceEventIdentity'] ==
                offer.metadata['sourceEventIdentity'],
          );
          NarrativeFactDefinition definition(String suffix) => manifest.facts
              .singleWhere((fact) => fact.description.endsWith(suffix));
          final offerFlag = definition(':switch:75');
          final rivalName = definition(':variable:28');
          final temporary = await Directory.systemTemp.createTemp(
            'converted-starter-save-',
          );
          addTearDown(() => temporary.delete(recursive: true));
          final saves = ConvertedQaDiskSave(
            path.join(temporary.path, 'save.json'),
          );
          final before = GameState(
            saveId: 'starter-${scenario.$1}-${scenario.$4}',
            currentMapId: mapEntry.id,
            playerPosition: GridPos(x: ball.pos.x, y: ball.pos.y + 1),
            playerFacing: EntityFacing.north,
            trainerProfile: const TrainerProfile(name: 'Leaf'),
            narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
              valuesByFactId: {
                offerFlag.id: NarrativeValue.boolean(true),
                rivalName.id: NarrativeValue.string('Blue'),
              },
            ),
          );
          final game = await mountConvertedQaGame(
            tester,
            projectFile,
            saves,
            before,
          );
          var firstDisposed = false;
          final controller = PlayerServiceRuntimeController.contextual(
            currentGameState: () => game.playerServiceGameStateSnapshot,
            commitAndSave: (_) async =>
                fail('Gift presentation must not commit separately.'),
            setInputLocked: (_) {},
            loadRecoveryCaps: (_) async =>
                const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
            projectRootDirectory: root,
            pokemonConfig: manifest.pokemon,
          );
          game.setPlayerServiceRuntimeController(controller);
          final services = <PokemonGiftInteractionStage>[];
          final subscription = controller.worldServiceSnapshots.listen((
            snapshot,
          ) {
            if (snapshot?.request
                case final OpenPokemonGiftInteractionService request) {
              services.add(request.stage);
              final interaction = request.interaction;
              final response = switch (interaction) {
                SceneConfirmationInteractionRequest() =>
                  SceneInteractionResult.confirmed(
                    requestId: interaction.requestId,
                    revision: interaction.revision,
                    value: false,
                  ),
                SceneTextInteractionRequest() =>
                  SceneInteractionResult.textSubmitted(
                    requestId: interaction.requestId,
                    revision: interaction.revision,
                    value: 'Companion',
                  ),
                _ => SceneInteractionResult.acknowledged(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                ),
              };
              unawaited(
                controller.dispatchWorldService(
                  RuntimeWorldServiceCommand(
                    action: RuntimeWorldServiceAction.confirm,
                    snapshotRevision: snapshot!.revision,
                    interactionResult: response,
                  ),
                ),
              );
            }
          });
          void press(RuntimeInputControl control) {
            expect(
              game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
              isTrue,
            );
            game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
          }

          NarrativeValue value(PlayableMapGame current, String suffix) {
            final fact = definition(suffix);
            return current.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
                  fact.id,
                ) ??
                fact.initialValue;
          }

          try {
            expect(game.gameStateSnapshot.party.members, isEmpty);
            expect(
              game.overworldInteractionSnapshot.primaryAction?.request.targetId,
              ball.id,
              reason: 'Inactive source actors must not steal the interaction.',
            );
            press(RuntimeInputControl.primary);
            var choice = false, sawDialogue = false;
            for (var tick = 0; tick < 6000; tick++) {
              game.update(.025);
              await game.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
              final dialogue = game.dialoguePresentationListenable.value;
              if (dialogue != null) {
                sawDialogue = true;
                if (dialogue.mode == DialoguePresentationMode.choices) {
                  if (!choice) {
                    choice = true;
                    if (scenario.$4 == 'no') press(RuntimeInputControl.down);
                    press(
                      scenario.$4 == 'cancel'
                          ? RuntimeInputControl.secondary
                          : RuntimeInputControl.primary,
                    );
                  }
                } else {
                  press(RuntimeInputControl.primary);
                }
              }
              if (choice &&
                  game.debugFlowPhaseName == 'overworld' &&
                  game.dialoguePresentationListenable.value == null &&
                  !game.debugIsNarrativeSpatialDispatchInFlight &&
                  !game.debugHasPendingDialogueLoad) {
                break;
              }
            }
            expect(
              sawDialogue,
              isTrue,
              reason:
                  'phase=${game.debugFlowPhaseName},input=${game.inputAuthoritySnapshot.context.name},seen=${game.gameStateSnapshot.progression.seenSpeciesIds},pending=${game.debugPendingSceneWaitCount}',
            );
            expect(choice, isTrue);
            await waitConvertedQaIdle(game);
            final granted = scenario.$4 == 'yes';
            final state = game.gameStateSnapshot;
            expect(state.progression.seenSpeciesIds, contains(scenario.$2));
            expect(state.party.members, hasLength(granted ? 1 : 0));
            expect(
              state.progression.caughtSpeciesIds.contains(scenario.$2),
              granted,
            );
            expect(
              value(game, ':variable:29').intValue,
              granted ? scenario.$3 : 0,
            );
            expect(value(game, ':switch:75').boolValue, !granted);
            expect(
              value(game, ':map:9:event:${scenario.$1}:self:A').boolValue,
              granted,
            );
            if (granted) {
              expect(services, isNotEmpty);
              expect(state.party.members.single.speciesId, scenario.$2);
              expect(state.party.members.single.level, 5);
              expect(
                state.party.members.single.provenance!.kind,
                PlayerPokemonOriginKind.gift,
              );
              final activeRivalX = switch (scenario.$1) {
                4 => 12,
                5 => 10,
                _ => 11,
              };
              final rivalClones = map.entities.where(
                (entity) =>
                    entity.properties['sourceEventAnchorY'] == '7' &&
                    const {
                      '10',
                      '11',
                      '12',
                    }.contains(entity.properties['sourceEventAnchorX']),
              );
              expect(rivalClones, hasLength(3));
              for (final clone in rivalClones) {
                final x = int.parse(clone.properties['sourceEventAnchorX']!);
                expect(
                  game.debugMapEntityPosition(clone.id),
                  x == activeRivalX ? GridPos(x: x, y: 7) : null,
                );
              }
              final poses = state
                  .mapInstanceWorldState
                  .instancesByMapId[mapEntry.id]!
                  .npcPoses;
              final expectedPoses = offer.graph.nodes
                  .map((node) => node.payload)
                  .whereType<SceneActionPayload>()
                  .map((action) => action.consequence)
                  .whereType<SceneSetNpcPoseConsequence>();
              expect(expectedPoses, hasLength(3));
              for (final expected in expectedPoses) {
                expect(
                  poses[expected.entityId]?.position,
                  GridPos(x: expected.x, y: expected.y),
                );
              }
            } else {
              expect(services, isEmpty);
            }
            expect(await game.saveGame(), isTrue);
            final saved = (await saves.load())!;
            game.onRemove();
            firstDisposed = true;
            await Future<void>.delayed(const Duration(milliseconds: 400));
            await tester.pumpWidget(const SizedBox.shrink());
            final restored = await mountConvertedQaGame(
              tester,
              projectFile,
              saves,
              saved,
              restoredSave: saveDataFromGameState(saved),
            );
            try {
              expect(restored.gameStateSnapshot.party, saved.party);
              expect(
                restored.gameStateSnapshot.progression.seenSpeciesIds,
                contains(scenario.$2),
              );
              expect(
                restored.gameStateSnapshot.appliedPokemonGrantOperationIds,
                saved.appliedPokemonGrantOperationIds,
              );
              if (granted) {
                expect(
                  restored
                      .gameStateSnapshot
                      .mapInstanceWorldState
                      .instancesByMapId[mapEntry.id]!
                      .npcPoses[rivalRoute.target.entityId]
                      ?.facing,
                  EntityFacing.north,
                  reason: 'The source rival ends facing north and keeps that facing after cold save restoration.',
                );
              }
              expect(
                value(restored, ':variable:29').intValue,
                granted ? scenario.$3 : 0,
              );
              expect(
                restored
                    .gameStateSnapshot
                    .mapInstanceWorldState
                    .instancesByMapId[mapEntry.id]!
                    .npcPoses,
                saved
                    .mapInstanceWorldState
                    .instancesByMapId[mapEntry.id]!
                    .npcPoses,
              );
            } finally {
              restored.onRemove();
              await Future<void>.delayed(const Duration(milliseconds: 400));
              await tester.pumpWidget(const SizedBox.shrink());
            }
          } finally {
            await subscription.cancel();
            controller.dispose();
            if (!firstDisposed) {
              game.onRemove();
            }
            await Future<void>.delayed(const Duration(milliseconds: 400));
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      },
      skip: root == null,
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
