import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

GameplayStepResult _interact({
  Direction facing = Direction.north,
  List<String> sides = const ['south'],
  bool blocked = true,
  GridSize size = const GridSize(width: 1, height: 1),
  MapEntityKind kind = MapEntityKind.npc,
  List<MapEntity> extra = const [],
  bool present = true,
  bool entityPresent = true,
  bool spatial = false,
  GridPos? target,
  bool extrasBeforeNpc = false,
}) {
  const origin = GridPos(x: 3, y: 3);
  final middle = GridPos(x: origin.x + facing.dx, y: origin.y + facing.dy);
  final destination = GridPos(x: middle.x + facing.dx, y: middle.y + facing.dy);
  final npc = MapEntity(
      id: 'nurse',
      kind: kind,
      pos: target ?? destination,
      size: size,
      npc: MapEntityNpcData.fromJson({'counterInteractionSides': sides}));
  final map = MapData(
      id: 'center',
      name: 'Center',
      size: const GridSize(width: 7, height: 7),
      spatialScene: spatial
          ? MapSpatialScene(
              width: 7, depth: 7, heightLevels: List.filled(49, 0))
          : null,
      entities: extrasBeforeNpc ? [...extra, npc] : [npc, ...extra],
      layers: [
        MapLayer.collision(
            id: 'counter',
            name: 'Counter',
            collisions: List.generate(
                49, (index) => blocked && index == middle.y * 7 + middle.x))
      ]);
  final world = GameplayWorldState.initial(
      map: map,
      playerPos: origin,
      playerFacing: facing,
      npcMapPresencePredicate: (_, __) => present,
      mapEntityPresencePredicate: (_, __) => entityPresent);
  return stepGameplayWorld(world, const InteractIntent());
}

void main() {
  for (final entry in [
    (Direction.north, 'south'),
    (Direction.south, 'north'),
    (Direction.east, 'west'),
    (Direction.west, 'east')
  ]) {
    test('declared NPC side ${entry.$2} permits one blocking counter cell', () {
      final result = _interact(facing: entry.$1, sides: [entry.$2]);
      expect(result, isA<NpcInteracted>());
      expect((result as NpcInteracted).entity.id, 'nurse');
    });
  }

  test('counter reach requires both a declared side and a blocking middle cell',
      () {
    expect(_interact(sides: []), isA<NothingToInteract>());
    expect(_interact(sides: ['north']), isA<NothingToInteract>());
    expect(_interact(blocked: false), isA<NothingToInteract>());
  });

  test('entity in the immediate cell retains interaction priority', () {
    final sign = MapEntity(
        id: 'front', kind: MapEntityKind.sign, pos: const GridPos(x: 3, y: 2));
    final result = _interact(extra: [sign]);
    expect(result, isA<SignInteracted>());
    expect((result as SignInteracted).entity.id, 'front');
  });

  test('counter reach refuses large footprints, non NPCs and absent NPCs', () {
    expect(_interact(size: const GridSize(width: 2, height: 1)),
        isA<NothingToInteract>());
    expect(_interact(kind: MapEntityKind.custom), isA<NothingToInteract>());
    expect(_interact(present: false), isA<NothingToInteract>());
    expect(_interact(entityPresent: false), isA<NothingToInteract>());
  });

  test(
      'counter declaration does not enable diagonal, farther or spatial interaction',
      () {
    expect(
        _interact(target: const GridPos(x: 4, y: 1)), isA<NothingToInteract>());
    expect(
        _interact(target: const GridPos(x: 3, y: 0)), isA<NothingToInteract>());
    expect(_interact(spatial: true), isA<NothingToInteract>());
  });

  test('counter refuses an ambiguous occupied NPC anchor', () {
    final other = MapEntity(
        id: 'other',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 3, y: 1),
        npc: const MapEntityNpcData());
    expect(_interact(extra: [other]), isA<NothingToInteract>());
  });

  test('counter refuses a wide neighboring footprint covering the NPC anchor',
      () {
    for (final kind in [MapEntityKind.custom, MapEntityKind.npc]) {
      final covering = MapEntity(
          id: 'covering',
          kind: kind,
          pos: const GridPos(x: 2, y: 1),
          size: const GridSize(width: 2, height: 1),
          npc: kind == MapEntityKind.npc ? const MapEntityNpcData() : null,
          properties: {mapEntityCollisionWidthProperty: '2'});
      expect(_interact(extra: [covering], extrasBeforeNpc: true),
          isA<NothingToInteract>(),
          reason: kind.name);
    }
  });
}
