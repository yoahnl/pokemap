import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_background.dart';

void main() {
  test('moves relative to its starting offset with source step delays', () {
    final background = BattleGen5SourceBackground(
      viewport: () => const ui.Rect.fromLTWH(0, 0, 256, 192),
    );
    background.scroll(x: 3, y: 4, frames: 0);
    background.tick();
    final dynamic moving = background;
    moving.move(x: 0, y: 8, frames: 2, wait: 1);
    background.tick();
    expect(background.offset, const ui.Offset(3, 8));
    background.tick();
    expect(background.offset, const ui.Offset(3, 8));
    background.tick();
    expect(background.offset, const ui.Offset(3, 12));
    expect(background.isMoving, isFalse);
  });

  testWidgets('ripples source pixels horizontally and vertically before restoring them',
      (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff000000), ui.BlendMode.src);
      canvas.drawRect(const ui.Rect.fromLTWH(128, 0, 384, 512),
          ui.Paint()..color = const ui.Color(0xff0000ff));
      canvas.drawRect(const ui.Rect.fromLTWH(0, 96, 512, 416),
          ui.Paint()..color = const ui.Color(0xffff0000));
      final picture = recorder.endRecording();
      final source = await picture.toImage(512, 512);
      final background = BattleGen5SourceBackground(
        viewport: () => const ui.Rect.fromLTWH(0, 0, 256, 192),
      );
      background.load(source);
      background.visible = true;
      Future<(int, int)> pixel(int x, int y) async {
        final output = ui.PictureRecorder();
        background.render(ui.Canvas(output));
        final frame = output.endRecording();
        final image = await frame.toImage(256, 192);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final index = (y * 256 + x) * 4;
        final result = (bytes!.getUint8(index), bytes.getUint8(index + 2));
        image.dispose();
        frame.dispose();
        return result;
      }

      final dynamic waving = background;
      expect(await pixel(129, 1), (0, 255));
      waving.startWave(mode: 0, amplitude: 0x4000, step: 90, frames: 3);
      background.tick();
      expect(waving.isWaving, isTrue);
      expect(await pixel(129, 1), (0, 0));
      background.tick();
      background.tick();
      expect(waving.isWaving, isFalse);
      expect(await pixel(129, 1), (0, 255));

      expect(await pixel(10, 97), (255, 0));
      waving.startWave(mode: 1, amplitude: 0x4000, step: 90, frames: 3);
      background.tick();
      expect(await pixel(10, 97), (0, 0));
      background.reset();
      expect(waving.isWaving, isFalse);
      source.dispose();
      picture.dispose();
    });
  });

  test('scrolls for frames plus one ticks and then stops', () {
    final background = BattleGen5SourceBackground(
      viewport: () => const ui.Rect.fromLTWH(0, 0, 256, 192),
    );
    background.scroll(x: -20, y: 2, frames: 2);
    expect(background.isMoving, isTrue);
    background.tick();
    expect(background.offset, const ui.Offset(-20, 2));
    background.tick();
    expect(background.offset, const ui.Offset(-40, 4));
    background.tick();
    expect(background.offset, const ui.Offset(-60, 6));
    expect(background.isMoving, isFalse);
    background.tick();
    expect(background.offset, const ui.Offset(-60, 6));
    background.reset();
    expect(background.offset, ui.Offset.zero);
    expect(background.isMoving, isFalse);
  });

  test('mirrors horizontal scrolling for the opposite source side', () {
    final background = BattleGen5SourceBackground(
      viewport: () => const ui.Rect.fromLTWH(0, 0, 256, 192),
    );
    background.scroll(x: -20, y: 0, frames: 0, mirror: true);
    background.tick();
    expect(background.offset, const ui.Offset(20, 0));
    expect(background.isMoving, isFalse);
  });

  test('background swing follows source steps and returns to its starting offset', () {
    final background = BattleGen5SourceBackground(
      viewport: () => const ui.Rect.fromLTWH(0, 0, 256, 192),
    );
    background.swing(x: 0, y: 8, frames: 2, wait: 0, count: 2);
    final offsets = <double>[];
    for (var tick = 0; tick < 8; tick++) {
      background.tick();
      offsets.add(background.offset.dy);
    }
    expect(offsets, [4, 8, 4, 0, 4, 8, 4, 0]);
    expect(background.isMoving, isFalse);
  });

  testWidgets('hiding the field paints black even without a background image',
      (tester) async {
    await tester.runAsync(() async {
      final background = BattleGen5SourceBackground(
        viewport: () => const ui.Rect.fromLTWH(0, 0, 20, 20),
      );
      Future<int> redChannel() async {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.src);
        background.render(canvas);
        final picture = recorder.endRecording();
        final image = await picture.toImage(20, 20);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final red = bytes!.getUint8(0);
        image.dispose();
        picture.dispose();
        return red;
      }

      background.hideField = true;
      expect(await redChannel(), 0);
      background.hideField = false;
      expect(await redChannel(), 255);
    });
  });

  testWidgets('palette frames follow the source timer and stop after the requested loops',
      (tester) async {
    await tester.runAsync(() async {
      Future<ui.Image> solid(ui.Color color) async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(512, 512);
        picture.dispose();
        return image;
      }

      final red = await solid(const ui.Color(0xffff0000));
      final blue = await solid(const ui.Color(0xff0000ff));
      final background = BattleGen5SourceBackground(
        viewport: () => const ui.Rect.fromLTWH(0, 0, 20, 20),
      );
      background.load(red);
      background.visible = true;
      background.animatePalette(frames: [red, blue], durations: [3, 3], loops: 2);
      Future<(int, int)> pixel() async {
        final recorder = ui.PictureRecorder();
        background.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(20, 20);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final result = (bytes!.getUint8(0), bytes.getUint8(2));
        image.dispose();
        picture.dispose();
        return result;
      }

      background.tick();
      expect(await pixel(), (255, 0));
      background.tick();
      background.tick();
      expect(await pixel(), (0, 255));
      background.tick();
      background.tick();
      expect(await pixel(), (255, 0));
      background.tick();
      expect(background.isPaletteAnimating, isTrue);
      background.tick();
      expect(await pixel(), (0, 255));
      expect(background.isPaletteAnimating, isFalse);
      red.dispose();
      blue.dispose();
    });
  });

  testWidgets('zero-duration palette frames advance on consecutive ticks',
      (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawColor(const ui.Color(0xffff0000), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(512, 512);
      picture.dispose();
      final background = BattleGen5SourceBackground(
        viewport: () => const ui.Rect.fromLTWH(0, 0, 20, 20),
      );
      background.load(image);
      background.animatePalette(frames: [image, image], durations: [0, 0], loops: 1);
      background.tick();
      expect(background.isPaletteAnimating, isTrue);
      background.tick();
      expect(background.isPaletteAnimating, isFalse);
      image.dispose();
    });
  });

  testWidgets('one-tick palette frames advance on consecutive ticks',
      (tester) async {
    await tester.runAsync(() async {
      Future<ui.Image> solid(ui.Color color) async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(512, 512);
        picture.dispose();
        return image;
      }

      final red = await solid(const ui.Color(0xffff0000));
      final blue = await solid(const ui.Color(0xff0000ff));
      final background = BattleGen5SourceBackground(
        viewport: () => const ui.Rect.fromLTWH(0, 0, 20, 20),
      );
      background.load(red);
      background.visible = true;
      background.animatePalette(frames: [red, blue], durations: [1, 1], loops: 1);
      Future<(int, int)> pixel() async {
        final recorder = ui.PictureRecorder();
        background.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(20, 20);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final result = (bytes!.getUint8(0), bytes.getUint8(2));
        image.dispose();
        picture.dispose();
        return result;
      }

      background.tick();
      expect(await pixel(), (255, 0));
      expect(background.isPaletteAnimating, isTrue);
      background.tick();
      expect(await pixel(), (0, 255));
      expect(background.isPaletteAnimating, isFalse);
      red.dispose();
      blue.dispose();
    });
  });

  testWidgets('fits a wide viewport without stretching the original pixels', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final sourceRecorder = ui.PictureRecorder();
      final sourceCanvas = ui.Canvas(sourceRecorder);
      sourceCanvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 512, 512),
        ui.Paint()..color = const ui.Color(0xffff0000),
      );
      sourceCanvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 128, 512),
        ui.Paint()..color = const ui.Color(0xff0000ff),
      );
      final sourcePicture = sourceRecorder.endRecording();
      final source = await sourcePicture.toImage(512, 512);
      final background = BattleGen5SourceBackground(
        viewport: () => const ui.Rect.fromLTWH(0, 0, 400, 100),
      );
      background.load(source);
      background.visible = true;
      final outputRecorder = ui.PictureRecorder();
      background.render(ui.Canvas(outputRecorder));
      final outputPicture = outputRecorder.endRecording();
      final output = await outputPicture.toImage(400, 100);
      final pixels = await output.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels!.getUint8((50 * 400 + 50) * 4 + 2), 255);
      expect(pixels.getUint8((50 * 400 + 350) * 4), 255);
      output.dispose();
      outputPicture.dispose();
      source.dispose();
      sourcePicture.dispose();
    });
  });
}
