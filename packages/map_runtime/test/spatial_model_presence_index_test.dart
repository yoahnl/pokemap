import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'model presence indexes authored identities once and keeps live predicates',
    () async {
      final qaRoot = Directory(
        Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
      );
      await qaRoot.create(recursive: true);
      final root = await qaRoot.createTemp('model-presence-');
      addTearDown(() => root.delete(recursive: true));
      final actorPath = '${root.path}/actor.png';
      await File(actorPath)
          .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
      final actor = ProjectCharacterEntry(
        id: 'actor',
        name: 'Actor',
        tilesetId: 'unused',
        animations: [
          for (final direction in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: direction,
              sourceAssetId: 'actor',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                  durationMs: 100,
                ),
              ],
            ),
        ],
      );
      final entities = _ReadCountingEntities([
        for (var index = 0; index < 256; index++)
          MapEntity(
            id: 'entity-$index',
            kind: MapEntityKind.item,
            pos: const GridPos(x: 1, y: 1),
            blocksMovement: false,
            item: const MapEntityItemData(gameItemId: 'item'),
          ),
      ]);
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        entities: entities,
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'neighbor',
          ),
        ],
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          instances: [
            for (var index = 0; index < 256; index++)
              SpatialModelInstance(
                id: 'model-$index',
                modelId: 'model',
                entityId: 'entity-$index',
                blocksMovement: false,
                position: Model3dVector3(x: 1, y: 0, z: 1),
              ),
            SpatialModelInstance(
              id: 'unlinked',
              modelId: 'model',
              blocksMovement: false,
              position: Model3dVector3(x: 1, y: 0, z: 1),
            ),
          ],
        ),
      );
      final bundle = RuntimeMapBundle(
        manifest: ProjectManifest(
          name: 'Model presence',
          maps: const [],
          tilesets: const [],
          settings: const ProjectSettings(
            dimension: ProjectDimension.threeD,
            defaultPlayerCharacterId: 'actor',
          ),
          characters: [actor],
        ),
        map: map,
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {'actor': actorPath},
      );
      final neighborEntities = _ReadCountingEntities(entities.values);
      final neighborBundle = bundle.copyWith(
        map: map.copyWith(
          id: 'neighbor',
          entities: neighborEntities,
          connections: const [],
        ),
      );
      final hidden = <String>{};
      var predicates = 0;
      final session = await SpatialExplorationSession.load(
        bundle,
        entityIsPresent: (mapId, entity) {
          predicates++;
          return !hidden.contains('$mapId:${entity.id}');
        },
        loadMap: (_) async => neighborBundle,
      );
      addTearDown(session.dispose);

      entities.reads = 0;
      for (var index = 0; index < 256; index++) {
        expect(session.modelIsPresent('map', 'model-$index'), isTrue);
      }
      expect(entities.reads, lessThanOrEqualTo(256));
      entities.reads = 0;
      predicates = 0;
      hidden.add('map:entity-255');
      for (var index = 0; index < 256; index++) {
        expect(session.modelIsPresent('map', 'model-$index'), index != 255);
      }
      expect(entities.reads, 0);
      expect(predicates, 256);
      expect(session.modelIsPresent('map', 'unlinked'), isTrue);
      expect(session.modelIsPresent('map', 'missing-model'), isTrue);
      expect(session.modelIsPresent('unloaded', 'model-0'), isFalse);
      await session.loadConnectionNeighbor(map.connections.single);
      neighborEntities.reads = 0;
      for (var index = 0; index < 256; index++) {
        expect(session.modelIsPresent('neighbor', 'model-$index'), isTrue);
      }
      expect(neighborEntities.reads, lessThanOrEqualTo(256));
      neighborEntities.reads = 0;
      hidden.add('neighbor:entity-255');
      expect(session.modelIsPresent('neighbor', 'model-255'), isFalse);
      expect(neighborEntities.reads, 0);
      hidden.clear();
      expect(session.modelIsPresent('map', 'model-255'), isTrue);

      entities.reads = 0;
      session.bundle = bundle.copyWith(
        map: map.copyWith(entities: [entities[0].copyWith(id: 'replacement')]),
      );
      expect(session.modelIsPresent('map', 'model-0'), isFalse);
      session.bundle = bundle;
      expect(session.modelIsPresent('map', 'model-0'), isTrue);
      expect(entities.reads, 1);
    },
  );
}

final class _ReadCountingEntities extends ListBase<MapEntity> {
  _ReadCountingEntities(this.values);

  final List<MapEntity> values;
  int reads = 0;

  @override
  int get length => values.length;

  @override
  set length(int value) => throw UnsupportedError('Immutable fixture');

  @override
  MapEntity operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, MapEntity value) =>
      throw UnsupportedError('Immutable fixture');
}
