import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

MapData itemMap() => MapData(
  id: 'field',
  name: 'Field',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(width: 8, depth: 8),
  entities: [
    MapEntity(
      id: 'item',
      kind: MapEntityKind.item,
      pos: const GridPos(x: 2, y: 2),
      item: const MapEntityItemData(gameItemId: 'resource'),
    ),
  ],
);

void main() {
  test(
    'placed model entity binding roundtrips and rejects missing or duplicate owners',
    () {
      final json = SpatialModelInstance(
        id: 'model',
        modelId: 'resource-model',
        position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
      ).toJson();
      final bound = SpatialModelInstance.fromJson({
        ...json,
        'entityId': 'item',
      });
      expect(bound.toJson()['entityId'], 'item');
      final map = itemMap();
      final configured = const SpatialMapOperations().upsertInstance(
        map,
        bound,
      );
      expect(
        MapData.fromJson(configured.toJson()).spatialScene!.instances.single,
        bound,
      );
      final moved = const SpatialMapOperations().upsertInstance(
        configured,
        bound.copyWith(position: Model3dVector3(x: 4.5, y: 0, z: 5.5)),
      );
      expect(moved.entities.single.pos, const GridPos(x: 4, y: 5));
      expect(
        () => MapData.fromJson(
          moved.copyWith(entities: itemMap().entities).toJson(),
        ),
        throwsFormatException,
      );
      expect(
        () => const SpatialMapOperations().upsertInstance(
          map,
          SpatialModelInstance.fromJson({...json, 'entityId': 'missing'}),
        ),
        throwsFormatException,
      );
      expect(
        () => const SpatialMapOperations().upsertInstance(
          configured,
          SpatialModelInstance.fromJson({
            ...json,
            'id': 'second',
            'entityId': 'item',
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => const SpatialMapOperations().upsertInstance(
          map,
          SpatialModelInstance.fromJson({...bound.toJson(), 'id': 'smt_generated'}),
        ),
        throwsFormatException,
      );
      expect(
        () => MapData.fromJson(configured.copyWith(entities: []).toJson()),
        throwsFormatException,
      );
      final repeating = map.copyWith(
        entities: [
          map.entities.single.copyWith(
            item: const MapEntityItemData(
              gameItemId: 'resource',
              pickupMode: ItemPickupMode.always,
            ),
          ),
        ],
      );
      expect(
        () => const SpatialMapOperations().upsertInstance(repeating, bound),
        throwsFormatException,
      );
    },
  );
}
