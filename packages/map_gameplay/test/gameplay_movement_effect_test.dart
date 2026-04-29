import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('GameplayMovementEffect', () {
    test('slide creates a slide effect with direction', () {
      final effect = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        direction: Direction.east,
      );

      expect(effect.kind, GameplayMovementEffectKind.slide);
      expect(effect.zoneId, 'ice-zone');
      expect(effect.zoneName, 'Ice Zone');
      expect(effect.position, const GridPos(x: 2, y: 1));
      expect(effect.priority, 4);
      expect(effect.direction, Direction.east);
      expect(effect.movementCost, isNull);
    });

    test('movementCost creates an effect with a positive cost', () {
      final effect = GameplayMovementEffect.movementCost(
        zoneId: 'mud-zone',
        zoneName: 'Mud Zone',
        position: const GridPos(x: 3, y: 1),
        priority: 2,
        movementCost: 2,
      );

      expect(effect.kind, GameplayMovementEffectKind.movementCost);
      expect(effect.zoneId, 'mud-zone');
      expect(effect.zoneName, 'Mud Zone');
      expect(effect.position, const GridPos(x: 3, y: 1));
      expect(effect.priority, 2);
      expect(effect.direction, isNull);
      expect(effect.movementCost, 2);
    });

    test('movementCost rejects non-positive costs', () {
      expect(
        () => GameplayMovementEffect.movementCost(
          zoneId: 'mud-zone',
          zoneName: 'Mud Zone',
          position: const GridPos(x: 3, y: 1),
          priority: 2,
          movementCost: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty zone identity', () {
      expect(
        () => GameplayMovementEffect.slide(
          zoneId: '',
          zoneName: 'Ice Zone',
          position: const GridPos(x: 2, y: 1),
          priority: 4,
          direction: Direction.east,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => GameplayMovementEffect.slide(
          zoneId: 'ice-zone',
          zoneName: ' ',
          position: const GridPos(x: 2, y: 1),
          priority: 4,
          direction: Direction.east,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uses value equality and stable hashCode', () {
      final first = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        direction: Direction.east,
      );
      final second = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        direction: Direction.east,
      );
      final different = GameplayMovementEffect.movementCost(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        movementCost: 2,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });
  });

  group('Moved movementEffect', () {
    test('defaults movementEffect to null', () {
      final moved = Moved(_world());

      expect(moved.movementEffect, isNull);
      expect(moved.hazardEffect, isNull);
    });

    test('can carry a slide movement effect', () {
      final effect = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 1,
        direction: Direction.east,
      );

      final moved = Moved(_world(), movementEffect: effect);

      expect(moved.movementEffect, effect);
      expect(moved.hazardEffect, isNull);
    });

    test('can carry a movement cost effect', () {
      final effect = GameplayMovementEffect.movementCost(
        zoneId: 'mud-zone',
        zoneName: 'Mud Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 1,
        movementCost: 2,
      );

      final moved = Moved(_world(), movementEffect: effect);

      expect(moved.movementEffect, effect);
      expect(moved.hazardEffect, isNull);
    });

    test('can carry hazardEffect and movementEffect together', () {
      const hazard = GameplayHazardEffect(
        zoneId: 'lava-zone',
        zoneName: 'Lava Zone',
        hazardKind: HazardKind.lava,
        damagePerStep: 5,
        position: GridPos(x: 1, y: 0),
        priority: 3,
      );
      final movement = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 2,
        direction: Direction.east,
      );

      final moved = Moved(
        _world(),
        hazardEffect: hazard,
        movementEffect: movement,
      );

      expect(moved.hazardEffect, hazard);
      expect(moved.movementEffect, movement);
    });

    test('keeps path animation signals intact', () {
      const signal = PathAnimationSignal(
        kind: PathAnimationSignalKind.trigger,
        layerId: 'path-layer',
        presetId: 'ice',
        ruleId: 'step-rule',
        trigger: PathAnimationTriggerType.onStep,
        mode: PathAnimationPlaybackMode.restartOnTrigger,
        sourcePos: GridPos(x: 1, y: 0),
      );
      final movement = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 2,
        direction: Direction.east,
      );

      final moved = Moved(
        _world(),
        movementEffect: movement,
        pathAnimationSignals: const [signal],
      );

      expect(moved.movementEffect, movement);
      expect(moved.pathAnimationSignals, const [signal]);
    });

    test('stepGameplayWorld does not produce a movementEffect yet', () {
      final result = stepGameplayWorld(
        _world(),
        const MoveIntent(Direction.east),
      );

      expect(result, isA<Moved>());
      final moved = result as Moved;
      expect(moved.world.player.pos, const GridPos(x: 1, y: 0));
      expect(moved.movementEffect, isNull);
    });

    test('stepGameplayWorld keeps lava hazard separate from movementEffect',
        () {
      final result = stepGameplayWorld(
        _world(
          gameplayZones: const [
            MapGameplayZone(
              id: 'lava-zone',
              name: 'Lava Zone',
              kind: GameplayZoneKind.hazard,
              area: MapRect(
                pos: GridPos(x: 1, y: 0),
                size: GridSize(width: 1, height: 1),
              ),
              priority: 3,
              hazard: HazardZonePayload(
                hazardKind: HazardKind.lava,
                damagePerStep: 5,
              ),
            ),
          ],
        ),
        const MoveIntent(Direction.east),
      );

      expect(result, isA<Moved>());
      final moved = result as Moved;
      expect(moved.hazardEffect, isNotNull);
      expect(moved.hazardEffect!.hazardKind, HazardKind.lava);
      expect(moved.movementEffect, isNull);
    });
  });
}

GameplayWorldState _world({
  List<MapGameplayZone> gameplayZones = const [],
}) {
  return GameplayWorldState.initial(
    map: MapData(
      id: 'movement_effect_map',
      name: 'Movement Effect Map',
      size: const GridSize(width: 3, height: 1),
      layers: const [
        MapLayer.tile(
          id: 'tile',
          name: 'Tile',
          tiles: [0, 0, 0],
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: [false, false, false],
        ),
      ],
      gameplayZones: gameplayZones,
    ),
    playerPos: const GridPos(x: 0, y: 0),
  );
}
