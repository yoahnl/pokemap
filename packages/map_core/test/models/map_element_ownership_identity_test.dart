import 'package:map_core/map_core_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'unrelated immutable map edits retain ownership storage despite getter wrappers',
    () {
      final map = MapData(
        id: 'a',
        name: 'A',
        size: const GridSize(width: 4, height: 4),
        layers: [const MapLayer.tile(id: 'ground', name: 'Sol')],
        placedElements: [
          const MapPlacedElement(
            id: 'mist',
            layerId: 'ground',
            elementId: 'mist',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      expect(identical(map.layers, map.layers), isFalse);
      expect(
        mapSharesElementOwnershipStorage(map, map.copyWith(name: 'Renamed')),
        isTrue,
      );
      expect(
        mapSharesElementOwnershipStorage(
          map,
          map.copyWith(
            entities: const [
              MapEntity(
                id: 'npc',
                name: 'NPC',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 1, y: 1),
              ),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        mapSharesElementOwnershipStorage(
          map,
          map.copyWith(
            placedElements: [
              map.placedElements.single.copyWith(layerId: 'other'),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        mapSharesElementOwnershipStorage(
          map,
          map.copyWith(layers: [map.layers.single.copyWith(name: 'Other')]),
        ),
        isFalse,
      );
      expect(
        mapSharesNonVisualOrderStorage(
          map,
          map.copyWith(layers: map.layers.reversed.toList()),
        ),
        isTrue,
      );
      expect(
        mapSharesNonVisualOrderStorage(map, map.copyWith(name: 'Renamed')),
        isFalse,
      );
      expect(
        mapSharesNonVisualOrderStorage(
          map,
          map.copyWith(
            entities: const [
              MapEntity(
                id: 'npc',
                name: 'NPC',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 1, y: 1),
              ),
            ],
          ),
        ),
        isFalse,
      );
    },
  );
}
