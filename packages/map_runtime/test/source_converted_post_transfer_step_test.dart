import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeMapBundleLoader;
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
  final configured =
      Platform.environment['AVELUNE_PROGRESS_POST_TRANSFER_PROJECT'];
  final output = Platform.environment['AVELUNE_PROGRESS_POST_TRANSFER_RECEIPT'];
  testWidgets(
    'converted gate departures finish their source post-transfer step',
    (tester) async {
      await tester.runAsync(() async {
        expect(path.isAbsolute(configured!), isTrue);
        expect(await Directory(configured).resolveSymbolicLinks(), configured);
        final projectFile = path.join(configured, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(5));
        final before = await _projectHashes(configured);
        final saveRoot = await Directory.systemTemp.createTemp(
          'post-transfer-save-',
        );
        final repository = _DiskSave(path.join(saveRoot.path, 'save.json'));
        final scenarios = <Map<String, Object?>>[];
        PlayableMapGame? game;
        try {
          for (final scenario in [
            (
              sourceMapId: 21,
              sourceEventId: 6,
              mapName: 'Cerulean City',
              start: const GridPos(x: 10, y: 8),
              anchor: const GridPos(x: 10, y: 9),
              targetSourceMapId: 24,
              targetName: 'Cerulean City Houses',
              sourceTransferDirection: 2,
            ),
            (
              sourceMapId: 46,
              sourceEventId: 26,
              mapName: 'Fuchsia City',
              start: const GridPos(x: 39, y: 29),
              anchor: const GridPos(x: 39, y: 30),
              targetSourceMapId: 49,
              targetName: 'Fuchsia City Houses',
              sourceTransferDirection: 0,
            ),
          ]) {
            final mapId = manifest.maps
                .singleWhere((entry) => entry.name == scenario.mapName)
                .id;
            final targetId = manifest.maps
                .singleWhere((entry) => entry.name == scenario.targetName)
                .id;
            final source = await loadRuntimeMapBundle(
              projectFilePath: projectFile,
              mapId: mapId,
            );
            final destination = await loadRuntimeMapBundle(
              projectFilePath: projectFile,
              mapId: targetId,
            );
            expect(_collisionAt(source.map, scenario.start), isFalse);
            expect(_collisionAt(source.map, scenario.anchor), isTrue);
            expect(
              _collisionAt(destination.map, const GridPos(x: 43, y: 4)),
              isFalse,
            );
            game = await _mount(
              tester,
              projectFile,
              repository,
              GameState(
                saveId: 'post-transfer',
                currentMapId: mapId,
                playerPosition: scenario.start,
                playerFacing: EntityFacing.south,
              ),
            );
            final activations = game.debugCompletedMapActivationDispatchCount;
            expect(
              game.handleRuntimeInputEvent(
                RuntimeInputEvent.press(RuntimeInputControl.down),
              ),
              isTrue,
            );
            try {
              await _wait(
                game,
                () => game!.gameStateSnapshot.currentMapId == targetId,
              );
            } finally {
              game.handleRuntimeInputEvent(
                RuntimeInputEvent.release(RuntimeInputControl.down),
              );
            }
            await _settle(game);
            expect(
              game.debugCompletedMapActivationDispatchCount,
              greaterThan(activations),
            );
            expect(game.debugPlayerGridPosition, const GridPos(x: 43, y: 4));
            expect(game.gameStateSnapshot.playerFacing, EntityFacing.south);
            expect(await game.saveGame(), isTrue);
            final saved = (await repository.load())!;
            expect(saved.playerPosition, const GridPos(x: 43, y: 4));
            expect(saved.currentMapId, targetId);
            expect(
              saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
              isEmpty,
            );
            game.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            game = null;
            game = await _mount(
              tester,
              projectFile,
              repository,
              GameState(
                saveId: 'post-transfer',
                currentMapId: targetId,
                playerPosition: const GridPos(x: 43, y: 5),
                playerFacing: EntityFacing.south,
              ),
            );
            expect(await game.loadGame(), isTrue);
            await _settle(game);
            expect(game.debugPlayerGridPosition, saved.playerPosition);
            expect(game.gameStateSnapshot.playerFacing, saved.playerFacing);
            expect(
              game.handleRuntimeInputEvent(
                RuntimeInputEvent.press(RuntimeInputControl.down),
              ),
              isTrue,
            );
            try {
              await _wait(
                game,
                () =>
                    game!.debugPlayerGridPosition == const GridPos(x: 43, y: 5),
              );
            } finally {
              game.handleRuntimeInputEvent(
                RuntimeInputEvent.release(RuntimeInputControl.down),
              );
            }
            await _settle(game);
            expect(game.debugPlayerGridPosition, const GridPos(x: 43, y: 5));
            expect(game.gameStateSnapshot.currentMapId, targetId);
            scenarios.add({
              'sourceMapId': scenario.sourceMapId,
              'sourceEventId': scenario.sourceEventId,
              'startPosition': scenario.start.toJson(),
              'departureFacing': 'south',
              'targetSourceMapId': scenario.targetSourceMapId,
              'sourceTransferDirection': scenario.sourceTransferDirection,
              'transferPosition': const GridPos(x: 43, y: 3).toJson(),
              'postTransferPosition': saved.playerPosition.toJson(),
              'postTransferFacing': saved.playerFacing.name,
              'diskSaveAndColdReloadVerified': true,
              'movementAfterReloadVerified': true,
            });
            game.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
            game = null;
          }
          scenarios.add(
            await _blockedArrival(
              tester,
              projectFile,
              repository,
              sourceMapId: manifest.maps
                  .singleWhere((entry) => entry.name == 'Cerulean City')
                  .id,
              targetMapId: manifest.maps
                  .singleWhere((entry) => entry.name == 'Cerulean City Houses')
                  .id,
            ),
          );
          expect(await _projectHashes(configured), before);
          final receipt = {
            'kind': 'convertedPostTransferStepRuntimeQualification',
            'projectPath': configured,
            'mapCount': manifest.maps.length,
            'publicRuntimeInputUsed': true,
            'qaInitialStatePolicy':
                'Positioned in-memory GameState; no project mutation.',
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
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
      });
    },
    skip: configured == null,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

bool _collisionAt(MapData map, GridPos position) => map.layers
    .whereType<CollisionLayer>()
    .any((layer) => layer.collisions[position.y * map.size.width + position.x]);

Future<PlayableMapGame> _mount(
  WidgetTester tester,
  String projectFile,
  _DiskSave repository,
  GameState initialState, {
  RuntimeMapBundleLoader? bundleLoader,
}) async {
  final bundle = bundleLoader == null
      ? await loadRuntimeMapBundle(
          projectFilePath: projectFile,
          mapId: initialState.currentMapId,
        )
      : await bundleLoader(
          projectFilePath: projectFile,
          mapId: initialState.currentMapId,
        );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    initialGameState: initialState,
    runtimeMapBundleLoader: bundleLoader,
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

Future<Map<String, Object?>> _blockedArrival(
  WidgetTester tester,
  String projectFile,
  _DiskSave repository, {
  required String sourceMapId,
  required String targetMapId,
}) async {
  var injectedLoads = 0;
  RuntimeMapBundle? firstBundle;
  RuntimeMapBundle? injectedDestination;
  Future<RuntimeMapBundle> load({
    required String projectFilePath,
    required String mapId,
  }) async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: mapId,
      projectCatalog: firstBundle?.projectCatalog,
    );
    firstBundle ??= bundle;
    if (mapId != targetMapId) return bundle;
    final layers = [...bundle.map.layers];
    final collisionIndex = layers.indexWhere(
      (layer) => layer is CollisionLayer,
    );
    expect(collisionIndex, greaterThanOrEqualTo(0));
    final layer = layers[collisionIndex] as CollisionLayer;
    final collisions = [...layer.collisions];
    final index = 4 * bundle.map.size.width + 43;
    expect(collisions[index], isFalse);
    collisions[index] = true;
    layers[collisionIndex] = layer.copyWith(collisions: collisions);
    final injected = bundle.copyWith(map: bundle.map.copyWith(layers: layers));
    expect(_collisionAt(injected.map, const GridPos(x: 43, y: 3)), isFalse);
    injectedLoads++;
    injectedDestination = injected;
    return injected;
  }

  final game = await _mount(
    tester,
    projectFile,
    repository,
    GameState(
      saveId: 'post-transfer-blocked',
      currentMapId: sourceMapId,
      playerPosition: const GridPos(x: 10, y: 8),
      playerFacing: EntityFacing.south,
    ),
    bundleLoader: load,
  );
  try {
    var sawDepartureFade = false;
    expect(
      game.handleRuntimeInputEvent(
        RuntimeInputEvent.press(RuntimeInputControl.down),
      ),
      isTrue,
    );
    try {
      await _wait(game, () {
        sawDepartureFade = sawDepartureFade || game.debugWorldToneValue.red < 0;
        return game.gameStateSnapshot.currentMapId == targetMapId;
      });
    } finally {
      game.handleRuntimeInputEvent(
        RuntimeInputEvent.release(RuntimeInputControl.down),
      );
    }
    await _settle(game);
    expect(injectedLoads, greaterThan(0));
    expect(sawDepartureFade, isTrue);
    expect(game.gameStateSnapshot.currentMapId, targetMapId);
    expect(game.debugPlayerGridPosition, const GridPos(x: 43, y: 3));
    final tone = game.debugWorldToneValue;
    expect([tone.red, tone.green, tone.blue, tone.gray], everyElement(0));
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    expect(
      game.handleRuntimeInputEvent(
        RuntimeInputEvent.press(RuntimeInputControl.down),
      ),
      isTrue,
    );
    try {
      for (var tick = 0; tick < 30; tick++) {
        game.update(0.016);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    } finally {
      game.handleRuntimeInputEvent(
        RuntimeInputEvent.release(RuntimeInputControl.down),
      );
    }
    await _settle(game);
    expect(game.debugPlayerGridPosition, const GridPos(x: 43, y: 3));
    final map = injectedDestination!.map;
    final lateral = [
      (RuntimeInputControl.left, const GridPos(x: 42, y: 3)),
      (RuntimeInputControl.right, const GridPos(x: 44, y: 3)),
    ].where((entry) => !_collisionAt(map, entry.$2)).firstOrNull;
    if (lateral != null) {
      expect(
        game.handleRuntimeInputEvent(RuntimeInputEvent.press(lateral.$1)),
        isTrue,
      );
      try {
        await _wait(game, () => game.debugPlayerGridPosition == lateral.$2);
      } finally {
        game.handleRuntimeInputEvent(RuntimeInputEvent.release(lateral.$1));
      }
      await _settle(game);
      expect(game.debugPlayerGridPosition, lateral.$2);
    }
    return {
      'sourceMapId': 21,
      'sourceEventId': 6,
      'targetSourceMapId': 24,
      'inMemoryCollisionInjectionOnly': const GridPos(x: 43, y: 4).toJson(),
      'blockedArrivalPosition': const GridPos(x: 43, y: 3).toJson(),
      'departureFadeObserved': sawDepartureFade,
      'neutralToneRestored': true,
      'overworldInputRestored': true,
      'blockedDownInputAccepted': true,
      'lateralMovementVerified': lateral != null,
      if (lateral == null)
        'lateralMovementLimit': 'Both adjacent source tiles are blocked.',
    };
  } finally {
    game.onRemove();
    await tester.pumpWidget(const SizedBox.shrink());
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
    'Post-transfer did not settle: map=${game.gameStateSnapshot.currentMapId}, '
    'position=${game.debugPlayerGridPosition}, phase=${game.debugFlowPhaseName}, '
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
