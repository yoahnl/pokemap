import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';
import 'spatial_model_entity_controls_support.dart';

void main() {
  for (final kind in const [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.strengthBoulder,
    FieldObstacleKind.rockSmashRock,
  ]) {
    test(
      '$kind creates a bound entity with reset policy and one undo',
      () async {
        final original = spatialEnvironmentMap();
        final instance = SpatialModelInstance(
          id: 'oak-1',
          modelId: 'oak',
          position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
          blocksMovement: true,
        );
        final map = original.copyWith(
          spatialScene: original.spatialScene!.copyWith(instances: [instance]),
        );
        final document = entityDocument(map);
        final commands = SpatialModelEditingCommands(
          document,
          spatialEnvironmentProject(),
        );
        expect(commands.canConfigureFieldObstacle(instance.id), isTrue);
        expect(
          await commands.configureFieldObstacle(
            instance.id,
            MapEntityFieldObstacleData(kind: kind),
          ),
          isTrue,
        );
        expect(document.current.entities.single.fieldObstacle!.kind, kind);
        expect(
          isValidSpatialFieldObstacle(
            document.current,
            document.current.entities.single,
          ),
          isTrue,
        );
        expect(document.undoCount, 1);
        expect(
          await commands.configureFieldObstacle(
            instance.id,
            MapEntityFieldObstacleData(
              kind: kind,
              resetPolicy: FieldObstacleResetPolicy.persistent,
            ),
          ),
          isTrue,
        );
        expect(
          document.current.entities.single.fieldObstacle!.resetPolicy,
          FieldObstacleResetPolicy.persistent,
        );
        document.restore(redo: false);
        document.restore(redo: false);
        expect(document.current, map);
      },
    );
  }

  test('ice block is refused in 3D without changing map or history', () async {
    final original = spatialEnvironmentMap();
    final map = original.copyWith(
      spatialScene: original.spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'oak-1',
            modelId: 'oak',
            position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
            blocksMovement: true,
          ),
        ],
      ),
    );
    final document = entityDocument(map);
    final commands = SpatialModelEditingCommands(
      document,
      spatialEnvironmentProject(),
    );
    expect(
      await commands.configureFieldObstacle(
        'oak-1',
        const MapEntityFieldObstacleData(kind: FieldObstacleKind.iceBlock),
      ),
      isFalse,
    );
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    expect(document.error, isNotNull);
  });

  test(
    'binding choices exclude NPC and repeating pickups and support undo',
    () {
      final instance = SpatialModelInstance(
        id: 'orb',
        modelId: 'oak',
        position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
      );
      final original = spatialEnvironmentMap();
      final map = original.copyWith(
        spatialScene: original.spatialScene!.copyWith(instances: [instance]),
        entities: [
          MapEntity(
            id: 'item',
            name: 'Objet',
            kind: MapEntityKind.item,
            pos: const GridPos(x: 1, y: 1),
            item: const MapEntityItemData(gameItemId: 'resource'),
          ),
          MapEntity(
            id: 'repeat',
            name: 'Objet répétable',
            kind: MapEntityKind.item,
            pos: const GridPos(x: 2, y: 1),
            item: const MapEntityItemData(
              gameItemId: 'resource',
              pickupMode: ItemPickupMode.always,
            ),
          ),
          MapEntity(
            id: 'npc',
            name: 'Habitant',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 3, y: 1),
          ),
        ],
      );
      final document = entityDocument(map);
      final commands = SpatialModelEditingCommands(
        document,
        spatialEnvironmentProject(),
      );
      expect(commands.bindableEntities(instance.id).map((entry) => entry.id), [
        'item',
      ]);
      expect(commands.bindEntity('orb', 'repeat'), isFalse);
      expect(commands.bindEntity('orb', 'npc'), isFalse);
      expect(commands.bindEntity('orb', 'missing'), isFalse);
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
      expect(commands.bindEntity('orb', 'item'), isTrue);
      expect(document.current.spatialScene!.instances.single.entityId, 'item');
      expect(document.current.entities.first.pos, const GridPos(x: 4, y: 3));
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, map);
    },
  );

  test(
    'obstacle delegates to targeted publisher and saving refuses local writes',
    () async {
      final map = spatialEnvironmentMap();
      final document = entityDocument(map);
      final calls = <(String, MapEntityFieldObstacleData?)>[];
      document.configureSpatialFieldObstacle = (id, value) async {
        calls.add((id, value));
        return false;
      };
      final commands = SpatialModelEditingCommands(
        document,
        spatialEnvironmentProject(),
      );
      const value = MapEntityFieldObstacleData(kind: FieldObstacleKind.cutTree);
      expect(await commands.configureFieldObstacle('oak-1', value), isFalse);
      expect(calls, [('oak-1', value)]);
      document.saving = true;
      expect(await commands.configureFieldObstacle('oak-1', value), isFalse);
      expect(commands.bindEntity('oak-1', 'entity'), isFalse);
      expect(calls, hasLength(1));
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
    },
  );
}
