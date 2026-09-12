import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show Direction;
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
      'OW007 shared Player Menu stops a loaded game and invalidates the held touch gesture',
      (tester) async {
    final game = await _loadGame(tester);
    final controller = _MenuController(game);
    addTearDown(controller.close);
    await _mountPlayer(tester, game, controller);
    final initialPosition = game.debugPlayerGridPosition;
    final held = await tester.startGesture(const Offset(100, 600),
        pointer: 1, kind: ui.PointerDeviceKind.touch);
    await held.moveBy(const Offset(48, 0));
    await tester.pump();
    expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
    _advance(game, frames: 1);
    expect(game.debugIsPlayerStepping, isTrue);

    final menu = await tester.startGesture(
        tester.getCenter(find.byType(PlayerOverworldMenuButton)),
        pointer: 2,
        kind: ui.PointerDeviceKind.touch);
    await menu.up();
    await tester.pump();
    expect(controller.snapshot.phase, RuntimePlayerPhase.paused);
    expect(controller.menuOpenCount, 1);
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
    expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
    _advance(game);
    expect(game.debugPlayerGridPosition, isNot(initialPosition));
    final stoppedPosition = game.debugPlayerGridPosition;
    final stoppedWorldPosition = _worldPosition(game);
    expect(stoppedPosition.x, lessThan(5));
    await held.moveBy(const Offset(32, 0));
    _expectStopped(game, stoppedPosition, stoppedWorldPosition);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(controller.snapshot.phase, RuntimePlayerPhase.playing);
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    await held.moveBy(const Offset(32, 0));
    await held.up();
    await tester.pump();
    _expectStopped(game, stoppedPosition, stoppedWorldPosition);
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);

    final fresh = await tester.startGesture(const Offset(100, 600),
        pointer: 3, kind: ui.PointerDeviceKind.touch);
    await fresh.moveBy(const Offset(48, 0));
    await tester.pump();
    expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
    _advance(game, frames: 15);
    expect(game.debugPlayerGridPosition.x, greaterThan(stoppedPosition.x));
    await fresh.up();
    await tester.pump();
    expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'OW007 real runtime authority rejects held keyboard repeats and late releases after resume',
      (tester) async {
    final game = await _loadGame(tester);
    final controller = _MenuController(game);
    addTearDown(controller.close);
    await _mountPlayer(tester, game, controller);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
    _advance(game, frames: 1);
    expect(game.debugIsPlayerStepping, isTrue);

    game.setExternalInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
    await tester.pump();
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
    expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
    _advance(game);
    final stoppedPosition = game.debugPlayerGridPosition;
    final stoppedWorldPosition = _worldPosition(game);
    expect(stoppedPosition.x, lessThan(5));
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    _expectStopped(game, stoppedPosition, stoppedWorldPosition);

    game.setExternalInputLock(RuntimeExternalInputLock.lifecycle,
        locked: false);
    await tester.pump();
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    _expectStopped(game, stoppedPosition, stoppedWorldPosition);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    _expectStopped(game, stoppedPosition, stoppedWorldPosition);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
    _advance(game, frames: 15);
    expect(game.debugPlayerGridPosition.x, greaterThan(stoppedPosition.x));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'OW007 canonical item interaction runs once and held confirm cannot replay after Menu',
      (tester) async {
    final game = await _loadGame(tester, position: const GridPos(x: 1, y: 2));
    final controller = _MenuController(game);
    addTearDown(controller.close);
    final primaryPresses = <RuntimeInputEvent>[];
    await _mountPlayer(tester, game, controller, observeRuntimeInput: (event) {
      if (event.control == RuntimeInputControl.primary && event.isPress) {
        primaryPresses.add(event);
      }
    });
    final initialQuantity = _etherQuantity(game.gameStateSnapshot);
    expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
    await tester.runAsync(() async {
      for (var frame = 0; frame < 240; frame++) {
        game.update(.016);
        await Future<void>.delayed(Duration.zero);
        if (!game.debugIsNarrativeSpatialDispatchInFlight &&
            game.gameStateSnapshot.storyFlags.activeFlags
                .contains('golden_item.pickup_collected')) {
          break;
        }
      }
      game.update(0);
    });
    await tester.pump();
    final collected = game.gameStateSnapshot;
    expect(_etherQuantity(collected), initialQuantity + 1);
    expect(collected.storyFlags.activeFlags,
        contains('golden_item.pickup_collected'));
    expect(
        collected.progression.completedStepIds, contains('golden_item.pickup'));
    expect(primaryPresses, hasLength(1));
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.snapshot.phase, RuntimePlayerPhase.paused);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyE);
    await tester.pump();
    expect(controller.snapshot.phase, RuntimePlayerPhase.paused);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(controller.snapshot.phase, RuntimePlayerPhase.playing);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
    _advance(game);
    expect(primaryPresses, hasLength(1));
    expect(_etherQuantity(game.gameStateSnapshot), initialQuantity + 1);
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    for (var frame = 0; frame < 240; frame++) {
      game.update(.016);
      await tester.pump(const Duration(milliseconds: 16));
      if (!game.debugIsNarrativeSpatialDispatchInFlight &&
          game.debugNotificationText != null) {
        break;
      }
    }
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
    expect(game.debugNotificationText, isNotNull);
    expect(primaryPresses, hasLength(2));
    expect(_etherQuantity(game.gameStateSnapshot), initialQuantity + 1);
    await tester.pump(const Duration(seconds: 2));
    game.update(0);
    expect(game.debugNotificationText, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

int _etherQuantity(GameState state) => state.bag.entries
    .where((entry) => entry.itemId == 'ether')
    .fold(0, (total, entry) => total + entry.quantity);

Future<_LoadedGame> _loadGame(WidgetTester tester,
    {GridPos position = const GridPos(x: 1, y: 3)}) async {
  final game = (await tester.runAsync(() async {
    final projectPath = p.normalize(p.join(
        Directory.current.path,
        '..',
        '..',
        'examples',
        'playable_runtime_host',
        'golden_item_system',
        'project.json'));
    final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath, mapId: 'golden_item_lab');
    final game = _LoadedGame(bundle: bundle, projectFilePath: projectPath);
    game.onGameResize(
        game.camera.viewfinder.position.clone()..setValues(390, 844));
    await game.onLoad();
    for (var frame = 0; frame < 240; frame++) {
      game.update(.016);
      await Future<void>.delayed(Duration.zero);
      if (!game.debugIsMapActivationDispatchInFlight) break;
    }
    expect(game.debugIsMapActivationDispatchInFlight, isFalse);
    game.debugSetPlayerStateForTest(position: position, facing: Direction.east);
    game.update(0);
    return game;
  }))!;
  addTearDown(game.onRemove);
  expect(game.isLoaded, isTrue);
  expect(game.inputAuthoritySnapshot.sprintAllowed, isTrue);
  expect(game.inputAuthorityListenable.value.sprintAllowed, isTrue);
  return game;
}

Future<void> _mountPlayer(
    WidgetTester tester, PlayableMapGame game, _MenuController controller,
    {ValueChanged<RuntimeInputEvent>? observeRuntimeInput}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final viewportKey = GlobalKey();
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    home: PokeMapPlayerSessionView(
      controller: controller,
      titlePresentation: const RuntimePlayerTitlePresentation(
          author: 'PokeMap', description: 'Golden Item System'),
      gameSceneBuilder: (_) => SizedBox.expand(key: viewportKey),
      gameplayViewportKey: viewportKey,
      gameplayInputRoute: (event) {
        observeRuntimeInput?.call(event);
        return game.handleRuntimeInputEvent(event);
      },
      gameplayInputAuthority: game.inputAuthorityListenable,
      overworldInteractions: game.overworldInteractions,
      touchControlsAvailable: true,
      controllerInputEnabled: false,
      hapticFeedback: () async {},
    ),
  ));
  await tester.pump();
}

void _advance(PlayableMapGame game, {int frames = 60}) {
  for (var frame = 0; frame < frames; frame++) {
    game.update(.016);
  }
}

Offset _worldPosition(PlayableMapGame game) {
  final point = game.debugPlayerWorldTopLeft;
  return Offset(point.x, point.y);
}

void _expectStopped(
    PlayableMapGame game, GridPos position, Offset worldPosition) {
  _advance(game);
  expect(game.debugPlayerGridPosition, position);
  expect(_worldPosition(game), worldPosition);
  expect(game.debugIsPlayerStepping, isFalse);
  expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
}

final class _LoadedGame extends PlayableMapGame {
  _LoadedGame({required super.bundle, required super.projectFilePath});

  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loaded = true;
  }
}

final class _MenuController implements RuntimePlayerViewController {
  _MenuController(this.game);

  final PlayableMapGame game;
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  var _phase = RuntimePlayerPhase.playing;
  var _revision = 1;
  var menuOpenCount = 0;

  @override
  RuntimePlayerSnapshot get snapshot => RuntimePlayerSnapshot(
        revision: _revision,
        phase: _phase,
        gameTitle: 'Golden Item System',
        pauseSection: _phase == RuntimePlayerPhase.paused
            ? RuntimePlayerPauseSection.root
            : null,
        preferences: const PlayerPreferencesSnapshot(
            locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
        actions: [
          RuntimePlayerActionAvailability.enabled(
              _phase == RuntimePlayerPhase.playing
                  ? RuntimePlayerAction.openMenu
                  : RuntimePlayerAction.resume),
        ],
      );

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<RuntimePlayerCommandResult> dispatch(
      RuntimePlayerCommand command) async {
    expect(command.snapshotRevision, _revision);
    expect(command.action,
        anyOf(RuntimePlayerAction.openMenu, RuntimePlayerAction.resume));
    final paused = command.action == RuntimePlayerAction.openMenu;
    if (paused) menuOpenCount++;
    game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu,
        locked: paused);
    _phase = paused ? RuntimePlayerPhase.paused : RuntimePlayerPhase.playing;
    _revision++;
    _snapshots.add(snapshot);
    return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted);
  }

  @override
  Future<RuntimePlayerCommandResult> requestBack(
          {required int snapshotRevision}) =>
      dispatch(RuntimePlayerCommand(
          action: RuntimePlayerAction.resume,
          snapshotRevision: snapshotRevision));

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
          RuntimeWorldServiceCommand command) async =>
      const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable);

  Future<void> close() => _snapshots.close();
}
