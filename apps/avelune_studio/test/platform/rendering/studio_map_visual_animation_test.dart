import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:avelune_studio/platform/rendering/studio_resource_decoder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

const _red = [255, 0, 0, 255];
const _green = [0, 255, 0, 255];
const _blue = [0, 0, 255, 255];
const _tile = TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0);

MapData _map({List<MapLayer>? layers, int width = 1}) => MapData(
  id: 'animation-map',
  name: 'Animation',
  size: GridSize(width: width, height: 1),
  layers:
      layers ??
      [
        const TileLayer(
          id: 'tiles',
          name: 'Tiles',
          palette: [_tile],
          cells: [1],
        ),
      ],
);

Future<(Directory, StudioMapResources)> _resources(
  WidgetTester tester,
  MapData map, {
  bool preload = true,
  StudioImageDecoder decode = decodeRuntimeTilesetImage,
  List<int> durations = const [100, 200, 300],
}) async => (await tester.runAsync(() async {
  final directory = await Directory.systemTemp.createTemp('studio_ac07_');
  final root = await directory.resolveSymbolicLinks();
  final pixels = image.Image(width: 24, height: 8);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 24; x++) {
      final color = x < 8
          ? _red
          : x < 16
          ? _green
          : _blue;
      pixels.setPixelRgba(x, y, color[0], color[1], color[2], color[3]);
    }
  }
  await File('$root/atlas.png').writeAsBytes(image.encodePng(pixels));
  final resources = await StudioMapResources.load(
    ProjectSession(sessionId: 'ac07', name: 'Animation', directoryPath: root),
    ProjectManifest(
      name: 'Animation',
      maps: [],
      settings: const ProjectSettings(
        tileWidth: 8,
        tileHeight: 8,
        displayScale: 1,
      ),
      tilesets: [
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas',
          relativePath: 'atlas.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'atlas',
            pixelWidth: 24,
            pixelHeight: 8,
            tileWidth: 8,
            tileHeight: 8,
            tileAnimations: [
              ProjectRegularAtlasTileAnimation(
                tileId: 0,
                frames: [
                  ProjectImageCollectionAnimationFrame(
                    tileId: 0,
                    durationMs: durations[0],
                  ),
                  ProjectImageCollectionAnimationFrame(
                    tileId: 1,
                    durationMs: durations[1],
                  ),
                  ProjectImageCollectionAnimationFrame(
                    tileId: 2,
                    durationMs: durations[2],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    decode: decode,
  );
  if (preload) {
    resources.setActiveMap(map);
    await resources.settled;
  }
  return (directory, resources);
}))!;

Widget _host(
  MapData map,
  StudioMapResources resources,
  GlobalKey boundary, {
  bool ticking = true,
  bool offstage = false,
  _PaintCounter? paintCounter,
}) => MaterialApp(
  home: Align(
    alignment: Alignment.topLeft,
    child: TickerMode(
      enabled: ticking,
      child: Offstage(
        offstage: offstage,
        child: RepaintBoundary(
          key: boundary,
          child: CustomPaint(
            foregroundPainter: paintCounter,
            child: SizedBox(
              width: map.size.width * 8,
              height: 8,
              child: StudioMapVisual(map: map, resources: resources),
            ),
          ),
        ),
      ),
    ),
  ),
);

class _PaintCounter extends CustomPainter {
  int count = 0;

  @override
  void paint(Canvas canvas, Size size) => count++;

  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}

Future<List<int>> _pixel(WidgetTester tester, GlobalKey boundary) async =>
    (await tester.runAsync(() async {
      final rendered =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      try {
        final bytes = (await rendered.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final offset = (4 * rendered.width + 4) * 4;
        return bytes.sublist(offset, offset + 4);
      } finally {
        rendered.dispose();
      }
    }))!;

Future<void> _close(
  WidgetTester tester,
  Directory directory,
  StudioMapResources resources,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() async {
    await resources.dispose();
    await directory.delete(recursive: true);
  });
  expect(tester.binding.transientCallbackCount, 0);
  expect(tester.takeException(), isNull);
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

void main() {
  testWidgets(
    'non-binary millisecond boundaries cannot leave the painted frame behind the clock',
    (tester) async {
      final map = _map();
      final (directory, resources) = await _resources(
        tester,
        map,
        durations: [1001, 2001, 3001],
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(_host(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(await _pixel(tester, boundary), _red);
      await tester.pump(const Duration(microseconds: 999));
      expect(await _pixel(tester, boundary), _red);
      await tester.pump(const Duration(microseconds: 1));
      expect(await _pixel(tester, boundary), _green);
      await tester.pump(const Duration(milliseconds: 2001));
      expect(await _pixel(tester, boundary), _blue);
      await tester.pump(const Duration(milliseconds: 3001));
      expect(await _pixel(tester, boundary), _red);
      await _close(tester, directory, resources);
    },
  );

  testWidgets(
    'native atlas paints all three timed frames at boundaries and loops',
    (tester) async {
      final map = _map();
      final (directory, resources) = await _resources(tester, map);
      final boundary = GlobalKey();
      final paintCounter = _PaintCounter();
      await tester.pumpWidget(
        _host(map, resources, boundary, paintCounter: paintCounter),
      );
      await tester.pump();
      final painted = paintCounter.count;
      expect(await _pixel(tester, boundary), _red);
      await tester.pump(const Duration(milliseconds: 99));
      expect(await _pixel(tester, boundary), _red);
      expect(paintCounter.count, painted);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await _pixel(tester, boundary), _green);
      expect(paintCounter.count, painted + 1);
      await tester.pump(const Duration(milliseconds: 199));
      expect(await _pixel(tester, boundary), _green);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await _pixel(tester, boundary), _blue);
      await tester.pump(const Duration(milliseconds: 299));
      expect(await _pixel(tester, boundary), _blue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await _pixel(tester, boundary), _red);
      await _close(tester, directory, resources);
    },
  );

  testWidgets(
    'TickerMode pauses clock and resumes without hidden elapsed time',
    (tester) async {
      final map = _map();
      final (directory, resources) = await _resources(tester, map);
      final boundary = GlobalKey();
      await tester.pumpWidget(_host(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await _pixel(tester, boundary), _green);
      await tester.pumpWidget(_host(map, resources, boundary, ticking: false));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(await _pixel(tester, boundary), _green);
      await tester.pumpWidget(_host(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 199));
      expect(await _pixel(tester, boundary), _green);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await _pixel(tester, boundary), _blue);
      await _close(tester, directory, resources);
    },
  );

  testWidgets('Offstage pauses and disposal reaps the animation ticker', (
    tester,
  ) async {
    final map = _map();
    final (directory, resources) = await _resources(tester, map);
    final boundary = GlobalKey();
    await tester.pumpWidget(_host(map, resources, boundary));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(map, resources, boundary, offstage: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(_host(map, resources, boundary));
    await tester.pump();
    expect(await _pixel(tester, boundary), _green);
    await tester.pump(const Duration(milliseconds: 200));
    expect(await _pixel(tester, boundary), _blue);
    await _close(tester, directory, resources);
  });

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
      const TileLayer(id: 'tiles', name: 'Tiles', palette: [_tile], cells: [0]),
    ),
    (
      'hidden layer',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        isVisible: false,
        palette: [_tile],
        cells: [1],
      ),
    ),
    (
      'transparent layer',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        opacity: 0,
        palette: [_tile],
        cells: [1],
      ),
    ),
    (
      'data layer',
      const TileLayer(
        id: 'tiles',
        name: 'Tiles',
        purpose: MapLayerPurpose.data,
        palette: [_tile],
        cells: [1],
      ),
    ),
  ]) {
    testWidgets('$name stays idle with no animation callbacks or redraws', (
      tester,
    ) async {
      final map = _map(layers: [layer]);
      final (directory, resources) = await _resources(tester, map);
      final boundary = GlobalKey();
      final paintCounter = _PaintCounter();
      await tester.pumpWidget(
        _host(map, resources, boundary, paintCounter: paintCounter),
      );
      await tester.pump();
      final painted = paintCounter.count;
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(paintCounter.count, painted);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await _close(tester, directory, resources);
    });
  }

  testWidgets('clock starts only after the animated atlas finishes loading', (
    tester,
  ) async {
    final gate = Completer<void>();
    final map = _map();
    final (directory, resources) = await _resources(
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
    await tester.pumpWidget(_host(map, resources, boundary));
    await tester.pump(const Duration(seconds: 1));
    expect(resources.images, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
    gate.complete();
    await _settleResources(tester, resources);
    await tester.pump();
    await tester.pump();
    expect(await _pixel(tester, boundary), _red);
    await tester.pump(const Duration(milliseconds: 100));
    expect(await _pixel(tester, boundary), _green);
    await _close(tester, directory, resources);
  });

  testWidgets(
    'renderer replacement resets clock and static replacement stays idle',
    (tester) async {
      final map = _map();
      final (directory, resources) = await _resources(tester, map);
      final boundary = GlobalKey();
      await tester.pumpWidget(_host(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await _pixel(tester, boundary), _blue);
      await tester.pumpWidget(
        _host(map.copyWith(name: 'Replacement'), resources, boundary),
      );
      await tester.pump();
      expect(await _pixel(tester, boundary), _red);
      final staticMap = _map(
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
      await tester.pumpWidget(_host(staticMap, resources, boundary));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(await _pixel(tester, boundary), _green);
      await _close(tester, directory, resources);
    },
  );

  testWidgets('scroll clipping stops animation outside the visible cells', (
    tester,
  ) async {
    final map = _map(
      width: 3,
      layers: [
        const TileLayer(
          id: 'tiles',
          name: 'Tiles',
          palette: [
            _tile,
            TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 1),
          ],
          cells: [1, 2, 2],
        ),
      ],
    );
    final (directory, resources) = await _resources(tester, map);
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
    expect(await _pixel(tester, boundary), _green);
    scroll.jumpTo(16);
    await tester.pump();
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 1));
    scroll.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(await _pixel(tester, boundary), _green);
    await tester.pump(const Duration(milliseconds: 200));
    expect(await _pixel(tester, boundary), _blue);
    await _close(tester, directory, resources);
    scroll.dispose();
  });

  testWidgets('regular atlas object tiles consume the same three-frame clock', (
    tester,
  ) async {
    final map = _map(
      layers: [
        const ObjectLayer(
          id: 'objects',
          name: 'Objects',
          tileObjects: [
            MapPlacedTile(
              id: 'tile',
              tile: _tile,
              anchorX: 0,
              anchorY: 1,
              width: 1,
              height: 1,
            ),
          ],
        ),
      ],
    );
    final (directory, resources) = await _resources(tester, map);
    final boundary = GlobalKey();
    await tester.pumpWidget(_host(map, resources, boundary));
    await tester.pump();
    expect(await _pixel(tester, boundary), _red);
    await tester.pump(const Duration(milliseconds: 100));
    expect(await _pixel(tester, boundary), _green);
    await tester.pump(const Duration(milliseconds: 200));
    expect(await _pixel(tester, boundary), _blue);
    await tester.pump(const Duration(milliseconds: 300));
    expect(await _pixel(tester, boundary), _red);
    await _close(tester, directory, resources);
  });

  testWidgets(
    'initially Offstage cached child starts when it becomes visible',
    (tester) async {
      final map = _map();
      final (directory, resources) = await _resources(tester, map);
      final boundary = GlobalKey();
      final hidden = ValueNotifier(true);
      final child = RepaintBoundary(
        key: boundary,
        child: SizedBox(
          width: 8,
          height: 8,
          child: StudioMapVisual(map: map, resources: resources),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder(
              valueListenable: hidden,
              builder: (_, value, _) => Offstage(offstage: value, child: child),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      hidden.value = false;
      await tester.pump();
      await tester.pump();
      expect(await _pixel(tester, boundary), _red);
      await tester.pump(const Duration(milliseconds: 100));
      expect(await _pixel(tester, boundary), _green);
      await _close(tester, directory, resources);
      hidden.dispose();
    },
  );

  testWidgets(
    'resource replacement disposes the old image and restarts its own clock',
    (tester) async {
      final map = _map();
      final (oldDirectory, oldResources) = await _resources(tester, map);
      final (directory, resources) = await _resources(tester, map);
      final oldImage = oldResources.images['atlas']!;
      final boundary = GlobalKey();
      await tester.pumpWidget(_host(map, oldResources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await _pixel(tester, boundary), _blue);
      await tester.pumpWidget(_host(map, resources, boundary));
      await tester.pump();
      await tester.runAsync(() async {
        await oldResources.dispose();
        await oldDirectory.delete(recursive: true);
      });
      expect(oldImage.debugDisposed, isTrue);
      expect(await _pixel(tester, boundary), _red);
      await tester.pump(const Duration(milliseconds: 100));
      expect(await _pixel(tester, boundary), _green);
      await _close(tester, directory, resources);
    },
  );

  testWidgets('a missing atlas stays idle and never advances the clock', (
    tester,
  ) async {
    final map = _map();
    final (directory, resources) = await _resources(
      tester,
      map,
      preload: false,
    );
    await tester.runAsync(() async {
      await File('${directory.path}/atlas.png').delete();
      resources.setActiveMap(map);
      await resources.settled;
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(_host(map, resources, boundary));
    await tester.pump();
    expect(resources.images, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await _close(tester, directory, resources);
  });

  for (final zeroOpacity in [false, true]) {
    testWidgets(
      zeroOpacity
          ? 'zero-opacity cached child resumes only when visible'
          : 'fully clipped cached child resumes only when on screen',
      (tester) async {
        final map = _map();
        final (directory, resources) = await _resources(tester, map);
        final boundary = GlobalKey();
        final hidden = ValueNotifier(true);
        final child = RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 8,
            height: 8,
            child: StudioMapVisual(map: map, resources: resources),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 8,
                height: 8,
                child: ClipRect(
                  child: ValueListenableBuilder(
                    valueListenable: hidden,
                    child: child,
                    builder: (_, value, child) => zeroOpacity
                        ? Opacity(opacity: value ? 0 : 1, child: child)
                        : Transform.translate(
                            offset: Offset(value ? 1000 : 0, 0),
                            child: child,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
        hidden.value = false;
        await tester.pump();
        await tester.pump();
        expect(await _pixel(tester, boundary), _red);
        await tester.pump(const Duration(milliseconds: 100));
        expect(await _pixel(tester, boundary), _green);
        await _close(tester, directory, resources);
        hidden.dispose();
      },
    );
  }
}
