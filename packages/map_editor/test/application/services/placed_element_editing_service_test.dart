import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_editing_service.dart';

void main() {
  group('PlacedElementEditingService canonical intents', () {
    const service = PlacedElementEditingService();

    test('builds one authored placed_element.place intent without tile writes',
        () {
      const source = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 16, height: 12),
        layers: <MapLayer>[
          TileLayer(
            id: 'objects',
            name: 'Objects',
            palette: <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(tilesetId: 'village', localTileId: 7),
            ],
            cells: <int>[1],
          ),
        ],
      );

      final intent = service.buildPlaceIntent(
        map: source,
        layerId: 'objects',
        elementId: 'guesthouse',
        pos: const GridPos(x: 4, y: 3),
      );

      expect(intent.actionId, 'placed_element.place');
      final instance = MapPlacedElement.fromJson(
        Map<String, dynamic>.from(intent.parameters['instance']! as Map),
      );
      expect(instance.id, 'objects::4::3');
      expect(instance.layerId, 'objects');
      expect(instance.elementId, 'guesthouse');
      expect(instance.pos, const GridPos(x: 4, y: 3));
      expect(instance.applyCollision, isTrue);
      expect(instance.properties['pokemapPlacementOrigin'], 'authored');
      expect(source.layers.whereType<TileLayer>().single.cells, const [1]);
      expect(source.placedElements, isEmpty);
    });

    test('reserves a stable suffix when the position id already exists', () {
      const source = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 8, height: 8),
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'objects::2::2',
            layerId: 'objects',
            elementId: 'tree',
            pos: GridPos(x: 2, y: 2),
          ),
          MapPlacedElement(
            id: 'objects::2::2_2',
            layerId: 'objects',
            elementId: 'rock',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      final intent = service.buildPlaceIntent(
        map: source,
        layerId: 'objects',
        elementId: 'guesthouse',
        pos: const GridPos(x: 2, y: 2),
      );

      final instance = MapPlacedElement.fromJson(
        Map<String, dynamic>.from(intent.parameters['instance']! as Map),
      );
      expect(instance.id, 'objects::2::2_3');
    });
  });
}
