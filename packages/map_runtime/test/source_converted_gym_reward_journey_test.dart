import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installConvertedQaHeadlessAudio);
  testWidgets('headless gym audio adapter completes native player lifecycle', (
    tester,
  ) async {
    await tester.runAsync(() async {
      installConvertedQaHeadlessAudio(completePlayback: true);
      final player = AudioPlayer();
      try {
        final complete = player.onPlayerComplete.first;
        await player.play(
          DeviceFileSource('/explicit-headless-audio-stub.wav'),
        );
        await complete;
      } finally {
        await player.dispose();
      }
    });
  });
  testWidgets('headless audio emits once per loaded source across manual loop resumes', (tester) async {
    await tester.runAsync(() async {
      installConvertedQaHeadlessAudio(completePlayback: true);
      final player = AudioPlayer();
      var completions = 0;
      final subscription = player.onPlayerComplete.listen((_) => completions++);
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.play(DeviceFileSource('/explicit-headless-audio-stub.wav'));
        await Future<void>.delayed(Duration.zero);
        expect(completions, 1);
        await player.seek(Duration.zero);
        await player.resume();
        await Future<void>.delayed(Duration.zero);
        expect(completions, 1);
        await player.setSource(DeviceFileSource('/next-headless-audio-stub.wav'));
        await player.resume();
        await Future<void>.delayed(Duration.zero);
        expect(completions, 2);
        await player.pause();
        await player.resume();
        await Future<void>.delayed(Duration.zero);
        expect(completions, 2);
      } finally {
        await subscription.cancel();
        await player.dispose();
      }
    });
  });

  testWidgets('headless audio never fabricates completion for native loops', (tester) async {
    await tester.runAsync(() async {
      installConvertedQaHeadlessAudio(completePlayback: true);
      final player = AudioPlayer();
      var completions = 0;
      final subscription = player.onPlayerComplete.listen((_) => completions++);
      try {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(DeviceFileSource('/explicit-headless-audio-loop.wav'));
        await Future<void>.delayed(Duration.zero);
        expect(completions, 0);
        await player.seek(Duration.zero);
        await player.resume();
        await Future<void>.delayed(Duration.zero);
        expect(completions, 0);
      } finally {
        await subscription.cancel();
        await player.dispose();
      }
    });
  });

  final root = Platform.environment['AVELUNE_GYM_PROJECT'];
  final output = Platform.environment['AVELUNE_GYM_RECEIPT'];
  for (final leader in ['Brock', 'Blaine']) {
    testWidgets(
      'converted $leader battle grants rewards once and survives cold reload',
      (tester) async {
        await tester.runAsync(() async {
          expect(path.isAbsolute(root!), isTrue);
          expect(await Directory(root).resolveSymbolicLinks(), root);
          final projectFile = path.join(root, 'project.json');
          final manifest = await loadProjectManifestFromFile(projectFile);
          expect(manifest.maps, hasLength(383));
          final trainer = manifest.trainers.singleWhere(
            (trainer) => trainer.name == leader,
          );
          final rewardOracle = leader == 'Brock'
              ? (
                  badgeId: 'source_badge_r1_b11_4d72f612ab3a89b5dc464f77',
                  itemId: 'source-item-c85eb9dfd407526308e09068',
                  symbol: 'TM100',
                  sourcePath: 'Data/Map020.rxdata',
                  sourceSha256: '2e55572935e1cffde255c4c3dd386cc4e066f9a51ecec55056351be366b53b51',
                  eventId: 3,
                  badgeIndex: 11,
                  badgeCommand: 16,
                  itemCommand: 24,
                )
              : (
                  badgeId: 'source_badge_r1_b17_4d72f612ab3a89b5dc464f77',
                  itemId: 'source-item-e13ff980fe9a90b962a239d1',
                  symbol: 'TM038',
                  sourcePath: 'Data/Map062.rxdata',
                  sourceSha256: 'fdccbb93c1c509acabb3be2449f7542292cb64fd1936a300427c63008511f77b',
                  eventId: 5,
                  badgeIndex: 17,
                  badgeCommand: 8,
                  itemCommand: 15,
                );
          final expectedMoney = leader == 'Brock' ? 1400 : 4700;
          expect(
            trainer.moneyReward,
            expectedMoney,
            reason:
                'Pinned Essentials BaseMoney 100 times maximum party level.',
          );
          final map = manifest.maps.singleWhere(
            (map) =>
                map.name == (leader == 'Brock' ? 'Pewter Gym' : 'Cinnabar Gym'),
          );
          final mapData = MapData.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(
                await File(path.join(root, map.relativePath)).readAsString(),
              ) as Map,
            ),
          );
          final entity = mapData.entities.singleWhere(
            (entity) => entity.npc?.trainerId == trainer.id,
          );
          final records = manifest.eventRegistry!.records
              .where((record) => record.toJson()['state'] == 'configured')
              .map((record) => record.toJson()['definition'] as Map)
              .where(
                (record) => (record['source'] as Map)['entityId'] == entity.id,
              )
              .toList();
          expect(records, hasLength(2));
          final scenes = records
              .map(
                (record) => manifest.scenes.singleWhere(
                  (scene) => scene.id == record['sceneId'],
                ),
              )
              .toList();
          final battleScene = scenes.singleWhere(
            (scene) => scene.graph.nodes.any(
              (node) => node.toJson()['kind'] == 'battle',
            ),
          );
          final actions = battleScene.graph.nodes
              .map((node) => node.toJson()['payload'] as Map)
              .toList();
          final badgeId =
              actions
                      .map((payload) => payload['consequence'])
                      .whereType<Map>()
                      .singleWhere(
                        (consequence) => consequence['kind'] == 'awardBadge',
                      )['badgeId']
                  as String;
          final reward = actions
              .map((payload) => payload['interactiveCommand'])
              .whereType<Map>()
              .singleWhere((command) => command['kind'] == 'giveItem');
          final itemId = reward['itemId'] as String;
          final itemQuantity = reward['quantity'] as int;
          expect(badgeId, rewardOracle.badgeId);
          expect(itemId, rewardOracle.itemId);
          expect(itemQuantity, 1);
          final catalog = await const RuntimeItemCatalogLoader().load(
            projectRootDirectory: root,
            pokemonConfig: manifest.pokemon,
          );
          expect(
            catalog!.entries
                .singleWhere((item) => item.id == itemId)
                .displayName,
            rewardOracle.symbol,
          );
          final fact = actions
              .map((payload) => payload['consequence'])
              .whereType<Map>()
              .singleWhere((consequence) => consequence['kind'] == 'setFact');
          final factId = fact['factId'] as String;
          final beforeFiles = await hashConvertedQaProjectFiles(root);
          final saveRoot = await Directory.systemTemp.createTemp(
            'converted-gym-save-',
          );
          final repository = ConvertedQaDiskSave(
            path.join(saveRoot.path, 'game.json'),
          );
          final initial = GameState(
            saveId: 'converted-gym-$leader',
            currentMapId: map.id,
            playerPosition: GridPos(
              x: entity.pos.x,
              y: entity.pos.y + entity.size.height,
            ),
            playerFacing: EntityFacing.north,
            trainerProfile: const TrainerProfile(
              name: 'QA battle only',
              money: 100,
            ),
            party: const PlayerParty(
              members: [
                PlayerPokemon(
                  individualId: 'explicit-qualification-blastoise',
                  nickname: 'QA battle only',
                  speciesId: 'blastoise',
                  natureId: 'hardy',
                  abilityId: 'torrent',
                  level: 100,
                  currentHp: 200,
                  knownMoveIds: ['surf'],
                  currentPpByMoveId: {'surf': 15},
                ),
              ],
            ),
          );
          PlayableMapGame? game;
          final lines = <String>[];
          try {
            game = await mountConvertedQaGame(
              tester,
              projectFile,
              repository,
              initial,
            );
            expect(game.gameStateSnapshot.party.members, hasLength(1));
            expect(
              game.gameStateSnapshot.party.members.single.copyWith(
                experience: null,
              ),
              initial.party.members.single,
            );
            expect(game.gameStateSnapshot.trainerProfile.badgeIds, isEmpty);
            expect(_quantity(game, itemId), 0);
            expect(_fact(game, manifest, factId), isFalse);
            expect(game.gameStateSnapshot.completedBattleRequestIds, isEmpty);
            pressConvertedQaPrimary(game);
            final battle = await driveConvertedQaDialogue(
              game,
              lines,
              requireBattle: true,
            );
            expect(battle.sawBattle, isTrue);
            expect(battle.sawVictory, isTrue);
            expect(battle.commands, greaterThan(0));
            final won = game.gameStateSnapshot;
            expect(won.trainerProfile.badgeIds, [badgeId]);
            final badge = manifest.badges.singleWhere(
              (badge) => badge.id == badgeId,
            );
            if (badge.fieldAbilityUnlock != null) {
              expect(
                won.progression.unlockedFieldAbilities,
                contains(badge.fieldAbilityUnlock),
              );
            }
            expect(
              won.trainerProfile.money,
              initial.trainerProfile.money + expectedMoney,
            );
            expect(_quantity(game, itemId), itemQuantity);
            expect(_fact(game, manifest, factId), isTrue);
            expect(won.completedBattleRequestIds, hasLength(1));
            expect(
              won.storyFlags.activeFlags,
              contains('trainer_defeated:${trainer.id}'),
            );
            expect(
              won.party.members.single.currentPpByMoveId!['surf'],
              lessThan(15),
            );
            final afterVictoryLines = <String>[];
            pressConvertedQaPrimary(game);
            final replay = await driveConvertedQaDialogue(
              game,
              afterVictoryLines,
              requireBattle: false,
            );
            expect(replay.sawBattle, isFalse);
            expect(afterVictoryLines, isNotEmpty);
            expect(game.gameStateSnapshot.trainerProfile, won.trainerProfile);
            expect(game.gameStateSnapshot.bag, won.bag);
            expect(
              game.gameStateSnapshot.completedBattleRequestIds,
              won.completedBattleRequestIds,
            );
            expect(await game.saveGame(), isTrue);
            final saved = game.gameStateSnapshot;
            game.onRemove();
            game = null;
            await tester.pumpWidget(const SizedBox.shrink());
            game = await mountConvertedQaGame(
              tester,
              projectFile,
              repository,
              initial,
            );
            expect(await game.loadGame(), isTrue);
            await waitConvertedQaIdle(game);
            expect(game.gameStateSnapshot.trainerProfile, saved.trainerProfile);
            expect(game.gameStateSnapshot.party, saved.party);
            expect(game.gameStateSnapshot.bag, saved.bag);
            expect(
              game.gameStateSnapshot.progression.copyWith(storyFlags: []),
              saved.progression.copyWith(storyFlags: []),
            );
            expect(game.gameStateSnapshot.progression.storyFlags.toSet(), {
              ...saved.progression.storyFlags,
              ...saved.storyFlags.activeFlags,
            });
            expect(game.gameStateSnapshot.storyFlags, saved.storyFlags);
            expect(
              game.gameStateSnapshot.narrativeFactRuntimeState,
              saved.narrativeFactRuntimeState,
            );
            expect(
              game.gameStateSnapshot.completedBattleRequestIds,
              saved.completedBattleRequestIds,
            );
            final reloadedLines = <String>[];
            pressConvertedQaPrimary(game);
            final reloadReplay = await driveConvertedQaDialogue(
              game,
              reloadedLines,
              requireBattle: false,
            );
            expect(reloadReplay.sawBattle, isFalse);
            expect(reloadedLines, afterVictoryLines);
            expect(game.gameStateSnapshot.trainerProfile, saved.trainerProfile);
            expect(game.gameStateSnapshot.bag, saved.bag);
            expect(_quantity(game, itemId), itemQuantity);
            expect(
              game.gameStateSnapshot.completedBattleRequestIds,
              saved.completedBattleRequestIds,
            );
            expect(await hashConvertedQaProjectFiles(root), beforeFiles);
            final receipt = {
              'kind': 'convertedGymBattleRewardJourney',
              'leader': leader,
              'projectPath': root,
              'trainerId': trainer.id,
              'battleSceneId': battleScene.id,
              'badgeId': badgeId,
              'itemId': itemId,
              'itemQuantity': itemQuantity,
              'sourceRewardOracle': {
                'sourcePath': rewardOracle.sourcePath,
                'sourceSha256': rewardOracle.sourceSha256,
                'eventId': rewardOracle.eventId,
                'pageIndex': 0,
                'badgeCommandIndex': rewardOracle.badgeCommand,
                'badgeIndex': rewardOracle.badgeIndex,
                'itemCommandIndex': rewardOracle.itemCommand,
                'itemSymbol': rewardOracle.symbol,
                'sourceScriptsExecuted': 0,
              },
              'moneyAwarded': trainer.moneyReward,
              'actualBattleVictory': battle.sawVictory,
              'battlePresentationCommands': battle.commands,
              'dialogues': lines,
              'postVictoryDialogues': afterVictoryLines,
              'coldReloadCount': 1,
              'rewardsInjected': false,
              'battleOutcomeInjected': false,
              'partySeededForIsolatedQa': true,
              'partySeed': initial.party.toJson(),
              'fullCampaignStartCertified': false,
              'projectFilesUnchanged': true,
              'audibleOutputCertified': false,
              'completedBattleRequestIds':
                  saved.completedBattleRequestIds.toList()..sort(),
            };
            if (output != null) {
              final target = '$output.${leader.toLowerCase()}.json';
              expect(path.isWithin(root, target), isFalse);
              await File(target)
                  .writeAsString(jsonEncode(receipt), flush: true);
            }
            stdout.writeln(jsonEncode(receipt));
          } finally {
            game?.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            await saveRoot.delete(recursive: true);
          }
        });
      },
      skip: root == null,
      timeout: const Timeout(Duration(minutes: 12)),
    );
  }
}

void installConvertedQaHeadlessAudio({bool completePlayback = false}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final sinks = <String, MockStreamHandlerEventSink>{};
  final releaseModes = <String, String>{};
  final loaded = <String>{};
  final completed = <String>{};
  for (final name in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      final arguments = call.arguments as Map;
      final id = arguments['playerId'] as String;
      switch (call.method) {
        case 'create':
          messenger.setMockStreamHandler(
            EventChannel('xyz.luan/audioplayers/events/$id'),
            MockStreamHandler.inline(
              onListen: (arguments, sink) {
                sinks[id] = sink;
              },
              onCancel: (arguments) {
                sinks.remove(id);
              },
            ),
          );
        case 'setReleaseMode':
          releaseModes[id] = arguments['releaseMode'] as String;
        case 'setSourceUrl' || 'setSourceBytes':
          loaded.add(id);
          completed.remove(id);
          sinks[id]?.success({'event': 'audio.onPrepared', 'value': true});
        case 'resume':
          if (completePlayback && loaded.contains(id) &&
              releaseModes[id] != ReleaseMode.loop.toString() &&
              completed.add(id)) {
            sinks[id]?.success({'event': 'audio.onComplete'});
          }
        case 'seek':
          sinks[id]?.success({'event': 'audio.onSeekComplete'});
        case 'dispose':
          releaseModes.remove(id);
          loaded.remove(id);
          completed.remove(id);
        case 'getCurrentPosition' || 'getDuration':
          return 0;
      }
      return null;
    },
  );
}

Future<({bool sawBattle, bool sawVictory, int commands})>
driveConvertedQaDialogue(
  PlayableMapGame game,
  List<String> lines, {
  required bool requireBattle,
}) async {
  var sawBattle = false;
  var sawVictory = false;
  var commands = 0;
  var quiet = 0;
  Object? previousTurn = Object();
  final watch = Stopwatch()..start();
  for (
    var tick = 0;
    tick < 30000 && watch.elapsed < const Duration(minutes: 5);
    tick++
  ) {
    final session = game.debugBattleSessionSnapshot;
    if (session != null) {
      sawBattle = true;
      if (session.state.currentTurn != previousTurn) {
        previousTurn = session.state.currentTurn;
        stdout.writeln(
          jsonEncode({
            'kind': 'gymBattleTurn',
            'commandsIssued': commands,
            'player': {
              'species': session.state.player.speciesId,
              'level': session.state.player.level,
              'hp': session.state.player.currentHp,
              'maxHp': session.state.player.maxHp,
              'moves': [
                for (final move in session.state.player.moves)
                  {'id': move.id, 'pp': move.currentPp},
              ],
            },
            'enemy': {
              'species': session.state.enemy.speciesId,
              'level': session.state.enemy.level,
              'hp': session.state.enemy.currentHp,
            },
          }),
        );
      }
      sawVictory = sawVictory || session.state.outcome?.isVictory == true;
    }
    final dialogue = game.dialoguePresentationListenable.value;
    if (dialogue != null) {
      if (lines.isEmpty || lines.last != dialogue.fullText) {
        lines.add(dialogue.fullText);
      }
      expect(dialogue.mode, isNot(DialoguePresentationMode.choices));
      pressConvertedQaPrimary(game);
    } else {
      final snapshot = game.battleCommandOverlayListenable.value;
      if (snapshot != null && snapshot.interactionsEnabled) {
        final entry = snapshot.entries
            .where((entry) => entry.enabled)
            .firstOrNull;
        expect(entry, isNotNull);
        expect(snapshot.mode, isNot(BattleCommandOverlayMode.pokemon));
        final selected = switch (snapshot.mode) {
          BattleCommandOverlayMode.root || BattleCommandOverlayMode.fight => 0,
          BattleCommandOverlayMode.continueOnly => entry!.index,
          _ => throw StateError(
            'Unexpected battle choice ${snapshot.mode}: ${snapshot.prompt}',
          ),
        };
        if (game.dispatchBattlePresentationCommand(
          BattleSelectEntryCommand(
            snapshotRevision: snapshot.revision,
            expectedMode: snapshot.mode,
            entryIndex: selected,
          ),
        )) {
          commands++;
        }
      }
    }
    quiet = _isIdle(game) && dialogue == null ? quiet + 1 : 0;
    if (quiet >= 20 && (sawBattle || !requireBattle)) {
      return (sawBattle: sawBattle, sawVictory: sawVictory, commands: commands);
    }
    game.update(0.05);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Converted gym did not complete: phase=${game.debugFlowPhaseName}, battle=$sawBattle, victory=$sawVictory, dialogue=${game.dialoguePresentationListenable.value?.fullText}, prompt=${game.battleCommandOverlayListenable.value?.prompt}',
  );
}

Future<PlayableMapGame> mountConvertedQaGame(
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
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    initialGameState: restoredSave == null ? initial : null,
    saveData: restoredSave,
    initialMapActivationReason: restoredSave == null ? MapActivationReason.initialBoot : MapActivationReason.saveRestore,
    saveRepository: repository,
    sceneSoundEffectPlaybackPort: _SoundFiles(bundle),
    dialogueFeedbackPlaybackPort: _SoundFiles(bundle),
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

bool _isIdle(PlayableMapGame game) =>
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

Future<void> waitConvertedQaIdle(PlayableMapGame game) async {
  var count = 0;
  for (var tick = 0; tick < 6000; tick++) {
    count = _isIdle(game) ? count + 1 : 0;
    if (count >= 20) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Gym did not become idle: ${game.debugFlowPhaseName}');
}

void pressConvertedQaPrimary(PlayableMapGame game) {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    ),
    isTrue,
  );
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
}

bool _fact(PlayableMapGame game, ProjectManifest manifest, String id) =>
    game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(id)?.boolValue ??
    manifest.facts.singleWhere((fact) => fact.id == id).defaultValue;

int _quantity(PlayableMapGame game, String id) => game
    .gameStateSnapshot
    .bag
    .entries
    .where((entry) => entry.itemId == id)
    .fold(0, (quantity, entry) => quantity + entry.quantity);

Future<Map<String, String>> hashConvertedQaProjectFiles(String root) async {
  final hashes = <String, String>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      hashes[path.relative(entry.path, from: root)] = crypto.sha256
          .convert(await entry.readAsBytes())
          .toString();
    } else if (entry is Link) {
      fail('The project must not contain symlinks: ${entry.path}');
    }
  }
  return hashes;
}

final class _SoundFiles
    implements SceneSoundEffectPlaybackPort, DialogueFeedbackPlaybackPort {
  _SoundFiles(this.bundle);
  final RuntimeMapBundle bundle;

  @override
  Future<void> playCue(DialogueAudioCue cue, {required String playbackId}) =>
      playSoundEffect(
        cue.mediaAssetId,
        volume: cue.volume,
        playbackId: playbackId,
      );

  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    final media = bundle.manifest.cinematicMediaAssets.singleWhere(
      (asset) => asset.id == mediaAssetId,
    );
    expect(media.kind, CinematicMediaAssetKind.sound);
    expect(
      await File(path.join(bundle.projectRootDirectory, media.relativePath))
          .exists(),
      isTrue,
    );
    expect(volume, inInclusiveRange(0, 1));
    expect(playbackId, isNotEmpty);
  }
}

final class ConvertedQaDiskSave extends FileGameSaveRepository {
  ConvertedQaDiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}
