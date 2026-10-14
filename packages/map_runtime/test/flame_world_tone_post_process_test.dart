import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/post_process.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_world_tone_controller.dart';
import 'package:map_runtime/src/presentation/flame/flame_world_tone_post_process.dart';

void main() {
  testWidgets('neutral tone preserves the rendered colored world', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    final pixels = await _render(tester, controller, const [
      ui.Color(0xffc04010),
      ui.Color(0xff2060a0),
      ui.Color(0xff000000),
    ]);
    expect(pixels, [192, 64, 16, 255, 32, 96, 160, 255, 0, 0, 0, 255]);
  });

  testWidgets('signed RGB tone is additive and clamps colored pixels', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    controller.setTone(
      SceneWorldToneValue(red: 80, green: -40, blue: 20, gray: 0),
      durationSeconds: 0,
    );
    final pixels = await _render(tester, controller, const [
      ui.Color(0xffc04010),
      ui.Color(0xff2060f0),
      ui.Color(0xff000000),
    ]);
    expect(pixels, [255, 24, 36, 255, 112, 56, 255, 255, 80, 0, 20, 255]);
  });

  testWidgets('gray mixes native luma before adding the RGB offsets', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    controller.setTone(
      SceneWorldToneValue(red: 20, green: -10, blue: 5, gray: 255),
      durationSeconds: 0,
    );
    final pixels = await _render(tester, controller, const [
      ui.Color(0xffff0000),
      ui.Color(0xff00ff00),
      ui.Color(0xff0000ff),
      ui.Color(0xff000000),
    ]);
    _expectPixels(pixels, [
      96,
      66,
      81,
      255,
      170,
      140,
      155,
      255,
      49,
      19,
      34,
      255,
      20,
      0,
      5,
      255,
    ]);
  });

  testWidgets('partial gray retains a proportion of the source chroma', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    controller.setTone(
      SceneWorldToneValue(red: 0, green: 0, blue: 0, gray: 127.5),
      durationSeconds: 0,
    );
    final pixels = await _render(tester, controller, const [
      ui.Color(0xffff0000),
    ]);
    _expectPixels(pixels, [166, 38, 38, 255]);
  });

  testWidgets('tone preserves opacity and does not paint transparent world', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    controller.setTone(
      SceneWorldToneValue(red: 40, green: -20, blue: 30, gray: 0),
      durationSeconds: 0,
    );
    final pixels = await _render(tester, controller, const [
      ui.Color(0x80406080),
      ui.Color(0x00000000),
      ui.Color(0xff000000),
    ]);
    _expectPixels(pixels, [
      104,
      76,
      158,
      128,
      0,
      0,
      0,
      0,
      40,
      0,
      30,
      255,
    ], tolerance: 2);
    expect(pixels[3], 128);
    expect(pixels[7], 0);
    expect(pixels[11], 255);
  });

  testWidgets('camera processing includes decor and player but excludes HUD', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    controller.setTone(
      SceneWorldToneValue(red: -100, green: 20, blue: 40, gray: 0),
      durationSeconds: 0,
    );
    final pixels = await _render(tester, controller, const [
      ui.Color(0xffc04010),
      ui.Color(0xffd02010),
      ui.Color(0xff000000),
    ], hud: const ui.Color(0xff804020));
    expect(pixels, [92, 84, 56, 255, 108, 52, 56, 255, 128, 64, 32, 255]);
  });

  testWidgets('post process updates cannot double advance its owner clock', (
    tester,
  ) async {
    final controller = SceneWorldToneController();
    controller.setTone(
      SceneWorldToneValue(red: 200, green: 0, blue: 0, gray: 0),
      durationSeconds: 2,
    );
    final postProcess = FlameWorldTonePostProcess(controller: controller);
    postProcess.update(1);
    expect(controller.value, SceneWorldToneValue.neutral);
    controller.advance(.5);
    final pixels = await _render(tester, controller, const [
      ui.Color(0xff000000),
    ]);
    expect(pixels, [50, 0, 0, 255]);
  });
}

void _expectPixels(List<int> actual, List<int> expected, {int tolerance = 1}) {
  expect(actual.length, expected.length);
  for (var index = 0; index < actual.length; index++) {
    expect(
      actual[index],
      closeTo(expected[index], tolerance),
      reason: 'channel $index',
    );
  }
}

Future<List<int>> _render(
  WidgetTester tester,
  SceneWorldToneController controller,
  List<ui.Color> colors, {
  ui.Color? hud,
}) async {
  final width = colors.length;
  final world = World(
    children: [
      for (var x = 0; x < width; x++)
        RectangleComponent(
          position: Vector2(x.toDouble(), 0),
          size: Vector2(1, 1),
          paint: ui.Paint()
            ..isAntiAlias = false
            ..color = colors[x],
        ),
    ],
  );
  final camera = CameraComponent.withFixedResolution(
    world: world,
    width: width.toDouble(),
    height: 1,
  );
  camera.viewfinder.anchor = Anchor.topLeft;
  camera.add(
    PostProcessComponent(
      postProcess: FlameWorldTonePostProcess(controller: controller),
    ),
  );
  if (hud != null) {
    camera.viewport.add(
      RectangleComponent(
        position: Vector2((width - 1).toDouble(), 0),
        size: Vector2(1, 1),
        paint: ui.Paint()
          ..isAntiAlias = false
          ..color = hud,
      ),
    );
  }
  final game = FlameGame(world: world, camera: camera);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width.toDouble(),
          height: 1,
          child: GameWidget(game: game),
        ),
      ),
    ),
  );
  await tester.pump();
  final pixels = await tester.runAsync(() async {
    await game.ready();
    expect(world.isMounted, isTrue);
    final recorder = ui.PictureRecorder();
    camera.renderTree(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, 1);
    picture.dispose();
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      return bytes!.buffer.asUint8List().toList(growable: false);
    } finally {
      image.dispose();
    }
  });
  await tester.pumpWidget(const SizedBox.shrink());
  return pixels!;
}
