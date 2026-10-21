import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        hashConvertedQaProjectFiles,
        installConvertedQaHeadlessAudio,
        pressConvertedQaPrimary;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_FIRST_RIVAL_PROJECT'];
  final receiptPath = Platform.environment['AVELUNE_FIRST_RIVAL_RECEIPT'];
  for (final scenario in [
    (event: 2, x: 8, victory: false, enemy: 'bulbasaur'),
    (event: 3, x: 7, victory: false, enemy: 'bulbasaur'),
    (event: 9, x: 9, victory: true, enemy: 'charmander'),
  ]) {
    testWidgets(
      'converted rival ${scenario.event} native ${scenario.victory ? 'victory' : 'loss'} preserves source continuation and cold saves',
      (tester) async {
        await tester.runAsync(() async {
          final projectFile = path.join(root!, 'project.json');
          final manifest = await loadProjectManifestFromFile(projectFile);
          expect(manifest.maps, hasLength(1));
          final mapId = manifest.maps.single.id;
          final bundleBytes = await File(
            Platform.environment['AVELUNE_FIRST_RIVAL_SOURCE_BUNDLE'] ??
                '$root.bundle.json',
          ).readAsBytes();
          final attestation =
              jsonDecode(utf8.decode(bundleBytes)) as Map<String, dynamic>;
          expect(attestation['strictNativeWriterVerified'], isTrue);
          expect(attestation['sourceSnapshotHash'], matches(r'^[a-f0-9]{64}$'));
          expect((attestation['maps'] as Map).keys, ['9']);
          expect(attestation['maps']['9']['id'], mapId);
          final sourceRivals = (attestation['projection']['events'] as List)
              .cast<Map>()
              .where(
                (row) =>
                    row['locator']['mapId'] == 9 &&
                    const [2, 3, 9].contains(row['locator']['eventId']),
              )
              .toList();
          expect(sourceRivals, hasLength(3));
          expect(
            sourceRivals.every(
              (row) => row['status'] == 'adaptedStaticSemantics',
            ),
            isTrue,
          );
          final trainerIds = {
            for (final row in sourceRivals)
              ...(row['nativeFirstRival']['nativeTrainerIds'] as Map).values
                  .cast<String>(),
          };
          expect(trainerIds, hasLength(3));
          expect(
            manifest.trainers.where(
              (trainer) => trainerIds.contains(trainer.id),
            ),
            hasLength(3),
          );
          expect(
            manifest.scenes
                .expand((scene) => scene.graph.nodes)
                .map((node) => node.payload)
                .whereType<SceneBattlePayload>()
                .where((battle) => trainerIds.contains(battle.trainerId)),
            hasLength(9),
          );
          final source = await loadRuntimeMapBundle(
            projectFilePath: projectFile,
            mapId: mapId,
          );
          final controller = source.map.entities.singleWhere(
            (entity) =>
                entity.pos == GridPos(x: scenario.x, y: 10) &&
                entity.properties['sourceEventIdentity'] != null,
          );
          final scene = manifest.scenes.singleWhere(
            (scene) =>
                scene.metadata['sourceEventIdentity'] ==
                    controller.properties['sourceEventIdentity'] &&
                scene.metadata['sourcePageIndex'] == '1',
          );
          final battles = scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneBattlePayload>()
              .toList();
          expect(battles, hasLength(3));
          expect(
            battles.every(
              (battle) =>
                  battle.defeatRecovery ==
                  SceneBattleDefeatRecovery.continueScene,
            ),
            isTrue,
          );
          final sceneTrackId = scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>()
              .map((payload) => payload.interactiveCommand)
              .whereType<SceneMusicInteractiveCommand>()
              .firstWhere(
                (music) => music.operation == SceneMusicOperation.play,
              )
              .mediaAssetId!;
          final sceneTrack = manifest.cinematicMediaAssets.singleWhere(
            (media) => media.id == sceneTrackId,
          );
          final sceneTrackPath = path.join(root, sceneTrack.relativePath);
          expect(await File(sceneTrackPath).exists(), isTrue);
          final choice = manifest.facts.singleWhere(
            (fact) =>
                fact.description.startsWith('Persistent source integer:') &&
                fact.description.endsWith(':variable:29'),
          );
          final selfFacts = {
            for (final event in [1, 2, 3, 9, 17, 18, 19])
              event: manifest.facts.singleWhere(
                (fact) =>
                    fact.description.endsWith(':map:9:event:$event:self:A'),
              ),
          };
          final companionOwners = {
            for (final event in [17, 18]) event: source.map.entities.singleWhere((entity) =>
              entity.properties['sourceEventIdentity'] == (attestation['projection']['events'] as List).cast<Map>()
                .singleWhere((row) => row['locator']['mapId'] == 9 && row['locator']['eventId'] == event)['sourceIdentity']).id,
          };
          final initial = GameState(
            saveId: 'explicit-isolated-first-rival-${scenario.event}',
            currentMapId: mapId,
            mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
              mapId: MapInstanceRuntimeState(instanceId: 'explicit-isolated-rival-visit', npcPoses: {
                for (final owner in companionOwners.values) owner: MapInstanceNpcPose(
                  position: const GridPos(x: 14, y: 4), facing: EntityFacing.south),
              }),
            }),
            playerPosition: GridPos(x: scenario.x, y: 11),
            playerFacing: EntityFacing.north,
            trainerProfile: const TrainerProfile(
              name: 'Explicit isolated Rival QA',
              money: 3000,
            ),
            narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
              valuesByFactId: {
                choice.id: NarrativeValue.integer(1),
                selfFacts[17]!.id: NarrativeValue.boolean(true),
                selfFacts[18]!.id: NarrativeValue.boolean(true),
              },
            ),
            party: PlayerParty(
              members: [
                PlayerPokemon(
                  individualId: 'explicit-qa-first-rival-bulbasaur',
                  speciesId: 'bulbasaur',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: scenario.victory ? 100 : 5,
                  currentHp: scenario.victory ? 300 : 1,
                  knownMoveIds: const ['tackle'],
                  currentPpByMoveId: const {'tackle': 35},
                ),
                if (!scenario.victory)
                  const PlayerPokemon(
                    individualId: 'explicit-qa-first-rival-second-bulbasaur',
                    speciesId: 'bulbasaur',
                    natureId: 'hardy',
                    abilityId: 'overgrow',
                    level: 5,
                    currentHp: 1,
                    knownMoveIds: ['tackle'],
                    currentPpByMoveId: {'tackle': 35},
                  ),
              ],
            ),
          );
          final before = await hashConvertedQaProjectFiles(root);
          final directory = await Directory.systemTemp.createTemp(
            'first-rival-save-',
          );
          final repository = ConvertedQaDiskSave(
            path.join(directory.path, 'save.json'),
          );
          final musicDriver = _MusicDriver();
          final music = RuntimeMusicService(
            driver: musicDriver,
            fadeDelay: (_) async {},
            fadeSteps: 1,
          );
          PlayableMapGame? active;
          Future<PlayableMapGame> mount({SaveData? restored}) async {
            final game = PlayableMapGame(
              bundle: await loadRuntimeMapBundle(
                projectFilePath: projectFile,
                mapId: mapId,
              ),
              projectFilePath: projectFile,
              initialGameState: restored == null ? initial : null,
              saveData: restored,
              initialMapActivationReason: restored == null
                  ? MapActivationReason.initialBoot
                  : MapActivationReason.saveRestore,
              saveRepository: repository,
              musicService: music,
            );
            active = game;
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
            return game;
          }

          try {
            final game = await mount();
            final initialMusicPath = music.playingPath;
            var sawBattle = false;
            var sawVictory = false;
            var sawDefeat = false;
            var commands = 0;
            var released = false;
            var quiet = 0;
            var sceneMusicUnderDialogue = false;
            var battleMusicHasPriority = false;
            final observedBattleMusicPaths = <String?>{};
            final enemies = <String>{};
            final lines = <String>[];
            for (var tick = 0; tick < 18000; tick++) {
              if (!sawBattle && !released && _idle(game)) {
                game.handleRuntimeInputEvent(
                  const RuntimeInputEvent.press(RuntimeInputControl.up),
                );
              }
              if (!released &&
                  (game.debugIsNarrativeSpatialDispatchInFlight ||
                      game.dialoguePresentationListenable.value != null ||
                      game.debugBattleSessionSnapshot != null)) {
                game.handleRuntimeInputEvent(
                  const RuntimeInputEvent.release(RuntimeInputControl.up),
                );
                released = true;
              }
              final battle = game.debugBattleSessionSnapshot;
              if (battle != null) {
                sawBattle = true;
                enemies.add(battle.state.enemy.speciesId);
                sawVictory =
                    sawVictory || battle.state.outcome?.isVictory == true;
                sawDefeat = sawDefeat || battle.state.outcome?.isDefeat == true;
                if (game.debugFlowPhaseName == 'battle') {
                  observedBattleMusicPaths.add(music.playingPath);
                  battleMusicHasPriority =
                      battleMusicHasPriority ||
                      music.playingPath != sceneTrackPath;
                }
              }
              final dialogue = game.dialoguePresentationListenable.value;
              if (dialogue != null) {
                sceneMusicUnderDialogue =
                    sceneMusicUnderDialogue ||
                    music.playingPath == sceneTrackPath;
                if (lines.isEmpty || lines.last != dialogue.fullText) {
                  lines.add(dialogue.fullText);
                }
                expect(dialogue.mode, isNot(DialoguePresentationMode.choices));
                pressConvertedQaPrimary(game);
              } else if (game.battleCommandOverlayListenable.value
                  case final overlay? when overlay.interactionsEnabled) {
                final entry = overlay.entries.firstWhere(
                  (entry) => entry.enabled,
                );
                final index = switch (overlay.mode) {
                  BattleCommandOverlayMode.root ||
                  BattleCommandOverlayMode.fight => 0,
                  BattleCommandOverlayMode.continueOnly ||
                  BattleCommandOverlayMode.pokemon => entry.index,
                  _ => throw StateError(
                    'Unexpected Rival overlay ${overlay.mode}: ${overlay.prompt}',
                  ),
                };
                if (game.dispatchBattlePresentationCommand(
                  BattleSelectEntryCommand(
                    snapshotRevision: overlay.revision,
                    expectedMode: overlay.mode,
                    entryIndex: index,
                  ),
                )) {
                  commands++;
                }
              }
              if (game.debugPostBattleOverlayMounted) {
                game.debugValidatePostBattleChoice();
              }
              quiet = sawBattle && _idle(game) ? quiet + 1 : 0;
              if (quiet >= 20) break;
              game.update(.05);
              await game.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(
              quiet,
              greaterThanOrEqualTo(20),
              reason:
                  'phase=${game.debugFlowPhaseName} pos=${game.debugPlayerGridPosition} lines=$lines battle=$sawBattle prompt=${game.battleCommandOverlayListenable.value?.prompt}',
            );
            expect(sawBattle, isTrue);
            expect(commands, greaterThan(0));
            expect(enemies, {scenario.enemy});
            expect(sawVictory, scenario.victory);
            expect(sawDefeat, !scenario.victory);
            expect(sceneMusicUnderDialogue, isTrue);
            expect(battleMusicHasPriority, isTrue);
            expect(musicDriver.loops, contains((sceneTrackPath, true)));
            expect(music.playingPath, initialMusicPath);
            expect(lines, isNotEmpty);
            final state = game.gameStateSnapshot;
            expect(state.currentMapId, mapId);
            expect(state.metadata[playerDefeatCountMetadataKey], isNull);
            expect(
              state.party.members.map((member) => member.currentHp),
              everyElement(greaterThan(1)),
            );
            expect(
              state.party.members.map((member) => member.individualId),
              initial.party.members.map((member) => member.individualId),
            );
            final expectedMarkers = scenario.event != 3 || scenario.victory;
            for (final entry in selfFacts.entries) {
              expect(
                _bool(state, entry.value),
                expectedMarkers || const [17, 18].contains(entry.key),
                reason: entry.value.description,
              );
            }
            if (!scenario.victory) {
              expect(state.trainerProfile.money, 3000);
            } else {
              expect(
                state.trainerProfile.money,
                3080,
                reason: 'Source PBS trainer_types FRLG_RIVAL1 BaseMoney16 times source party level5.',
              );
              expect(lines.join('\n'), contains('WHAT? Unbelievable!'));
            }
            expect(await game.saveGame(), isTrue);
            final saved = (await repository.load())!;
            game.onRemove();
            active = null;
            await tester.pumpWidget(const SizedBox.shrink());
            await Future<void>.delayed(const Duration(milliseconds: 400));
            final cold = await mount(restored: saveDataFromGameState(saved));
            for (var tick = 0; tick < 150; tick++) {
              cold.update(.05);
              await cold.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(cold.dialoguePresentationListenable.value, isNull);
            expect(cold.debugBattleSessionSnapshot, isNull);
            expect(cold.gameStateSnapshot.party, saved.party);
            expect(cold.gameStateSnapshot.trainerProfile, saved.trainerProfile);
            for (final entry in selfFacts.entries) {
              expect(
                _bool(cold.gameStateSnapshot, entry.value),
                expectedMarkers || const [17, 18].contains(entry.key),
              );
            }
            expect(await hashConvertedQaProjectFiles(root), before);
            if (receiptPath != null) {
              await File('$receiptPath.${scenario.event}.json').writeAsString(
                jsonEncode({
                  'kind': 'convertedFirstRivalNativeBattleJourney',
                  'projectRoot': root,
                  'sourceSnapshotHash': attestation['sourceSnapshotHash'],
                  'strictCompositionBundleSha256': crypto.sha256
                      .convert(bundleBytes)
                      .toString(),
                  'sourceMapId': 9,
                  'sourceEventId': scenario.event,
                  'sourceSceneId': scene.id,
                  'actualNativeBattle': sawBattle,
                  'actualNativeVictory': sawVictory,
                  'actualNativeDefeat': sawDefeat,
                  'sceneMusicUnderDialogue': sceneMusicUnderDialogue,
                  'nativeBattleAudioSelectionPriority': battleMusicHasPriority,
                  'observedNativeBattleMusicPaths': observedBattleMusicPaths
                      .toList(),
                  'initialAmbienceRestoredAtSceneEnd': true,
                  'sourceStarterChoiceVariable29': 1,
                  'sourceRewardOracle': {
                    'trainerTypes': 'PBS/trainer_types.txt:226-230',
                    'baseMoney': 16,
                    'sourceTrainerPartyLevel': 5,
                    'victoryMoney': 80,
                  },
                  'observedEnemySpecies': enemies.toList(),
                  'commandsIssued': commands,
                  'dialogueLines': lines,
                  'sourceSelfAMarkers': {
                    for (final entry in selfFacts.entries)
                      '${entry.key}': _bool(saved, entry.value),
                  },
                  'savedParty': saved.party.toJson(),
                  'coldReloadVerified': true,
                  'projectFilesUnchanged': before.length,
                  'explicitQaPreparation': {
                    'position': initial.playerPosition.toJson(),
                    'party': initial.party.toJson(),
                    'typedFacts': initial.narrativeFactRuntimeState.toJson(),
                    'mapInstances': initial.mapInstanceWorldState.toJson(),
                    'hiddenPosePreparationOracle': 'Source starter Grass page uses command202 for companions17/18 at14,4; explicit isolated preparation',
                    'trainerProfile': initial.trainerProfile.toJson(),
                  },
                  'battleOutcomeInjected': false,
                  'continuousCampaignQualified': false,
                  'audibleAudioCertified': false,
                  'sourceTemporalAudioParity': false,
                  'sourceScriptsExecuted': 0,
                  'aiCalls': 0,
                }),
              );
            }
          } finally {
            active?.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            await music.dispose();
            await Future<void>.delayed(const Duration(milliseconds: 400));
            await directory.delete(recursive: true);
          }
        });
      },
      skip: root == null,
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}

bool _bool(GameState state, NarrativeFactDefinition fact) =>
    state.narrativeFactRuntimeState.valueFor(fact.id)?.boolValue ??
    fact.defaultValue;

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    game.debugCompletedMapActivationDispatchCount > 0 &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition &&
    !game.debugIsPlayerStepping;

final class _MusicDriver implements FlameCinematicAudioDriver {
  var nextHandle = 0;
  final loops = <(String, bool)>[];

  @override
  Future<Object> play(
    String filePath, {
    required double volume,
    required bool loop,
  }) async {
    loops.add((filePath, loop));
    return 'first_rival_qa_${nextHandle++}';
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {}
}
