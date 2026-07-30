import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart';

void main() {
  test('projects source foreground cells through the placed rotation', () {
    final mask = buildCinematicBackdropForegroundTileCellIndices(
      map: _map(
        element: const MapPlacedElement(
          id: 'placed',
          layerId: 'objects',
          elementId: 'prop',
          pos: GridPos(x: 1, y: 1),
          quarterTurns: 1,
        ),
      ),
      manifest: _manifest(sourceWidth: 2, collisionCells: const [
        GridPos(x: 0, y: 0),
      ]),
    );

    // Source (1,0) is foreground and becomes destination (0,1) at q1.
    expect(mask['objects'], {9});
  });

  test('placed instructions carry rotated destination geometry', () async {
    final image = await _asymmetricTileImage();
    final plan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: _map(
        element: const MapPlacedElement(
          id: 'placed',
          layerId: 'objects',
          elementId: 'prop',
          pos: GridPos(x: 1, y: 1),
          quarterTurns: 1,
        ),
      ),
      manifest: _manifest(),
      tilesets: {
        'tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'tiles',
          image: image,
          tileWidth: 8,
          tileHeight: 4,
        ),
      },
    );

    final instruction = plan.instructions.single;
    expect(instruction.quarterTurns, 1);
    expect(instruction.destinationWidthPx, isA<int>());
    expect(instruction.destinationHeightPx, isA<int>());
    expect(instruction.destinationWidthPx, 8);
    expect(instruction.destinationHeightPx, 4);
    expect(instruction.destinationRect, const ui.Rect.fromLTWH(8, 4, 8, 4));
    expect(instruction.elementBottomY, 2);
    image.dispose();
  });

  test('ordinary layer instructions declare an unrotated cell destination',
      () async {
    final image = await _asymmetricTileImage();
    final plan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: const MapData(
        id: 'tile-map',
        name: 'Tile map',
        size: GridSize(width: 1, height: 1),
        layers: [
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'tiles',
            tiles: [1],
          ),
        ],
      ),
      manifest: _manifest(),
      tilesets: {
        'tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'tiles',
          image: image,
          tileWidth: 8,
          tileHeight: 4,
        ),
      },
    );

    final instruction = plan.instructions.single;
    expect(instruction.quarterTurns, 0);
    expect(instruction.destinationWidthPx, isA<int>());
    expect(instruction.destinationHeightPx, isA<int>());
    expect(instruction.destinationWidthPx, 8);
    expect(instruction.destinationHeightPx, 4);
    image.dispose();
  });

  test('renderer rotates an asymmetric rectangular source cell clockwise',
      () async {
    final image = await _asymmetricTileImage();
    const instruction = CinematicMapBackdropLayerBitmapInstruction(
      id: 'placed:0:0',
      layerId: 'objects',
      layerLabel: 'Objects',
      layerKind: CinematicMapBackdropLayerKind.object,
      renderPass: CinematicMapBackdropRenderPass.placedBackground,
      zOrder: 0,
      tilesetId: 'tiles',
      sourceRect: ui.Rect.fromLTWH(0, 0, 8, 4),
      destinationRect: ui.Rect.fromLTWH(0, 0, 8, 4),
      opacity: 1,
      sourceFamily: 'placedElement',
      sourceId: 'placed',
      elementBottomY: 1,
      elementX: 0,
      layerIndex: 0,
      quarterTurns: 1,
      destinationWidthPx: 8,
      destinationHeightPx: 4,
    );
    final plan = CinematicMapBackdropLayerRenderPlan(
      mapWidth: 1,
      mapHeight: 1,
      tileWidth: 8,
      tileHeight: 4,
      tilesets: {
        'tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'tiles',
          image: image,
          tileWidth: 8,
          tileHeight: 4,
        ),
      },
      instructions: [instruction],
      diagnostics: const [],
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    CinematicMapBackdropLayerRenderPainter(
      plan: plan,
      palette: const CinematicMapBackdropTileRenderPalette(
        background: ui.Color(0x00000000),
        border: ui.Color(0x00000000),
        grid: ui.Color(0x00000000),
      ),
      paintBackground: false,
      paintGrid: false,
      paintBorder: false,
    ).paint(canvas, const ui.Size(8, 4));
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(8, 4);
    final bytes =
        (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!;

    expect(_rgba(bytes, x: 4, y: 0, width: 8), [255, 0, 0, 255]);
    expect(_rgba(bytes, x: 4, y: 3, width: 8), [0, 0, 255, 255]);
    picture.dispose();
    rendered.dispose();
    image.dispose();
  });
}

ProjectManifest _manifest({
  int sourceWidth = 1,
  List<GridPos> collisionCells = const [],
}) {
  return ProjectManifest(
    name: 'Rotation',
    maps: const [],
    settings: const ProjectSettings(
      tileWidth: 8,
      tileHeight: 4,
      displayScale: 1,
    ),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'props', name: 'Props'),
    ],
    elements: [
      ProjectElementEntry(
        id: 'prop',
        name: 'Prop',
        tilesetId: 'tiles',
        categoryId: 'props',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(
              x: 0,
              y: 0,
              width: sourceWidth,
              height: 1,
            ),
          ),
        ],
        collisionProfile: collisionCells.isEmpty
            ? null
            : ElementCollisionProfile(cells: collisionCells),
      ),
    ],
  );
}

MapData _map({required MapPlacedElement element}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: [
      TileLayer(
        id: 'objects',
        name: 'Objects',
        tilesetId: 'tiles',
        tiles: List<int>.filled(16, 0),
      ),
    ],
    placedElements: [element],
  );
}

Future<ui.Image> _asymmetricTileImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(4, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 4);
  picture.dispose();
  return image;
}

List<int> _rgba(
  ByteData bytes, {
  required int x,
  required int y,
  required int width,
}) {
  final offset = ((y * width) + x) * 4;
  return [
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
}
