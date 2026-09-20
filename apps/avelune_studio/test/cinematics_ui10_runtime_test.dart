import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'support/ui06_scene_fixture.dart';
import 'support/ui10_cinematic_fixture.dart';

void main() {
  testWidgets(
    'UI10 real Flame cinematic animates before Scene continuation and restores authoring bytes',
    (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => createUi10Fixture(runtimeEntry: true),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final before = (await tester.runAsync(
        () => ui10AuthoringBytes(fixture.directory),
      ))!;
      final bundle = (await tester.runAsync(
        () => loadRuntimeMapBundle(
          projectFilePath: '${fixture.directory.path}/project.json',
          mapId: 'jardin',
        ),
      ))!;
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: '${fixture.directory.path}/project.json',
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: GameWidget(game: game),
          ),
        ),
      );
      await _until(tester, () => game.isLoaded && game.debugIsCinematicPlaying);
      game.pauseEngine();
      final start = game.debugPlayerWorldTopLeft.clone();
      final camera = game.debugCameraWorldTopLeft.clone();
      final originalPlayer = game.debugExpectedPlayerWorldTopLeft;
      final player = game.descendants().whereType<PlayerComponent>().single;
      final originalFocus = originalPlayer + player.size / 2;
      final originalCamera =
          originalFocus -
          Vector2(
            game.camera.visibleWorldRect.width / 2,
            game.camera.visibleWorldRect.height / 2,
          );

      expect(_continued(game), isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);
      final startPixels = await _capture(tester, key, 'runtime-01-start.png');
      game.update(.7);
      await tester.pump();
      final middle = game.debugPlayerWorldTopLeft.clone();
      expect(middle.x, greaterThan(start.x));
      expect(_continued(game), isFalse);
      final movementPixels = await _capture(
        tester,
        key,
        'runtime-02-movement.png',
      );
      expect(movementPixels, isNot(startPixels));
      game.update(.95);
      await tester.pump();
      expect(game.debugPlayerWorldTopLeft.x, greaterThan(middle.x));
      game.update(.3);
      await tester.pump();
      expect(game.debugCameraWorldTopLeft, isNot(camera));
      expect(_continued(game), isFalse);
      final cameraPixels = await _capture(tester, key, 'runtime-03-camera.png');
      expect(cameraPixels, isNot(movementPixels));
      game.update(.6);
      await tester.pump();
      expect(game.debugCinematicFadeOpacity, greaterThan(0));
      expect(_continued(game), isFalse);
      final fadePixels = await _capture(tester, key, 'runtime-04-fade.png');
      expect(fadePixels, isNot(cameraPixels));
      game.update(.7);
      await _until(
        tester,
        () => !game.debugIsMapActivationDispatchInFlight,
        manual: game,
      );
      expect(_continued(game), isTrue);
      expect(game.debugIsCinematicPlaying, isFalse);
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.debugCinematicFadeOpacity, isNull);
      expect(game.debugCameraWorldTopLeft.x, closeTo(originalCamera.x, .6));
      expect(game.debugCameraWorldTopLeft.y, closeTo(originalCamera.y, .6));
      expect(game.debugPlayerWorldTopLeft, originalPlayer);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(Ui06SceneFixture.eventId),
      );
      await _capture(tester, key, 'runtime-05-scene-continued.png');
      expect(
        await tester.runAsync(() => ui10AuthoringBytes(fixture.directory)),
        before,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'UI10 leaving real runtime cancels cinematic without continuation or event consumption',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => createUi10Fixture(runtimeEntry: true),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final before = (await tester.runAsync(
        () => ui10AuthoringBytes(fixture.directory),
      ))!;
      final bundle = (await tester.runAsync(
        () => loadRuntimeMapBundle(
          projectFilePath: '${fixture.directory.path}/project.json',
          mapId: 'jardin',
        ),
      ))!;
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: '${fixture.directory.path}/project.json',
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      );
      await _until(tester, () => game.isLoaded && game.debugIsCinematicPlaying);
      game.pauseEngine();
      final start = game.debugPlayerWorldTopLeft.clone();
      game.update(.8);
      expect(game.debugPlayerWorldTopLeft, isNot(start));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(game.debugIsCinematicPlaying, isFalse);
      expect(_continued(game), isFalse);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(Ui06SceneFixture.eventId)),
      );
      expect(
        await tester.runAsync(() => ui10AuthoringBytes(fixture.directory)),
        before,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

bool _continued(PlayableMapGame game) =>
    game
        .gameStateSnapshot
        .narrativeFactRuntimeState
        .overridesByFactId[Ui06SceneFixture.departureFactId] ==
    true;

Future<void> _until(
  WidgetTester tester,
  bool Function() done, {
  PlayableMapGame? manual,
}) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    manual?.update(.016);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  }
  fail('UI10 runtime did not settle');
}

Future<Uint8List> _capture(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final directory = Platform.environment['AVELUNE_CAPTURE_DIR'];
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  repaint(boundary);
  await tester.pump();
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    if (directory != null) {
      await Directory(directory).create(recursive: true);
      await File('$directory/$name').writeAsBytes(bytes);
    }
    image.dispose();
    return bytes;
  }))!;
}
