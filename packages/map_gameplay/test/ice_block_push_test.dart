import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const origin = GridPos(x: 4, y: 4);

MapData room(Direction direction,
        {List<MapEntity> blockers = const [], bool ice = true}) =>
    MapData(
      id: 'ice-room',
      name: 'Ice room',
      size: const GridSize(width: 10, height: 10),
      entities: [
        MapEntity(
          id: 'cube',
          kind: MapEntityKind.custom,
          pos: GridPos(x: origin.x + direction.dx, y: origin.y + direction.dy),
          fieldObstacle: const MapEntityFieldObstacleData(
              kind: FieldObstacleKind.iceBlock),
        ),
        ...blockers,
      ],
      gameplayZones: ice
          ? const [
              MapGameplayZone(
                id: 'ice',
                kind: GameplayZoneKind.movementEffect,
                area: MapRect(
                    pos: GridPos(x: 0, y: 0),
                    size: GridSize(width: 10, height: 10)),
                movementEffect: MovementEffectZonePayload(),
              )
            ]
          : const [],
    );

GameState state(Direction direction) => GameState(
      saveId: 'ice-test',
      currentMapId: 'ice-room',
      playerPosition: origin,
      playerFacing: direction.asFacing,
      mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
        'ice-room': MapInstanceRuntimeState(instanceId: 'visit-1'),
      }),
    );

GameplayWorldState world(MapData map, GameState value, Direction direction) =>
    GameplayWorldState.initial(
      map: map,
      playerPos: value.playerPosition,
      playerFacing: direction,
      tileWidth: 32,
      tileHeight: 32,
    );

void main() {
  for (final direction in Direction.values) {
    test(
        'contact pushes and slides ${direction.name} without Force or following the block',
        () {
      final authored = room(direction), initial = state(direction);
      expect(initial.party.members, isEmpty);
      expect(initial.progression.unlockedFieldAbilities, isEmpty);
      var moved = startIceBlockPush(
        world: world(authored, initial, direction),
        gameState: initial,
        entityId: 'cube',
        direction: direction,
      );
      expect(moved, isA<FieldObstacleSlideMoved>());
      var last = moved as FieldObstacleSlideMoved;
      final cells = <GridPos>[last.to];
      while (last.slide != null) {
        moved = stepFieldObstacleSlide(
          slide: last.slide!,
          world: last.world,
          gameState: last.gameState,
        );
        if (moved is FieldObstacleSlideStopped) break;
        expect(moved, isA<FieldObstacleSlideMoved>());
        last = moved as FieldObstacleSlideMoved;
        cells.add(last.to);
        expect(cells.length, lessThan(11));
      }
      expect(last.world.player.pos, origin);
      expect(last.gameState.playerPosition, origin);
      expect(
          last.to,
          switch (direction) {
            Direction.north => const GridPos(x: 4, y: 0),
            Direction.south => const GridPos(x: 4, y: 9),
            Direction.east => const GridPos(x: 9, y: 4),
            Direction.west => const GridPos(x: 0, y: 4),
          });
      final restored =
          gameStateFromStrictSaveJson(strictGameStateSaveJson(last.gameState));
      final projected = applyFieldObstacleWorldStateToMap(
        map: authored,
        instances: restored.mapInstanceWorldState,
        instance: restored.mapInstanceWorldState.instanceRef(authored.id)!,
      );
      expect(projected.entities.single.pos, last.to);
      final reset = setupDifferentMapInstance(
        state: restored.mapInstanceWorldState,
        targetMapId: authored.id,
        allocateId: (_) => 'visit-2',
      );
      expect(
          applyFieldObstacleWorldStateToMap(
            map: authored,
            instances: reset,
            instance: reset.instanceRef(authored.id)!,
          ).entities.single.pos,
          authored.entities.single.pos);
    });
  }

  for (final kind in ['npc', 'cube', 'wall', 'reservation']) {
    test('$kind blocks the first step without mutating the world', () {
      var authored = room(Direction.east, blockers: [
        if (kind == 'npc')
          const MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 6, y: 4),
            npc: MapEntityNpcData(),
          ),
        if (kind == 'cube')
          const MapEntity(
            id: 'other',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 6, y: 4),
            fieldObstacle:
                MapEntityFieldObstacleData(kind: FieldObstacleKind.iceBlock),
          ),
      ]);
      if (kind == 'wall') {
        authored = authored.copyWith(layers: [
          MapLayer.collision(
            id: 'wall',
            name: 'Wall',
            collisions: List.generate(100, (i) => i == 46),
          )
        ]);
      }
      final initial = state(Direction.east), before = initial.toJson();
      final value = world(authored, initial, Direction.east);
      final result = startIceBlockPush(
        world: value,
        gameState: initial,
        entityId: 'cube',
        direction: Direction.east,
        characterReservations: kind == 'reservation'
            ? const [
                PixelRect(
                  leftPx: 192,
                  topPx: 128,
                  widthPx: 32,
                  heightPx: 32,
                )
              ]
            : const [],
      );
      expect(result, isA<FieldObstacleSlideStopped>());
      expect(initial.toJson(), before);
      expect(value.map, authored);
    });
  }

  test('normal ground stops after one cube step and does not move the player',
      () {
    final map = room(Direction.east, ice: false),
        initial = state(Direction.east);
    final result = startIceBlockPush(
      world: world(map, initial, Direction.east),
      gameState: initial,
      entityId: 'cube',
      direction: Direction.east,
    ) as FieldObstacleSlideMoved;
    expect(result.to, const GridPos(x: 6, y: 4));
    expect(result.slide, isNull);
    expect(result.gameState.playerPosition, origin);
  });

  test(
      'a saved cube cannot be cleared and another obstacle cannot impersonate it',
      () {
    final map = room(Direction.east), initial = state(Direction.east);
    final value = world(map, initial, Direction.east);
    final cleared = initial.copyWith(
        mapInstanceWorldState: initial.mapInstanceWorldState.clearFieldObstacle(
      initial.mapInstanceWorldState.instanceRef(map.id)!,
      'cube',
    ));
    expect(
        startIceBlockPush(
            world: value,
            gameState: cleared,
            entityId: 'cube',
            direction: Direction.east),
        isA<FieldObstacleSlideRefused>());
    expect(
        startIceBlockPush(
            world: value,
            gameState: initial,
            entityId: 'missing',
            direction: Direction.east),
        isA<FieldObstacleSlideRefused>());
    expect(
        startIceBlockPush(
            world: value,
            gameState: initial,
            entityId: 'cube',
            direction: Direction.north),
        isA<FieldObstacleSlideRefused>());
    expect(
        evaluateFieldObstacleAttempt(
            map: map, gameState: initial, entityId: 'cube'),
        isA<FieldObstacleUnavailable>());
  });
}
