import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'model visibility follows daily state without hiding its bound entity',
    () async {
      final anchor = MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 4, y: 4),
        blocksMovement: true,
      );
      final session = await _loadActorLookupSession([anchor]);
      final reference = PeriodicRewardReference(
        sceneId: 'harvest',
        nodeId: 'claim',
        rewardId: 'fruit',
      );
      final command = SceneInteractiveCommand.claimPeriodicReward(
        definition: PeriodicItemRewardDefinition(
          rewardId: 'fruit',
          label: 'Fruit',
          itemId: 'fruit',
          quantity: 1,
        ),
      );
      final source = SceneAsset(
        id: 'harvest',
        name: 'Harvest',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'claim',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(command),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'claim',
              kind: SceneEdgeKind.defaultFlow,
            ),
            for (final port in command.outputPortIds)
              SceneEdge(
                id: port,
                fromNodeId: 'claim',
                fromPortId: port,
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
          ],
        ),
      );
      final original = session.bundle;
      final map = original.map.copyWith(
        spatialScene: original.map.spatialScene!.copyWith(
          instances: [
            for (final full in [true, false])
              SpatialModelInstance(
                id: full ? 'full' : 'empty',
                modelId: 'tree',
                position: Model3dVector3(x: 4.5, y: 0, z: 4.5),
                entityId: full ? 'tree' : null,
                blocksMovement: false,
                visibilityCondition: NarrativeEventConditionExpression.leaf(
                  NarrativeEventCondition.periodicRewardAvailable(
                    reference: reference,
                    expectedValue: full,
                  ),
                ),
              ),
          ],
        ),
      );
      session.bundle = original.copyWith(
        map: map,
        manifest: original.manifest.copyWith(scenes: [source]),
      );
      var reads = 0;
      session.lookupRewardScenes = (id) {
        reads++;
        expect(id, 'harvest');
        return [source];
      };
      var state = GameState(
        saveId: 'visibility',
        gameplayCalendarState: GameplayCalendarState(
          observedLocalDay: '2026-10-31',
          dayRevision: 1,
        ),
      );
      session.presentationStateProvider = () => state;
      for (var i = 0; i < 20; i++) {
        expect(session.modelIsPresent('map', 'full'), isTrue);
        expect(session.modelIsPresent('map', 'empty'), isFalse);
      }
      expect(reads, 1);
      state = state.copyWith(
        periodicRewardState: PeriodicRewardState(
          claimsById: {
            'fruit': PeriodicRewardClaim(
              revision: 1,
              lastClaimDayRevision: 1,
              lastClaimLocalDay: '2026-10-31',
            ),
          },
        ),
      );
      expect(session.modelIsPresent('map', 'full'), isFalse);
      expect(session.modelIsPresent('map', 'empty'), isTrue);
      expect(session.fieldObstacleIsPresent('tree'), isTrue);
      expect(session.bundle.map.entities.single.blocksMovement, isTrue);
      state = state.copyWith(
        gameplayCalendarState: GameplayCalendarState(
          observedLocalDay: '2026-11-01',
          dayRevision: 2,
        ),
      );
      expect(session.modelIsPresent('map', 'full'), isTrue);
      expect(session.modelIsPresent('map', 'empty'), isFalse);
      expect(reads, 1);
      session.presentationStateProvider = null;
      expect(session.modelIsPresent('map', 'full'), isFalse);
      expect(session.modelIsPresent('map', 'empty'), isFalse);
      session.presentationStateProvider = () => state;
      session.lookupRewardScenes = (_) => const [];
      expect(session.modelIsPresent('map', 'full'), isFalse);
      expect(session.modelIsPresent('map', 'empty'), isFalse);
      session.lookupRewardScenes = (_) => [source];
      expect(session.modelIsPresent('map', 'full'), isTrue);
    },
  );

  for (final actorCount in [10, 1000]) {
    test(
      'installed actor lookup avoids source scans for $actorCount live actors',
      () async {
        final entities = _ReadCountingEntities([
          for (var index = 0; index < actorCount; index++)
            MapEntity(
              id: 'actor-$index',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 6, y: 6),
              npc: const MapEntityNpcData(characterId: 'actor'),
            ),
        ]);
        final blockerId = 'actor-${actorCount - 1}';
        var world = const SpatialWorldState.empty();
        var worldReads = 0;
        var present = true;
        final session = await _loadActorLookupSession(
          entities,
          worldStateProvider: () {
            worldReads++;
            return world;
          },
          entityIsPresent: (_, _) => present,
        );
        session.attachWorldStateProviders();
        entities.reads = 0;
        worldReads = 0;

        expect(
          session.movement.canTraverseActor(2.5, 2.5, 2.5625, 2.5),
          isTrue,
        );
        expect(session.movement.isPositionTraversable, isTrue);
        expect(worldReads, greaterThanOrEqualTo(actorCount * 3));
        expect(entities.reads, 0);

        world = world.setActorState(
          'map',
          blockerId,
          SpatialActorRuntimeState(x: 2.5, z: 2.5, facing: EntityFacing.west),
        );
        expect(session.movement.isPositionTraversable, isFalse);
        expect(
          session.movement.canTraverseActor(2.5, 2.5, 2.5625, 2.5),
          isFalse,
        );
        present = false;
        expect(session.movement.isPositionTraversable, isTrue);
        present = true;
        expect(session.movement.isPositionTraversable, isFalse);
        session.entityProjection = (_, entity) => entity.id == blockerId
            ? entity.copyWith(blocksMovement: false)
            : entity;
        expect(session.movement.isPositionTraversable, isTrue);
        session.entityProjection = null;
        expect(session.movement.isPositionTraversable, isFalse);
        session.worldStateProvider = () => const SpatialWorldState.empty();
        expect(session.movement.isPositionTraversable, isTrue);
        expect(entities.reads, 0);
      },
    );
  }

  test(
    'installed actor lookup keeps live story and autonomy pose precedence',
    () async {
      final entities = _ReadCountingEntities([
        const MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 6, y: 6),
          npc: MapEntityNpcData(characterId: 'actor'),
        ),
      ]);
      final session = await _loadActorLookupSession(
        entities,
        worldStateProvider: () => const SpatialWorldState.empty().setActorState(
          'map',
          'npc',
          SpatialActorRuntimeState(x: 2.5, z: 2.5, facing: EntityFacing.south),
        ),
      );
      session.attachWorldStateProviders();
      entities.reads = 0;
      const clear = SpatialCinematicActorPose(
        x: 6.5,
        z: 6.5,
        facing: EntityFacing.north,
      );
      const blocked = SpatialCinematicActorPose(
        x: 2.5,
        z: 2.5,
        facing: EntityFacing.east,
      );
      SpatialCinematicActorPose? story;
      var autonomous = clear;
      var storyReads = 0;
      var autonomousReads = 0;
      session.npcStoryPose = (_) {
        storyReads++;
        return story;
      };
      session.npcAutonomousPose = (_) {
        autonomousReads++;
        return autonomous;
      };

      expect(session.movement.isPositionTraversable, isTrue);
      expect(storyReads, 1);
      expect(autonomousReads, 1);
      story = blocked;
      expect(session.movement.isPositionTraversable, isFalse);
      expect(autonomousReads, 1);
      expect(
        session.movement.actorStateProvider!('npc')!.facing,
        EntityFacing.east,
      );
      story = clear;
      expect(session.movement.isPositionTraversable, isTrue);
      story = null;
      autonomous = blocked;
      expect(session.movement.isPositionTraversable, isFalse);
      session.npcAutonomousPose = null;
      expect(
        session.movement.actorStateProvider!('npc')!.facing,
        EntityFacing.south,
      );
      expect(session.movement.isPositionTraversable, isFalse);
      expect(entities.reads, 0);
    },
  );

  test(
    'installed actor lookup preserves first owner and replacement identity',
    () async {
      const first = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 6, y: 6),
        npc: MapEntityNpcData(characterId: 'actor'),
      );
      const duplicate = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 4),
        npc: MapEntityNpcData(characterId: 'actor'),
      );
      final entities = _ReadCountingEntities([first, duplicate]);
      final session = await _loadActorLookupSession(entities);
      final original = session.bundle;
      MapEntity? resolved;
      session.npcStoryPose = (entity) {
        resolved = entity;
        return SpatialCinematicActorPose(
          x: entity.pos.x + .5,
          z: entity.pos.y + .5,
          facing: EntityFacing.north,
        );
      };
      session.attachWorldStateProviders();
      entities.reads = 0;
      expect(session.movement.canTraverseActor(4.5, 4.5, 4.5625, 4.5), isTrue);
      expect(resolved, same(first));
      expect(session.movement.actorStateProvider!('missing'), isNull);
      expect(resolved, same(first));
      expect(entities.reads, 0);

      final replacements = _ReadCountingEntities([duplicate]);
      session.bundle = original.copyWith(
        map: original.map.copyWith(entities: replacements),
      );
      session.attachWorldStateProviders();
      replacements.reads = 0;
      expect(session.movement.canTraverseActor(4.5, 4.5, 4.5625, 4.5), isFalse);
      expect(resolved, same(duplicate));
      expect(replacements.reads, 0);
      session.bundle = original;
      session.attachWorldStateProviders();
      expect(session.movement.canTraverseActor(4.5, 4.5, 4.5625, 4.5), isTrue);
      expect(resolved, same(first));
      expect(entities.reads, 0);
    },
  );

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
              visibilityCondition: NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.fact('hidden', false),
              ),
            ),
            SpatialModelInstance(
              id: 'neighbor-dependent',
              modelId: 'model',
              blocksMovement: false,
              position: Model3dVector3(x: 1, y: 0, z: 1),
              visibilityCondition: NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.mapEventInstanceBoolean(
                  mapId: 'neighbor', eventId: 'entity-255', key: 'on',
                  expectedValue: true,
                ),
              ),
            ),
          ],
        ),
      );
      final bundle = RuntimeMapBundle(
        manifest: ProjectManifest(
          name: 'Model presence',
          maps: const [],
          tilesets: const [],
          facts: [NarrativeFactDefinition(id: 'hidden', label: 'Hidden')],
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
      var state = GameState(saveId: 'model-presence',
        mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
          'neighbor': MapInstanceRuntimeState(instanceId: 'neighbor-1',
            eventBooleans: {'entity-255': {'on': true}}),
        }),
      );
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
      session.presentationStateProvider = () => state;

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
      expect(session.modelIsPresent('map', 'neighbor-dependent'), isFalse);
      await session.loadConnectionNeighbor(map.connections.single);
      neighborEntities.reads = 0;
      for (var index = 0; index < 256; index++) {
        expect(session.modelIsPresent('neighbor', 'model-$index'), isTrue);
      }
      expect(neighborEntities.reads, lessThanOrEqualTo(256));
      expect(session.modelIsPresent('map', 'neighbor-dependent'), isTrue);
      neighborEntities.reads = 0;
      for (var i = 0; i < 100; i++) {
        expect(session.modelIsPresent('map', 'neighbor-dependent'), isTrue);
      }
      expect(neighborEntities.reads, 0);
      hidden.add('neighbor:entity-255');
      expect(session.modelIsPresent('neighbor', 'model-255'), isFalse);
      expect(neighborEntities.reads, 0);
      expect(session.modelIsPresent('neighbor', 'unlinked'), isTrue);
      state = state.copyWith(
        storyFlags: const StoryFlags(activeFlags: {'hidden'}),
      );
      expect(session.modelIsPresent('map', 'unlinked'), isFalse);
      expect(session.modelIsPresent('neighbor', 'unlinked'), isFalse);
      state = const GameState(saveId: 'model-presence');
      expect(session.modelIsPresent('map', 'unlinked'), isTrue);
      expect(session.modelIsPresent('neighbor', 'unlinked'), isTrue);
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

Future<SpatialExplorationSession> _loadActorLookupSession(
  List<MapEntity> entities, {
  SpatialWorldState Function()? worldStateProvider,
  bool Function(String, MapEntity)? entityIsPresent,
}) async {
  final qaRoot = Directory(
    Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
  );
  await qaRoot.create(recursive: true);
  final root = await qaRoot.createTemp('actor-lookup-');
  addTearDown(() => root.delete(recursive: true));
  final path = '${root.path}/actor.png';
  await File(path)
      .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
  final session = await SpatialExplorationSession.load(
    RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Actor lookup',
        maps: const [],
        tilesets: const [],
        settings: const ProjectSettings(
          dimension: ProjectDimension.threeD,
          defaultPlayerCharacterId: 'actor',
        ),
        characters: [
          ProjectCharacterEntry(
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
                      source: TilesetSourceRect(
                        x: 0,
                        y: 0,
                        width: 32,
                        height: 32,
                      ),
                      durationMs: 100,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
      map: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        entities: entities,
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 2.5, z: 2.5),
          ),
        ),
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {'actor': path},
    ),
    entityIsPresent: entityIsPresent,
  );
  addTearDown(session.dispose);
  session.worldStateProvider = worldStateProvider;
  return session;
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
