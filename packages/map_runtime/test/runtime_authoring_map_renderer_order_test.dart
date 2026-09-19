import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('authoring pixels and runtime passes obey order after JSON reload',
      () async {
    final map = MapData.fromJson(const MapData(
      id: 'order',
      name: 'Order',
      size: GridSize(width: 1, height: 1),
      layers: [
        TileLayer(id: 'decor', name: 'Decor', cells: [0])
      ],
      placedElements: [
        MapPlacedElement(
            id: 'red',
            layerId: 'decor',
            elementId: 'red',
            pos: GridPos(x: 0, y: 0),
            visualOrder: 2),
        MapPlacedElement(
            id: 'blue',
            layerId: 'decor',
            elementId: 'blue',
            pos: GridPos(x: 0, y: 0),
            visualOrder: 1),
      ],
    ).toJson());
    final bundle = surfaceTestBundle(map: map, elements: [
      for (final id in ['red', 'blue'])
        ProjectElementEntry(
            id: id,
            name: id,
            tilesetId: id,
            categoryId: 'test',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
            ]),
    ]);
    final images = {
      'red': await runtimeTilesetImage(const [Color(0xffff0000)]),
      'blue': await runtimeTilesetImage(const [Color(0xff0000ff)]),
    };
    addTearDown(() {
      for (final image in images.values) {
        image.dispose();
      }
    });
    final authoring =
        RuntimeAuthoringMapRenderer(bundle: bundle, images: images)..update(0);
    final studioImage = await _paint((canvas) => authoring.paint(canvas));
    addTearDown(studioImage.dispose);
    final background =
        MapLayersComponent(bundle: bundle, tileImagesByTilesetId: images)
          ..update(0);
    final foreground = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
        renderPass: MapLayerRenderPass.foreground)
      ..update(0);
    final runtimeImage = await _paint((canvas) {
      background.render(canvas);
      foreground.render(canvas);
    });
    addTearDown(runtimeImage.dispose);
    expect(await pixelAt(studioImage, 16, 16), rgba(255, 0, 0, 255));
    expect(await pixelAt(runtimeImage, 16, 16), rgba(255, 0, 0, 255));
  });

  test('fixed rank never moves upper decor behind actor pass', () async {
    final bundle = surfaceTestBundle(
        map: const MapData(
          id: 'phase',
          name: 'Phase',
          size: GridSize(width: 1, height: 2),
          layers: [
            TileLayer(id: 'decor', name: 'Decor', cells: [0, 0])
          ],
          placedElements: [
            MapPlacedElement(
                id: 'tree',
                layerId: 'decor',
                elementId: 'tree',
                pos: GridPos(x: 0, y: 0),
                visualOrder: -100)
          ],
        ),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'tree',
            categoryId: 'test',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2))
            ],
            collisionProfile:
                ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]),
          )
        ]);
    final pixels = await _paint(
        (canvas) => canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 64),
            Paint()..color = const Color(0xffff0000)),
        height: 64);
    final image = RuntimeTilesetImage(
        images: [pixels],
        chunks: const [RuntimeTilesetChunk(top: 0, height: 64, width: 32)],
        width: 32,
        height: 64);
    addTearDown(image.dispose);
    final background = MapLayersComponent(
        bundle: bundle, tileImagesByTilesetId: {'tree': image})
      ..update(0);
    final foreground = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: {'tree': image},
        renderPass: MapLayerRenderPass.foreground)
      ..update(0);
    final rendered = await _paint((canvas) {
      background.render(canvas);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 64),
          Paint()..color = const Color(0xff00ff00));
      foreground.render(canvas);
    }, height: 64);
    addTearDown(rendered.dispose);
    expect(await pixelAt(rendered, 16, 16), rgba(255, 0, 0, 255));
    expect(await pixelAt(rendered, 16, 48), rgba(0, 255, 0, 255));
  });
}

Future<ui.Image> _paint(void Function(Canvas) paint, {int height = 32}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final result = await picture.toImage(32, height);
  picture.dispose();
  return result;
}
