import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioEvents = MethodChannel('xyz.luan/audioplayers.global/events');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEvents, (call) async {
          if (call.method != 'listen' && call.method != 'cancel') {
            throw UnsupportedError(call.method);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEvents, null);
  });
  final configured = Platform.environment['AVELUNE_INVENTORY_GATES_PROJECT'];
  final output = Platform.environment['AVELUNE_INVENTORY_GATES_RECEIPT'];
  testWidgets(
    'converted inventory gates and Tea donor execute and persist',
    (tester) async {
      await tester.runAsync(() async {
        expect(path.isAbsolute(configured!), isTrue);
        expect(await Directory(configured).resolveSymbolicLinks(), configured);
        final projectFile = path.join(configured, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(4));
        String mapId(String name) =>
            manifest.maps.singleWhere((map) => map.name == name).id;
        final islandId = mapId('Cinnabar Island');
        final gymId = mapId('Cinnabar Gym');
        final mansionId = mapId('Celadon Mansion');
        String factId(int map, int event) => manifest.facts
            .singleWhere(
              (fact) =>
                  fact.description.endsWith(':map:$map:event:$event:self:A'),
            )
            .id;
        final doorFact = factId(58, 11);
        final controllerFact = factId(58, 16);
        final teaFact = factId(42, 5);
        final catalogFile = path.join(
          configured,
          manifest.pokemon.catalogFiles['items']!,
        );
        final catalog = ProjectItemCatalog.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(await File(catalogFile).readAsString()) as Map,
          ),
        );
        String itemId(String name) => catalog.entries
            .singleWhere(
              (item) =>
                  item.displayName.toLowerCase().replaceAll(' ', '') == name,
            )
            .id;
        final secretKeyId = itemId('secretkey');
        final teaId = itemId('tea');
        final before = await _projectHashes(configured);
        final saveRoot = await Directory.systemTemp.createTemp(
          'inventory-gates-save-',
        );
        final repository = _DiskSave(path.join(saveRoot.path, 'save.json'));
        final scenarios = <Map<String, Object?>>[];
        PlayableMapGame? game;
        Future<void> unmount() async {
          game?.onRemove();
          game = null;
          await tester.pumpWidget(const SizedBox.shrink());
        }

        try {
          GameState islandState({bool withKey = false}) => GameState(
            saveId: 'inventory-gates',
            currentMapId: islandId,
            playerPosition: const GridPos(x: 26, y: 5),
            playerFacing: EntityFacing.north,
            bag: Bag(
              entries: [
                if (withKey) BagEntry(itemId: secretKeyId, quantity: 1),
              ],
            ),
          );
          game = await _mount(tester, projectFile, repository, islandState());
          expect(_fact(game!, manifest, doorFact), isFalse);
          expect(_fact(game!, manifest, controllerFact), isFalse);
          _press(game!, RuntimeInputControl.primary);
          await _wait(
            game!,
            () => game!.dialoguePresentationListenable.value != null,
          );
          final lockedText =
              game!.dialoguePresentationListenable.value!.fullText;
          expect(lockedText.toLowerCase(), contains('door is locked'));
          await _finishDialogue(game!);
          expect(game!.gameStateSnapshot.currentMapId, islandId);
          expect(game!.debugPlayerGridPosition, const GridPos(x: 26, y: 5));
          expect(_fact(game!, manifest, doorFact), isFalse);
          expect(_fact(game!, manifest, controllerFact), isFalse);
          final activations = game!.debugCompletedMapActivationDispatchCount;
          await _ticks(game!, 120);
          expect(game!.debugCompletedMapActivationDispatchCount, activations);
          await _settle(game!);
          scenarios.add({
            'sourceMapId': 58,
            'sourceEventId': 11,
            'keyPresent': false,
            'lockedText': lockedText,
            'transferPrevented': true,
            'controllerRemainedInactive': true,
            'idleFramesWithoutRedispatch': 120,
          });
          await unmount();
          game = await _mount(
            tester,
            projectFile,
            repository,
            islandState(withKey: true),
          );
          expect(_quantity(game!, secretKeyId), 1);
          expect(_fact(game!, manifest, doorFact), isTrue);
          expect(_fact(game!, manifest, controllerFact), isTrue);
          expect(
            game!.handleRuntimeInputEvent(
              RuntimeInputEvent.press(RuntimeInputControl.up),
            ),
            isTrue,
          );
          try {
            await _wait(
              game!,
              () => game!.gameStateSnapshot.currentMapId == gymId,
            );
          } finally {
            game!.handleRuntimeInputEvent(
              RuntimeInputEvent.release(RuntimeInputControl.up),
            );
          }
          final transferPosition = game!.debugPlayerGridPosition;
          expect(transferPosition, const GridPos(x: 27, y: 25));
          await _settle(game!);
          expect(_fact(game!, manifest, doorFact), isTrue);
          expect(_fact(game!, manifest, controllerFact), isTrue);
          expect(await game!.saveGame(), isTrue);
          final keySave = (await repository.load())!;
          final arrivalPosition = game!.debugPlayerGridPosition;
          await unmount();
          game = await _mount(tester, projectFile, repository, islandState());
          expect(await game!.loadGame(), isTrue);
          await _settle(game!);
          expect(game!.gameStateSnapshot.currentMapId, gymId);
          expect(game!.debugPlayerGridPosition, arrivalPosition);
          expect(
            game!.gameStateSnapshot.narrativeFactRuntimeState,
            keySave.narrativeFactRuntimeState,
          );
          expect(_quantity(game!, secretKeyId), 1);
          expect(_fact(game!, manifest, doorFact), isTrue);
          expect(_fact(game!, manifest, controllerFact), isTrue);
          final latchedState = GameState(
            saveId: 'key-latched-without-key',
            currentMapId: islandId,
            playerPosition: const GridPos(x: 26, y: 5),
            playerFacing: EntityFacing.north,
            narrativeFactRuntimeState: keySave.narrativeFactRuntimeState,
          );
          await unmount();
          game = await _mount(tester, projectFile, repository, latchedState);
          expect(_quantity(game!, secretKeyId), 0);
          expect(_fact(game!, manifest, doorFact), isTrue);
          expect(_fact(game!, manifest, controllerFact), isTrue);
          final latchedActivations =
              game!.debugCompletedMapActivationDispatchCount;
          await _ticks(game!, 120);
          expect(
            game!.debugCompletedMapActivationDispatchCount,
            latchedActivations,
          );
          await _settle(game!);
          scenarios.add({
            'sourceMapId': 58,
            'sourceEventId': 16,
            'qaKeySeed': {
              'itemId': secretKeyId,
              'quantity': 1,
              'remoteAcquisitionCertified': false,
            },
            'targetSourceMapId': 62,
            'transferPosition': transferPosition.toJson(),
            'arrivalPosition': arrivalPosition.toJson(),
            'doorFactId': doorFact,
            'controllerFactId': controllerFact,
            'mapEnterLatchBeforeInputVerified': true,
            'latchPersistsWithoutKeySeedVerified': true,
            'diskSaveAndColdReloadVerified': true,
          });
          await unmount();
          final teaStart = GameState(
            saveId: 'tea-donor',
            currentMapId: mansionId,
            playerPosition: const GridPos(x: 5, y: 11),
            playerFacing: EntityFacing.west,
          );
          game = await _mount(tester, projectFile, repository, teaStart);
          expect(_quantity(game!, teaId), 0);
          expect(_fact(game!, manifest, teaFact), isFalse);
          _press(game!, RuntimeInputControl.left);
          await _ticks(game!, 8);
          await _settle(game!);
          expect(game!.debugPlayerGridPosition, const GridPos(x: 5, y: 11));
          expect(game!.gameStateSnapshot.playerFacing, EntityFacing.west);
          _press(game!, RuntimeInputControl.primary);
          await _wait(
            game!,
            () => game!.dialoguePresentationListenable.value != null,
          );
          final firstDialogue = await _finishDialogue(game!);
          expect(firstDialogue, isNotEmpty);
          expect(_quantity(game!, teaId), 1);
          expect(_fact(game!, manifest, teaFact), isTrue);
          _press(game!, RuntimeInputControl.primary);
          await _wait(
            game!,
            () => game!.dialoguePresentationListenable.value != null,
          );
          final repeatedDialogue = await _finishDialogue(game!);
          expect(repeatedDialogue, isNotEmpty);
          expect(_quantity(game!, teaId), 1);
          expect(await game!.saveGame(), isTrue);
          final teaSave = (await repository.load())!;
          await unmount();
          game = await _mount(tester, projectFile, repository, teaStart);
          expect(await game!.loadGame(), isTrue);
          await _settle(game!);
          expect(
            game!.gameStateSnapshot.narrativeFactRuntimeState,
            teaSave.narrativeFactRuntimeState,
          );
          expect(_fact(game!, manifest, teaFact), isTrue);
          expect(_quantity(game!, teaId), 1);
          _press(game!, RuntimeInputControl.primary);
          await _wait(
            game!,
            () => game!.dialoguePresentationListenable.value != null,
          );
          await _finishDialogue(game!);
          expect(_quantity(game!, teaId), 1);
          scenarios.add({
            'sourceMapId': 42,
            'sourceEventId': 5,
            'qaStartPosition': teaStart.playerPosition.toJson(),
            'qaStartFacing': teaStart.playerFacing.name,
            'itemId': teaId,
            'firstDialogue': firstDialogue,
            'repeatedDialogue': repeatedDialogue,
            'grantQuantity': 1,
            'repeatGrantPrevented': true,
            'selfSwitchFactId': teaFact,
            'diskSaveAndColdReloadVerified': true,
            'repeatAfterReloadVerified': true,
          });
          await unmount();
          expect(await _projectHashes(configured), before);
          final receipt = {
            'kind': 'convertedInventoryGatesRuntimeQualification',
            'projectPath': configured,
            'mapCount': manifest.maps.length,
            'publicRuntimeInputUsed': true,
            'audioPlayback': 'validatedMediaReferencesWithHeadlessPlaybackPort',
            'audibleOutputCertified': false,
            'scenarios': scenarios,
            'projectFilesUnchanged': true,
            'fileHashes': before,
            'combatRulesModified': false,
            'battleExecutionCertified': false,
            'fullCampaignCertified': false,
            'sourceScriptsExecuted': 0,
          };
          if (output != null) {
            expect(path.isAbsolute(output), isTrue);
            expect(path.isWithin(configured, output), isFalse);
            await File(output).writeAsString(jsonEncode(receipt), flush: true);
          }
          stdout.writeln(
            jsonEncode({
              'kind': receipt['kind'],
              'scenarios': scenarios,
              'projectFilesUnchanged': true,
              'projectFileCount': before.length,
              'receiptPath': output,
            }),
          );
        } finally {
          await unmount();
          await saveRoot.delete(recursive: true);
        }
      });
    },
    skip: configured == null,
    timeout: const Timeout(Duration(minutes: 4)),
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
    .fold(0, (total, entry) => total + entry.quantity);

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<List<String>> _finishDialogue(PlayableMapGame game) async {
  final lines = <String>[];
  for (var count = 0; count < 80; count++) {
    final presentation = game.dialoguePresentationListenable.value;
    if (presentation != null) {
      if (lines.isEmpty || lines.last != presentation.fullText) {
        lines.add(presentation.fullText);
      }
      _press(game, RuntimeInputControl.primary);
      await _ticks(game, 2);
    } else if (_idle(game)) {
      await _settle(game);
      return lines;
    } else {
      await _ticks(game, 4);
    }
  }
  fail(
    'Dialogue did not finish: ${game.dialoguePresentationListenable.value?.fullText}',
  );
}

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<PlayableMapGame> _mount(
  WidgetTester tester,
  String projectFile,
  _DiskSave repository,
  GameState initialState,
) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: initialState.currentMapId,
  );
  expect(
    bundle.map.layers.whereType<CollisionLayer>().any(
      (layer) =>
          layer.collisions[initialState.playerPosition.y *
                  bundle.map.size.width +
              initialState.playerPosition.x],
    ),
    isFalse,
    reason: 'The QA start position must be on a walkable source tile.',
  );
  final audio = _SceneSoundTrace(bundle);
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    initialGameState: initialState,
    sceneSoundEffectPlaybackPort: audio,
    dialogueFeedbackPlaybackPort: audio,
  );
  try {
    game.onGameResize(Vector2(320, 240));
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
    await _wait(
      game,
      () => game.debugCompletedMapActivationDispatchCount > 0 && _idle(game),
    );
    await _settle(game);
    expect(game.debugPlayerGridPosition, initialState.playerPosition);
    return game;
  } catch (_) {
    game.onRemove();
    rethrow;
  }
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition &&
    !game.debugIsPlayerStepping;

Future<void> _settle(PlayableMapGame game) async {
  var quietFrames = 0;
  await _wait(game, () {
    quietFrames =
        _idle(game) &&
            game.dialoguePresentationListenable.value == null &&
            game.inputAuthoritySnapshot.acceptsOverworldInput
        ? quietFrames + 1
        : 0;
    return quietFrames >= 20;
  });
  expect(game.debugIsPlayerVisible, isTrue);
}

Future<void> _wait(PlayableMapGame game, bool Function() complete) async {
  final elapsed = Stopwatch()..start();
  for (
    var tick = 0;
    tick < 4000 && elapsed.elapsed < const Duration(seconds: 30);
    tick++
  ) {
    if (complete()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Inventory gate did not settle: map=${game.gameStateSnapshot.currentMapId}, '
    'position=${game.debugPlayerGridPosition}, facing=${game.gameStateSnapshot.playerFacing}, phase=${game.debugFlowPhaseName}, '
    'input=${game.inputAuthoritySnapshot.acceptsOverworldInput}, '
    'dialogue=${game.dialoguePresentationListenable.value?.fullText}',
  );
}

Future<Map<String, String>> _projectHashes(String root) async {
  final result = <String, String>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      result[path.relative(entry.path, from: root)] = crypto.sha256
          .convert(await entry.readAsBytes())
          .toString();
    } else if (entry is Link) {
      fail('Qualification projects must not contain symlinks: ${entry.path}');
    }
  }
  return result;
}

final class _SceneSoundTrace
    implements SceneSoundEffectPlaybackPort, DialogueFeedbackPlaybackPort {
  _SceneSoundTrace(this.bundle);
  final RuntimeMapBundle bundle;

  @override
  Future<void> playCue(DialogueAudioCue cue, {required String playbackId}) =>
      playSoundEffect(cue.mediaAssetId, volume: cue.volume, playbackId: playbackId);

  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    final asset = bundle.manifest.cinematicMediaAssets.singleWhere(
      (asset) => asset.id == mediaAssetId,
    );
    expect(asset.kind, CinematicMediaAssetKind.sound);
    expect(volume, inInclusiveRange(0.0, 1.0));
    expect(playbackId, isNotEmpty);
    expect(
      await File(path.join(bundle.projectRootDirectory, asset.relativePath))
          .exists(),
      isTrue,
    );
  }
}

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}
