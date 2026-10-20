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

const _city = 'map_27c95c67fd0e65a40ddbaa3764cd75fa7da3a00ee21f59703570e337';
const _gym = 'map_68b32fba920a2a863000f9684012a59937e5d2b625b9aff8d1b00e98';
const _islandExterior =
    'map_1544cbf1db4f4c66910e694cf6246fca44371f12300d82b3178955b6';
const _port = 'map_15f832aa43c224638a7e25d282904accb454b43b7d3c1710715a2514';
const _harbor = 'map_84d1f1309e98c1f5bde50e35e49896cc0e38e86b5efe4dbb936bdaef';
const _islandInterior =
    'map_73a655af02da2b75a1604a20b0dd0dbb4cdb6ad24276d8038b14347d';
const _gymProgress = 'fact_source_variable_1fccbb7d9a00d7e5c64cb471';
const _harborVisited = 'fact_source_event_80a342671ea8dff6a1f6026d_switch_86';

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
  final configured =
      Platform.environment['AVELUNE_STANDARD_DOORS_PROJECT_PATH'];
  final output = Platform.environment['AVELUNE_STANDARD_DOORS_RECEIPT'];
  testWidgets(
    'published Kanto progression doors retain conditions transfers and saved consequences',
    (tester) async {
      await tester.runAsync(() async {
        expect(path.isAbsolute(configured!), isTrue);
        expect(await Directory(configured).resolveSymbolicLinks(), configured);
        final projectFile = path.join(configured, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        expect(
          manifest.facts
              .singleWhere((fact) => fact.id == _gymProgress)
              .valueKind,
          NarrativeValueKind.integer,
        );
        expect(
          manifest.facts
              .singleWhere((fact) => fact.id == _harborVisited)
              .valueKind,
          NarrativeValueKind.boolean,
        );
        final files = <String>[
          projectFile,
          for (final mapId in [
            _city,
            _gym,
            _harbor,
            _port,
            _islandInterior,
            _islandExterior,
          ])
            path.join(
              configured,
              manifest.maps
                  .singleWhere((entry) => entry.id == mapId)
                  .relativePath,
            ),
        ];
        final before = {for (final file in files) file: await _hash(file)};
        final saveRoot = await Directory.systemTemp.createTemp(
          'kanto-progression-save-',
        );
        final repository = _DiskSave(path.join(saveRoot.path, 'save.json'));
        final scenarios = <Map<String, Object?>>[];
        PlayableMapGame? game;
        try {
          game = await _start(
            tester,
            projectFile,
            repository,
            mapId: _city,
            position: const GridPos(x: 36, y: 11),
            facing: EntityFacing.north,
            gymProgress: 6,
          );
          _press(game, RuntimeInputControl.primary);
          await _waitUntil(
            game,
            () => game!.dialoguePresentationListenable.value != null,
          );
          final lockedLine =
              game.dialoguePresentationListenable.value!.fullText;
          expect(lockedLine.toLowerCase(), contains('locked'));
          expect(game.gameStateSnapshot.currentMapId, _city);
          expect(game.debugPlayerGridPosition, const GridPos(x: 36, y: 11));
          await _finishDialogue(game);
          _expectControl(game);
          scenarios.add({
            'sourceMapId': 10,
            'sourceEventId': 26,
            'variable30': 6,
            'lockedDialogue': lockedLine,
            'transferRefused': true,
            'controlRestored': true,
          });
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;

          game = await _start(
            tester,
            projectFile,
            repository,
            mapId: _city,
            position: const GridPos(x: 36, y: 11),
            facing: EntityFacing.north,
            gymProgress: 7,
          );
          await _transfer(
            game,
            RuntimeInputControl.up,
            destinationMapId: _gym,
            destination: const GridPos(x: 19, y: 24),
          );
          await _transfer(
            game,
            RuntimeInputControl.down,
            destinationMapId: _city,
            destination: const GridPos(x: 36, y: 11),
          );
          game = await _saveAndColdReload(
            tester,
            game,
            projectFile,
            repository,
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
              _gymProgress,
            ),
            NarrativeValue.integer(7),
          );
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 35, y: 11),
          );
          scenarios.add({
            'sourceMapId': 10,
            'sourceEventId': 26,
            'returnSourceMapId': 14,
            'returnSourceEventId': 1,
            'variable30': 7,
            'gymRoundTripVerified': true,
            'returnPosition': const GridPos(x: 36, y: 11).toJson(),
            'diskSaveAndColdReloadVerified': true,
            'movementAfterReloadVerified': true,
          });
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;

          game = await _start(
            tester,
            projectFile,
            repository,
            mapId: _harbor,
            position: const GridPos(x: 10, y: 5),
            facing: EntityFacing.north,
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .valueFor(_harborVisited)
                    ?.boolValue ??
                false,
            isFalse,
          );
          await _transfer(
            game,
            RuntimeInputControl.up,
            destinationMapId: _port,
            destination: const GridPos(x: 12, y: 13),
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
              _harborVisited,
            ),
            const NarrativeValue.boolean(true),
          );
          game = await _saveAndColdReload(
            tester,
            game,
            projectFile,
            repository,
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
              _harborVisited,
            ),
            const NarrativeValue.boolean(true),
          );
          await _move(
            game,
            RuntimeInputControl.right,
            const GridPos(x: 13, y: 13),
          );
          scenarios.add({
            'sourceMapId': 256,
            'sourceEventId': 2,
            'destinationSourceMapId': 241,
            'destinationPosition': const GridPos(x: 12, y: 13).toJson(),
            'switch86Before': false,
            'switch86After': true,
            'diskSaveAndColdReloadVerified': true,
            'movementAfterReloadVerified': true,
          });
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;

          game = await _start(
            tester,
            projectFile,
            repository,
            mapId: _islandInterior,
            position: const GridPos(x: 15, y: 20),
            facing: EntityFacing.south,
          );
          await _transfer(
            game,
            RuntimeInputControl.down,
            destinationMapId: _islandExterior,
            destination: const GridPos(x: 28, y: 10),
          );
          await _move(
            game,
            RuntimeInputControl.down,
            const GridPos(x: 28, y: 11),
          );
          scenarios.add({
            'sourceMapId': 257,
            'sourceEventId': 3,
            'destinationSourceMapId': 142,
            'destinationPosition': const GridPos(x: 28, y: 10).toJson(),
            'departureVerified': true,
            'controlRestored': true,
            'northwardArrivalBranchVerified': false,
            'arrivalBranchLimit': 'The standard source arrival is (15,20), outside event anchor (15,21).',
          });
          for (final entry in before.entries) {
            expect(
              await _hash(entry.key),
              entry.value,
              reason: 'Runtime QA must not modify the published project.',
            );
          }
          final receipt = {
            'kind':
                'publishedKantoStandardProgressionDoorsRuntimeQualification',
            'projectPath': configured,
            'mapCount': manifest.maps.length,
            'qaInitialStatePolicy': 'In-memory positioned GameState with declared progression facts; project files unchanged.',
            'publicRuntimeInputUsed': true,
            'scenarios': scenarios,
            'projectAndSixMapsUnchanged': true,
            'fileHashes': before,
            'combatRulesModified': false,
            'nativeAveluneBattlesRetained': true,
            'battleExecutionCertified': false,
            'studioGuiCertified': false,
            'fullCampaignCertified': false,
            'sourceScriptsExecuted': 0,
          };
          if (output != null) {
            expect(path.isAbsolute(output), isTrue);
            await File(output).writeAsString(jsonEncode(receipt), flush: true);
          }
          stdout.writeln(jsonEncode(receipt));
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
      });
    },
    skip: configured == null,
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

Future<PlayableMapGame> _start(
  WidgetTester tester,
  String projectFile,
  _DiskSave repository, {
  required String mapId,
  required GridPos position,
  required EntityFacing facing,
  int? gymProgress,
}) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: mapId,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    initialGameState: GameState(
      saveId: 'standard-progression-doors',
      currentMapId: mapId,
      playerPosition: position,
      playerFacing: facing,
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: {
          if (gymProgress != null)
            _gymProgress: NarrativeValue.integer(gymProgress),
        },
      ),
    ),
    sceneSoundEffectPlaybackPort: _SceneSoundTrace(bundle),
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
    await _waitUntil(
      game,
      () => game.debugCompletedMapActivationDispatchCount > 0 && _idle(game),
    );
    await _settle(game);
    _expectControl(game);
    expect(game.gameStateSnapshot.currentMapId, mapId);
    expect(game.debugPlayerGridPosition, position);
    return game;
  } catch (_) {
    game.onRemove();
    rethrow;
  }
}

Future<void> _transfer(
  PlayableMapGame game,
  RuntimeInputControl control, {
  required String destinationMapId,
  required GridPos destination,
}) async {
  final sourceMapId = game.gameStateSnapshot.currentMapId;
  expect(sourceMapId, isNot(destinationMapId));
  final activationCount = game.debugCompletedMapActivationDispatchCount;
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  try {
    await _waitUntil(
      game,
      () => game.gameStateSnapshot.currentMapId == destinationMapId,
    );
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await _settle(game);
  expect(
    game.debugCompletedMapActivationDispatchCount,
    greaterThan(activationCount),
  );
  expect(game.gameStateSnapshot.currentMapId, destinationMapId);
  expect(game.debugPlayerGridPosition, destination);
  _expectControl(game);
}

Future<PlayableMapGame> _saveAndColdReload(
  WidgetTester tester,
  PlayableMapGame game,
  String projectFile,
  _DiskSave repository,
) async {
  await _settle(game);
  expect(await game.saveGame(), isTrue);
  final saved = (await repository.load())!;
  expect(saved.currentMapId, game.gameStateSnapshot.currentMapId);
  expect(saved.playerPosition, game.debugPlayerGridPosition);
  expect(
    saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
    isEmpty,
  );
  game.onRemove();
  await tester.pumpWidget(const SizedBox.shrink());
  final reloaded = await _start(
    tester,
    projectFile,
    repository,
    mapId: saved.currentMapId,
    position: saved.playerPosition,
    facing: saved.playerFacing,
  );
  try {
    expect(await reloaded.loadGame(), isTrue);
    await _settle(reloaded);
    expect(reloaded.gameStateSnapshot.currentMapId, saved.currentMapId);
    expect(reloaded.debugPlayerGridPosition, saved.playerPosition);
    expect(
      reloaded.gameStateSnapshot.narrativeFactRuntimeState,
      saved.narrativeFactRuntimeState,
    );
    _expectControl(reloaded);
    return reloaded;
  } catch (_) {
    reloaded.onRemove();
    rethrow;
  }
}

Future<void> _move(
  PlayableMapGame game,
  RuntimeInputControl control,
  GridPos destination,
) async {
  final mapId = game.gameStateSnapshot.currentMapId;
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  try {
    await _waitUntil(game, () => game.debugPlayerGridPosition == destination);
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await _settle(game);
  expect(game.gameStateSnapshot.currentMapId, mapId);
  expect(game.debugPlayerGridPosition, destination);
  _expectControl(game);
}

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<void> _finishDialogue(PlayableMapGame game) async {
  for (
    var count = 0;
    count < 12 && game.dialoguePresentationListenable.value != null;
    count++
  ) {
    _press(game, RuntimeInputControl.primary);
    await _ticks(game, 2);
  }
  await _settle(game);
  expect(game.dialoguePresentationListenable.value, isNull);
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

void _expectControl(PlayableMapGame game) {
  expect(_idle(game), isTrue);
  expect(game.debugIsPlayerVisible, isTrue);
  expect(game.dialoguePresentationListenable.value, isNull);
  expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
}

Future<void> _settle(PlayableMapGame game) async {
  var quietFrames = 0;
  await _waitUntil(game, () {
    quietFrames =
        _idle(game) &&
            game.dialoguePresentationListenable.value == null &&
            game.inputAuthoritySnapshot.acceptsOverworldInput
        ? quietFrames + 1
        : 0;
    return quietFrames >= 20;
  });
}

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() complete) async {
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
    'Standard door did not settle: '
    'map=${game.gameStateSnapshot.currentMapId}, '
    'position=${game.debugPlayerGridPosition}, '
    'phase=${game.debugFlowPhaseName}, '
    'dialogue=${game.dialoguePresentationListenable.value?.fullText}, '
    'input=${game.inputAuthoritySnapshot.acceptsOverworldInput}',
  );
}

Future<String> _hash(String file) async =>
    crypto.sha256.convert(await File(file).readAsBytes()).toString();

final class _SceneSoundTrace implements SceneSoundEffectPlaybackPort {
  _SceneSoundTrace(this.bundle);
  final RuntimeMapBundle bundle;

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
