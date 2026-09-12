import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/main.dart' as runtime_host;
import 'package:pokemap_loader/src/runtime_startup_host.dart';

void main() {
  testWidgets('standalone Player capsule dispatches into its loaded game',
      (tester) async {
    final root = await tester.runAsync(() async {
      final target = await Directory.systemTemp.createTemp('ow006_host_tap_');
      final source = Directory(p.join(Directory.current.path, 'golden_item_system'));
      await for (final entry in source.list(recursive: true)) {
        final destination = p.join(target.path, p.relative(entry.path, from: source.path));
        if (entry is Directory) {
          await Directory(destination).create(recursive: true);
        } else if (entry is File) {
          await File(destination).parent.create(recursive: true);
          await entry.copy(destination);
        }
      }
      return target;
    });
    final messenger = tester.binding.defaultBinaryMessenger;
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    const gamepadChannel = MethodChannel('xyz.luan/gamepads');
    const audioEventsChannel =
        MethodChannel('xyz.luan/audioplayers.global/events');
    messenger.setMockMethodCallHandler(pathChannel, (_) async => root!.path);
    messenger.setMockMethodCallHandler(gamepadChannel, (_) async => <Object>[]);
    messenger.setMockMethodCallHandler(audioEventsChannel, (call) async {
      if (call.method != 'listen' && call.method != 'cancel') {
        throw UnsupportedError(call.method);
      }
      return null;
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(seconds: 3));
      messenger.setMockMethodCallHandler(pathChannel, null);
      messenger.setMockMethodCallHandler(gamepadChannel, null);
      messenger.setMockMethodCallHandler(audioEventsChannel, null);
      await tester.runAsync(() => root!.delete(recursive: true));
    });
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    PlayableMapGame? currentGame;
    runtime_host.runRuntimeHost(
      initialProjectFilePath: p.join(root!.path, 'project.json'),
      onGameChanged: (game) => currentGame = game,
    );
    await _until(tester, () => _shell(tester)?.snapshot.phase == RuntimeStartupPhase.titlePrompt);
    var shell = _shell(tester)!;
    shell.onStartupCommand(RuntimeStartupCommand(
      action: RuntimeStartupAction.pressStart,
      snapshotRevision: shell.snapshot.revision,
    ));
    await _until(tester, () =>
        _shell(tester)?.snapshot.playerSnapshot?.isActionEnabled(RuntimePlayerAction.newGame) ?? false);
    shell = _shell(tester)!;
    RuntimePlayerCommandResult? launchResult;
    unawaited(Future<RuntimePlayerCommandResult>.sync(() => shell.onPlayerCommand(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: shell.snapshot.playerSnapshot!.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: standaloneRuntimeProfileId,
          slotId: standaloneRuntimeSlotId,
        ),
      ),
    )).then<void>((result) => launchResult = result));
    await _until(tester, () =>
        currentGame?.isLoaded == true ||
        _shell(tester)?.snapshot.playerSnapshot?.preSessionRequest != null);
    final request = _shell(tester)?.snapshot.playerSnapshot?.preSessionRequest;
    if (request != null) {
      shell = _shell(tester)!;
      final result = switch (request.kind) {
        SceneInteractionRequestKind.text => SceneInteractionResult.textSubmitted(
          requestId: request.requestId, revision: request.revision, value: 'OW006 QA'),
        SceneInteractionRequestKind.confirmation => SceneInteractionResult.confirmed(
          requestId: request.requestId, revision: request.revision, value: true),
        _ => SceneInteractionResult.acknowledged(
          requestId: request.requestId, revision: request.revision),
      };
      unawaited(Future<RuntimePlayerCommandResult>.sync(() => shell.onPlayerCommand(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.resolvePreSessionInteraction,
          snapshotRevision: shell.snapshot.playerSnapshot!.revision,
          payload: result,
        ),
      )));
    }
    await _until(tester, () =>
        launchResult != null &&
        currentGame?.isLoaded == true &&
        find.byType(PlayerOverworldActionCapsule).evaluate().isNotEmpty);
    expect(launchResult, isA<RuntimePlayerCommandResult>().having(
        (result) => result.status, 'status', RuntimePlayerCommandStatus.accepted));
    final game = currentGame!;
    final before = _etherQuantity(game.gameStateSnapshot);
    expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
    await tester.tap(find.byType(PlayerOverworldActionCapsule));
    await _until(tester, () => _etherQuantity(game.gameStateSnapshot) == before + 1);
    expect(game.gameStateSnapshot.storyFlags.activeFlags,
        contains('golden_item.pickup_collected'));
    await _until(tester, () =>
        !game.debugIsNarrativeSpatialDispatchInFlight &&
        game.debugNotificationText == null &&
        find.byType(PlayerOverworldActionCapsule).evaluate().isNotEmpty);
    await tester.tap(find.byType(PlayerOverworldActionCapsule));
    await _until(tester, () =>
        !game.debugIsNarrativeSpatialDispatchInFlight &&
        game.debugNotificationText == null);
    expect(_etherQuantity(game.gameStateSnapshot), before + 1);
    final position = game.debugPlayerGridPosition;
    expect(game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down)), isTrue);
    try {
      await _until(tester, () => game.debugPlayerGridPosition != position);
    } finally {
      game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.down));
    }
    await _until(tester, () =>
        find.byType(PlayerOverworldActionCapsule).evaluate().isEmpty);
    expect(_etherQuantity(game.gameStateSnapshot), before + 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 3));
  });
}

PlayerRuntimeStartupShell? _shell(WidgetTester tester) {
  final finder = find.byType(PlayerRuntimeStartupShell);
  return finder.evaluate().isEmpty ? null : tester.widget<PlayerRuntimeStartupShell>(finder);
}

Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 500; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  fail('Standalone Player did not reach the expected startup or interaction state.');
}

int _etherQuantity(GameState state) => state.bag.entries
    .where((entry) => entry.itemId == 'ether')
    .fold(0, (quantity, entry) => quantity + entry.quantity);
