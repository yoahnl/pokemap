import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  group('Environment brush cursor overlay', () {
    test('MapGridPainter ne lève pas avec un overlay paint', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.paint,
        ),
      ).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('MapGridPainter ne lève pas avec un overlay erase', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.erase,
        ),
      ).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('MapGridPainter ne lève pas avec size 5 au bord de map', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 0, y: 0),
          brushSize: 5,
          mode: EnvironmentMaskEditMode.paint,
        ),
      ).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('MapGridPainter ne lève pas avec overlay null', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(null).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('shouldRepaint distingue paint et erase', () {
      final paintPainter = _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.paint,
        ),
      );
      final erasePainter = _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.erase,
        ),
      );

      expect(erasePainter.shouldRepaint(paintPainter), isTrue);
    });
  });
}

MapGridPainter _painter(EnvironmentMaskBrushCursorOverlay? overlay) {
  return MapGridPainter(
    map: const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        TileLayer(
          id: 'tiles',
          name: 'Sol',
          tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ],
    ),
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: const <String, ui.Image?>{},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    environmentBrushCursorOverlay: overlay,
  );
}
