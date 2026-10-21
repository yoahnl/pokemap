import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
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
  final root = Platform.environment['AVELUNE_ESCORT_PROJECT'];
  final output = Platform.environment['AVELUNE_ESCORT_RECEIPT'];
  final prepareLab = Platform.environment['AVELUNE_ESCORT_PREPARATION'] == '1';
  for (final variant in [(12, 18), (14, 19)]) {
    testWidgets(
      'converted source escort ${variant.$1} walks into the laboratory and saves',
      (tester) async {
        await tester.runAsync(() async {
          final projectFile = path.join(root!, 'project.json');
          final manifest = await loadProjectManifestFromFile(projectFile);
          final source = manifest.maps.singleWhere(
            (m) => m.name == 'Pallet Town',
          );
          final destination = manifest.maps.singleWhere(
            (m) => m.name == "Oak's Lab",
          );
          bool flag(PlayableMapGame game, int id) {
            final definition = manifest.facts.singleWhere(
              (f) =>
                  f.description ==
                  'Persistent source boolean: source:ev09-real-source-defects:switch:$id',
            );
            return game.gameStateSnapshot.narrativeFactRuntimeState
                    .valueFor(definition.id)
                    ?.boolValue ??
                definition.defaultValue;
          }

          final map = MapData.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(
                await File(path.join(root, source.relativePath)).readAsString(),
              ) as Map,
            ),
          );
          final sourceIdentity = variant.$1 == 12
              ? 's1:f477ee7e85cc9d3aaf2a183f8af7d8db3872316f412353dd5344b8ffa494966a'
              : 's1:74032ca2c7e798454c89d225511fdb3121f45d769137bbab77e6143c72acf9a1';
          final scene = manifest.scenes.singleWhere(
            (s) =>
                s.metadata['sourceEventIdentity'] == sourceIdentity &&
                s.metadata['sourcePageIndex'] == '0',
          );
          final movieId = scene.graph.nodes
              .map((n) => n.payload)
              .whereType<SceneCinematicPayload>()
              .single
              .cinematicId;
          final movie = manifest.cinematics.singleWhere((c) => c.id == movieId);
          expect(
            movie.timeline.steps.where(
              (s) => s.parallelGroupId == 'source_escort_pair',
            ),
            hasLength(2),
          );
          final guideId = movie.stageContext!.actorBindings
              .singleWhere((b) => b.actorId == 'guide')
              .mapEntityId!;
          final guideCharacter = map.entities
              .singleWhere((e) => e.id == guideId)
              .npc!
              .characterId!;
          final saveRoot = await Directory.systemTemp.createTemp(
            'converted-escort-save-',
          );
          addTearDown(() => saveRoot.delete(recursive: true));
          final saves = ConvertedQaDiskSave(
            path.join(saveRoot.path, 'save.json'),
          );
          final initial = GameState(
            saveId: 'escort-${variant.$1}',
            currentMapId: source.id,
            playerPosition: GridPos(x: variant.$2, y: 2),
            playerFacing: EntityFacing.north,
            trainerProfile: const TrainerProfile(
              name: 'Escort qualification only',
            ),
          );
          final game = await mountConvertedQaGame(
            tester,
            projectFile,
            saves,
            initial,
          );
          final lines = <String>{};
          final labLines = <String>[];
          var sawMovie = false,
              sawBothActorsMoving = false,
              sawDoorEntry = false;
          Vector2? previousPlayer, previousGuide;
          try {
            expect(game.gameStateSnapshot.party.members, isEmpty);
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.up),
            );
            for (var tick = 0; tick < 3000; tick++) {
              game.update(.025);
              await game.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
              if (game.debugIsCinematicPlaying) {
                sawMovie = true;
                game.handleRuntimeInputEvent(
                  const RuntimeInputEvent.release(RuntimeInputControl.up),
                );
                final actor = game.world.children
                    .whereType<OverworldActorComponent>()
                    .where((a) => a.character.id == guideCharacter)
                    .firstOrNull;
                final player = game.world.children
                    .whereType<PlayerComponent>()
                    .single;
                if (actor != null) {
                  final p = player.position.clone(), g = actor.position.clone();
                  if (previousPlayer != null &&
                      previousGuide != null &&
                      p.distanceTo(previousPlayer) > .001 &&
                      g.distanceTo(previousGuide) > .001) {
                    sawBothActorsMoving = true;
                  }
                  previousPlayer = p;
                  previousGuide = g;
                }
                if (game.debugCinematicDialogueLine case final line?) {
                  lines.add(line);
                  game.handleRuntimeInputEvent(
                    const RuntimeInputEvent.press(RuntimeInputControl.primary),
                  );
                  game.handleRuntimeInputEvent(
                    const RuntimeInputEvent.release(
                      RuntimeInputControl.primary,
                    ),
                  );
                }
              } else if (sawMovie &&
                  game.gameStateSnapshot.currentMapId == source.id) {
                sawDoorEntry = true;
              }
              final dialogue = game.dialoguePresentationListenable.value;
              if (dialogue != null &&
                  game.gameStateSnapshot.currentMapId == destination.id) {
                if (labLines.isEmpty || labLines.last != dialogue.fullText) {
                  labLines.add(dialogue.fullText);
                }
                game.handleRuntimeInputEvent(
                  const RuntimeInputEvent.press(RuntimeInputControl.primary),
                );
                game.handleRuntimeInputEvent(
                  const RuntimeInputEvent.release(RuntimeInputControl.primary),
                );
              }
              if (prepareLab && tick % 500 == 0) {
                stdout.writeln(
                  jsonEncode({
                    'kind': 'labProgress',
                    'tick': tick,
                    'position': game.debugPlayerGridPosition.toJson(),
                    'waits': game.debugPendingSceneWaitCount,
                    'autorun': game.debugIsEntityAutorunInFlight,
                    'activation': game.debugIsMapActivationDispatchInFlight,
                    'pendingDialogue': game.debugHasPendingDialogueLoad,
                    'dialogue': dialogue?.fullText,
                    'oakVisible': game.debugIsNpcActorVisible(
                      'ac13_3091d360a3437593628f5002',
                    ),
                    'oakFacing': game
                        .debugNpcVisualFacing('ac13_3091d360a3437593628f5002')
                        ?.name,
                    'actorPositions': [
                      for (final a
                          in game.world
                              .descendants()
                              .whereType<OverworldActorComponent>())
                        {
                          'character': a.character.id,
                          'pos': a.gridPos?.toJson(),
                          'moving': a.isStepping,
                          'facing': a.facing.name,
                          'mounted': a.isMounted,
                          'removed': a.isRemoved,
                          'parent': a.parent.runtimeType.toString(),
                        },
                    ],
                    'labLines': labLines.length,
                  }),
                );
              }
              if (sawMovie &&
                  (!prepareLab || labLines.length == 12) &&
                  game.gameStateSnapshot.currentMapId == destination.id &&
                  !game.debugIsGameplayInputLocked &&
                  !game.debugIsMapActivationDispatchInFlight &&
                  !game.debugIsLoadActivationWorkInFlight &&
                  !game.debugHasPendingMapTransition) {
                break;
              }
            }
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.release(RuntimeInputControl.up),
            );
            if (prepareLab) {
              expect(
                labLines,
                hasLength(12),
                reason:
                    "Autorun lab failed to progress; see labProgress receipt",
              );
            }
            await waitConvertedQaIdle(game);
            expect(sawMovie, isTrue);
            expect(sawBothActorsMoving, isTrue);
            expect(sawDoorEntry, isTrue);
            expect(lines, hasLength(4));
            expect(lines.first, contains("Hey! Wait!"));
            expect(game.gameStateSnapshot.currentMapId, destination.id);
            final expectedPosition = GridPos(x: 8, y: prepareLab ? 6 : 14);
            expect(game.debugPlayerGridPosition, expectedPosition);
            if (prepareLab) {
              expect(labLines, hasLength(12));
              expect(labLines.join(' '), contains('Go on, choose!'));
              expect(flag(game, 74), isFalse);
              expect(flag(game, 75), isTrue);
            }
            expect(game.gameStateSnapshot.party.members, isEmpty);
            expect(
              game.gameStateSnapshot.narrativeFactRuntimeState
                      .valueFor('fact_source_variable_42ff340145d6e92e40b862d8')
                      ?.intValue ??
                  0,
              0,
            );
            expect(await game.saveGame(), isTrue);
            final saved = (await saves.load())!;
            expect(saved.currentMapId, destination.id);
            expect(saved.playerPosition, expectedPosition);
            if (prepareLab) {
              game.onRemove();
              await Future<void>.delayed(const Duration(milliseconds: 400));
              await tester.pumpWidget(const SizedBox.shrink());
              final restored = await mountConvertedQaGame(
                tester,
                projectFile,
                saves,
                game.gameStateSnapshot,
                restoredSave: saveDataFromGameState(saved),
              );
              try {
                expect(restored.debugPlayerGridPosition, expectedPosition);
                expect(restored.gameStateSnapshot.party.members, isEmpty);
                expect(flag(restored, 74), isFalse);
                expect(flag(restored, 75), isTrue);
                expect(restored.dialoguePresentationListenable.value, isNull);
              } finally {
                restored.onRemove();
                await Future<void>.delayed(const Duration(milliseconds: 400));
                await tester.pumpWidget(const SizedBox.shrink());
              }
            }
            if (output != null) {
              await File('$output.${variant.$1}.json').writeAsString(
                jsonEncode({
                  'eventId': variant.$1,
                  'sourceIdentity': sourceIdentity,
                  'sourceMapSha256': 'a45202a4797d4a5701b44ada8d5142eee895bad5977fbd7cab653c3c35647559',
                  'sourceCommandsExecuted': false,
                  'aiCalls': 0,
                  'dialogueLines': lines.toList(),
                  'labDialogueLines': labLines,
                  'labPreparationQualified': prepareLab,
                  'coldReloadReason': prepareLab ? 'saveRestore' : null,
                  'parallelMovementObserved': sawBothActorsMoving,
                  'destination': saved.currentMapId,
                  'position': saved.playerPosition.toJson(),
                  'partyCount': saved.party.members.length,
                  'saved': true,
                  'campaignNewGameQualified': false,
                }),
              );
            }
          } finally {
            game.onRemove();
            await Future<void>.delayed(const Duration(milliseconds: 400));
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 3)),
      skip: root == null,
    );
  }
}
