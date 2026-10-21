import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        driveConvertedQaDialogue,
        hashConvertedQaProjectFiles,
        installConvertedQaHeadlessAudio,
        mountConvertedQaGame,
        pressConvertedQaPrimary,
        waitConvertedQaIdle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installConvertedQaHeadlessAudio);
  final root = Platform.environment['AVELUNE_FLY_PROJECT'];
  final output = Platform.environment['AVELUNE_FLY_RECEIPT'];
  testWidgets(
    'converted Celebrity gives HM02 once and native Player teaches Fly durably',
    (tester) async {
      await tester.runAsync(() async {
        expect(path.isAbsolute(root!), isTrue);
        expect(await Directory(root).resolveSymbolicLinks(), root);
        final projectFile = path.join(root, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        const mapId =
            'map_6a76816eb02baabc6935b7c0b44a4b9dc18a2056900b0dcbba293efe';
        const entityId = 'ac13_b78631b5f6b00bc6e09b9aa2';
        const itemId = 'source-item-829ae09782bfc9b9b78dab84';
        final map = manifest.maps.singleWhere((map) => map.id == mapId);
        final data = MapData.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
              await File(path.join(root, map.relativePath)).readAsString(),
            ) as Map,
          ),
        );
        final entity = data.entities.singleWhere((item) => item.id == entityId);
        final catalog = await const RuntimeItemCatalogLoader().load(
          projectRootDirectory: root,
          pokemonConfig: manifest.pokemon,
        );
        final item = catalog!.entries.singleWhere((item) => item.id == itemId);
        expect(item.displayName, 'HM02');
        expect(item.machine, isNotNull);
        expect(item.machine!.moveId, 'fly');
        expect(item.machine!.kind, ProjectMoveMachineKind.hm);
        expect(item.machine!.consumable, isFalse);
        final before = await hashConvertedQaProjectFiles(root);
        final saves = await Directory.systemTemp.createTemp(
          'converted-fly-save-',
        );
        final repository = ConvertedQaDiskSave(
          path.join(saves.path, 'game.json'),
        );
        final initial = GameState(
          saveId: 'converted-fly-donor',
          currentMapId: mapId,
          playerPosition: GridPos(
            x: entity.pos.x,
            y: entity.pos.y + entity.size.height,
          ),
          playerFacing: EntityFacing.north,
          trainerProfile: const TrainerProfile(name: 'QA Fly only', money: 100),
          party: const PlayerParty(
            members: [
              PlayerPokemon(
                individualId: 'explicit-qualification-pidgey',
                nickname: 'QA Fly only',
                speciesId: 'pidgey',
                natureId: 'hardy',
                abilityId: 'keen_eye',
                level: 20,
                currentHp: 40,
                knownMoveIds: ['gust'],
                currentPpByMoveId: {'gust': 35},
              ),
            ],
          ),
        );
        PlayableMapGame? game;
        PlayerServiceRuntimeController? controller;
        final lines = <String>[];
        final repeatLines = <String>[];
        try {
          game = await mountConvertedQaGame(
            tester,
            projectFile,
            repository,
            initial,
          );
          expect(_quantity(game, itemId), 0);
          expect(game.gameStateSnapshot.trainerProfile.badgeIds, isEmpty);
          expect(game.gameStateSnapshot.party.members.single.knownMoveIds, [
            'gust',
          ]);
          pressConvertedQaPrimary(game);
          final gift = await driveConvertedQaDialogue(
            game,
            lines,
            requireBattle: false,
          );
          expect(gift.sawBattle, isFalse);
          expect(lines.join('\n'), contains('secret retreat'));
          expect(lines.join('\n'), contains('HM02'));
          expect(_quantity(game, itemId), 1);
          pressConvertedQaPrimary(game);
          await driveConvertedQaDialogue(
            game,
            repeatLines,
            requireBattle: false,
          );
          expect(repeatLines.join('\n'), contains('HM02 is Fly'));
          expect(_quantity(game, itemId), 1);
          final activeGame = game;
          controller = PlayerServiceRuntimeController.contextual(
            currentGameState: () => activeGame.playerServiceGameStateSnapshot,
            commitAndSave: activeGame.commitAndSavePlayerServiceState,
            setInputLocked: (locked) => activeGame.setExternalInputLock(
              RuntimeExternalInputLock.playerService,
              locked: locked,
            ),
            loadRecoveryCaps: (_) async =>
                const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
            projectRootDirectory: root,
            pokemonConfig: manifest.pokemon,
            itemCatalog: ItemCatalogSnapshot.fromCatalog(catalog),
          );
          game.setPlayerServiceRuntimeController(controller);
          final learned = await controller.useBagItemOutsideBattle(
            const RuntimePlayerPauseCommand.useBagItem(
              itemTargetId: itemId,
              partyTargetId: 'party.0',
            ),
          );
          expect(learned.status, RuntimePlayerPauseCommandStatus.accepted);
          expect(game.gameStateSnapshot.party.members.single.knownMoveIds, [
            'gust',
            'fly',
          ]);
          expect(_quantity(game, itemId), 1);
          expect(game.gameStateSnapshot.trainerProfile.badgeIds, isEmpty);
          expect(await File(repository.filePath).exists(), isTrue);
          expect(await game.saveGame(), isTrue);
          final saved = game.gameStateSnapshot;
          controller.dispose();
          controller = null;
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
          expect(game.gameStateSnapshot.party, saved.party);
          expect(game.gameStateSnapshot.bag, saved.bag);
          expect(game.gameStateSnapshot.trainerProfile, saved.trainerProfile);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState,
            saved.narrativeFactRuntimeState,
          );
          final reloadedLines = <String>[];
          pressConvertedQaPrimary(game);
          await driveConvertedQaDialogue(
            game,
            reloadedLines,
            requireBattle: false,
          );
          expect(reloadedLines, repeatLines);
          expect(_quantity(game, itemId), 1);
          expect(game.gameStateSnapshot.party, saved.party);
          expect(await hashConvertedQaProjectFiles(root), before);
          final receipt = {
            'kind': 'convertedFlyRewardJourney',
            'projectPath': root,
            'sourcePath': 'Data/Map125.rxdata',
            'sourceSha256': 'd9f5f397a0207fb98b245833d77cc4e0ee37f70794b8bf54d20556f8842ff579',
            'sourceEventId': 11,
            'sourceGiveCommandIndex': 4,
            'sourcePageIndex': 0,
            'mapId': mapId,
            'entityId': entityId,
            'itemId': itemId,
            'actualDonorInteraction': true,
            'actualNativeMachineUse': true,
            'machineConsumed': false,
            'moveLearned': 'fly',
            'coldReloadCount': 1,
            'duplicateReward': false,
            'rewardsInjected': false,
            'badgesInjected': false,
            'partySeededForIsolatedQa': true,
            'partySeed': initial.party.toJson(),
            'fullCampaignStartCertified': false,
            'flyTravelCertified': false,
            'projectFilesUnchanged': true,
            'audibleOutputCertified': false,
            'dialogues': lines,
            'postGiftDialogues': repeatLines,
          };
          if (output != null) {
            expect(path.isWithin(root, output), isFalse);
            await File(output).writeAsString(jsonEncode(receipt), flush: true);
          }
          stdout.writeln(jsonEncode(receipt));
        } finally {
          controller?.dispose();
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saves.delete(recursive: true);
        }
      });
    },
    skip: root == null,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

int _quantity(PlayableMapGame game, String id) => game
    .gameStateSnapshot
    .bag
    .entries
    .where((entry) => entry.itemId == id)
    .fold(0, (quantity, entry) => quantity + entry.quantity);
