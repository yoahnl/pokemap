import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

Future<void> playCreatedClairbois(
  WidgetTester tester,
  ProjectSession session,
) async {
  final port = LocalMapWorkspaceAdapter();
  final project = (await tester.runAsync(() => port.loadProject(session)))!;
  final entry = project.maps.first;
  final document = (await tester.runAsync(() => port.loadMap(session, entry)))!;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StudioPlaytestView(
          session: session,
          entry: entry,
          expectedRevision: document.revision,
          port: port,
          onClose: () {},
        ),
      ),
    ),
  );
  Future<void> waitUntil(bool Function() ready) async {
    for (var i = 0; i < 500 && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(ready(), isTrue);
  }

  PlayableMapGame? loaded;
  await waitUntil(() {
    final finder = find.byType(GameWidget<PlayableMapGame>);
    if (finder.evaluate().isEmpty) return false;
    loaded = tester.widget<GameWidget<PlayableMapGame>>(finder).game;
    return loaded!.isLoaded && !loaded!.debugIsMapActivationDispatchInFlight;
  });
  final game = loaded!;
  await playClairboisRoute(tester, game);
  await tester.pumpWidget(const SizedBox());
}

Future<void> playClairboisRoute(
  WidgetTester tester,
  PlayableMapGame game, {
  bool Function(RuntimeInputEvent)? input,
}) async {
  Future<void> waitUntil(bool Function() ready) async {
    for (var i = 0; i < 500 && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(ready(), isTrue);
  }

  expect(game.debugPlayerGridPosition, const GridPos(x: 16, y: 16));
  final send = input ?? game.handleRuntimeInputEvent;
  void press(RuntimeInputControl control) {
    expect(send(RuntimeInputEvent.press(control)), isTrue);
    game.update(.016);
    final released = send(RuntimeInputEvent.release(control));
    if (control != RuntimeInputControl.primary &&
        !game.inputAuthoritySnapshot.isGameplayLocked) {
      expect(released, isTrue);
    }
    game.update(.3);
  }

  final position = game.debugPlayerWorldTopLeft;
  press(RuntimeInputControl.up);
  expect(game.debugPlayerGridPosition, const GridPos(x: 16, y: 15));
  expect(game.debugPlayerWorldTopLeft.y - position.y, closeTo(-64, .001));
  expect(game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
  for (var i = 0; i < 3; i++) {
    press(RuntimeInputControl.up);
  }
  press(RuntimeInputControl.right);
  press(RuntimeInputControl.up);
  expect(game.debugPlayerGridPosition, const GridPos(x: 17, y: 12));
  press(RuntimeInputControl.primary);
  await waitUntil(
    () => game.inputAuthoritySnapshot.context == RuntimeInputContext.dialogue,
  );
  expect(
    game.dialoguePresentationListenable.value?.fullText,
    contains('Bienvenue à Clairbois'),
  );
  for (
    var i = 0;
    i < 8 &&
        game.inputAuthoritySnapshot.context == RuntimeInputContext.dialogue;
    i++
  ) {
    game.update(2);
    press(RuntimeInputControl.primary);
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.overworld);
  for (var i = 0; i < 2; i++) {
    press(RuntimeInputControl.left);
  }
  for (var i = 0; i < 6; i++) {
    press(RuntimeInputControl.up);
  }
  await waitUntil(
    () =>
        game.debugLastCompletedMapActivation?.mapId == 'maison' &&
        !game.debugIsMapActivationDispatchInFlight,
  );
  expect(game.debugPlayerGridPosition, const GridPos(x: 6, y: 8));
  press(RuntimeInputControl.down);
  await waitUntil(
    () =>
        game.debugLastCompletedMapActivation?.mapId == 'first-map' &&
        !game.debugIsMapActivationDispatchInFlight,
  );
  expect(game.debugPlayerGridPosition, const GridPos(x: 15, y: 7));
  for (var i = 0; i < 11; i++) {
    press(RuntimeInputControl.down);
  }
  for (var i = 0; i < 4; i++) {
    press(RuntimeInputControl.left);
  }
  expect(game.debugPlayerGridPosition, const GridPos(x: 11, y: 18));
  press(RuntimeInputControl.left);
  expect(game.debugPlayerGridPosition, const GridPos(x: 11, y: 18));
}
