import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/border_jump_fixture.dart';
import 'support/moving_platform_fixture.dart';
import 'support/moving_prop_fixture.dart';

void main() {
  group('slide movement effects', () {
    for (final direction in Direction.values) {
      test('arrival uses actual ${direction.name} movement direction', () {
        final world = _world(zones: [_ice()]);
        final result = stepGameplayWorld(world, MoveIntent(direction));

        expect(result, isA<Moved>());
        final effect = (result as Moved).movementEffect;
        expect(effect, isNotNull);
        expect(effect!.kind, GameplayMovementEffectKind.slide);
        expect(effect.direction, direction);
        expect(effect.position, result.world.player.pos);
      });
    }

    test('overlap priority keeps the last authored zone on ties', () {
      final zones = [_ice(id: 'z', priority: 2), _ice(id: 'a', priority: 2)];
      for (final ordered in [zones, zones.reversed.toList()]) {
        final world = _world(zones: ordered);
        final result =
            stepGameplayWorld(world, const MoveIntent(Direction.east));
        expect((result as Moved).movementEffect!.zoneId, ordered.last.id);
      }
      final result = stepGameplayWorld(
        _world(zones: [...zones, _ice(id: 'high', priority: 3)]),
        const MoveIntent(Direction.east),
      );
      expect((result as Moved).movementEffect!.zoneId, 'high');
    });

    test('invalid movement-effect masks never expose a slide', () {
      for (final mask in const [
        [GridPos(x: 0, y: 0)],
        [GridPos(x: 2, y: 1)],
      ]) {
        final world = _world(zones: [_ice().copyWith(cellMask: mask)]);
        final result =
            stepGameplayWorld(world, const MoveIntent(Direction.east));
        expect((result as Moved).movementEffect, isNull);
      }
    });

    test('unnamed authored zones use their ID as effect label', () {
      final result = stepGameplayWorld(
        _world(zones: [_ice().copyWith(name: '')]),
        const MoveIntent(Direction.east),
      );
      expect((result as Moved).movementEffect!.zoneName, 'ice');
    });

    test('movement cost remains outside the slide consumer', () {
      final result = stepGameplayWorld(
        _world(zones: [
          _ice().copyWith(
              movementEffect: const MovementEffectZonePayload(
            effectKind: MovementEffectZoneKind.movementCost,
            movementCost: 4,
          )),
        ]),
        const MoveIntent(Direction.east),
      );
      expect((result as Moved).movementEffect, isNull);
    });

    test('a higher priority non-slide effect masks the slide beneath it', () {
      for (final reversed in [false, true]) {
        final zones = [
          _ice(priority: 1),
          _ice(id: 'mud', priority: 2).copyWith(
            movementEffect: const MovementEffectZonePayload(
              effectKind: MovementEffectZoneKind.movementCost,
              movementCost: 3,
            ),
          ),
        ];
        final result = stepGameplayWorld(
          _world(zones: reversed ? zones.reversed.toList() : zones),
          const MoveIntent(Direction.east),
        );
        expect((result as Moved).movementEffect, isNull);
      }
    });

    test('an invalid winning payload never exposes a residual slide', () {
      for (final payload in [
        null,
        const MovementEffectZonePayload(movementCost: 0),
        const MovementEffectZonePayload(
            directedJump: DirectedJumpZonePayload(
          direction: MapConnectionDirection.east,
        )),
      ]) {
        final result = stepGameplayWorld(
          _world(zones: [
            _ice(priority: 1),
            _ice(id: 'invalid', priority: 2).copyWith(movementEffect: payload),
          ]),
          const MoveIntent(Direction.east),
        );
        expect((result as Moved).movementEffect, isNull);
      }
    });

    test('automatic warp arrival stays prioritary over ice', () {
      final result = stepGameplayWorld(
        _world(zones: [
          _ice()
        ], warps: const [
          MapWarp(
            id: 'exit',
            pos: GridPos(x: 4, y: 3),
            targetMapId: 'next',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ]),
        const MoveIntent(Direction.east),
      );
      expect(result, isA<WarpTriggered>());
    });
  });

  group('GameplaySlideController', () {
    test('standing or turning on ice does not start a slide', () {
      final controller = GameplaySlideController();
      final world = _world(zones: [_ice()]);
      expect(controller.isSliding, isFalse);
      expect(controller.nextIntent(world: world, pixelsPerStep: 16), isNull);
    });

    for (final direction in Direction.values) {
      test('continues ${direction.name} without input until leaving ice', () {
        final controller = GameplaySlideController();
        var world = _world(zones: [_ice()]);
        world = _move(controller, world, MoveIntent(direction)).world;
        expect(controller.direction, direction);
        final intent = controller.nextIntent(world: world, pixelsPerStep: 16)!;
        expect(intent.direction, direction);
        world = _move(controller, world, intent).world;
        expect(controller.isSliding, isFalse);
        expect(controller.nextIntent(world: world, pixelsPerStep: 16), isNull);
        expect(
            world.player.pos,
            GridPos(
              x: 3 + direction.dx * 2,
              y: 3 + direction.dy * 2,
            ));
      });
    }

    test('blocking stops retries and a new successful manual move rearms', () {
      final controller = GameplaySlideController();
      var world = _world(zones: [_ice()], walls: {const GridPos(x: 5, y: 3)});
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      final automatic = controller.nextIntent(world: world, pixelsPerStep: 16)!;
      final blocked = _move(controller, world, automatic);
      expect(blocked, isA<Blocked>());
      world = blocked.world;
      expect(controller.isSliding, isFalse);
      for (var idle = 0; idle < 4; idle++) {
        expect(controller.nextIntent(world: world, pixelsPerStep: 16), isNull);
      }
      world = _move(controller, world, const MoveIntent(Direction.north)).world;
      expect(controller.isSliding, isTrue);
      expect(controller.nextIntent(world: world, pixelsPerStep: 16)!.direction,
          Direction.north);
    });

    for (final reserved in [false, true]) {
      test('${reserved ? 'reserved actor' : 'NPC'} blocks automatic movement',
          () {
        final controller = GameplaySlideController();
        var world = _world(
            zones: [_ice()],
            entities: reserved
                ? []
                : const [
                    MapEntity(
                      id: 'npc',
                      kind: MapEntityKind.npc,
                      pos: GridPos(x: 5, y: 3),
                      blocksMovement: true,
                      npc: MapEntityNpcData(),
                    ),
                  ]);
        world =
            _move(controller, world, const MoveIntent(Direction.east)).world;
        final intent = controller.nextIntent(world: world, pixelsPerStep: 16)!;
        final result = stepGameplayWorld(
          world,
          intent,
          characterReservations: reserved
              ? const [
                  PixelRect(leftPx: 80, topPx: 48, widthPx: 16, heightPx: 16),
                ]
              : const [],
        );
        controller.recordStep(
            previousWorld: world, intent: intent, result: result);
        expect(result, isA<Blocked>());
        expect(controller.isSliding, isFalse);
      });
    }

    test('movement terrain gates remain effective during sliding', () {
      final controller = GameplaySlideController();
      var world = _world(zones: [
        _ice(),
        const MapGameplayZone(
          id: 'water',
          kind: GameplayZoneKind.movement,
          area: MapRect(
              pos: GridPos(x: 5, y: 3), size: GridSize(width: 1, height: 1)),
          movement: MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      ]);
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      final result = _move(controller, world,
          controller.nextIntent(world: world, pixelsPerStep: 16)!);
      expect((result as Blocked).reason,
          GameplayMovementBlockReason.waterRequiresSurf);
      expect(controller.isSliding, isFalse);
    });

    test('stationary moving props use the same collision authority', () {
      final fixture = MovingPropFixture();
      final controller = GameplaySlideController();
      var world = GameplayWorldState.initial(
        map: fixture.map.copyWith(gameplayZones: [
          _ice(
              area: const MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 10, height: 10),
          ))
        ]),
        project: fixture.project,
        playerPos: const GridPos(x: 0, y: 2),
        tileWidth: 32,
        tileHeight: 32,
      );
      world = _move(controller, world,
              const MoveIntent(Direction.east, pixelsPerStep: 32))
          .world;
      expect(controller.isSliding, isTrue);
      final result = _move(controller, world,
          controller.nextIntent(world: world, pixelsPerStep: 32)!);
      expect(result, isA<Blocked>());
      expect(controller.isSliding, isFalse);
    });

    test('platform controls stop slide before platform execution', () {
      final fixture = MovingPlatformFixture();
      final definition = MovingPlatformDefinition.fromJson({
        ...fixture.definition.toJson(),
        'lattice': {...fixture.definition.lattice.toJson(), 'widthPx': 16},
        'controls': [
          {
            'id': 'go',
            'cell': {'x': 0, 'y': 0},
            'motion': 'forward'
          }
        ],
      });
      final controller = GameplaySlideController();
      var world = fixture.world(
        map: fixture.map.copyWith(
          movingPlatforms: [definition],
          gameplayZones: [
            _ice(
                area: const MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 10, height: 10),
            ))
          ],
          layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 22)],
        ),
        player: const GridPos(x: 1, y: 2),
      );
      world = world.withPlayer(world.player.copyWith(
        playerPositionPx: const PixelPosition(leftPx: 40, topPx: 64),
      ));
      final result = _move(controller, world,
          const MoveIntent(Direction.east, pixelsPerStep: 32));
      expect((result as Moved).platformControl, isNotNull);
      expect(controller.isSliding, isFalse);
    });

    test('map bounds terminate a full-map slide', () {
      final controller = GameplaySlideController();
      var world = _world(zones: [
        _ice(
            area: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 7, height: 7),
        ))
      ]);
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      GameplayStepResult? result;
      for (var tick = 0; tick < 8 && controller.isSliding; tick++) {
        result = _move(controller, world,
            controller.nextIntent(world: world, pixelsPerStep: 16)!);
        world = result.world;
      }
      expect(result, isA<Blocked>());
      expect(
          (result as Blocked).reason, GameplayMovementBlockReason.outOfBounds);
      expect(controller.isSliding, isFalse);
    });

    test('pixel corridor budget does not truncate valid travel', () {
      final controller = GameplaySlideController();
      var world = _world(
        size: const GridSize(width: 70, height: 7),
        player: const GridPos(x: 1, y: 3),
        zones: [
          _ice(
              area: const MapRect(
            pos: GridPos(x: 2, y: 2),
            size: GridSize(width: 66, height: 3),
          ))
        ],
        tileWidth: 24,
        tileHeight: 32,
      );
      world = _move(controller, world,
              const MoveIntent(Direction.east, pixelsPerStep: 24))
          .world;
      var pixels = 0;
      while (controller.isSliding && pixels < 2000) {
        final intent = controller.nextIntent(world: world, pixelsPerStep: 1)!;
        world = _move(controller, world, intent).world;
        pixels++;
      }
      expect(world.player.pos, const GridPos(x: 68, y: 3));
      expect(pixels, greaterThan(1500));
      expect(pixels, lessThan(2000));
      expect(controller.isSliding, isFalse);
    });

    test('stale position and explicit resets cannot resume inertia', () {
      for (final reset in [false, true]) {
        final controller = GameplaySlideController();
        var world = _world(zones: [_ice()]);
        world =
            _move(controller, world, const MoveIntent(Direction.east)).world;
        if (reset) {
          controller.reset();
        } else {
          world = world.withPlayer(world.player.copyWith(
            playerPositionPx: PixelPosition(
              leftPx: world.player.playerPositionPx.leftPx,
              topPx: world.player.playerPositionPx.topPx + 1,
            ),
          ));
        }
        expect(controller.nextIntent(world: world, pixelsPerStep: 16), isNull);
        expect(controller.isSliding, isFalse);
      }
    });

    test('a result with no displacement cannot rearm a stopped slide', () {
      final controller = GameplaySlideController();
      final world = _world(zones: [_ice()]);
      controller.recordStep(
        previousWorld: world,
        intent: const MoveIntent(Direction.east),
        result: Moved(world,
            movementEffect: GameplayMovementEffect.slide(
              zoneId: 'ice',
              zoneName: 'Ice',
              position: world.player.pos,
              priority: 0,
              direction: Direction.east,
            )),
      );
      expect(controller.isSliding, isFalse);
    });

    test('an automatic warp interrupts an active slide', () {
      final controller = GameplaySlideController();
      var world = _world(
        player: const GridPos(x: 1, y: 3),
        zones: [_ice()],
        warps: const [
          MapWarp(
            id: 'exit',
            pos: GridPos(x: 3, y: 3),
            targetMapId: 'next',
            targetPos: GridPos(x: 1, y: 1),
          )
        ],
      );
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      final result = _move(controller, world,
          controller.nextIntent(world: world, pixelsPerStep: 16)!);
      expect(result, isA<WarpTriggered>());
      expect(controller.isSliding, isFalse);
    });

    test('movement behaviors interrupt rather than disappear under ice', () {
      final controller = GameplaySlideController();
      final base = _world(zones: [_ice()]);
      final world = GameplayWorldState.initial(
        map: base.map.copyWith(placedElements: const [
          MapPlacedElement(
            id: 'message',
            layerId: 'objects',
            elementId: 'sign',
            pos: GridPos(x: 4, y: 3),
            applyCollision: false,
            behaviors: [
              MapPlacedElementBehavior(
                trigger: MapPlacedElementTriggerType.onEnter,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'Stop',
                ),
              )
            ],
          )
        ]),
        playerPos: base.player.pos,
      );
      final result = _move(controller, world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      expect(controller.isSliding, isFalse);
    });

    test('a canonical Border jump takes priority over continued sliding', () {
      final fixture = BorderJumpFixture();
      final controller = GameplaySlideController();
      var world = fixture.world(
        direction: Direction.south,
        playerPos: GridPos(x: fixture.carrier.x, y: fixture.carrier.y - 2),
        mapOverride: fixture.map.copyWith(gameplayZones: [
          _ice(
              area: const MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 12, height: 12),
          ))
        ]),
      );
      world = _move(controller, world,
              const MoveIntent(Direction.south, pixelsPerStep: 32))
          .world;
      expect(controller.isSliding, isTrue);
      final result = _move(controller, world,
          controller.nextIntent(world: world, pixelsPerStep: 32)!);
      expect(result, isA<Jumped>());
      expect(controller.isSliding, isFalse);
    });

    test('a connected map boundary terminates slide state before transfer', () {
      final controller = GameplaySlideController();
      final base = _world(zones: [
        _ice(
            area: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 7, height: 7),
        ))
      ]);
      var world = GameplayWorldState.initial(
        map: base.map.copyWith(connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'next',
            offset: 0,
          )
        ]),
        playerPos: const GridPos(x: 5, y: 3),
      );
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      final result = _move(controller, world,
          controller.nextIntent(world: world, pixelsPerStep: 16)!);
      expect(result, isA<ConnectionTriggered>());
      expect(controller.isSliding, isFalse);
    });

    test('passive facing changes preserve the original slide direction', () {
      final controller = GameplaySlideController();
      var world = _world(zones: [_ice()]);
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      world = world.withPlayer(world.player.copyWith(facing: Direction.north));
      expect(controller.nextIntent(world: world, pixelsPerStep: 16)!.direction,
          Direction.east);
    });

    test('map replacement invalidates slide state even at identical pixels',
        () {
      final controller = GameplaySlideController();
      var world = _world(zones: [_ice()]);
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      final replacement = GameplayWorldState.initial(
        map: world.map.copyWith(id: 'replacement'),
        playerPos: world.player.pos,
      ).withPlayer(world.player);
      expect(
          controller.nextIntent(world: replacement, pixelsPerStep: 16), isNull);
      expect(controller.isSliding, isFalse);
    });

    test('invalid movement extent cannot enter an unbounded pixel loop', () {
      final controller = GameplaySlideController();
      var world = _world(zones: [_ice()]);
      world = _move(controller, world, const MoveIntent(Direction.east)).world;
      for (final pixels in [0, -1, 17]) {
        expect(() => controller.nextIntent(world: world, pixelsPerStep: pixels),
            throwsArgumentError);
      }
    });
  });
}

GameplayStepResult _move(GameplaySlideController controller,
    GameplayWorldState world, MoveIntent intent) {
  final result = stepGameplayWorld(world, intent);
  controller.recordStep(previousWorld: world, intent: intent, result: result);
  return result;
}

MapGameplayZone _ice({String id = 'ice', int priority = 0, MapRect? area}) =>
    MapGameplayZone(
      id: id,
      name: 'Ice',
      kind: GameplayZoneKind.movementEffect,
      area: area ??
          const MapRect(
            pos: GridPos(x: 2, y: 2),
            size: GridSize(width: 3, height: 3),
          ),
      priority: priority,
      movementEffect: const MovementEffectZonePayload(),
    );

GameplayWorldState _world({
  List<MapGameplayZone> zones = const [],
  GridPos player = const GridPos(x: 3, y: 3),
  List<MapWarp> warps = const [],
  List<MapEntity> entities = const [],
  Set<GridPos> walls = const {},
  GridSize size = const GridSize(width: 7, height: 7),
  int tileWidth = 16,
  int tileHeight = 16,
}) =>
    GameplayWorldState.initial(
      map: MapData(
        id: 'ice-map',
        name: 'Ice map',
        size: size,
        gameplayZones: zones,
        warps: warps,
        entities: entities,
        layers: [
          MapLayer.collision(
            id: 'walls',
            name: 'Walls',
            collisions: [
              for (var y = 0; y < size.height; y++)
                for (var x = 0; x < size.width; x++)
                  walls.contains(GridPos(x: x, y: y)),
            ],
          ),
        ],
      ),
      playerPos: player,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
