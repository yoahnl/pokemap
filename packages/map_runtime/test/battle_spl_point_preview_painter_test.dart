import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_emitter_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_preview_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'paints the selected texture at the projected particle position',
    () async {
      final texture = await _solidImage(const ui.Color(0xffffffff));
      addTearDown(texture.dispose);
      final painter = BattleSplPointPreviewPainter(
        textures: {1: texture},
        pixelsPerUnit: 20,
        aspectRatio4096: 4096,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      painter.paint(
        canvas,
        origin: const ui.Offset(10, 20),
        particles: [_particle(x: 4096, emitterX: 4096, baseScale: 2048)],
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(60, 40);
      addTearDown(image.dispose);
      picture.dispose();
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      List<int> pixel(int x, int y) {
        final offset = (y * 60 + x) * 4;
        return List.generate(4, (index) => bytes.getUint8(offset + index));
      }

      expect(pixel(50, 20), [255, 0, 0, 255]);
      expect(pixel(35, 20), [0, 0, 0, 0]);
      expect(pixel(5, 20), [0, 0, 0, 0]);
    },
  );

  test('rejects a missing texture before painting any particle', () async {
    final texture = await _solidImage(const ui.Color(0xffffffff));
    addTearDown(texture.dispose);
    final painter = BattleSplPointPreviewPainter(
      textures: {1: texture},
      pixelsPerUnit: 20,
      aspectRatio4096: 4096,
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    expect(
      () => painter.paint(
        canvas,
        origin: ui.Offset.zero,
        particles: [_particle(), _particle(texture: 2)],
      ),
      throwsFormatException,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    addTearDown(image.dispose);
    picture.dispose();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    expect(bytes.buffer.asUint8List().every((value) => value == 0), isTrue);
  });

  test('orients directional parents by their projected velocity', () async {
    final texture = await _solidImage(const ui.Color(0xffffffff));
    addTearDown(texture.dispose);
    final painter = BattleSplPointPreviewPainter(
      textures: {1: texture},
      pixelsPerUnit: 10,
      aspectRatio4096: 8192,
      directionalParents: true,
    );
    Future<ui.Image> render(BattleSplVector velocity) async {
      final recorder = ui.PictureRecorder();
      painter.paint(
        ui.Canvas(recorder),
        origin: const ui.Offset(30, 30),
        particles: [_particle(velocity: velocity)],
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(60, 60);
      picture.dispose();
      return image;
    }

    final horizontal = await render((x: 0, y: 1, z: 0));
    final vertical = await render((x: 1, y: 0, z: 0));
    final hidden = await render((x: 0, y: 0, z: 1));
    addTearDown(horizontal.dispose);
    addTearDown(vertical.dispose);
    addTearDown(hidden.dispose);
    final h = (await horizontal.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final v = (await vertical.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final z = (await hidden.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    int alpha(ByteData data, int x, int y) =>
        data.getUint8((y * 60 + x) * 4 + 3);

    expect(alpha(h, 45, 30), 255);
    expect(alpha(h, 30, 45), 0);
    expect(alpha(v, 45, 30), 0);
    expect(alpha(v, 30, 45), 255);
    expect(alpha(z, 30, 30), 0);
  });

  test('applies animated scale only on the declared axis', () async {
    final texture = await _solidImage(const ui.Color(0xffffffff));
    addTearDown(texture.dispose);
    Future<ui.Image> render(BattleSplPreviewScaleAxis axis) async {
      final recorder = ui.PictureRecorder();
      BattleSplPointPreviewPainter(
        textures: {1: texture},
        pixelsPerUnit: 10,
        aspectRatio4096: 4096,
        scaleAxis: axis,
      ).paint(
        ui.Canvas(recorder),
        origin: const ui.Offset(30, 30),
        particles: [_particle(animScale: 2048)],
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(60, 60);
      picture.dispose();
      return image;
    }

    final x = await render(BattleSplPreviewScaleAxis.x);
    final y = await render(BattleSplPreviewScaleAxis.y);
    addTearDown(x.dispose);
    addTearDown(y.dispose);
    final xBytes = (await x.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final yBytes = (await y.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    int alpha(ByteData data, int x, int y) =>
        data.getUint8((y * 60 + x) * 4 + 3);
    expect(alpha(xBytes, 30, 38), 255);
    expect(alpha(xBytes, 38, 30), 0);
    expect(alpha(yBytes, 30, 38), 0);
    expect(alpha(yBytes, 38, 30), 255);
  });

  test('restores the canvas when an image is already disposed', () async {
    final texture = await _solidImage(const ui.Color(0xffffffff));
    final painter = BattleSplPointPreviewPainter(
      textures: {1: texture},
      pixelsPerUnit: 20,
      aspectRatio4096: 4096,
    );
    texture.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final saveCount = canvas.getSaveCount();

    expect(
      () => painter.paint(
        canvas,
        origin: const ui.Offset(10, 20),
        particles: [_particle()],
      ),
      throwsA(anything),
    );
    expect(canvas.getSaveCount(), saveCount);
    recorder.endRecording().dispose();
  });
}

BattleSplPointParticle _particle({
  int x = 0,
  int emitterX = 0,
  int baseScale = 4096,
  int animScale = 4096,
  BattleSplVector velocity = (x: 0, y: 0, z: 0),
  int texture = 1,
}) => BattleSplPointParticle(
  id: 1,
  motion: BattleSplParticleMotion(
    position: (x: x, y: 0, z: 0),
    velocity: velocity,
    rotation: 0,
    angularVelocity: 0,
  ),
  emitterPosition: (x: emitterX, y: 0, z: 0),
  baseScale4096: baseScale,
  baseAlpha5: 31,
  animatedAlpha5: 31,
  scale4096: animScale,
  color: (red: 31, green: 0, blue: 0),
  alpha5: 31,
  texture: texture,
);

Future<ui.Image> _solidImage(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
      .drawRect(const ui.Rect.fromLTWH(0, 0, 2, 2), ui.Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  picture.dispose();
  return image;
}
