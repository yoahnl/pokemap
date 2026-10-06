import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('map composition exposes only the current visual phases', () {
    final plan = buildMapVisualCompositionPlan(_map()).plan!;
    expect(
        plan.steps.map((step) => step.kind.name), isNot(contains('shadows')));
    expect(plan.steps.map((step) => step.stableKey),
        contains('placedElements:decor'));
  });

  test('runtime and authoring retain ground, decor order and preview content',
      () async {
    final map = MapData.fromJson(_map().toJson());
    final bundle = surfaceTestBundle(map: map, elements: [
      for (final id in ['red', 'blue'])
        ProjectElementEntry(
          id: id,
          name: id,
          tilesetId: id,
          categoryId: 'test',
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
    ]);
    final images = {
      'base': await runtimeTilesetImage(const [Color(0xff00ff00)]),
      'red': await runtimeTilesetImage(const [Color(0xffff0000)]),
      'blue': await runtimeTilesetImage(const [Color(0xff0000ff)]),
    };
    addTearDown(() {
      for (final image in images.values) {
        image.dispose();
      }
    });
    final renderer = RuntimeAuthoringMapRenderer(bundle: bundle, images: images)
      ..update(0);
    addTearDown(renderer.dispose);
    final background = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: images,
    )..update(0);
    final foreground = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: images,
      renderPass: MapLayerRenderPass.foreground,
    )..update(0);
    addTearDown(background.dispose);
    addTearDown(foreground.dispose);
    final runtime = await _paint((canvas) {
      background.render(canvas);
      foreground.render(canvas);
    });
    addTearDown(runtime.dispose);
    final authoring = await _paint(renderer.paint);
    addTearDown(authoring.dispose);
    expect(await pixelAt(runtime, 16, 16), rgba(255, 0, 0, 255));
    expect(await pixelAt(runtime, 48, 16), rgba(0, 255, 0, 255));
    expect(await _pixels(authoring), await _pixels(runtime));

    renderer.setPlacedElementPreview(
      map.placedElements.first.copyWith(pos: const GridPos(x: 1, y: 0)),
    );
    final preview = await _paint(renderer.paint);
    addTearDown(preview.dispose);
    expect(await pixelAt(preview, 16, 16), rgba(0, 0, 255, 255));
    expect(await pixelAt(preview, 48, 16), rgba(255, 0, 0, 255));
    renderer.clearPlacedElementPreview();
    final restored = await _paint(renderer.paint);
    addTearDown(restored.dispose);
    expect(await _pixels(restored), await _pixels(runtime));
    expect(bundle.map, map);
  });
}

MapData _map() => const MapData(
      id: 'visual-content',
      name: 'Visual content',
      size: GridSize(width: 2, height: 1),
      layers: [
        TileLayer(
          id: 'decor',
          name: 'Decor',
          palette: [TileLayerPaletteEntry(tilesetId: 'base', localTileId: 0)],
          cells: [1, 1],
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'red',
          layerId: 'decor',
          elementId: 'red',
          pos: GridPos(x: 0, y: 0),
          visualOrder: 2,
        ),
        MapPlacedElement(
          id: 'blue',
          layerId: 'decor',
          elementId: 'blue',
          pos: GridPos(x: 0, y: 0),
          visualOrder: 1,
        ),
      ],
    );

Future<ui.Image> _paint(void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(64, 32);
  } finally {
    picture.dispose();
  }
}

Future<List<int>> _pixels(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
