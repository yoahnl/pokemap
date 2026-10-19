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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_LOT4_DOORS_REFERENCE'];
  testWidgets(
    'converted doors restore control, contact and finite routes across a cold disk reload',
    (tester) async {
      await tester.runAsync(() async {
        final reference = Map<String, dynamic>.from(
          jsonDecode(await File(referencePath!).readAsString()) as Map,
        );
        expect(reference['kind'], 'originalLot4DoorsReference');
        expect(reference['nativeWriterVerified'], isTrue);
        expect(reference['sourceScriptsExecuted'], 0);
        expect(reference['aiCalls'], 0);
        expect(reference['manualStudioCertified'], isFalse);
        expect(reference['manualPlayerCertified'], isFalse);
        final projectFile = reference['projectFilePath'] as String;
        final sourceRoot = reference['sourceRootPath'] as String;
        final nativeRoot = path.dirname(projectFile);
        expect(await _hashes(sourceRoot), reference['sourceHashesBefore']);
        expect(await _hashes(nativeRoot), reference['nativeHashes']);
        final mapIds = reference['mapIds'] as Map;
        final firstMap = mapIds['42'] as String;
        final secondMap = mapIds['43'] as String;
        final ids = reference['entityIds'] as Map;
        final routedNpc = ids['$firstMap:Finite routed NPC'] as String;
        final projection =
            (reference['sourceEvents'] as Map)['projection'] as Map;
        expect(projection['qualifiedEventCount'], 5);
        expect(projection['quarantinedEventCount'], 1);
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile,
          mapId: firstMap,
        );
        final invisibleIds = [
          for (final entry in ids.entries)
            if ((entry.key as String).endsWith(':Invisible paired door'))
              entry.value as String,
        ];
        final invisibleRoutes = bundle.manifest.scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.interactiveCommand)
            .whereType<SceneActorRouteInteractiveCommand>()
            .where((command) => invisibleIds.contains(command.target.entityId));
        expect(invisibleRoutes, isEmpty);
        final saveRoot = await Directory.systemTemp.createTemp(
          'lot4-doors-save-',
        );
        final savePath = path.join(saveRoot.path, 'save.json');
        PlayableMapGame? game;
        try {
          game = await _start(
            tester,
            projectFile,
            firstMap,
            _DiskSave(savePath),
          );
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 2, y: 2),
            facing: Direction.north,
          );
          await _move(
            game,
            RuntimeInputControl.right,
            const GridPos(x: 3, y: 2),
          );
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 2, y: 2),
          );
          await _door(game, secondMap);
          expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
          expect(game.debugIsPlayerVisible, isTrue);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          await _move(
            game,
            RuntimeInputControl.right,
            const GridPos(x: 3, y: 2),
          );
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 2, y: 2),
          );
          await _door(game, firstMap);
          expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
          expect(game.debugIsPlayerVisible, isTrue);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          await _collision(game);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 1, y: 3),
            facing: Direction.south,
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          );
          await _waitUntil(
            game,
            () =>
                game!.dialoguePresentationListenable.value?.fullText ==
                'Touch one.',
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          );
          expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 4));
          await _finishDialogue(game);
          await _move(game, RuntimeInputControl.up, const GridPos(x: 1, y: 3));
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 3, y: 3),
            facing: Direction.south,
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          );
          await _waitUntil(
            game,
            () =>
                game!.dialoguePresentationListenable.value?.fullText ==
                'Touch two.',
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          );
          expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 3));
          await _finishDialogue(game);
          await _move(game, RuntimeInputControl.up, const GridPos(x: 3, y: 2));
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 5, y: 3),
            facing: Direction.south,
          );
          await _interact(game, 'Before routes.');
          _advance(game);
          var npcMoved = false;
          var playerMoved = false;
          var lockedDuringRoute = false;
          await _waitUntil(game, () {
            npcMoved |=
                game!.debugNpcGridPosition(routedNpc) ==
                const GridPos(x: 6, y: 4);
            playerMoved |=
                game.debugPlayerGridPosition == const GridPos(x: 6, y: 3);
            if (npcMoved || playerMoved) {
              lockedDuringRoute |= game.inputAuthoritySnapshot.isGameplayLocked;
            }
            return game.dialoguePresentationListenable.value?.fullText ==
                'After routes.';
          });
          expect(npcMoved, isTrue);
          expect(playerMoved, isTrue);
          expect(lockedDuringRoute, isTrue);
          expect(
            game.debugNpcGridPosition(routedNpc),
            const GridPos(x: 5, y: 4),
          );
          expect(game.debugPlayerGridPosition, const GridPos(x: 5, y: 3));
          await _finishDialogue(game);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 4, y: 3),
          );
          await _collision(game);
          expect(await game.saveGame(), isTrue);
          final saved = (await _DiskSave(savePath).load())!;
          expect(saved.currentMapId, firstMap);
          expect(saved.playerPosition, const GridPos(x: 6, y: 1));
          expect(
            saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
            isEmpty,
          );
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;
          game = await _start(
            tester,
            projectFile,
            firstMap,
            _DiskSave(savePath),
          );
          expect(await game.loadGame(), isTrue);
          await _waitUntil(game, () => _idle(game!));
          expect(game.debugPlayerGridPosition, const GridPos(x: 6, y: 1));
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          await _collision(game);
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 5, y: 1),
          );
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 2, y: 2),
            facing: Direction.north,
          );
          await _door(game, secondMap);
          expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
          expect(game.debugIsPlayerVisible, isTrue);
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
        expect(await _hashes(sourceRoot), reference['sourceHashesBefore']);
        expect(await _hashes(nativeRoot), reference['nativeHashes']);
      });
    },
    skip: referencePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _door(PlayableMapGame game, String destination) async {
  var hidden = false;
  var locked = false;
  final before = game.debugCompletedMapActivationDispatchCount;
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.up),
    ),
    isTrue,
  );
  try {
    await _waitUntil(game, () {
      hidden |= !game.debugIsPlayerVisible;
      locked |= game.inputAuthoritySnapshot.isGameplayLocked;
      return game.gameStateSnapshot.currentMapId == destination &&
          game.debugPlayerGridPosition == const GridPos(x: 2, y: 2) &&
          _idle(game);
    });
  } finally {
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.up),
    );
  }
  expect(hidden, isTrue);
  expect(locked, isTrue);
  expect(game.debugCompletedMapActivationDispatchCount, before + 1);
  await _ticks(game, 30);
  expect(game.gameStateSnapshot.currentMapId, destination);
  expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
}

Future<void> _collision(PlayableMapGame game) async {
  game.debugSetPlayerStateForTest(
    position: const GridPos(x: 6, y: 1),
    facing: Direction.north,
  );
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.up),
    ),
    isTrue,
  );
  await _ticks(game, 24);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.up),
  );
  expect(game.debugPlayerGridPosition, const GridPos(x: 6, y: 1));
  expect(game.debugIsPlayerStepping, isFalse);
  expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
}

Future<void> _move(
  PlayableMapGame game,
  RuntimeInputControl control,
  GridPos destination,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  try {
    await _waitUntil(game, () => game.debugPlayerGridPosition == destination);
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await _waitUntil(game, () => !game.debugIsPlayerStepping && _idle(game));
  expect(game.debugPlayerGridPosition, destination);
}

Future<PlayableMapGame> _start(
  WidgetTester tester,
  String projectFile,
  String mapId,
  FileGameSaveRepository repository,
) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: mapId,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    initialGameState: GameState(
      saveId: 'lot4-doors',
      currentMapId: bundle.map.id,
    ),
  );
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
    () =>
        game.debugCompletedMapActivationDispatchCount > 0 &&
        _idle(game) &&
        game.inputAuthoritySnapshot.acceptsOverworldInput,
  );
  await _ticks(game, 2);
  await _waitUntil(game, () => _idle(game));
  return game;
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition;

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<void> _interact(PlayableMapGame game, String line) async {
  expect(_idle(game), isTrue);
  _press(game, RuntimeInputControl.primary);
  await _waitUntil(
    game,
    () => game.dialoguePresentationListenable.value != null,
  );
  expect(game.dialoguePresentationListenable.value!.fullText, line);
}

void _advance(PlayableMapGame game) {
  if (!game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed) {
    _press(game, RuntimeInputControl.primary);
    expect(
      game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
      isTrue,
    );
  }
  _press(game, RuntimeInputControl.primary);
}

Future<void> _finishDialogue(PlayableMapGame game) async {
  _advance(game);
  await _waitUntil(game, () => _idle(game));
  expect(game.dialoguePresentationListenable.value, isNull);
}

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 480; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'LOT4 doors did not settle: phase=${game.debugFlowPhaseName}, '
    'position=${game.debugPlayerGridPosition}',
  );
}

Future<Map<String, String>> _hashes(String root) async {
  final entries = <String, String>{};
  await for (final entity in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      entries[path.relative(entity.path, from: root)] = crypto.sha256
          .convert(await entity.readAsBytes())
          .toString();
    }
  }
  final names = entries.keys.toList()..sort();
  return {for (final name in names) name: entries[name]!};
}

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}
