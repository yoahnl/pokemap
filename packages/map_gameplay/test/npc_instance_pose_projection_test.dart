import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  ({
    MapData map,
    ProjectManifest project,
    MapInstanceRef instance,
    MapInstanceWorldState instances
  }) variantFixture(
      {GridPos position = const GridPos(x: 3, y: 3),
      bool knownCharacter = true}) {
    final condition = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('closed', true));
    final map = MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
              id: 'wall',
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 1, y: 1),
              presentation: MapEntityPresentation(variants: [
                MapEntityPresentationVariant(
                    id: 'closed',
                    condition: condition,
                    characterId: 'wall-character',
                    blocksMovement: true,
                    size: const GridSize(width: 2, height: 2)),
                MapEntityPresentationVariant(
                    id: 'open',
                    condition: NarrativeEventConditionExpression.not(condition),
                    blocksMovement: false),
              ])),
        ]);
    final project =
        ProjectManifest(name: 'Variants', tilesets: const [], maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json')
    ], characters: [
      if (knownCharacter)
        const ProjectCharacterEntry(
            id: 'wall-character', name: 'Wall', tilesetId: 'actors')
    ], facts: [
      NarrativeFactDefinition(id: 'closed', label: 'Closed')
    ]);
    final instance = MapInstanceRef(mapId: 'room', instanceId: 'visit');
    final instances = MapInstanceWorldState(instancesByMapId: {
      'room': MapInstanceRuntimeState(instanceId: 'visit'),
    }).setNpcPoses(instance, {
      'wall': MapInstanceNpcPose(position: position, facing: EntityFacing.east)
    });
    return (
      map: map,
      project: project,
      instance: instance,
      instances: instances
    );
  }

  test('declared custom to NPC presentation restores saved position and facing',
      () {
    final fixture = variantFixture();
    final active = projectMapEntityPresentations(
        project: fixture.project,
        gameState: GameState(
            saveId: 'saved',
            mapInstanceWorldState: fixture.instances,
            storyFlags: const StoryFlags(activeFlags: {'closed'})),
        map: fixture.map);
    final result = applyFieldObstacleWorldStateToMap(
        map: active,
        authoringMap: fixture.map,
        project: fixture.project,
        instance: fixture.instance,
        instances: MapInstanceWorldState.fromJson(fixture.instances.toJson()));
    expect(result.entities.single.kind, MapEntityKind.npc);
    expect(result.entities.single.pos, const GridPos(x: 3, y: 3));
    expect(result.entities.single.npc!.facing, EntityFacing.east);
    expect(fixture.map.entities.single.kind, MapEntityKind.custom);
  });

  test(
      'inactive custom presentation stays inactive while saved pose is retained',
      () {
    final fixture = variantFixture();
    final result = applyFieldObstacleWorldStateToMap(
        map: fixture.map,
        project: fixture.project,
        instance: fixture.instance,
        instances: fixture.instances);
    expect(result.entities.single.kind, MapEntityKind.custom);
    expect(result.entities.single.npc, isNull);
    expect(result.entities.single.pos, const GridPos(x: 1, y: 1));
    expect(fixture.instances.instancesByMapId['room']!.npcPoses, hasLength(1));
  });

  for (final invalid in [
    'unknown character',
    'no project',
    'no presentation',
    'forged NPC',
    'duplicate owner',
    'variant footprint outside',
    'custom NPC payload',
    'changed size',
    'changed collision',
    'changed blocking'
  ]) {
    test('variant pose rejects $invalid', () {
      final fixture = variantFixture(
          knownCharacter: invalid != 'unknown character',
          position: invalid == 'variant footprint outside'
              ? const GridPos(x: 7, y: 3)
              : const GridPos(x: 3, y: 3));
      var authored = fixture.map;
      var map = fixture.map;
      if (invalid == 'no presentation') {
        authored = map = fixture.map.copyWith(entities: [
          fixture.map.entities.single.copyWith(presentation: null)
        ]);
      }
      if (invalid == 'duplicate owner') {
        authored = authored.copyWith(
            entities: [...authored.entities, authored.entities.single]);
      }
      if (invalid == 'forged NPC') {
        map = map.copyWith(entities: [
          map.entities.single.copyWith(
              kind: MapEntityKind.npc,
              npc: const MapEntityNpcData(characterId: 'unrelated'))
        ]);
      }
      if (invalid == 'custom NPC payload') {
        map = map.copyWith(entities: [
          map.entities.single.copyWith(
              npc: const MapEntityNpcData(characterId: 'wall-character'))
        ]);
      }
      if (const {'changed size', 'changed collision', 'changed blocking'}
          .contains(invalid)) {
        map = projectMapEntityPresentations(
            project: fixture.project,
            gameState: const GameState(
                saveId: 'saved',
                storyFlags: StoryFlags(activeFlags: {'closed'})),
            map: map);
        final current = map.entities.single;
        map = map.copyWith(entities: [
          current.copyWith(
              size: invalid == 'changed size'
                  ? const GridSize(width: 1, height: 1)
                  : current.size,
              blocksMovement: invalid == 'changed blocking'
                  ? false
                  : current.blocksMovement,
              properties: invalid == 'changed collision'
                  ? {...current.properties, 'collision.width': '1'}
                  : current.properties)
        ]);
      }
      expect(
          () => applyNpcInstancePosesToMap(
              map: map,
              authoringMap: authored,
              project: invalid == 'no project' ? null : fixture.project,
              instance: fixture.instance,
              instances: fixture.instances),
          throwsStateError);
    });
  }

  test('NPC terrain validation covers the whole footprint', () {
    const map = MapData(
      id: 'room',
      name: 'Room',
      size: GridSize(width: 8, height: 8),
      entities: [
        MapEntity(
            id: 'guide',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 2, height: 2),
            properties: {'collision.width': '2', 'collision.height': '2'},
            npc: MapEntityNpcData(displayName: 'Guide')),
      ],
      gameplayZones: [
        MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 4, y: 3), size: GridSize(width: 1, height: 1)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf)),
      ],
    );
    final instance = MapInstanceRef(mapId: 'room', instanceId: 'visit');
    final state = MapInstanceWorldState(instancesByMapId: {
      'room': MapInstanceRuntimeState(instanceId: 'visit'),
    }).setNpcPoses(instance, {
      'guide': MapInstanceNpcPose(
          position: const GridPos(x: 3, y: 3), facing: EntityFacing.south),
    });
    expect(
        () => applyNpcInstancePosesToMap(
            map: map, authoringMap: map, instances: state, instance: instance),
        throwsStateError);
  });

  test('pose preparation validates the complete final world atomically', () {
    const map = MapData(
        id: 'room',
        name: 'Room',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
              id: 'guide',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 2),
              blocksMovement: true,
              properties: {'collision.width': '1', 'collision.height': '1'},
              npc: MapEntityNpcData(displayName: 'Guide')),
          MapEntity(
              id: 'wall',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 4, y: 4),
              blocksMovement: true,
              properties: {'collision.width': '1', 'collision.height': '1'}),
        ]);
    final project =
        ProjectManifest(name: 'Pose', tilesets: const [], maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
    ]);
    final world = GameplayWorldState.initial(
        map: map, playerPos: const GridPos(x: 1, y: 1), project: project);
    final scope = MapInstanceRef(mapId: 'room', instanceId: 'visit');
    final state = MapInstanceWorldState(instancesByMapId: {
      'room': MapInstanceRuntimeState(instanceId: 'visit'),
    });
    CinematicActorPoseCommit prepare(GridPos pos, {String id = 'guide'}) =>
        prepareCinematicActorPoseCommit(
            world: world,
            authoringMap: map,
            instances: state,
            instance: scope,
            project: project,
            npcPoses: {
              id: MapInstanceNpcPose(position: pos, facing: EntityFacing.east),
            });
    for (final invalid in [
      const GridPos(x: -1, y: 2),
      const GridPos(x: 8, y: 2),
      const GridPos(x: 4, y: 4),
      const GridPos(x: 1, y: 1)
    ]) {
      expect(() => prepare(invalid),
          throwsA(anyOf(isA<StateError>(), isA<ArgumentError>())),
          reason: '$invalid');
      expect(state.instancesByMapId['room']!.npcPoses, isEmpty);
      expect(world.map.entities.first.pos, const GridPos(x: 2, y: 2));
    }
    expect(() => prepare(const GridPos(x: 3, y: 3), id: 'missing'),
        throwsStateError);
    final result = prepare(const GridPos(x: 3, y: 3));
    expect(result.world.map.entities.first.npc!.facing, EntityFacing.east);
    expect(
        result.instances.instancesByMapId['room']!.npcPoses['guide']!.position,
        const GridPos(x: 3, y: 3));
  });

  test('ordinary NPC pose restores position and facing without field obstacles',
      () {
    final map = MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 8, height: 8),
      layers: const [],
      entities: const [
        MapEntity(
            id: 'guide',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
            npc: MapEntityNpcData(
                displayName: 'Guide', facing: EntityFacing.south)),
      ],
    );
    final scope = MapInstanceRef(mapId: 'room', instanceId: 'visit');
    final state = MapInstanceWorldState(instancesByMapId: {
      'room': MapInstanceRuntimeState(instanceId: 'visit'),
    }).setNpcPoses(scope, {
      'guide': MapInstanceNpcPose(
          position: const GridPos(x: 4, y: 3), facing: EntityFacing.west),
    });
    final restored = MapInstanceWorldState.fromJson(state.toJson());
    final result = applyFieldObstacleWorldStateToMap(
        map: map, authoringMap: map, instances: restored, instance: scope);
    expect(result.entities.single.pos, const GridPos(x: 4, y: 3));
    expect(result.entities.single.npc!.facing, EntityFacing.west);
    expect(map.entities.single.pos, const GridPos(x: 2, y: 2));
    expect(map.entities.single.npc!.facing, EntityFacing.south);
  });
}
