import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('portrait collection artwork reframes while the complete backdrop stays opaque', () async {
    final artRecorder = ui.PictureRecorder();
    final artCanvas = Canvas(artRecorder);
    artCanvas.drawRect(
      const Rect.fromLTWH(0, 0, 40, 20),
      Paint()..color = const Color(0xFFCC3311),
    );
    artCanvas.drawRect(
      const Rect.fromLTWH(0, 20, 40, 20),
      Paint()..color = const Color(0xFF1166CC),
    );
    final picture = artRecorder.endRecording();
    final artwork = await picture.toImage(40, 40);
    picture.dispose();
    final cache = BattleVisualAssetCache(imageLoader: (_) async => artwork);
    addTearDown(cache.dispose);
    final component = BattleSceneBackdropComponent(
      size: Vector2(80, 120),
      artworkRect: const Rect.fromLTWH(0, 0, 80, 60),
      visualAssetCache: cache,
      backgroundSpec: const BattleBackgroundSpec.explicitImage(
        absolutePath: '/fixture/collection.png',
        fallbackKey: BattleBackgroundKey.wildOutdoor,
      ),
    );
    await component.onLoad();
    addTearDown(component.onRemove);
    Future<List<int>> pixels() async {
      final recorder = ui.PictureRecorder();
      component.render(Canvas(recorder));
      final rendering = recorder.endRecording();
      final image = await rendering.toImage(
        component.size.x.toInt(),
        component.size.y.toInt(),
      );
      rendering.dispose();
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List().toList();
      image.dispose();
      for (var alpha = 3; alpha < bytes.length; alpha += 4) {
        expect(
          bytes[alpha],
          255,
          reason: 'No transparent pixels below the collection panel',
        );
      }
      return bytes;
    }

    var bytes = await pixels();
    expect(bytes.sublist((45 * 80 + 40) * 4, (45 * 80 + 40) * 4 + 4), [
      0x11,
      0x66,
      0xCC,
      0xFF,
    ]);
    component.size.setValues(90, 140);
    component.artworkRect = const Rect.fromLTWH(0, 0, 90, 70);
    bytes = await pixels();
    expect(bytes.sublist((55 * 90 + 45) * 4, (55 * 90 + 45) * 4 + 4), [
      0x11,
      0x66,
      0xCC,
      0xFF,
    ]);
    component.artworkRect = null;
    bytes = await pixels();
    expect(bytes.sublist((55 * 90 + 45) * 4, (55 * 90 + 45) * 4 + 4), [
      0xCC,
      0x33,
      0x11,
      0xFF,
    ]);
  });

  for (final key in BattleBackgroundKey.values) {
    test('generated $key covers the complete viewport and its resized dock area', () async {
      final component = BattleSceneBackdropComponent(
        size: Vector2(844, 390),
        backgroundSpec: BattleBackgroundSpec(key: key),
      );
      await component.onLoad();
      addTearDown(component.onRemove);
      for (final viewport in const [
        Size(844, 390),
        Size(390, 844),
        Size(768, 432),
      ]) {
        component.size.setValues(viewport.width, viewport.height);
        final recorder = ui.PictureRecorder();
        component.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          viewport.width.toInt(),
          viewport.height.toInt(),
        );
        picture.dispose();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        final pixels = data!.buffer.asUint8List();
        int? transparentPixel;
        for (var offset = 3; offset < pixels.length; offset += 4) {
          if (pixels[offset] != 255) {
            transparentPixel = offset ~/ 4;
            break;
          }
        }
        expect(
          transparentPixel,
          isNull,
          reason:
              '$key must cover $viewport below and between floating command cards',
        );
      }
    });
  }

  test(
    'explicit battle artwork is rendered without generated scenery or shading',
    () async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 20, 20),
        Paint()..color = const Color(0xFF60AC38),
      );
      final picture = recorder.endRecording();
      final artwork = await picture.toImage(20, 20);
      picture.dispose();
      final cache = BattleVisualAssetCache(imageLoader: (_) async => artwork);
      addTearDown(cache.dispose);
      final component = BattleSceneBackdropComponent(
        size: Vector2(80, 56),
        visualAssetCache: cache,
        backgroundSpec: const BattleBackgroundSpec.explicitImage(
          absolutePath: '/fixture/battle-art.png',
          fallbackKey: BattleBackgroundKey.trainerOutdoor,
        ),
      );
      await component.onLoad();
      addTearDown(component.onRemove);
      expect(component.hasResolvedExplicitImage, isTrue);
      final output = ui.PictureRecorder();
      component.render(Canvas(output));
      final renderedPicture = output.endRecording();
      final rendered = await renderedPicture.toImage(80, 56);
      renderedPicture.dispose();
      addTearDown(rendered.dispose);
      final pixels = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      for (var offset = 0; offset < pixels.length; offset += 4) {
        expect(
          pixels.sublist(offset, offset + 4),
          [0x60, 0xAC, 0x38, 0xFF],
          reason: 'Artwork pixel ${offset ~/ 4} must retain its authored color',
        );
      }
    },
  );
}
