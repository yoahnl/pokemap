import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('spatial object contracts', () {
    test('entity payload incompatible with kind is refused', () {
      const entity = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 0, y: 0),
        sign: MapEntitySignData(plainText: 'wrong payload'),
      );

      expect(
        () => const EntityActions().create(_emptyMap(), entity),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'entity.payload_kind_mismatch',
          ),
        ),
      );
    });

    test('batch move is atomic when one entity would leave map bounds', () {
      final map = _emptyMap().copyWith(
        entities: const [
          MapEntity(
            id: 'first',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 0, y: 0),
          ),
          MapEntity(
            id: 'second',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      expect(
        () => const EntityActions().moveBatch(
          map,
          const {
            'first': GridPos(x: 1, y: 1),
            'second': GridPos(x: 4, y: 4),
          },
        ),
        throwsA(isA<MapAuthoringException>()),
      );
      expect(map.entities[0].pos, const GridPos(x: 0, y: 0));
      expect(map.entities[1].pos, const GridPos(x: 2, y: 2));
    });

    test('dispatcher exposes placed, entity, NPC, trigger and zone actions',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'placed_element.place',
          'placed_element.move',
          'placed_element.delete',
          'entity.create',
          'entity.batch_move',
          'entity.delete',
          'npc.set_dialogue',
          'npc.set_visibility_rule',
          'npc.set_movement_mode',
          'npc.waypoint_add',
          'trigger.create',
          'trigger.delete_apply',
          'gameplay_zone.create',
          'gameplay_zone.set_hazard_payload',
          'gameplay_zone.delete',
        }),
      );
    });
  });
}

MapData _emptyMap() => const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 4, height: 4),
    );
