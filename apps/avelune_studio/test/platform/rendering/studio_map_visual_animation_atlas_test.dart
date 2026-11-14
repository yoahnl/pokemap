import 'dart:async';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'studio_map_visual_animation_fixtures.dart';

void main() {
  for (final (name, layer) in <(String, TileLayer)>[
    (
      'static occupied tile',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        palette: [TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 1)],
        cells: [1],
      ),
    ),
    (
      'unused animated palette',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        palette: [animatedTile],
        cells: [0],
      ),
    ),
    (
      'hidden layer',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        isVisible: false,
        palette: [animatedTile],
        cells: [1],
      ),
    ),
    (
      'transparent layer',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        opacity: 0,
        palette: [animatedTile],
        cells: [1],
      ),
    ),
    (
      'data layer',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        purpose: MapLayerPurpose.data,
        palette: [animatedTile],
        cells: [1],
      ),
    ),
  ]) {
    testWidgets('$name stays idle with no animation callbacks or redraws', (
      tester,
    ) async {
      final map = animatedMap(layers: [layer]);
      final (directory, resources) = await animatedResources(tester, map);
      final boundary = GlobalKey();
      final paintCounter = PaintCounter();
      await tester.pumpWidget(
        animationHost(map, resources, boundary, paintCounter: paintCounter),
      );
      await tester.pump();
      final painted = paintCounter.count;
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(paintCounter.count, painted);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await closeAnimationHost(tester, directory, resources);
    });
  }

  testWidgets('clock starts only after the animated atlas finishes loading', (
    tester,
  ) async {
    final gate = Completer<void>();
    final map = animatedMap();
    final (directory, resources) = await animatedResources(
      tester,
      map,
      preload: false,
      decode: (bytes, {transparentColor}) async {
        await gate.future;
        return decodeRuntimeTilesetImage(
          bytes,
          transparentColor: transparentColor,
        );
      },
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(animationHost(map, resources, boundary));
    await tester.pump(const Duration(seconds: 1));
    expect(resources.images, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
    gate.complete();
    await _settleResources(tester, resources);
    await tester.pump();
    await tester.pump();
    expect(await paintedPixel(tester, boundary), redFrame);
    await tester.pump(const Duration(milliseconds: 100));
    expect(await paintedPixel(tester, boundary), greenFrame);
    await closeAnimationHost(tester, directory, resources);
  });

  testWidgets(
    'renderer replacement resets clock and static replacement stays idle',
    (tester) async {
      final map = animatedMap();
      final (directory, resources) = await animatedResources(tester, map);
      final boundary = GlobalKey();
      await tester.pumpWidget(animationHost(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await paintedPixel(tester, boundary), blueFrame);
      await tester.pumpWidget(
        animationHost(map.copyWith(name: 'Replacement'), resources, boundary),
      );
      await tester.pump();
      expect(await paintedPixel(tester, boundary), redFrame);
      final staticMap = animatedMap(
        layers: [
          const TileLayer(
            id: 'tiles',
            name: 'Tiles',
            palette: [
              TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 1),
            ],
            cells: [1],
          ),
        ],
      );
      await tester.pumpWidget(animationHost(staticMap, resources, boundary));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(await paintedPixel(tester, boundary), greenFrame);
      await closeAnimationHost(tester, directory, resources);
    },
  );

  testWidgets('scroll clipping stops animation outside the visible cells', (
    tester,
  ) async {
    final map = animatedMap(
      width: 3,
      layers: [
        const TileLayer(
          id: 'tiles',
          name: 'Tiles',
          palette: [
            animatedTile,
            TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 1),
          ],
          cells: [1, 2, 2],
        ),
      ],
    );
    final (directory, resources) = await animatedResources(tester, map);
    final boundary = GlobalKey();
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 8,
            height: 8,
            child: SingleChildScrollView(
              controller: scroll,
              scrollDirection: Axis.horizontal,
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 24,
                  height: 8,
                  child: StudioMapVisual(map: map, resources: resources),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(await paintedPixel(tester, boundary), greenFrame);
    scroll.jumpTo(16);
    await tester.pump();
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 1));
    scroll.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(await paintedPixel(tester, boundary), greenFrame);
    await tester.pump(const Duration(milliseconds: 200));
    expect(await paintedPixel(tester, boundary), blueFrame);
    await closeAnimationHost(tester, directory, resources);
    scroll.dispose();
  });

  testWidgets('regular atlas object tiles consume the same three-frame clock', (
    tester,
  ) async {
    final map = animatedMap(
      layers: [
        const ObjectLayer(
          id: 'objects',
          name: 'Objects',
          tileObjects: [
            MapPlacedTile(
              id: 'tile',
              tile: animatedTile,
              anchorX: 0,
              anchorY: 1,
              width: 1,
              height: 1,
            ),
          ],
        ),
      ],
    );
    final (directory, resources) = await animatedResources(tester, map);
    final boundary = GlobalKey();
    await tester.pumpWidget(animationHost(map, resources, boundary));
    await tester.pump();
    expect(await paintedPixel(tester, boundary), redFrame);
    await tester.pump(const Duration(milliseconds: 100));
    expect(await paintedPixel(tester, boundary), greenFrame);
    await tester.pump(const Duration(milliseconds: 200));
    expect(await paintedPixel(tester, boundary), blueFrame);
    await tester.pump(const Duration(milliseconds: 300));
    expect(await paintedPixel(tester, boundary), redFrame);
    await closeAnimationHost(tester, directory, resources);
  });
}

Future<void> _settleResources(
  WidgetTester tester,
  StudioMapResources resources,
) async {
  var settled = false;
  resources.settled.then((_) => settled = true);
  for (var i = 0; i < 100 && !settled; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump();
  }
  expect(settled, isTrue);
}
