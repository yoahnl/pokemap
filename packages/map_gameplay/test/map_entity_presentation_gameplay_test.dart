import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test(
      'a new page applies its declared facing and unchanged page preserves route facing',
      () {
    final condition = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('changed', true));
    final owner = MapEntity(
        id: 'owner',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 2),
        npc: const MapEntityNpcData(characterId: 'hero'),
        presentation: MapEntityPresentation(variants: [
          MapEntityPresentationVariant(
              id: 'changed',
              condition: condition,
              characterId: 'hero',
              facing: EntityFacing.west,
              blocksMovement: true),
          MapEntityPresentationVariant(
              id: 'base',
              condition: NarrativeEventConditionExpression.not(condition),
              characterId: 'hero',
              facing: EntityFacing.south,
              blocksMovement: true),
        ]));
    final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        entities: [owner]);
    final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'actors')
        ],
        facts: [
          NarrativeFactDefinition(id: 'changed', label: 'Changed')
        ]);
    const initial = GameState(saveId: 'save');
    final old = GameplayWorldState.initial(
            map: map,
            project: project,
            gameState: initial,
            playerPos: const GridPos(x: 0, y: 0))
        .withEntityFacing('owner', EntityFacing.east);
    final state = initial.copyWith(
        storyFlags: const StoryFlags(activeFlags: {'changed'}));
    final changed = old.withEntityPresentations(
        project: project, gameState: state, sourceMap: map);
    expect(changed.map.entities.single.npc!.facing, EntityFacing.west);
    final faced = changed.withEntityFacing('owner', EntityFacing.north);
    expect(
        faced
            .withEntityPresentations(
                project: project, gameState: state, sourceMap: map)
            .map
            .entities
            .single
            .npc!
            .facing,
        EntityFacing.north);
  });

  test(
      'spatial collision and interaction consume the current presentation before spawn checks',
      () {
    var state = const GameState(saveId: 'save');
    final condition = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('changed', true));
    final owner = MapEntity(
        id: 'owner',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 3, y: 3),
        npc: const MapEntityNpcData(characterId: 'hero'),
        presentation: MapEntityPresentation(variants: [
          MapEntityPresentationVariant(
              id: 'changed',
              condition: condition,
              blocksMovement: false,
              interactionMode: MapEntityInteractionMode.overlap),
          MapEntityPresentationVariant(
              id: 'base',
              condition: NarrativeEventConditionExpression.not(condition),
              characterId: 'hero',
              blocksMovement: true,
              size: const GridSize(width: 2, height: 2)),
        ]));
    final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 8),
        entities: [owner],
        spatialScene: MapSpatialScene(
            width: 8, depth: 8, heightLevels: List.filled(64, 0)));
    final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'actors')
        ],
        facts: [NarrativeFactDefinition(id: 'changed', label: 'Changed')]);
    MapEntity? resolve(MapEntity entity) => projectMapEntityPresentation(
        project: project, gameState: state, map: map, entity: entity);
    final movement = SpatialMovementController.fromMap(
        map: map,
        models: const [],
        spatialArrival: PlayerSpatialPosition(x: 2.5, z: 3.5),
        entityProjection: resolve);
    expect(movement.canTraverseActor(2.5, 3.5, 3.5, 3.5), isFalse);
    state =
        state.copyWith(storyFlags: const StoryFlags(activeFlags: {'changed'}));
    expect(movement.canTraverseActor(2.5, 3.5, 3.5, 3.5), isTrue);
    expect(
        findSpatialEntityInteraction(
                scene: map.spatialScene!,
                entities: [resolve(owner)!],
                x: 3.5,
                z: 3.5,
                facing: EntityFacing.north)
            ?.id,
        'owner');
    expect(
        () => SpatialMovementController.fromMap(
            map: map,
            models: const [],
            spatialArrival: PlayerSpatialPosition(x: 3.5, z: 3.5),
            entityProjection: resolve),
        returnsNormally);
  });
  test(
      'page changes update collision, footprint and overlap interaction together',
      () {
    final condition = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('changed', true));
    final owner = MapEntity(
        id: 'owner',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 2),
        npc: const MapEntityNpcData(characterId: 'hero'),
        presentation: MapEntityPresentation(variants: [
          MapEntityPresentationVariant(
              id: 'changed',
              condition: condition,
              blocksMovement: false,
              size: const GridSize(width: 2, height: 2),
              interactionMode: MapEntityInteractionMode.overlap),
          MapEntityPresentationVariant(
              id: 'base',
              condition: NarrativeEventConditionExpression.not(condition),
              characterId: 'hero',
              blocksMovement: true,
              size: const GridSize(width: 4, height: 1)),
        ]));
    final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        entities: [owner]);
    final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'actors')
        ],
        facts: [
          NarrativeFactDefinition(id: 'changed', label: 'Changed')
        ]);
    const initial = GameState(saveId: 'save');
    final world = GameplayWorldState.initial(
        map: map,
        project: project,
        gameState: initial,
        playerPos: const GridPos(x: 2, y: 3),
        playerFacing: Direction.north);
    expect(
        stepGameplayWorld(world, const InteractIntent()), isA<NpcInteracted>());
    expect(world.entityAt(5, 2)?.id, 'owner');
    final changedState = initial.copyWith(
        storyFlags: const StoryFlags(activeFlags: {'changed'}));
    final changed = world.withEntityPresentations(
        project: project, gameState: changedState, sourceMap: map);
    expect(changed.map.entities.single.blocksMovement, isFalse);
    expect(changed.entityAt(5, 2), isNull);
    expect(stepGameplayWorld(changed, const InteractIntent()),
        isA<EntityInteracted>());
    final restored = changed.withEntityPresentations(
        project: project, gameState: initial, sourceMap: map);
    expect(restored.map.entities.single.npc?.characterId, 'hero');
    expect(restored.entityAt(5, 2)?.id, 'owner');
  });

  for (final facing in Direction.values) {
    test(
        'wide custom counter interaction follows ${facing.name} and rejects ambiguous far cells',
        () {
      const origin = GridPos(x: 4, y: 4);
      final target =
          GridPos(x: origin.x + facing.dx * 2, y: origin.y + facing.dy * 2);
      final side = switch (facing) {
        Direction.north => EntityFacing.south,
        Direction.south => EntityFacing.north,
        Direction.west => EntityFacing.east,
        Direction.east => EntityFacing.west,
      };
      final owner = MapEntity(
          id: 'owner',
          kind: MapEntityKind.custom,
          pos: target,
          size: facing == Direction.north || facing == Direction.south
              ? const GridSize(width: 2, height: 1)
              : const GridSize(width: 1, height: 2),
          counterInteractionSides: [side]);
      GameplayWorldState world(List<MapEntity> entities) =>
          GameplayWorldState.initial(
              map: MapData(
                  id: 'map',
                  name: 'Map',
                  size: const GridSize(width: 10, height: 10),
                  entities: entities,
                  layers: [
                    MapLayer.collision(
                        id: 'terrain',
                        name: 'Terrain',
                        collisions: List.generate(
                            100,
                            (i) =>
                                i ==
                                (origin.y + facing.dy) * 10 +
                                    origin.x +
                                    facing.dx))
                  ]),
              playerPos: origin,
              playerFacing: facing);
      expect(stepGameplayWorld(world([owner]), const InteractIntent()),
          isA<EntityInteracted>());
      expect(
          stepGameplayWorld(world([owner, owner.copyWith(id: 'other')]),
              const InteractIntent()),
          isA<NothingToInteract>());
    });
  }
}
