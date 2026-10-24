import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        mountConvertedQaGame,
        installConvertedQaHeadlessAudio,
        pressConvertedQaPrimary,
        driveConvertedQaDialogue,
        hashConvertedQaProjectFiles;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_STD09_PLAYER_REFERENCE'];
  final receiptPath = Platform.environment['AVELUNE_STD09_PLAYER_RECEIPT'];
  final savePath = Platform.environment['AVELUNE_STD09_PLAYER_SAVE'];
  final originPath = Platform.environment['AVELUNE_STD09_COLD_ORIGIN'];
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  testWidgets(
    'STD09 public conversion survives a new game journey and a cold process',
    (tester) async {
      await tester.runAsync(() async {
        final reference =
            jsonDecode(await File(referencePath!).readAsString()) as Map;
        expect(reference['writerVerified'], isTrue);
        expect(reference['strictReopenVerified'], isTrue);
        final projectFile = '${reference['projectPath']}/project.json';
        final manifest = await loadProjectManifestFromFile(projectFile);
        Future<Map<String, String>> hashes() =>
            hashConvertedQaProjectFiles(reference['projectPath'] as String);
        final items = await const RuntimeItemCatalogLoader().load(
          projectRootDirectory: reference['projectPath'] as String,
          pokemonConfig: manifest.pokemon,
        );
        final keyId = items!.entries
            .singleWhere((item) => item.tags.contains('key-item'))
            .id;
        final before = await hashes();
        final repository = ConvertedQaDiskSave(savePath!);
        Map? origin;
        late GameState initial;
        SaveData? saved;
        if (originPath != null) {
          origin = jsonDecode(await File(originPath).readAsString()) as Map;
          expect(origin['journeyComplete'], isTrue);
          expect(origin['runtimePid'], isNot(pid));
          expect(origin['projectHashes'], before);
          expect(
            origin['saveSha256'],
            crypto.sha256
                .convert(await File(savePath).readAsBytes())
                .toString(),
          );
          final restored = await repository.load();
          expect(restored, isNotNull);
          initial = restored!;
          saved = saveDataFromGameState(initial);
        } else {
          expect(await repository.load(), isNull);
          initial = await _newGame(projectFile);
          expect(initial.party.members, hasLength(1));
          expect(initial.bag.entries, isEmpty);
        }
        final game = await mountConvertedQaGame(
          tester,
          projectFile,
          repository,
          initial,
          restoredSave: saved,
        );
        final lines = <String>[];
        var battleObserved = false;
        var victoryObserved = false;
        final checkpoints = <String>[];
        try {
          game.resumeEngine();
          if (origin == null) {
            final startMap = reference['startMapId'] as String;
            expect(game.gameStateSnapshot.currentMapId, startMap);
            await _walk(game, const GridPos(x: 0, y: 4));
            await _walk(game, const GridPos(x: 2, y: 4));
            await _face(game, RuntimeInputControl.up);
            await _chooseGuide(game, cancel: true);
            await driveConvertedQaDialogue(game, lines, requireBattle: false);
            expect(lines, contains('Cancelled safely'));
            await _chooseGuide(game, cancel: false);
            await driveConvertedQaDialogue(game, lines, requireBattle: false);
            expect(lines, contains('Original common event'));
            expect(lines, isNot(contains('Unreachable common tail')));
            await _walk(game, const GridPos(x: 2, y: 3));
            pressConvertedQaPrimary(game);
            await driveConvertedQaDialogue(game, lines, requireBattle: false);
            expect(lines, contains('Common variable persisted'));
            checkpoints.add('choiceCancellationCommonEventAndVariablePage');
            await _walk(game, const GridPos(x: 6, y: 4));
            await _walk(game, const GridPos(x: 6, y: 3));
            game.handleRuntimeInputEvent(
              RuntimeInputEvent.press(RuntimeInputControl.up),
            );
            try {
              for (var frame = 0; frame < 60; frame++) {
                game.update(1 / 60);
                await Future<void>.delayed(const Duration(milliseconds: 5));
              }
            } finally {
              game.handleRuntimeInputEvent(
                RuntimeInputEvent.release(RuntimeInputControl.up),
              );
            }
            expect(game.gameStateSnapshot.currentMapId, startMap);
            expect(game.debugPlayerGridPosition, const GridPos(x: 6, y: 3));
            checkpoints.add('conditionalPassageClosedBeforeItem');
            await _walk(game, const GridPos(x: 4, y: 4));
            await _walk(game, const GridPos(x: 4, y: 3));
            await _face(game, RuntimeInputControl.up);
            pressConvertedQaPrimary(game);
            await driveConvertedQaDialogue(game, lines, requireBattle: false);
            expect(
              const BagOperations().quantityOf(
                game.gameStateSnapshot.bag,
                keyId,
              ),
              1,
            );
            checkpoints.add('sourceItemReceived');
            final moneyBefore = game.gameStateSnapshot.trainerProfile.money;
            await _walk(game, const GridPos(x: 8, y: 6));
            await _face(game, RuntimeInputControl.up);
            pressConvertedQaPrimary(game);
            final battle = await driveConvertedQaDialogue(
              game,
              lines,
              requireBattle: true,
            );
            battleObserved = battle.sawBattle;
            victoryObserved = battle.sawVictory;
            expect(battleObserved, isTrue);
            expect(victoryObserved, isTrue);
            expect(
              game.gameStateSnapshot.trainerProfile.money,
              moneyBefore + manifest.trainers.single.moneyReward,
            );
            expect(
              game.gameStateSnapshot.storyFlags.activeFlags.any(
                (flag) => flag.startsWith('trainer_defeated:'),
              ),
              isTrue,
            );
            checkpoints.add('aveluneTrainerBattleAndReward');
            await _walk(game, const GridPos(x: 6, y: 6));
            await _walk(game, const GridPos(x: 6, y: 3));
            await _step(game, RuntimeInputControl.up);
            await _until(
              game,
              () =>
                  game.gameStateSnapshot.currentMapId ==
                  reference['presentationMapId'],
            );
            checkpoints.add('conditionalPassageAndMapTransfer');
            await _walk(game, const GridPos(x: 4, y: 3));
            await _face(game, RuntimeInputControl.up);
            pressConvertedQaPrimary(game);
            await _until(
              game,
              () =>
                  game.debugWorldPresentationFrame.pictures.isNotEmpty &&
                  !game.debugIsGameplayInputLocked,
            );
            checkpoints.add('sourcePictureCinematic');
            expect(await game.saveGame(), isTrue);
          } else {
            expect(initial.toJson(), origin['savedState']);
            final restored = game.gameStateSnapshot;
            final previousTokens =
                initial.narrativeEventProgress.appliedNarrativeResetTokens;
            final currentTokens =
                restored.narrativeEventProgress.appliedNarrativeResetTokens;
            expect(currentTokens, containsAll(previousTokens));
            final activationTokens = currentTokens.toSet().difference(
              previousTokens.toSet(),
            );
            expect(activationTokens, hasLength(1));
            expect(activationTokens.single, startsWith('map:mapact_'));
            expect(
              restored.copyWith(
                narrativeEventProgress: restored.narrativeEventProgress
                    .copyWith(appliedNarrativeResetTokens: previousTokens),
              ),
              initial,
            );
            pressConvertedQaPrimary(game);
            await _until(
              game,
              () =>
                  game.debugWorldPresentationFrame.pictures.isNotEmpty &&
                  !game.debugIsGameplayInputLocked,
            );
            await _walk(game, const GridPos(x: 6, y: 3));
            await _face(game, RuntimeInputControl.up);
            pressConvertedQaPrimary(game);
            await _until(
              game,
              () =>
                  game.debugWorldPresentationFrame.pictures.isEmpty &&
                  !game.debugIsGameplayInputLocked,
            );
            expect(await game.saveGame(), isTrue);
            checkpoints.add('sameSaveRestoredByDifferentProcess');
            checkpoints.add('movementAndSourceInteractionAfterRestore');
          }
          expect(await hashes(), before);
          final state = await repository.load();
          expect(state, isNotNull);
          final receipt = {
            'kind': 'std09ConvertedPublicJourney',
            'runtimePid': pid,
            'originPid': origin?['runtimePid'],
            'journeyComplete': origin == null,
            'coldProcessQualified': origin != null,
            'newGameAdaptation': reference['newGameAdaptation'],
            'sourceBootstrapParity': false,
            'partyOrFlagsOrPositionInjected': false,
            'battleObserved': battleObserved,
            'victoryObserved': victoryObserved,
            'checkpoints': checkpoints,
            'dialogueLines': lines,
            'projectHashes': before,
            'saveSha256': crypto.sha256
                .convert(await File(savePath).readAsBytes())
                .toString(),
            'savedState': state!.toJson(),
            'audibleAudioQualified': false,
            'physicalIphoneQualified': false,
          };
          await File(receiptPath!).writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
          );
        } finally {
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    },
    skip: referencePath == null || receiptPath == null || savePath == null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<GameState> _newGame(String projectFile) async {
  final flow = RuntimeProjectNewGameFlowPort(
    projectFilePath: () async => projectFile,
    initialMapPreloader: RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile,
      loadSave: (_) async => null,
      tilesetImageLoader: (
        paths, {
        transparentColorByTilesetId = const {},
        onProgress,
      }) async => {},
    ),
  );
  final interactions = HeadlessSceneInteractionPort();
  final subscription = interactions.requests.listen((request) {
    final result = switch (request) {
      SceneTextInteractionRequest() => SceneInteractionResult.textSubmitted(
        requestId: request.requestId,
        revision: request.revision,
        value: 'Original Player',
      ),
      SceneSelectionInteractionRequest() =>
        SceneInteractionResult.selectionSubmitted(
          requestId: request.requestId,
          revision: request.revision,
          selectedOptionIds: [request.options.first.id],
        ),
      _ => throw StateError(
        'Unexpected new game interaction ${request.runtimeType}',
      ),
    };
    expect(interactions.resolve(result).isAccepted, isTrue);
  });
  try {
    final preparation = await flow.prepare();
    var draft = NewGameDraft.start(
      draftId: 'std09',
      projectRevision: preparation.projectRevision,
      slotId: 'slot1',
      config: preparation.project.newGame,
    );
    final runner = preparation.preSessionRunner;
    if (runner != null) {
      draft = await runner.run(
        runId: 'std09',
        draft: draft,
        interactions: interactions,
      );
    }
    if (draft.starterOptionId == null) {
      final result = draft.apply(
        NewGameDraftCommand.selectStarter(
          expectedRevision: draft.revision,
          starterOptionId: preparation.project.newGame.starterOptions.first.id,
        ),
      );
      expect(result.status, NewGameDraftCommandStatus.applied);
      draft = result.draft;
    }
    final revision = await flow.readCurrentProjectRevision();
    final committed = commitNewGameDraft(
      journal: NewGameSeedCommitJournal.empty(),
      operationId: 'std09',
      currentProjectRevision: revision,
      expectedDraftRevision: draft.revision,
      draft: draft,
    );
    expect(committed.status, NewGameSeedCommitStatus.committed);
    return createNewGameStateFromSeed(
      project: preparation.project,
      startMap: preparation.startMap,
      initialRecoveryMap: preparation.initialRecoveryMap,
      seed: committed.seed!,
      currentProjectRevision: revision,
      tileWidthPx: preparation.project.settings.tileWidth,
      tileHeightPx: preparation.project.settings.tileHeight,
    );
  } finally {
    await subscription.cancel();
    interactions.close();
    flow.clear();
  }
}

Future<void> _until(PlayableMapGame game, bool Function() condition) async {
  for (var frame = 0; frame < 2000; frame++) {
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (condition()) return;
  }
  fail(
    'STD09 runtime did not reach checkpoint: ${game.debugFlowPhaseName}, ${game.debugPlayerGridPosition}',
  );
}

Future<void> _chooseGuide(PlayableMapGame game, {required bool cancel}) async {
  pressConvertedQaPrimary(game);
  await _until(game, () {
    final dialogue = game.dialoguePresentationListenable.value;
    if (dialogue?.mode == DialoguePresentationMode.choices) return true;
    if (dialogue != null) pressConvertedQaPrimary(game);
    return false;
  });
  final control = cancel
      ? RuntimeInputControl.secondary
      : RuntimeInputControl.primary;
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  await _until(
    game,
    () =>
        game.dialoguePresentationListenable.value?.mode !=
        DialoguePresentationMode.choices,
  );
}

Future<void> _step(PlayableMapGame game, RuntimeInputControl control) async {
  final before = game.debugPlayerGridPosition;
  final map = game.gameStateSnapshot.currentMapId;
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  try {
    await _until(
      game,
      () =>
          game.debugPlayerGridPosition != before ||
          game.gameStateSnapshot.currentMapId != map,
    );
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await _until(
    game,
    () =>
        !game.debugIsPlayerStepping &&
        !game.debugHasPendingMapTransition &&
        (!game.debugIsGameplayInputLocked ||
            game.dialoguePresentationListenable.value != null ||
            game.debugBattleSessionSnapshot != null),
  );
}

Future<void> _face(PlayableMapGame game, RuntimeInputControl control) async {
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.update(.001);
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  await Future<void>.delayed(const Duration(milliseconds: 5));
}

Future<void> _walk(PlayableMapGame game, GridPos target) async {
  var attempts = 0;
  while (game.debugPlayerGridPosition != target && attempts++ < 40) {
    final current = game.debugPlayerGridPosition;
    final control = current.y != target.y
        ? current.y < target.y
              ? RuntimeInputControl.down
              : RuntimeInputControl.up
        : current.x < target.x
        ? RuntimeInputControl.right
        : RuntimeInputControl.left;
    await _step(game, control);
  }
  expect(game.debugPlayerGridPosition, target);
}
