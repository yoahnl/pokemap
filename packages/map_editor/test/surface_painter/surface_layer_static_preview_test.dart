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

    test('paintSurfaceLayerAtlasTilePreview draws the resolved first frame',
        () async {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
        ],
      );
      final project = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: _surfaceCatalog(),
      );
      final tilesetImage = await _testTilesetImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      paintSurfaceLayerAtlasTilePreview(
        canvas: canvas,
        layer: layer,
        mapSize: const GridSize(width: 3, height: 3),
        project: project,
        tilesetImagesById: {'water-tileset': tilesetImage},
        tileWidth: 32,
        tileHeight: 32,
        zoom: 1,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(96, 96);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((48 * image.width) + 48) * 4;
      expect(pixels!.getUint8(offset), greaterThan(220));
      expect(pixels.getUint8(offset + 1), lessThan(40));
      expect(pixels.getUint8(offset + 2), lessThan(40));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });

    test('paintSurfaceLayerAtlasTilePreview draws the current frame', () async {
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
        ],
      );
      final project = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: _surfaceCatalog(),
      );
      final tilesetImage = await _testTilesetImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      paintSurfaceLayerAtlasTilePreview(
        canvas: canvas,
        layer: layer,
        mapSize: const GridSize(width: 3, height: 3),
        project: project,
        tilesetImagesById: {'water-tileset': tilesetImage},
        tileWidth: 32,
        tileHeight: 32,
        zoom: 1,
        elapsedMs: 120,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(96, 96);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((48 * image.width) + 48) * 4;
      expect(pixels!.getUint8(offset), lessThan(40));
      expect(pixels.getUint8(offset + 1), lessThan(40));
      expect(pixels.getUint8(offset + 2), greaterThan(220));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });
  });
}

ProjectSurfaceCatalog _surfaceCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'Water Atlas',
        tilesetId: 'water-tileset',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 4, rows: 4),
          layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
        ),
      ),
    ],
    animations: [
      ProjectSurfaceAnimation(
        id: 'water-isolated-loop',
        name: 'Water Isolated',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'water-atlas',
                column: 2,
                row: 0,
              ),
              durationMs: 120,
            ),
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'water-atlas',
                column: 3,
                row: 0,
              ),
              durationMs: 120,
            ),
          ],
        ),
      ),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-isolated-loop',
            ),
          ],
        ),
      ),
    ],
  );
}

Future<ui.Image> _testTilesetImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 128, 128),
    Paint()..color = Colors.transparent,
  );
  canvas.drawRect(
    const Rect.fromLTWH(64, 0, 32, 32),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    const Rect.fromLTWH(96, 0, 32, 32),
    Paint()..color = const Color(0xFF0000FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(128, 128);
  picture.dispose();
  return image;
}
