import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        driveConvertedQaDialogue,
        hashConvertedQaProjectFiles,
        installConvertedQaHeadlessAudio,
        pressConvertedQaPrimary,
        waitConvertedQaIdle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_CUT_GIVER_PROJECT'];
  final output = Platform.environment['AVELUNE_CUT_GIVER_RECEIPT'];
  for (final abort in [false, true]) {
    testWidgets(
      'converted Captain lateral reward ${abort ? 'abort' : 'save'}',
      (tester) async {
        await tester.runAsync(() async {
          final projectFile = path.join(root!, 'project.json');
          final project = await loadProjectManifestFromFile(projectFile);
          final reference = project.maps.single;
          final map = MapData.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(
                await File(path.join(root, reference.relativePath))
                    .readAsString(),
              ) as Map,
            ),
          );
          final captain = map.entities.singleWhere(
            (entity) =>
                entity.presentation?.variants.any(
                  (v) => v.id == 'page_0_locked',
                ) ==
                true,
          );
          final locked = captain.presentation!.variants.singleWhere(
            (v) => v.id == 'page_0_locked',
          );
          final released = captain.presentation!.variants.singleWhere(
            (v) => v.id == 'page_0_released',
          );
          final scene = project.scenes.singleWhere(
            (scene) =>
                scene.metadata['sourceEventIdentity'] ==
                    captain.properties['sourceEventIdentity'] &&
                scene.graph.nodes.any(
                  (node) =>
                      node.payload is SceneActionPayload &&
                      (node.payload as SceneActionPayload).interactiveCommand
                          is SceneGiveItemInteractiveCommand,
                ),
          );
          final actions = scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>();
          final reward = actions
              .map((a) => a.interactiveCommand)
              .whereType<SceneGiveItemInteractiveCommand>()
              .single;
          final release = actions
              .map((a) => a.consequence)
              .whereType<SceneSetMapEventInstanceBooleanConsequence>()
              .single;
          final flag = project.facts.singleWhere(
            (fact) => fact.description.endsWith(':switch:62'),
          );
          final before = await hashConvertedQaProjectFiles(root);
          final temporary = await Directory.systemTemp.createTemp(
            'captain-cut-save-',
          );
          final repository = ConvertedQaDiskSave(
            path.join(temporary.path, 'save.json'),
          );
          final initial = GameState(
            saveId: 'captain-lateral-$abort',
            currentMapId: map.id,
            playerPosition: GridPos(x: captain.pos.x - 1, y: captain.pos.y),
            playerFacing: EntityFacing.east,
            trainerProfile: const TrainerProfile(name: 'Captain qualification'),
          );
          PlayableMapGame? mounted;
          final lines = <String>[];
          final stages = <String>[];
          var aborted = false;
          try {
            final game = mounted = await _mount(
              tester,
              projectFile,
              repository,
              initial,
            );
            String? character(GameState state) => projectMapEntityPresentation(
              project: project,
              gameState: state,
              map: map,
              entity: captain,
            )?.npc?.characterId;
            int quantity() => game.gameStateSnapshot.bag.entries
                .where((entry) => entry.itemId == reward.itemId)
                .fold(0, (sum, entry) => sum + entry.quantity);
            bool releasedIn(GameState state) =>
                state
                    .mapInstanceWorldState
                    .instancesByMapId[map.id]
                    ?.eventBooleans[captain.id]?[release.key] ==
                true;
            expect(game.debugNpcVisualFacing(captain.id), EntityFacing.north);
            expect(game.debugNpcGridPosition(captain.id), captain.pos);
            expect(character(game.gameStateSnapshot), locked.characterId);
            expect(quantity(), 0);
            expect(
              game.overworldInteractionSnapshot.primaryAction?.request.targetId,
              captain.id,
            );
            pressConvertedQaPrimary(game);
            final watch = Stopwatch()..start();
            for (
              var tick = 0;
              tick < 20000 && watch.elapsed < const Duration(seconds: 15);
              tick++
            ) {
              final dialogue = game.dialoguePresentationListenable.value;
              if (dialogue != null) {
                if (lines.isEmpty || lines.last != dialogue.fullText) {
                  final candidates = game.world
                      .descendants()
                      .whereType<OverworldActorComponent>()
                      .where(
                        (actor) =>
                            actor.isGameplayPresent &&
                            {
                              locked.characterId,
                              released.characterId,
                            }.contains(actor.character.id),
                      )
                      .toList();
                  if (candidates.isEmpty) {
                    game.update(.05);
                    await game.ready();
                    await Future<void>.delayed(const Duration(milliseconds: 1));
                    continue;
                  }
                  final visible = candidates.single;
                  lines.add(dialogue.fullText);
                  if (visible.character.id == locked.characterId) {
                    stages.add('locked');
                  } else {
                    expect(visible.character.id, released.characterId);
                    expect(
                      game.debugNpcVisualFacing(captain.id),
                      EntityFacing.west,
                    );
                    expect(game.debugNpcGridPosition(captain.id), captain.pos);
                    stages.add('released');
                    if (abort) {
                      game.debugResetBattleForTest();
                      aborted = true;
                      break;
                    }
                  }
                }
                pressConvertedQaPrimary(game);
              }
              if (game.debugFlowPhaseName == 'overworld' &&
                  !game.debugIsNarrativeOutcomeWorkInFlight &&
                  !game.debugIsNarrativeSpatialDispatchInFlight &&
                  stages.contains('released') &&
                  game.gameStateSnapshot.narrativeFactRuntimeState
                          .valueFor(flag.id)
                          ?.boolValue ==
                      true &&
                  dialogue == null) {
                break;
              }
              game.update(.05);
              await game.ready();
              if (tick % 500 == 0) {
                stdout.writeln(
                  jsonEncode({
                    'stage': 'captainFrame',
                    'tick': tick,
                    'phase': game.debugFlowPhaseName,
                    'releaseInWorkingState': releasedIn(
                      game.playerServiceGameStateSnapshot,
                    ),
                    'actorFacing': game.debugNpcVisualFacing(captain.id)?.name,
                    'npcMovement':
                        '${game.scriptedNpcMovementStatus(captain.id)}',
                    'sceneWaits': game.debugPendingSceneWaitCount,
                    'dialogue':
                        game.dialoguePresentationListenable.value?.fullText,
                  }),
                );
              }
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            await waitConvertedQaIdle(game);
            expect(stages, containsAll(['locked', 'released']));
            expect(game.debugBattleSessionSnapshot, isNull);
            final completed =
                game.gameStateSnapshot.narrativeFactRuntimeState
                    .valueFor(flag.id)
                    ?.boolValue ==
                true;
            if (abort) {
              expect(aborted, isTrue);
              expect(quantity(), 0);
              expect(completed, isFalse);
              expect(releasedIn(game.gameStateSnapshot), isFalse);
              expect(character(game.gameStateSnapshot), locked.characterId);
              expect(await game.saveGame(), isTrue);
            } else {
              expect(quantity(), 1);
              expect(completed, isTrue);
              expect(character(game.gameStateSnapshot), released.characterId);
              expect(game.debugNpcVisualFacing(captain.id), EntityFacing.west);
              expect(game.debugNpcGridPosition(captain.id), captain.pos);
              if (output != null) {
                await File('$output.before-save-state.json').writeAsString(
                    jsonEncode(game.companionGameStateSnapshot.toJson()));
              }
              expect(await game.saveGame(), isTrue);
              final saved = (await repository.load())!;
              if (output != null) {
                await File('$output.pre-cold-state.json')
                    .writeAsString(jsonEncode(saved.toJson()));
              }
              expect(
                saved
                    .mapInstanceWorldState
                    .instancesByMapId[map.id]!
                    .npcPoses[captain.id]!
                    .facing,
                EntityFacing.west,
              );
              game.onRemove();
              mounted = null;
              await tester.pumpWidget(const SizedBox.shrink());
              await Future<void>.delayed(const Duration(milliseconds: 400));
              final cold = mounted = await _mount(
                tester,
                projectFile,
                repository,
                saved,
                restoredSave: saveDataFromGameState(saved),
              );
              await waitConvertedQaIdle(cold);
              expect(cold.gameStateSnapshot.bag, saved.bag);
              expect(
                cold.gameStateSnapshot.narrativeFactRuntimeState,
                saved.narrativeFactRuntimeState,
              );
              expect(
                cold
                    .gameStateSnapshot
                    .mapInstanceWorldState
                    .instancesByMapId[map.id]!
                    .npcPoses[captain.id],
                saved
                    .mapInstanceWorldState
                    .instancesByMapId[map.id]!
                    .npcPoses[captain.id],
              );
              expect(cold.debugNpcVisualFacing(captain.id), EntityFacing.west);
              expect(cold.debugNpcGridPosition(captain.id), captain.pos);
              expect(await cold.loadGame(), isTrue);
              await waitConvertedQaIdle(cold);
              expect(cold.debugNpcVisualFacing(captain.id), EntityFacing.west);
              expect(cold.debugNpcGridPosition(captain.id), captain.pos);
              final repeat = <String>[];
              pressConvertedQaPrimary(cold);
              await driveConvertedQaDialogue(
                cold,
                repeat,
                requireBattle: false,
              );
              expect(repeat.join('\n'), contains('set sail'));
              expect(cold.gameStateSnapshot.bag, saved.bag);
            }
            expect(await hashConvertedQaProjectFiles(root), before);
            final receipt = {
              'kind': 'convertedCaptainCutGiverJourney',
              'projectPath': root,
              'sourceMapId': 186,
              'sourceEventId': 2,
              'lateralApproach': 'west',
              'sourceInitialDirectionFix': true,
              'sourceInternalFacingParityQualified': false,
              'businessEffectsPreserved': true,
              'abortedBeforeGrant': abort,
              'rewardQuantity': abort ? 0 : 1,
              'coldSaveVerified': !abort,
              'warmLoadVerified': !abort,
              'projectFilesUnchanged': true,
              'progressionSeeded': false,
              'playerPositionSeededForIsolatedQa': true,
              'fullCampaignStartCertified': false,
              'fieldCutUseCertified': false,
              'audibleOutputCertified': false,
              'stages': stages,
              'dialogues': lines,
            };
            stdout.writeln(jsonEncode(receipt));
            if (output != null) {
              await File('$output.${abort ? 'abort' : 'save'}.json')
                  .writeAsString(jsonEncode(receipt));
            }
          } finally {
            mounted?.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            await temporary.delete(recursive: true);
          }
        });
      },
      skip: root == null,
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}

Future<PlayableMapGame> _mount(
  WidgetTester tester,
  String projectFile,
  ConvertedQaDiskSave repository,
  GameState initial, {
  SaveData? restoredSave,
}) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: initial.currentMapId,
  );
  final audio = _CaptainAudioWitness(bundle);
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    initialGameState: restoredSave == null ? initial : null,
    saveData: restoredSave,
    initialMapActivationReason: restoredSave == null
        ? MapActivationReason.initialBoot
        : MapActivationReason.saveRestore,
    saveRepository: repository,
    dialogueFeedbackPlaybackPort: audio,
    sceneSoundEffectPlaybackPort: audio,
  );
  try {
    game.onGameResize(Vector2(640, 480));
    game.setDialogueFlutterOverlayPreferred(true);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget<PlayableMapGame>(game: game),
      ),
    );
    await game.toBeLoaded();
    await game.ready();
    game.pauseEngine();
    await waitConvertedQaIdle(game);
    expect(game.debugPlayerGridPosition, initial.playerPosition);
    return game;
  } catch (_) {
    game.onRemove();
    rethrow;
  }
}

final class _CaptainAudioWitness
    implements DialogueFeedbackPlaybackPort, SceneSoundEffectPlaybackPort {
  _CaptainAudioWitness(this.bundle);
  final RuntimeMapBundle bundle;

  @override
  Future<void> playCue(
    DialogueAudioCue cue, {
    required String playbackId,
  }) async {
    stdout.writeln(
      jsonEncode({
        'stage': 'cueStart',
        'id': cue.mediaAssetId,
        'role': cue.role.name,
        'playbackId': playbackId,
      }),
    );
    await playSoundEffect(
      cue.mediaAssetId,
      volume: cue.volume,
      playbackId: playbackId,
    );
    stdout.writeln(
      jsonEncode({'stage': 'cueComplete', 'id': cue.mediaAssetId}),
    );
  }

  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    final asset = bundle.manifest.cinematicMediaAssets.singleWhere(
      (a) => a.id == mediaAssetId,
    );
    expect(asset.kind, CinematicMediaAssetKind.sound);
    expect(
      await File(path.join(bundle.projectRootDirectory, asset.relativePath))
          .exists(),
      isTrue,
    );
    expect(volume, inInclusiveRange(0, 1));
    expect(playbackId, isNotEmpty);
  }
}
