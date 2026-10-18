import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('NPC terrain validation covers the whole footprint', () {
    const map = MapData(id: 'room', name: 'Room',
      size: GridSize(width: 8, height: 8), entities: [
        MapEntity(id: 'guide', kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1), size: GridSize(width: 2, height: 2),
          properties: {'collision.width': '2', 'collision.height': '2'},
          npc: MapEntityNpcData(displayName: 'Guide')),
      ], gameplayZones: [
        MapGameplayZone(id: 'water', kind: GameplayZoneKind.movement,
          area: MapRect(pos: GridPos(x: 4, y: 3), size: GridSize(width: 1, height: 1)),
          movement: MovementZonePayload(requiredMode: MovementMode.surf)),
      ],
    );
    final instance = MapInstanceRef(mapId: 'room', instanceId: 'visit');
    final state = MapInstanceWorldState(instancesByMapId: {
      'room': MapInstanceRuntimeState(instanceId: 'visit'),
    }).setNpcPoses(instance, {
      'guide': MapInstanceNpcPose(position: const GridPos(x: 3, y: 3),
          facing: EntityFacing.south),
    });
    expect(() => applyNpcInstancePosesToMap(map: map, authoringMap: map,
        instances: state, instance: instance), throwsStateError);
  });

  test('pose preparation validates the complete final world atomically', () {
    const map = MapData(id: 'room', name: 'Room',
        size: GridSize(width: 8, height: 8), entities: [
      MapEntity(id: 'guide', kind: MapEntityKind.npc, pos: GridPos(x: 2, y: 2), blocksMovement: true,
          properties: {'collision.width': '1', 'collision.height': '1'},
          npc: MapEntityNpcData(displayName: 'Guide')),
      MapEntity(id: 'wall', kind: MapEntityKind.custom, pos: GridPos(x: 4, y: 4), blocksMovement: true,
          properties: {'collision.width': '1', 'collision.height': '1'}),
    ]);
    final project = ProjectManifest(name: 'Pose', tilesets: const [], maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
    ]);
    final world = GameplayWorldState.initial(map: map,
        playerPos: const GridPos(x: 1, y: 1), project: project);
    final scope = MapInstanceRef(mapId: 'room', instanceId: 'visit');
    final state = MapInstanceWorldState(instancesByMapId: {
      'room': MapInstanceRuntimeState(instanceId: 'visit'),
    });
    CinematicActorPoseCommit prepare(GridPos pos, {String id = 'guide'}) =>
        prepareCinematicActorPoseCommit(world: world, authoringMap: map,
            instances: state, instance: scope, project: project, npcPoses: {
          id: MapInstanceNpcPose(position: pos, facing: EntityFacing.east),
        });
    for (final invalid in [const GridPos(x: -1, y: 2),
      const GridPos(x: 8, y: 2), const GridPos(x: 4, y: 4),
      const GridPos(x: 1, y: 1)]) {
      expect(() => prepare(invalid), throwsA(anyOf(isA<StateError>(), isA<ArgumentError>())), reason: '$invalid');
      expect(state.instancesByMapId['room']!.npcPoses, isEmpty);
      expect(world.map.entities.first.pos, const GridPos(x: 2, y: 2));
    }
    expect(() => prepare(const GridPos(x: 3, y: 3), id: 'missing'), throwsStateError);
    final result = prepare(const GridPos(x: 3, y: 3));
    expect(result.world.map.entities.first.npc!.facing, EntityFacing.east);
    expect(result.instances.instancesByMapId['room']!.npcPoses['guide']!.position,
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
