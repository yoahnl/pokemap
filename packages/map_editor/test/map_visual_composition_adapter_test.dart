import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  test('canonical Surface above Tile follows the shared core plan', () async {
    final legacy = await _renderCenter(
      visualStack: null,
    );
    final canonical = await _renderCenter(
      visualStack: MapVisualStackConfig.canonicalV1,
    );

    expect(legacy, const ui.Color(0xFFFF0000));
    expect(canonical, const ui.Color(0xFF0000FF));
  });

  test('future semantics render no legacy pixels', () async {
    final color = await _renderCenter(
      visualStack: MapVisualStackConfig(semanticsVersion: 99),
    );

    expect(color.a, 0);
  });
}

Future<ui.Color> _renderCenter({
  required MapVisualStackConfig? visualStack,
}) async {
  final tileset = await _twoColorTileset();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final map = MapData(
    id: 'visual-order',
    name: 'Visual order',
    size: const GridSize(width: 1, height: 1),
    version: visualStack == null ? ProjectVersion.v1 : ProjectVersion.v3,
    visualStack: visualStack,
    layers: const <MapLayer>[
      SurfaceLayer(
        id: 'surface',
        name: 'Surface',
        placements: <SurfaceCellPlacement>[
          SurfaceCellPlacement(
            x: 0,
            y: 0,
            surfacePresetId: 'blue-surface',
          ),
        ],
      ),
      TileLayer(
        id: 'tile',
        name: 'Tile',
        tilesetId: 'colors',
        tiles: <int>[1],
      ),
    ],
  );
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: <String, ui.Image?>{'colors': tileset},
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{'colors': 2},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: ProjectManifest(
      name: 'Parity',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'colors-atlas',
            name: 'Colors',
            tilesetId: 'colors',
            geometry: SurfaceAtlasGeometry(
              tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
              gridSize: SurfaceAtlasGridSize(columns: 2, rows: 1),
              layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
            ),
          ),
        ],
        animations: [
          ProjectSurfaceAnimation(
            id: 'blue-static',
            name: 'Blue',
            timeline: SurfaceAnimationTimeline(
              frames: [
                SurfaceAnimationFrame(
                  tileRef: SurfaceAtlasTileRef(
                    atlasId: 'colors-atlas',
                    column: 1,
                    row: 0,
                  ),
                  durationMs: 1000,
                ),
              ],
            ),
          ),
        ],
        presets: [
          ProjectSurfacePreset(
            id: 'blue-surface',
            name: 'Blue surface',
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'blue-static',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    showGrid: false,
  ).paint(canvas, const ui.Size(16, 16));

  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 16);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = ((8 * image.width) + 8) * 4;
  final color = ui.Color.fromARGB(
    pixels!.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
  picture.dispose();
  image.dispose();
  tileset.dispose();
  return color;
}

Future<ui.Image> _twoColorTileset() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(
      const ui.Rect.fromLTWH(0, 0, 16, 16),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    )
    ..drawRect(
      const ui.Rect.fromLTWH(16, 0, 16, 16),
      ui.Paint()..color = const ui.Color(0xFF0000FF),
    );
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 16);
  picture.dispose();
  return image;
}
