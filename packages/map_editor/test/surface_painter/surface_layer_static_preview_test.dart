import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_painter/surface_layer_static_preview.dart';

void main() {
  group('SurfaceLayer static preview', () {
    test('builds preview cells for visible in-bounds placements', () {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        ],
      );

      final cells = buildSurfaceLayerStaticPreviewCells(
        layer: layer,
        mapSize: const GridSize(width: 3, height: 3),
      );

      expect(cells, hasLength(3));
      expect(cells[1].placement, layer.placements[1]);
      expect(cells[1].role, SurfaceVariantRole.horizontal);
      expect(cells[1].color, surfaceStaticPreviewColorForPresetId('water'));
    });

    test('ignores invisible SurfaceLayer placements', () {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        isVisible: false,
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        ],
      );

      final cells = buildSurfaceLayerStaticPreviewCells(
        layer: layer,
        mapSize: const GridSize(width: 3, height: 3),
      );

      expect(cells, isEmpty);
    });

    test('ignores placements outside the map bounds', () {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 4, y: 0, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 0, y: 4, surfacePresetId: 'water'),
        ],
      );

      final cells = buildSurfaceLayerStaticPreviewCells(
        layer: layer,
        mapSize: const GridSize(width: 2, height: 2),
      );

      expect(cells.map((cell) => cell.placement).toList(), [
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
      ]);
    });

    test('does not connect different presets in the same layer', () {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'lava'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'mud'),
        ],
      );

      final cells = buildSurfaceLayerStaticPreviewCells(
        layer: layer,
        mapSize: const GridSize(width: 3, height: 3),
      );

      final water = cells.singleWhere(
        (cell) => cell.placement.surfacePresetId == 'water',
      );
      expect(water.role, SurfaceVariantRole.isolated);
    });

    test('uses deterministic colors per surfacePresetId', () {
      final first = surfaceStaticPreviewColorForPresetId('water');
      final second = surfaceStaticPreviewColorForPresetId('water');
      final other = surfaceStaticPreviewColorForPresetId('lava');

      expect(first, second);
      expect(first, isNot(other));
    });

    test('paintSurfaceLayerStaticPreview does not require real atlas tiles',
        () {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'unknown-water'),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      paintSurfaceLayerStaticPreview(
        canvas: canvas,
        layer: layer,
        mapSize: const GridSize(width: 3, height: 3),
        tileWidth: 32,
        tileHeight: 32,
        zoom: 1,
      );

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}
