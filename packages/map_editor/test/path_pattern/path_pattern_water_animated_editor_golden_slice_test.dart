import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  test('golden slice eau 2x2 animée depuis JSON dans MapGridPainter', () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(_fixtureRaw()) as Map<String, dynamic>,
    );
    const map = MapData(
      id: 'water_golden',
      name: 'Water Golden',
      size: GridSize(width: 4, height: 2),
      layers: <MapLayer>[
        PathLayer(
          id: 'path_main',
          name: 'Path',
          presetId: 'water-base',
          cells: <bool>[
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
          ],
        ),
      ],
    );

    final mainImage = await _createTilesetImage(
      row0: const [
        ui.Color(0xFFFF0000),
        ui.Color(0xFF00FF00),
        ui.Color(0xFF0000FF),
        ui.Color(0xFFFFFF00),
      ],
      row1: const [
        ui.Color(0xFFFF00FF),
        ui.Color(0xFF00FFFF),
        ui.Color(0xFFFFA500),
        ui.Color(0xFF444444),
      ],
    );
    final fxImage = await _createTilesetImage(
      row0: const [
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
      ],
      row1: const [
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFFFFFFFF),
      ],
    );

    final frame0 = await _render(
      map: map,
      manifest: manifest,
      imagesById: {
        'tileset-main': mainImage,
        'tileset-water-fx': fxImage,
      },
      elapsedMs: 0,
    );
    final frame1 = await _render(
      map: map,
      manifest: manifest,
      imagesById: {
        'tileset-main': mainImage,
        'tileset-water-fx': fxImage,
      },
      elapsedMs: 220,
    );

    await _expectRgb(frame0, 8, 8,
        redExpected: 255, greenExpected: 0, blueExpected: 0, label: 'frame0 A');
    await _expectRgb(frame0, 24, 8,
        redExpected: 0, greenExpected: 255, blueExpected: 0, label: 'frame0 B');
    await _expectRgb(frame0, 8, 24,
        redExpected: 0, greenExpected: 0, blueExpected: 255, label: 'frame0 C');
    await _expectRgb(frame0, 24, 24,
        redExpected: 255, greenExpected: 255, blueExpected: 0, label: 'frame0 D');
    await _expectRgb(frame0, 40, 8,
        redExpected: 255,
        greenExpected: 0,
        blueExpected: 0,
        label: 'frame0 A repeat');
    await _expectRgb(frame0, 56, 24,
        redExpected: 255,
        greenExpected: 255,
        blueExpected: 0,
        label: 'frame0 D repeat');

    await _expectRgb(frame1, 8, 8,
        redExpected: 255, greenExpected: 0, blueExpected: 255, label: 'frame1 A');
    await _expectRgb(frame1, 24, 8,
        redExpected: 0, greenExpected: 255, blueExpected: 255, label: 'frame1 B');
    await _expectRgb(frame1, 8, 24,
        redExpected: 255, greenExpected: 165, blueExpected: 0, label: 'frame1 C');
    await _expectRgb(frame1, 24, 24,
        redExpected: 255,
        greenExpected: 255,
        blueExpected: 255,
        label: 'frame1 D override');
    await _expectRgb(frame1, 40, 8,
        redExpected: 255,
        greenExpected: 0,
        blueExpected: 255,
        label: 'frame1 A repeat');
    await _expectRgb(frame1, 56, 24,
        redExpected: 255,
        greenExpected: 255,
        blueExpected: 255,
        label: 'frame1 D repeat');

    frame0.dispose();
    frame1.dispose();
    mainImage.dispose();
    fxImage.dispose();
  });
}

Future<ui.Image> _render({
  required MapData map,
  required ProjectManifest manifest,
  required Map<String, ui.Image> imagesById,
  required int elapsedMs,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: imagesById,
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{
      'tileset-main': 4,
      'tileset-water-fx': 4,
    },
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: manifest,
    editorEntityAnimationMs: elapsedMs,
  ).paint(canvas, const ui.Size(64, 32));

  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  return image;
}

Future<void> _expectRgb(
  ui.Image image,
  int x,
  int y, {
  required int redExpected,
  required int greenExpected,
  required int blueExpected,
  required String label,
}) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = ((y * image.width) + x) * 4;
  final red = bytes!.getUint8(offset);
  final green = bytes.getUint8(offset + 1);
  final blue = bytes.getUint8(offset + 2);

  final color = '($red,$green,$blue)';
  expect(red, redExpected, reason: '$label red $color');
  expect(green, greenExpected, reason: '$label green $color');
  expect(blue, blueExpected, reason: '$label blue $color');
}

Future<ui.Image> _createTilesetImage({
  required List<ui.Color> row0,
  required List<ui.Color> row1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 64, 32),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );

  for (var x = 0; x < row0.length; x += 1) {
    canvas.drawRect(
      ui.Rect.fromLTWH((x * 16).toDouble(), 0, 16, 16),
      ui.Paint()..color = row0[x],
    );
    canvas.drawRect(
      ui.Rect.fromLTWH((x * 16).toDouble(), 16, 16, 16),
      ui.Paint()..color = row1[x],
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  return image;
}

String _fixtureRaw() {
  return File(
    '../map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
  ).readAsStringSync();
}
