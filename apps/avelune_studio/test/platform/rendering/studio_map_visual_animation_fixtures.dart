import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:avelune_studio/platform/rendering/studio_resource_decoder.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

const redFrame = [255, 0, 0, 255];

const greenFrame = [0, 255, 0, 255];

const blueFrame = [0, 0, 255, 255];

const animatedTile = TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0);

MapData animatedMap({List<MapLayer>? layers, int width = 1}) => MapData(
  id: 'animation-map',
  name: 'Animation',
  size: GridSize(width: width, height: 1),
  layers:
      layers ??
      [
        const TileLayer(
          id: 'tiles',
          name: 'Tiles',
          palette: [animatedTile],
          cells: [1],
        ),
      ],
);

Future<(Directory, StudioMapResources)> animatedResources(
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
          ? redFrame
          : x < 16
          ? greenFrame
          : blueFrame;
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

Widget animationHost(
  MapData map,
  StudioMapResources resources,
  GlobalKey boundary, {
  bool ticking = true,
  bool offstage = false,
  PaintCounter? paintCounter,
  MapEditorState? editorState,
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
              child: editorState == null
                  ? StudioMapVisual(map: map, resources: resources)
                  : MapEditorVisibilityScope(
                      state: editorState,
                      child: StudioMapVisual(map: map, resources: resources),
                    ),
            ),
          ),
        ),
      ),
    ),
  ),
);

class PaintCounter extends CustomPainter {
  int count = 0;

  @override
  void paint(Canvas canvas, Size size) => count++;

  @override
  bool shouldRepaint(PaintCounter oldDelegate) => false;
}

Future<List<int>> paintedPixel(WidgetTester tester, GlobalKey boundary) async =>
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

Future<void> closeAnimationHost(
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
