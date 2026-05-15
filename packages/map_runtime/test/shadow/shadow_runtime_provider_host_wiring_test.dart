import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime shadow provider host wiring', () {
    test('RuntimeMapGame remains constructible without a provider', () {
      final game = RuntimeMapGame(bundle: _bundle());

      expect(game.shadowCollectionProvider, isNull);
    });

    test('RuntimeMapGame passes the provider to its mounted map layer',
        () async {
      var calls = 0;
      ShadowRuntimeInstructionCollection? provider() {
        calls += 1;
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: 'FF0000'),
          ],
        );
      }

      final game = RuntimeMapGame(
        bundle: _bundle(),
        shadowCollectionProvider: provider,
      );

      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;
      final image = await _render(layer);

      expect(layer.shadowCollectionProvider, same(provider));
      expect(calls, 1);
      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('RuntimeMapGame can use a different collection on later renders',
        () async {
      final controller = ShadowRuntimeCollectionController(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: 'FF0000'),
          ],
        ),
      );
      final game = RuntimeMapGame(
        bundle: _bundle(),
        shadowCollectionProvider: controller.provide,
      );

      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;
      final firstImage = await _render(layer);
      controller.replace(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '00FF00'),
          ],
        ),
      );
      final secondImage = await _render(layer);

      expect(await pixelAt(firstImage, 16, 16), rgba(255, 0, 0, 255));
      expect(await pixelAt(secondImage, 16, 16), rgba(0, 255, 0, 255));
    });

    test('PlayableMapGame remains constructible without a provider', () {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
      );

      expect(game.shadowCollectionProvider, isNull);
    });

    test('PlayableMapGame passes the provider only to background layers',
        () async {
      var calls = 0;
      ShadowRuntimeInstructionCollection? provider() {
        calls += 1;
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        );
      }

      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        shadowCollectionProvider: provider,
      );

      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      final layers = game.world.children.whereType<MapLayersComponent>();
      final background = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
      final foreground = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );
      await _render(foreground);
      final backgroundImage = await _render(background);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(calls, 1);
      expect(await pixelAt(backgroundImage, 16, 16), rgba(0, 0, 0, 255));
    });
  });
}

RuntimeMapBundle _bundle() {
  return surfaceTestBundle(
    tilesets: const <ProjectTilesetEntry>[],
    map: const MapData(
      id: 'shadow-host-test',
      name: 'Shadow Host Test',
      size: GridSize(width: 1, height: 1),
      layers: [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(32, 32);
}

ShadowRuntimeRenderInstruction _shadow({
  String colorHexRgb = '000000',
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: colorHexRgb,
  );
}
