import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_layer_grouping.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  group('MapGridPainter tile layer order', () {
    test('paints bottom_to_top opt-in layers in authored list order', () async {
      final color = await _paintOverlappingLayers(
        properties: const <String, dynamic>{
          'tileLayerOrder': 'bottom_to_top',
        },
      );

      expect(color, _blue);
    });

    test('preserves reverse-order rendering for legacy maps', () async {
      final color = await _paintOverlappingLayers();

      expect(color, _red);
    });

    test('applies bottom_to_top ordering to the foreground pass', () async {
      final color = await _paintOverlappingLayers(
        properties: const <String, dynamic>{
          'tileLayerOrder': 'bottom_to_top',
        },
        explicitForeground: true,
      );

      expect(color, _blue);
    });

    test('preserves legacy ordering in the foreground pass', () async {
      final color = await _paintOverlappingLayers(
        explicitForeground: true,
      );

      expect(color, _red);
    });

    test('applies bottom_to_top ordering to placed elements', () async {
      final color = await _paintOverlappingLayers(
        properties: const <String, dynamic>{
          'tileLayerOrder': 'bottom_to_top',
        },
        placedElements: true,
      );

      expect(color, _blue);
    });

    test('preserves legacy ordering for placed elements', () async {
      final color = await _paintOverlappingLayers(
        placedElements: true,
      );

      expect(color, _red);
    });

    test('map with Border keeps bottom_to_top foreground Tile order', () async {
      final color = await _paintOverlappingLayers(
        properties: const <String, dynamic>{
          'tileLayerOrder': 'bottom_to_top',
        },
        explicitForeground: true,
        includeBorder: true,
      );

      expect(color, _blue);
    });

    test('map with Border keeps legacy inverse foreground Tile order',
        () async {
      final color = await _paintOverlappingLayers(
        explicitForeground: true,
        includeBorder: true,
      );

      expect(color, _red);
    });

    test('map with Border defers ordinary placed elements below entities',
        () async {
      expect(
        await _paintLayerAgainstEntity(
          'l_tile_furniture',
          placedElement: true,
          includeBorder: true,
        ),
        _red,
      );
    });

    test('map with Border keeps foreground Tile above entities', () async {
      expect(
        await _paintLayerAgainstEntity(
          'l_tile_overhead',
          includeBorder: true,
        ),
        _blue,
      );
    });

    for (final layerId in <String>[
      'l_tile_overhead',
      'l_tile_occlusion',
    ]) {
      test('paints $layerId after normal entities', () async {
        expect(await _paintLayerAgainstEntity(layerId), _blue);
        expect(
          await _paintLayerAgainstEntity(
            layerId,
            placedElement: true,
          ),
          _blue,
        );
      });
    }

    test('keeps an ordinary tile layer below normal entities', () async {
      expect(await _paintLayerAgainstEntity('l_tile_furniture'), _red);
      expect(
        await _paintLayerAgainstEntity(
          'l_tile_furniture',
          placedElement: true,
        ),
        _red,
      );
    });

    test('group reorder immediately changes the painted top layer', () async {
      const map = MapData(
        id: 'reorder_paint',
        name: 'Reorder paint',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v6,
        visualStack: MapVisualStackConfig.canonicalV1,
        layers: <MapLayer>[
          TileLayer(
            id: 'blue_top',
            name: 'Blue top',
            palette: _testPalette,
            cells: <int>[2],
          ),
          TileLayer(
            id: 'red_bottom',
            name: 'Red bottom',
            palette: _testPalette,
            cells: <int>[1],
          ),
        ],
      );
      final reordered = const MapLayerGroupService().moveAdjacent(
        map: map,
        layerId: 'blue_top',
        direction: MapLayerGroupMoveDirection.down,
      );

      expect(await _paintMap(map), _blue);
      expect(await _paintMap(reordered), _red);
    });
  });
}

const _red = ui.Color(0xFFFF0000);
const _blue = ui.Color(0xFF0000FF);
const _testPalette = <TileLayerPaletteEntry>[
  TileLayerPaletteEntry(tilesetId: 'test_tileset', localTileId: 0),
  TileLayerPaletteEntry(tilesetId: 'test_tileset', localTileId: 1),
];

Future<ui.Color> _paintOverlappingLayers({
  Map<String, dynamic> properties = const <String, dynamic>{},
  bool explicitForeground = false,
  bool placedElements = false,
  bool includeBorder = false,
}) async {
  final bottomId = explicitForeground ? 'bottom_foreground' : 'bottom';
  final topId = explicitForeground ? 'top_foreground' : 'top';
  final map = MapData(
    id: 'layer_order_test',
    name: 'Layer order test',
    size: const GridSize(width: 1, height: 1),
    properties: properties,
    layers: <MapLayer>[
      TileLayer(
        id: bottomId,
        name: bottomId,
        palette: _testPalette,
        cells: <int>[placedElements ? 0 : 1],
      ),
      if (includeBorder)
        const BorderLayer(id: 'border-sentinel', name: 'Border sentinel'),
      TileLayer(
        id: topId,
        name: topId,
        palette: _testPalette,
        cells: <int>[placedElements ? 0 : 2],
      ),
    ],
    placedElements: placedElements
        ? <MapPlacedElement>[
            MapPlacedElement(
              id: 'bottom_element',
              layerId: bottomId,
              elementId: 'bottom_element',
              pos: const GridPos(x: 0, y: 0),
            ),
            MapPlacedElement(
              id: 'top_element',
              layerId: topId,
              elementId: 'top_element',
              pos: const GridPos(x: 0, y: 0),
            ),
          ]
        : const <MapPlacedElement>[],
  );
  return _paintMap(map);
}

Future<ui.Color> _paintMap(MapData map) async {
  final tilesetImage = await _twoColorTileset();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: <String, ui.Image?>{
      'test_tileset': tilesetImage,
    },
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{'test_tileset': 2},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    project: const ProjectManifest(
      name: 'Layer order test',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'bottom_element',
          name: 'Bottom element',
          tilesetId: 'test_tileset',
          categoryId: 'test',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
        ProjectElementEntry(
          id: 'top_element',
          name: 'Top element',
          tilesetId: 'test_tileset',
          categoryId: 'test',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
          ],
        ),
      ],
    ),
  ).paint(canvas, const ui.Size(16, 16));

  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 16);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final center = ((8 * image.width) + 8) * 4;
  final color = ui.Color.fromARGB(
    pixels!.getUint8(center + 3),
    pixels.getUint8(center),
    pixels.getUint8(center + 1),
    pixels.getUint8(center + 2),
  );

  picture.dispose();
  image.dispose();
  tilesetImage.dispose();
  return color;
}

Future<ui.Image> _twoColorTileset() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 16, 16),
    ui.Paint()..color = _red,
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(16, 0, 16, 16),
    ui.Paint()..color = _blue,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 16);
  picture.dispose();
  return image;
}

Future<ui.Color> _paintLayerAgainstEntity(
  String layerId, {
  bool placedElement = false,
  bool includeBorder = false,
}) async {
  final tilesetImage = await _twoColorTileset();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  MapGridPainter(
    map: MapData(
      id: 'foreground_marker_test',
      name: 'Foreground marker test',
      size: const GridSize(width: 1, height: 1),
      properties: includeBorder
          ? const <String, dynamic>{'tileLayerOrder': 'bottom_to_top'}
          : const <String, dynamic>{},
      layers: <MapLayer>[
        TileLayer(
          id: layerId,
          name: layerId,
          palette: _testPalette,
          cells: <int>[placedElement ? 0 : 2],
        ),
        if (includeBorder)
          const BorderLayer(id: 'border-sentinel', name: 'Border sentinel'),
      ],
      placedElements: placedElement
          ? <MapPlacedElement>[
              MapPlacedElement(
                id: 'overhead_element',
                layerId: layerId,
                elementId: 'overhead_element',
                pos: const GridPos(x: 0, y: 0),
              ),
            ]
          : const <MapPlacedElement>[],
      entities: const <MapEntity>[
        MapEntity(
          id: 'actor',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 0, y: 0),
          editorVisual: MapEntityEditorVisual(elementId: 'actor'),
        ),
      ],
    ),
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: <String, ui.Image?>{
      'test_tileset': tilesetImage,
    },
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{'test_tileset': 2},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    project: const ProjectManifest(
      name: 'Foreground marker test',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'actor',
          name: 'Actor',
          tilesetId: 'test_tileset',
          categoryId: 'test',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
        ProjectElementEntry(
          id: 'overhead_element',
          name: 'Overhead element',
          tilesetId: 'test_tileset',
          categoryId: 'test',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
          ],
        ),
      ],
    ),
  ).paint(canvas, const ui.Size(16, 16));

  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 16);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final center = ((8 * image.width) + 8) * 4;
  final color = ui.Color.fromARGB(
    pixels!.getUint8(center + 3),
    pixels.getUint8(center),
    pixels.getUint8(center + 1),
    pixels.getUint8(center + 2),
  );

  picture.dispose();
  image.dispose();
  tilesetImage.dispose();
  return color;
}
