import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

Future<void> playCreatedSyntheticTemplate(
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
  await playSyntheticTemplateRoute(tester, game);
  await tester.pumpWidget(const SizedBox());
}

Future<void> playSyntheticTemplateRoute(
  WidgetTester tester,
  PlayableMapGame game, {
  bool Function(RuntimeInputEvent)? input,
}) async {
  final initial = game.debugPlayerGridPosition;
  final send = input ?? game.handleRuntimeInputEvent;
  expect(send(const RuntimeInputEvent.press(RuntimeInputControl.up)), isTrue);
  game.update(.016);
  expect(send(const RuntimeInputEvent.release(RuntimeInputControl.up)), isTrue);
  game.update(.3);
  expect(game.debugPlayerGridPosition, GridPos(x: initial.x, y: initial.y - 1));
  expect(game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
  expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.overworld);
}
