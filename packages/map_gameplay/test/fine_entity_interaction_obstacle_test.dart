import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('a front custom surface is reachable without hiding its collider', () {
    for (final barrier in [false, true]) {
      final original = _world(barrier: barrier);
      final world = _world(
          map: original.map.copyWith(entities: const [
        MapEntity(
            id: 'target',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 6, y: 6),
            properties: {'collision.width': '1'}),
        MapEntity(
            id: 'other',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 7, y: 6),
            properties: {'collision.width': '1'}),
      ]));
      const target =
          PixelRect(leftPx: 192, topPx: 192, widthPx: 32, heightPx: 32);
      expect(world.worldStaticObstaclesCollidePixelRect(target), isTrue);
      expect(
          world.worldStaticObstaclesCollidePixelRect(target,
              ignoredEntityId: 'target'),
          isTrue);
      expect(
          isPlayerFrontInteractionUnobstructed(
              world: world,
              targetRect: const MapRect(
                  pos: GridPos(x: 6, y: 6),
                  size: GridSize(width: 1, height: 1)),
              ignoredEntityId: 'target'),
          !barrier);
    }
  });

  for (final barrier in [false, true]) {
    test(
        'front MapRect permission ${barrier ? 'rejects' : 'accepts'} the same independent obstacle',
        () {
      final original = _world(barrier: barrier);
      final world = _world(map: original.map.copyWith(entities: []));
      expect(
          isPlayerFrontInteractionUnobstructed(
              world: world,
              targetRect: const MapRect(
                  pos: GridPos(x: 6, y: 6),
                  size: GridSize(width: 1, height: 1))),
          !barrier);
    });
  }

  test(
      'front MapRect permission refuses an incoherent physical pose and a distant target',
      () {
    final world = _world();
    expect(
        isPlayerFrontInteractionUnobstructed(
            world: world,
            targetRect: const MapRect(
                pos: GridPos(x: 7, y: 6), size: GridSize(width: 1, height: 1))),
        isFalse);
    expect(
        isPlayerFrontInteractionUnobstructed(
            world: world.withPlayer(
                world.player.copyWith(pos: const GridPos(x: 4, y: 6))),
            targetRect: const MapRect(
                pos: GridPos(x: 5, y: 6), size: GridSize(width: 1, height: 1))),
        isFalse);
  });
  for (final kind in [MapEntityKind.sign, MapEntityKind.npc]) {
    test(
        'a fine-position player reaches $kind when the separate barrier is removed',
        () {
      final world = _world(kind: kind);
      expect(world.player.pos, const GridPos(x: 5, y: 6));
      expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
      final result = stepGameplayWorld(world, const InteractIntent());
      expect(
          result,
          kind == MapEntityKind.sign
              ? isA<SignInteracted>()
              : isA<NpcInteracted>());
    });

    test(
        'a separate fine barrier blocks movement and interaction with $kind behind it',
        () {
      final world = _world(kind: kind, barrier: true);
      expect(world.player.pos, const GridPos(x: 5, y: 6));
      expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
      expect(
          world.worldStaticObstaclesCollidePixelRect(const PixelRect(
              leftPx: 185, topPx: 216, widthPx: 1, heightPx: 1)),
          isTrue);
      final movement = stepGameplayWorld(
          world, const MoveIntent(Direction.east, pixelsPerStep: 32));
      expect(movement, isA<Blocked>());
      expect(movement.world.player.playerPositionPx,
          world.player.playerPositionPx);
      expect(stepGameplayWorld(world, const InteractIntent()),
          isA<NothingToInteract>());
    });
  }

  test('an absent sign is not selected at the same fine position', () {
    final world = _world().withMapEntityPresencePredicate((_, __) => false);
    expect(stepGameplayWorld(world, const InteractIntent()),
        isA<NothingToInteract>());
  });

  test('a sign outside the normal one-cell reach stays unavailable', () {
    expect(stepGameplayWorld(_world(centerX: 111), const InteractIntent()),
        isA<NothingToInteract>());
  });

  test(
      'the immediate entity keeps priority over its authored action when unobstructed',
      () {
    final result =
        stepGameplayWorld(_world(action: true), const InteractIntent());
    expect(result, isA<SignInteracted>());
    expect((result as SignInteracted).entity.id, 'sign');
  });

  test('an occluded priority entity does not expose its authored action', () {
    expect(
        stepGameplayWorld(
            _world(barrier: true, action: true), const InteractIntent()),
        isA<NothingToInteract>());
  });

  for (final barrier in [false, true]) {
    test(
        'the vertical front interaction ${barrier ? 'stops before' : 'reaches beyond'} the separate barrier',
        () {
      final world = _world(barrier: barrier, facing: Direction.south);
      expect(world.player.pos, const GridPos(x: 6, y: 5));
      expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
      expect(stepGameplayWorld(world, const InteractIntent()),
          barrier ? isA<NothingToInteract>() : isA<SignInteracted>());
    });
  }

  test('strict save and cold map reload preserve the blocked fine interaction',
      () {
    final before = _world(barrier: true);
    final state = gameStateFromStrictSaveJson(strictGameStateSaveJson(GameState(
      saveId: 'fine-interaction',
      currentMapId: before.map.id,
      playerPosition: before.player.pos,
      playerFacing: before.player.facing.asFacing,
      playerPixelPosition: PixelOffset(
          x: before.player.playerPositionPx.leftPx,
          y: before.player.playerPositionPx.topPx),
    )));
    final map = MapData.fromJson(
        jsonDecode(jsonEncode(before.map.toJson())) as Map<String, dynamic>);
    final restored = _world(map: map, state: state);
    expect(restored.player.pos, before.player.pos);
    expect([
      restored.player.playerPositionPx.leftPx,
      restored.player.playerPositionPx.topPx
    ], [
      before.player.playerPositionPx.leftPx,
      before.player.playerPositionPx.topPx
    ]);
    expect(stepGameplayWorld(restored, const InteractIntent()),
        isA<NothingToInteract>());
  });
}

GameplayWorldState _world(
    {MapEntityKind kind = MapEntityKind.sign,
    bool barrier = false,
    bool action = false,
    int centerX = 175,
    Direction facing = Direction.east,
    MapData? map,
    GameState? state}) {
  final selected = map ??
      MapData(
          id: 'room',
          name: 'Room',
          size: const GridSize(width: 16, height: 16),
          layers: const [
            MapLayer.object(id: 'objects', name: 'Objects')
          ],
          entities: [
            MapEntity(
                id: kind == MapEntityKind.sign ? 'sign' : 'npc',
                kind: kind,
                pos: const GridPos(x: 6, y: 6),
                sign: kind == MapEntityKind.sign
                    ? const MapEntitySignData(plainText: 'Panneau')
                    : null,
                npc: kind == MapEntityKind.npc
                    ? const MapEntityNpcData(characterId: 'person')
                    : null)
          ],
          placedElements: [
            if (barrier)
              MapPlacedElement(
                  id: 'separate-barrier',
                  layerId: 'objects',
                  elementId: 'barrier',
                  pos: facing == Direction.south
                      ? const GridPos(x: 6, y: 5)
                      : const GridPos(x: 5, y: 6),
                  pixelOffset: facing == Direction.south
                      ? const PixelOffset(x: 0, y: 25)
                      : const PixelOffset(x: 25, y: 0),
                  pixelSize: facing == Direction.south
                      ? const PixelSize(width: 32, height: 2)
                      : const PixelSize(width: 2, height: 32),
                  properties: {
                    pokemapPlacementOriginProperty:
                        pokemapPlacementOriginAuthored
                  }),
            if (action)
              const MapPlacedElement(
                  id: 'action',
                  layerId: 'objects',
                  elementId: 'barrier',
                  pos: GridPos(x: 6, y: 6),
                  applyCollision: false,
                  behaviors: [
                    MapPlacedElementBehavior(
                        trigger: MapPlacedElementTriggerType.onAction,
                        effect: MapPlacedElementEffect(
                            type: MapPlacedElementEffectType.showMessage,
                            message: 'Action'))
                  ]),
          ]);
  final project = ProjectManifest(
    name: 'Fine interaction',
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
    ],
    elements: [
      ProjectElementEntry(
          id: 'barrier',
          name: 'Barrier',
          tilesetId: 'tiles',
          categoryId: 'objects',
          frames: const [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
          ],
          collisionProfile: ElementCollisionProfile(
              collisionMask: ElementCollisionPixelMask(
                  widthPx: 32,
                  heightPx: 32,
                  dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                      widthPx: 32,
                      heightPx: 32,
                      solidPixels: List.filled(1024, true)))))
    ],
  );
  final world = GameplayWorldState.initial(
      map: selected,
      project: project,
      playerPos: const GridPos(x: 0, y: 0),
      tileWidth: 32,
      tileHeight: 32);
  final position = state?.playerPixelPosition == null
      ? facing == Direction.south
          ? const PixelPosition(leftPx: 176, topPx: 119)
          : PixelPosition(leftPx: centerX - 32, topPx: 160)
      : PixelPosition(
          leftPx: state!.playerPixelPosition!.x,
          topPx: state.playerPixelPosition!.y);
  final rect =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: position, spriteWidthPx: 64, spriteHeightPx: 64);
  final pos = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
      playerCollisionRectPx: rect,
      tileWidthPx: 32,
      tileHeightPx: 32,
      mapWidthCells: selected.size.width,
      mapHeightCells: selected.size.height);
  return world.withPlayer(world.player.copyWith(
      pos: pos,
      playerPositionPx: position,
      playerSpriteWidthPx: 64,
      playerSpriteHeightPx: 64,
      facing: state?.playerFacing.asDirection ?? facing));
}
