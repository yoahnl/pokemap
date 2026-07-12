import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'support/selbrume_map_test_fixture.dart';
import 'surface/surface_runtime_test_support.dart';

const _interiorMapIds = <String>[
  'map_phare_interieur',
  'map_sommet_phare',
  'map_cabane_gardien',
  'map_maison_joueur',
];

const _interiorLayerIds = <String>[
  'l_terrain',
  'l_tile_floor',
  'l_tile_walls',
  'l_tile_furniture',
  'l_tile_overhead',
  'l_tile_fx',
  'l_collisions',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the four Selbrume interiors expose the canonical seven layers',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };

    for (final mapId in _interiorMapIds) {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: SelbrumeMapTestFixture.projectFilePath,
        mapId: mapId,
      );
      final map = bundle.map;
      final expectedCellCount = map.size.width * map.size.height;

      expect(map.layers.map((layer) => layer.id), _interiorLayerIds,
          reason: '$mapId must keep the Section 5.3 layer order');
      expect(map.layers.first, isA<TerrainLayer>(), reason: mapId);
      for (var index = 1; index <= 5; index += 1) {
        expect(map.layers[index], isA<TileLayer>(),
            reason: '$mapId/${_interiorLayerIds[index]}');
      }
      expect(map.layers.last, isA<CollisionLayer>(), reason: mapId);

      for (final layer in map.layers) {
        final cellCount = switch (layer) {
          TerrainLayer(:final terrains) => terrains.length,
          TileLayer(:final tiles) => tiles.length,
          CollisionLayer(:final collisions) => collisions.length,
          _ => -1,
        };
        expect(cellCount, expectedCellCount, reason: '$mapId/${layer.id}');
      }

      final tileLayersById = <String, TileLayer>{
        for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
      };
      for (final placed in map.placedElements) {
        final targetLayer = tileLayersById[placed.layerId];
        final element = elementsById[placed.elementId];
        expect(targetLayer, isNotNull,
            reason: '$mapId/${placed.id} must target an existing TileLayer');
        expect(element, isNotNull,
            reason: '$mapId/${placed.id} must target a registered element');
        expect(placed.layerId, element!.recommendedLayerId,
            reason: '$mapId/${placed.id} must use the authored layer contract');
        expect(targetLayer!.tilesetId, element.tilesetId,
            reason: '$mapId/${placed.id} must use the layer atlas it declares');
      }

      expect(map.properties['tileLayerOrder'], 'bottom_to_top', reason: mapId);
      expect(
        map.layers.map((layer) => layer.id),
        isNot(contains('l_host_selbrume_lighthouse_interior')),
        reason: mapId,
      );
      expect(
        map.layers.map((layer) => layer.id),
        isNot(contains('l_host_selbrume_cabin_interior')),
        reason: mapId,
      );
    }
  });

  test('bottom_to_top is opt-in and legacy maps retain reverse tile order',
      () async {
    final legacy = await _renderTwoLayerMap(const <String, dynamic>{});
    final canonical = await _renderTwoLayerMap(
      const <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
    );

    // Historical maps list their highest-priority layer first, so the first
    // (red) tile remains on top unless the new contract is explicitly enabled.
    expect(await pixelAt(legacy, 16, 16), rgba(200, 20, 20, 255));
    // Canonical interiors list layers bottom-to-top: the second (green) tile
    // must therefore be painted last and remain visible.
    expect(await pixelAt(canonical, 16, 16), rgba(20, 200, 20, 255));

    final legacyPlaced = await _renderTwoLayerMap(
      const <String, dynamic>{},
      placedElements: true,
    );
    final canonicalPlaced = await _renderTwoLayerMap(
      const <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
      placedElements: true,
    );
    expect(await pixelAt(legacyPlaced, 16, 16), rgba(200, 20, 20, 255));
    expect(await pixelAt(canonicalPlaced, 16, 16), rgba(20, 200, 20, 255));
  });
}

Future<ui.Image> _renderTwoLayerMap(
  Map<String, dynamic> properties, {
  bool placedElements = false,
}) async {
  final component = MapLayersComponent(
    bundle: surfaceTestBundle(
      map: MapData(
        id: 'layer-order-contract',
        name: 'Layer order contract',
        size: const GridSize(width: 1, height: 1),
        properties: properties,
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'bottom',
            name: 'Bottom',
            tilesetId: 'red',
            tiles: <int>[placedElements ? 0 : 1],
          ),
          MapLayer.tile(
            id: 'top',
            name: 'Top',
            tilesetId: 'green',
            tiles: <int>[placedElements ? 0 : 1],
          ),
        ],
        placedElements: placedElements
            ? const <MapPlacedElement>[
                MapPlacedElement(
                  id: 'bottom-element',
                  layerId: 'bottom',
                  elementId: 'bottom-element',
                  pos: GridPos(x: 0, y: 0),
                ),
                MapPlacedElement(
                  id: 'top-element',
                  layerId: 'top',
                  elementId: 'top-element',
                  pos: GridPos(x: 0, y: 0),
                ),
              ]
            : const <MapPlacedElement>[],
      ),
      elements: const <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'bottom-element',
          name: 'Bottom element',
          tilesetId: 'red',
          categoryId: 'test',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
        ProjectElementEntry(
          id: 'top-element',
          name: 'Top element',
          tilesetId: 'green',
          categoryId: 'test',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    ),
    tileImagesByTilesetId: <String, RuntimeTilesetImage>{
      'red': await runtimeTilesetImage(const <Color>[Color(0xFFC81414)]),
      'green': await runtimeTilesetImage(const <Color>[Color(0xFF14C814)]),
    },
  );
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  return recorder.endRecording().toImage(
        surfaceTestTileSize,
        surfaceTestTileSize,
      );
}
