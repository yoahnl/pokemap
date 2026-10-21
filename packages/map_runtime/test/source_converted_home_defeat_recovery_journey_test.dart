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
        installConvertedQaHeadlessAudio,
        ConvertedQaDiskSave,
        hashConvertedQaProjectFiles,
        pressConvertedQaPrimary;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_HOME_RECOVERY_PROJECT'];
  final starterSavePath =
      Platform.environment['AVELUNE_HOME_RECOVERY_STARTER_SAVE'];
  final sourceReceiptPath =
      Platform.environment['AVELUNE_HOME_RECOVERY_SOURCE_RECEIPT'];
  testWidgets(
    'real converted trainer defeat returns to converted Mom and cold saves without repeating recovery',
    (tester) async {
      await tester.runAsync(() async {
        final projectFile = path.join(root!, 'project.json');
        final original = await loadProjectManifestFromFile(projectFile);
        final point = original.newGame.initialRecoveryPoint!;
        final marker = original.defeatRecovery!.recoveredFactId;
        final sourceHome = original.maps.singleWhere(
          (map) => map.id == point.mapId,
        );
        final mom = original.scenes.singleWhere(
          (scene) =>
              scene.metadata['sourcePageIndex'] == '2' &&
              scene.graph.nodes.any(
                (node) =>
                    node.payload is SceneActionPayload &&
                    (node.payload as SceneActionPayload).consequence
                        is SceneHealPartyConsequence,
              ),
        );
        expect(point.position, const GridPos(x: 9, y: 7));
        expect(point.facing, EntityFacing.north);
        expect(mom.metadata['sourceEventIdentity'], isNotNull);
        final momSource = original.eventRegistry!.records
            .map((record) => record.definitionOrNull)
            .whereType<NarrativeEventDefinition>()
            .singleWhere((definition) => definition.sceneId == mom.id)
            .source;
        final before = await hashConvertedQaProjectFiles(root);
        final sourceReceipt = jsonDecode(
          await File(sourceReceiptPath ?? '$root.receipt.json').readAsString(),
        ) as Map;
        final battleScene = original.scenes.singleWhere(
          (scene) => scene.id == sourceReceipt['sourceTrainerSceneId'],
        );
        final battle = battleScene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneBattlePayload>()
            .single;
        expect(
          battle.defeatRecovery,
          SceneBattleDefeatRecovery.returnToRecoveryPoint,
        );
        final victoryFacts = battleScene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.consequence)
            .whereType<SceneSetFactConsequence>()
            .where((consequence) => consequence.value == true)
            .map((consequence) => consequence.factId)
            .toSet();
        expect(victoryFacts, isNotEmpty);
        final trainer = original.trainers.singleWhere(
          (trainer) => trainer.id == battle.trainerId,
        );
        final routeEntries = <ProjectMapEntry>[];
        for (final entry in original.maps) {
          final map = MapData.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(
                await File(path.join(root, entry.relativePath)).readAsString(),
              ) as Map,
            ),
          );
          if (map.entities.any((entity) => entity.id == battle.npcEntityId)) {
            routeEntries.add(entry);
          }
        }
        final routeEntry = routeEntries.single;
        final routeBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile,
          mapId: routeEntry.id,
        );
        final npc = routeBundle.map.entities.singleWhere(
          (entity) => entity.id == battle.npcEntityId,
        );
        final manifest = original;
        final directory = await Directory.systemTemp.createTemp(
          'converted-home-defeat-save-',
        );
        addTearDown(() async {
          if (await directory.exists()) await directory.delete(recursive: true);
        });
        final repository = ConvertedQaDiskSave(
          path.join(directory.path, 'game.json'),
        );
        var initial = GameState(
          saveId: 'explicit-isolated-home-defeat',
          currentMapId: routeEntry.id,
          playerPosition: GridPos(x: npc.pos.x, y: npc.pos.y + npc.size.height),
          playerFacing: EntityFacing.north,
          metadata: {
            playerRecoveryMapIdMetadataKey: point.mapId,
            playerRecoveryPositionXMetadataKey: point.position.x.toString(),
            playerRecoveryPositionYMetadataKey: point.position.y.toString(),
            playerRecoveryFacingMetadataKey: point.facing.name,
          },
          trainerProfile: const TrainerProfile(
            name: 'Explicit isolated QA',
            money: 1000,
          ),
          party: const PlayerParty(
            members: [
              PlayerPokemon(
                individualId: 'explicit-qa-one-hp-bulbasaur',
                speciesId: 'bulbasaur',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 5,
                currentHp: 1,
                knownMoveIds: ['tackle'],
                currentPpByMoveId: {'tackle': 2},
              ),
            ],
          ),
        );
        String? inputSaveSha256;
        GameState? actualStarter;
        if (starterSavePath != null) {
          final bytes = await File(starterSavePath).readAsBytes();
          inputSaveSha256 = crypto.sha256.convert(bytes).toString();
          actualStarter = gameStateFromStrictSaveJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
          );
          expect(
            PlayerRecoveryPoint.tryRead(actualStarter),
            PlayerRecoveryPoint(
              mapId: point.mapId,
              position: point.position,
              facing: point.facing,
            ),
          );
          expect(_marker(actualStarter, manifest, marker), isFalse);
          expect(actualStarter.party.members, hasLength(1));
          expect(actualStarter.party.members.single.speciesId, 'bulbasaur');
          expect(actualStarter.party.members.single.level, 5);
          expect(actualStarter.party.members.single.currentHp, 19);
          expect(actualStarter.trainerProfile.money, 3000);
          expect(actualStarter.trainerProfile.badgeIds, isEmpty);
          expect(actualStarter.metadata[playerDefeatCountMetadataKey], isNull);
          initial = actualStarter.copyWith(
            currentMapId: routeEntry.id,
            playerPosition: GridPos(
              x: npc.pos.x,
              y: npc.pos.y + npc.size.height,
            ),
            playerPixelPosition: null,
            playerSpatialPosition: null,
            playerFacing: EntityFacing.north,
            mapInstanceWorldState: retainMapInstance(
              state: actualStarter.mapInstanceWorldState,
              mapId: routeEntry.id,
              allocateId: (mapId) => 'explicit-qa-relocation-$mapId',
            ),
          );
          for (final entry
              in actualStarter.mapInstanceWorldState.instancesByMapId.entries) {
            expect(
              initial.mapInstanceWorldState.instancesByMapId[entry.key],
              entry.value,
            );
          }
          expect(
            initial
                .mapInstanceWorldState
                .instancesByMapId[routeEntry.id]!
                .npcPoses,
            isEmpty,
          );
          expect(initial.party, actualStarter.party);
          expect(initial.pokemonStorage, actualStarter.pokemonStorage);
          expect(initial.bag, actualStarter.bag);
          expect(initial.trainerProfile, actualStarter.trainerProfile);
          expect(
            initial.narrativeFactRuntimeState,
            actualStarter.narrativeFactRuntimeState,
          );
          expect(initial.storyFlags, actualStarter.storyFlags);
          expect(initial.metadata, actualStarter.metadata);
        }
        final expectedMoney = starterSavePath == null ? 900 : 2700;
        PlayableMapGame? game;
        final lines = <String>[];
        var commands = 0;
        var sawBattle = false;
        var sawDefeat = false;
        var checkpoints = 0;
        var markerAtCheckpoint = false;
        final checkpointStates = <Map<String, dynamic>>[];
        final recoveryLandingStates = <Map<String, dynamic>>[];
        Future<PlayableMapGame> mount({SaveData? saved}) async {
          final base = await loadRuntimeMapBundle(
            projectFilePath: projectFile,
            mapId: saved == null
                ? initial.currentMapId
                : gameStateFromSaveData(saved).currentMapId,
            additionalCharacterIds: {
              if (initial.trainerProfile.avatarCharacterId case final String id
                  when id.isNotEmpty)
                id,
            },
          );
          final mounted = PlayableMapGame(
            bundle: base,
            projectFilePath: projectFile,
            initialGameState: saved == null ? initial : null,
            saveData: saved,
            initialMapActivationReason: saved == null
                ? MapActivationReason.initialBoot
                : MapActivationReason.saveRestore,
            saveRepository: repository,
            sceneSoundEffectPlaybackPort: _SoundFiles(
              base.copyWith(manifest: manifest),
            ),
            beforeNarrativeAuthorityPreparation: (occurrence) async {
              if (occurrence.source != momSource) return;
              final state = game!.playerServiceGameStateSnapshot;
              if (_marker(state, manifest, marker)) {
                expect(state.currentMapId, sourceHome.id);
                expect(state.metadata[playerDefeatCountMetadataKey], '1');
                expect(state.trainerProfile.money, expectedMoney);
                recoveryLandingStates.add(state.toJson());
              }
            },
            defeatRecoveryCheckpointEmitter: () async {
              checkpoints++;
              final state = game!.gameStateSnapshot;
              markerAtCheckpoint = _marker(state, manifest, marker);
              checkpointStates.add(state.toJson());
              expect(state.currentMapId, sourceHome.id);
              expect(state.metadata[playerDefeatCountMetadataKey], '1');
              expect(state.trainerProfile.money, expectedMoney);
              if (!markerAtCheckpoint) {
                expect(state.party.members.single.currentHp, greaterThan(1));
                expect(lines.join('\n').toLowerCase(), contains('mom'));
              }
            },
          );
          game = mounted;
          mounted.onGameResize(Vector2(640, 480));
          mounted.setDialogueFlutterOverlayPreferred(true);
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: GameWidget<PlayableMapGame>(game: mounted),
            ),
          );
          await mounted.toBeLoaded();
          await mounted.ready();
          mounted.pauseEngine();
          return mounted;
        }

        try {
          final mounted = await mount();
          var quiet = 0;
          for (var tick = 0; tick < 12000; tick++) {
            if (!sawBattle && tick % 20 == 0 && _idle(mounted)) {
              pressConvertedQaPrimary(mounted);
            }
            final session = mounted.debugBattleSessionSnapshot;
            if (session != null) {
              sawBattle = true;
              sawDefeat = sawDefeat || session.state.outcome?.isDefeat == true;
            }
            final dialogue = mounted.dialoguePresentationListenable.value;
            if (dialogue != null) {
              if (lines.isEmpty || lines.last != dialogue.fullText) {
                lines.add(dialogue.fullText);
              }
              expect(await mounted.saveGame(), isFalse);
              pressConvertedQaPrimary(mounted);
            } else {
              final choices = mounted.battleCommandOverlayListenable.value;
              if (choices != null &&
                  choices.interactionsEnabled &&
                  choices.entries.isNotEmpty) {
                if (mounted.dispatchBattlePresentationCommand(
                  BattleSelectEntryCommand(
                    snapshotRevision: choices.revision,
                    expectedMode: choices.mode,
                    entryIndex: choices.entries
                        .firstWhere((entry) => entry.enabled)
                        .index,
                  ),
                )) {
                  commands++;
                }
              }
            }
            quiet =
                checkpoints == 1 &&
                    lines.isNotEmpty &&
                    _idle(mounted) &&
                    !_marker(mounted.gameStateSnapshot, manifest, marker)
                ? quiet + 1
                : 0;
            if (quiet >= 20) break;
            mounted.update(.05);
            await mounted.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          final state = mounted.gameStateSnapshot;
          expect(sawBattle, isTrue);
          expect(sawDefeat, isTrue);
          expect(commands, greaterThan(0));
          expect(checkpoints, 1);
          expect(recoveryLandingStates, isNotEmpty);
          expect(lines, isNotEmpty);
          expect(lines.join('\n').toLowerCase(), contains('mom'));
          expect(_marker(state, manifest, marker), isFalse);
          expect(state.currentMapId, sourceHome.id);
          expect(state.playerPosition, point.position);
          expect(state.metadata[playerDefeatCountMetadataKey], '1');
          expect(state.trainerProfile.money, expectedMoney);
          expect(state.party.members.single.currentHp, greaterThan(1));
          expect(
            state.party.members.single.individualId,
            initial.party.members.single.individualId,
          );
          expect(state.trainerProfile.badgeIds, isEmpty);
          expect(
            state.storyFlags.activeFlags,
            isNot(contains('trainer_defeated:${trainer.id}')),
          );
          for (final id in victoryFacts) {
            expect(_marker(state, manifest, id), isFalse);
          }
          expect(await mounted.saveGame(), isTrue);
          final saved = (await repository.load())!;
          final disk = saveDataFromGameState(saved);
          expect(saved.metadata[playerDefeatCountMetadataKey], '1');
          expect(_marker(saved, manifest, marker), isFalse);
          mounted.onRemove();
          game = null;
          await tester.pumpWidget(const SizedBox.shrink());
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final cold = await mount(saved: disk);
          for (var tick = 0; tick < 150; tick++) {
            cold.update(.05);
            await cold.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          expect(cold.dialoguePresentationListenable.value, isNull);
          expect(cold.debugBattleSessionSnapshot, isNull);
          expect(
            cold.gameStateSnapshot.metadata[playerDefeatCountMetadataKey],
            '1',
          );
          expect(cold.gameStateSnapshot.trainerProfile.money, expectedMoney);
          expect(cold.gameStateSnapshot.party, saved.party);
          expect(_marker(cold.gameStateSnapshot, manifest, marker), isFalse);
          for (final id in victoryFacts) {
            expect(_marker(cold.gameStateSnapshot, manifest, id), isFalse);
          }
          expect(checkpoints, 1);
          expect(await hashConvertedQaProjectFiles(root), before);
          final receipt = {
            'kind': 'convertedTrainerDefeatHomeRecoveryJourney',
            'projectPath': root,
            'sourceHomeSceneId': mom.id,
            'recoveryConfig': original.defeatRecovery!.toJson(),
            'nativeRecoveryPoint': point.toJson(),
            'actualNativeBattle': sawBattle,
            'actualNativeDefeat': sawDefeat,
            'battleCommands': commands,
            'markerPublishedAtCheckpoint': markerAtCheckpoint,
            'recoveryMarkerSeenBeforeMom': true,
            'recoveryLandingStates': recoveryLandingStates,
            'markerClearedByConvertedMom': true,
            'dialogues': lines,
            'checkpointStates': checkpointStates,
            'coldReload': true,
            'duplicateRecovery': false,
            'projectFilesUnchanged': true,
            'qaPartySeeded': starterSavePath == null
                ? initial.party.toJson()
                : false,
            'qaPositionSeeded': true,
            'qaRelocationMapInstanceCreated': starterSavePath != null,
            'actualStarterSavePath': starterSavePath,
            'actualStarterSaveSha256': inputSaveSha256,
            'actualStarterParty': actualStarter?.party.toJson(),
            'initialMoney': initial.trainerProfile.money,
            'nativeMoneyAfterLoss': state.trainerProfile.money,
            'combinedFullProjectMaps': manifest.maps.length,
            'nativeRuntimeMapLoader': true,
            'sourceBattleScene': battleScene.toJson(),
            'sourceTrainer': trainer.toJson(),
            'sourceTrainerIdentity': sourceReceipt['sourceTrainerIdentity'],
            'sourceVictoryFactsRemainFalseAfterLossAndColdReload': victoryFacts
                .toList(),
            'outcomesInjected': false,
            'sourceFlagsInjected': false,
            'sourceConvertedTrainerBattleToMomRecoveryQualified': true,
            'freshCampaignQualified': false,
            'sourceStoredPokemonHealingQualified': false,
            'audibleOutputQualified': false,
            'sourceScriptsExecuted': 0,
            'aiCalls': 0,
          };
          if (Platform.environment['AVELUNE_HOME_RECOVERY_RECEIPT']
              case final file?) {
            await File(file).writeAsString(jsonEncode(receipt), flush: true);
          }
          if (starterSavePath != null) {
            expect(
              crypto.sha256
                  .convert(await File(starterSavePath).readAsBytes())
                  .toString(),
              inputSaveSha256,
            );
          }
          stdout.writeln(jsonEncode(receipt));
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await Future<void>.delayed(const Duration(milliseconds: 150));
          await directory.delete(recursive: true);
        }
      });
    },
    skip: root == null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

bool _marker(GameState state, ProjectManifest manifest, String id) =>
    state.narrativeFactRuntimeState.valueFor(id)?.boolValue ??
    manifest.facts.singleWhere((fact) => fact.id == id).defaultValue;
bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugHasPendingMapTransition &&
    !game.debugHasPendingDialogueLoad;

final class _SoundFiles implements SceneSoundEffectPlaybackPort {
  _SoundFiles(this.bundle);
  final RuntimeMapBundle bundle;
  @override
  Future<void> playSoundEffect(
    String id, {
    required double volume,
    required String playbackId,
  }) async {
    final media = bundle.manifest.cinematicMediaAssets.singleWhere(
      (asset) => asset.id == id,
    );
    expect(
      await File(path.join(bundle.projectRootDirectory, media.relativePath))
          .exists(),
      isTrue,
    );
    expect(volume, inInclusiveRange(0, 1));
  }
}
