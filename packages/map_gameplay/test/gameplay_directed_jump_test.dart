import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/border_jump_fixture.dart';

GridPos _cell(BorderJumpFixture fixture, int delta) =>
    GridPos(x: fixture.carrier.x, y: fixture.carrier.y + delta);

MapData _solid(BorderJumpFixture fixture, GridPos cell) =>
    fixture.map.copyWith(layers: [
      ...fixture.map.layers,
      MapLayer.collision(
        id: 'generic-solid',
        name: 'Generic solid',
        collisions: List.generate(144, (i) => i == cell.y * 12 + cell.x),
      ),
    ]);

MapData _water(BorderJumpFixture fixture, GridPos cell) =>
    fixture.map.copyWith(gameplayZones: [
      MapGameplayZone(
        id: 'native-water',
        name: 'Native water',
        kind: GameplayZoneKind.movement,
        area: MapRect(pos: cell, size: const GridSize(width: 1, height: 1)),
        movement: const MovementZonePayload(requiredMode: MovementMode.surf),
      ),
    ]);

GameplayStepResult _step(
  GameplayWorldState world, {
  Direction direction = Direction.south,
  Iterable<PixelRect> reservations = const [],
}) =>
    stepGameplayWorld(
      world,
      MoveIntent(direction),
      characterReservations: reservations,
    );

void main() {
  test('zero displacement never activates a Border jump', () {
    final fixture = BorderJumpFixture();
    final world = fixture.world(direction: Direction.south);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.south, pixelsPerStep: 0));
    expect(result, isA<Blocked>());
    expect(result.world.player.playerPositionPx,
        same(world.player.playerPositionPx));
  });

  test('backward displacement does not activate a forward Border jump', () {
    final fixture = BorderJumpFixture();
    final world = fixture.world(direction: Direction.south);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.south, pixelsPerStep: -16));
    expect(result, isA<Moved>());
    expect(result.world.player.playerPositionPx.topPx,
        world.player.playerPositionPx.topPx - 16);
  });

  for (final direction in Direction.values) {
    test('${direction.name} crosses only its bound B and translates two cells',
        () {
      final fixture = BorderJumpFixture(direction: direction);
      final world = fixture.world(direction: direction);
      final result = _step(world, direction: direction) as Jumped;
      expect(result.plan.binding, same(world.borderJumpBindings.single));
      expect(result.plan.sourcePos, world.player.pos);
      expect(result.plan.viaPos, fixture.carrier);
      expect(
          result.plan.landingPos,
          GridPos(
            x: fixture.carrier.x + direction.dx,
            y: fixture.carrier.y + direction.dy,
          ));
      expect(result.world.player.playerPositionPx.leftPx,
          world.player.playerPositionPx.leftPx + direction.dx * 64);
      expect(result.world.player.playerPositionPx.topPx,
          world.player.playerPositionPx.topPx + direction.dy * 64);
      expect(result.plan.durationMs, 420);
      expect(result.plan.peakHeightPx, 19);
    });
  }

  for (final npcLast in [true, false]) {
    test(
        'overlapping blockers at C refuse offset landing with npcLast=$npcLast',
        () {
      final fixture = BorderJumpFixture();
      final sign = MapEntity(
          id: 'landing-sign', kind: MapEntityKind.sign, pos: _cell(fixture, 1));
      final npc = MapEntity(
          id: 'landing-npc', kind: MapEntityKind.npc, pos: _cell(fixture, 1));
      final map =
          fixture.map.copyWith(entities: npcLast ? [sign, npc] : [npc, sign]);
      final initial =
          fixture.world(direction: Direction.south, mapOverride: map);
      final world = initial.withPlayer(initial.player.copyWith(
        playerPositionPx: PixelPosition(
          leftPx: initial.player.playerPositionPx.leftPx,
          topPx: initial.player.playerPositionPx.topPx - 20,
        ),
      ));
      expect(world.player.pos, _cell(fixture, -1));
      final result = _step(world);
      expect(result, isA<Blocked>());
      expect(result.world.player.playerPositionPx,
          same(world.player.playerPositionPx));
    });
  }

  for (final npcLast in [true, false]) {
    test('overlap presence and relocation stay exact with npcLast=$npcLast',
        () {
      final fixture = BorderJumpFixture();
      final cell = _cell(fixture, 1);
      final sign =
          MapEntity(id: 'landing-sign', kind: MapEntityKind.sign, pos: cell);
      final npc =
          MapEntity(id: 'landing-npc', kind: MapEntityKind.npc, pos: cell);
      final map =
          fixture.map.copyWith(entities: npcLast ? [sign, npc] : [npc, sign]);
      final initial =
          fixture.world(direction: Direction.south, mapOverride: map);
      final world = initial.withPlayer(initial.player.copyWith(
        playerPositionPx: PixelPosition(
          leftPx: initial.player.playerPositionPx.leftPx,
          topPx: initial.player.playerPositionPx.topPx - 20,
        ),
      ));
      expect(world.entityAt(cell.x, cell.y)?.id, npcLast ? npc.id : sign.id);
      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(cell.x, cell.y,
              ignoredEntityId: npc.id),
          isTrue);
      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(cell.x, cell.y,
              ignoredEntityId: sign.id),
          isTrue);
      expect(
          _step(world.withMapEntityPresencePredicate(
              (_, entity) => entity.id != sign.id)),
          isA<Jumped>());
      expect(_step(world.withNpcMapPresencePredicate((_, __) => false)),
          isA<Blocked>());
      expect(_step(world.withMapEntityPresencePredicate((_, __) => false)),
          isA<Jumped>());
      expect(
          _step(world.withEntityPosition(sign.id, const GridPos(x: 8, y: 8))),
          isA<Jumped>());
      expect(_step(world.withEntityPosition(npc.id, const GridPos(x: 8, y: 8))),
          isA<Blocked>());
      expect(_step(world), isA<Blocked>());
    });

    test('ordinary offset walking checks every overlap with npcLast=$npcLast',
        () {
      final fixture = BorderJumpFixture();
      final cell = _cell(fixture, 1);
      final sign =
          MapEntity(id: 'landing-sign', kind: MapEntityKind.sign, pos: cell);
      final npc =
          MapEntity(id: 'landing-npc', kind: MapEntityKind.npc, pos: cell);
      final map = fixture.map.copyWith(
        layers: [fixture.map.layers.last],
        entities: npcLast ? [sign, npc] : [npc, sign],
      );
      final initial = fixture.world(
          direction: Direction.east, mapOverride: map, playerPos: cell);
      final world = initial.withPlayer(initial.player.copyWith(
        playerPositionPx: PixelPosition(
          leftPx: initial.player.playerPositionPx.leftPx,
          topPx: initial.player.playerPositionPx.topPx - 20,
        ),
      ));
      expect(world.borderJumpBindings, isEmpty);
      expect(_step(world, direction: Direction.east), isA<Blocked>());
      expect(
          _step(
              world.withMapEntityPresencePredicate(
                  (_, entity) => entity.id != sign.id),
              direction: Direction.east),
          isA<Moved>());
      expect(
          _step(world.withNpcMapPresencePredicate((_, __) => false),
              direction: Direction.east),
          isA<Blocked>());
      expect(
          _step(world.withMapEntityPresencePredicate((_, __) => false),
              direction: Direction.east),
          isA<Moved>());
    });
  }

  test('inverted permission crosses the same physical B from the opposite side',
      () {
    final fixture = BorderJumpFixture(jumpSide: BorderLineSide.inverted);
    expect(
        _step(fixture.world(direction: Direction.north),
            direction: Direction.north),
        isA<Jumped>());
    expect(
        _step(fixture.world(direction: Direction.south)), isNot(isA<Jumped>()));
  });

  test('wrong-direction walking remains blocked by the full Border module', () {
    final fixture = BorderJumpFixture();
    final world = fixture.world(direction: Direction.north);
    final attempt = stepGameplayWorld(
        world, const MoveIntent(Direction.north, pixelsPerStep: 32));
    expect(attempt, isNot(isA<Jumped>()));
    expect(attempt.world.player.pos, world.player.pos);
  });

  test('off-center source pixels are preserved in the landing position', () {
    final fixture = BorderJumpFixture();
    final world = fixture.world(direction: Direction.south);
    final offset = world.withPlayer(world.player.copyWith(
      playerPositionPx: PixelPosition(
        leftPx: world.player.playerPositionPx.leftPx + 3,
        topPx: world.player.playerPositionPx.topPx - 2,
      ),
    ));
    final jumped = _step(offset) as Jumped;
    expect(jumped.plan.sourcePositionPx, same(offset.player.playerPositionPx));
    expect(jumped.plan.landingPositionPx.leftPx,
        offset.player.playerPositionPx.leftPx);
    expect(jumped.plan.landingPositionPx.topPx,
        offset.player.playerPositionPx.topPx + 64);
  });

  test('large sprite offsets use actual feet instead of sprite origin', () {
    final fixture = BorderJumpFixture();
    final base = fixture.world(direction: Direction.south);
    final player = GameplayPlayerState.fromGridSpawn(
      cell: base.player.pos,
      facing: Direction.south,
      tileWidthPx: 32,
      tileHeightPx: 32,
      mapWidthCells: 12,
      mapHeightCells: 12,
      spriteWidthPx: 64,
      spriteHeightPx: 64,
    );
    final jumped = _step(base.withPlayer(player)) as Jumped;
    expect(jumped.world.player.playerSpriteWidthPx, 64);
    expect(jumped.plan.sourcePositionPx.leftPx, player.playerPositionPx.leftPx);
    expect(jumped.plan.landingPositionPx.topPx,
        player.playerPositionPx.topPx + 64);
  });

  test(
      'a forged grid position cannot hide current collision at the source feet',
      () {
    final fixture = BorderJumpFixture();
    final world = fixture.world(direction: Direction.south);
    final forged = world.withPlayer(world.player.copyWith(
      playerPositionPx: PixelPosition(
        leftPx: world.player.playerPositionPx.leftPx,
        topPx: world.player.playerPositionPx.topPx + 32,
      ),
    ));
    expect(_step(forged), isA<Blocked>());
  });

  for (final delta in [-1, 0, 1]) {
    test('generic full-cell collision at ${delta + 1} is never excluded', () {
      final fixture = BorderJumpFixture();
      final map = _solid(fixture, _cell(fixture, delta));
      final world = fixture.world(direction: Direction.south, mapOverride: map);
      final result = _step(world);
      expect(result, isA<Blocked>());
      expect(result.world.player.playerPositionPx,
          same(world.player.playerPositionPx));
    });

    test('active blocking entity at ${delta + 1} prevents admission', () {
      final fixture = BorderJumpFixture();
      final map = fixture.map.copyWith(entities: [
        MapEntity(
            id: 'blocker', kind: MapEntityKind.npc, pos: _cell(fixture, delta)),
      ]);
      final world = fixture.world(direction: Direction.south, mapOverride: map);
      expect(_step(world), isA<Blocked>());
      expect(_step(world.withNpcMapPresencePredicate((mapId, entity) => false)),
          isA<Jumped>());
    });

    test('current character reservation at ${delta + 1} prevents admission',
        () {
      final fixture = BorderJumpFixture();
      final world = fixture.world(direction: Direction.south);
      final pos = _cell(fixture, delta);
      expect(
          _step(world, reservations: [
            PixelRect(
                leftPx: pos.x * 32,
                topPx: pos.y * 32,
                widthPx: 32,
                heightPx: 32),
          ]),
          isA<Blocked>());
    });

    test('native water at ${delta + 1} requires surf without changing geometry',
        () {
      final fixture = BorderJumpFixture();
      final map = _water(fixture, _cell(fixture, delta));
      final walk = fixture.world(direction: Direction.south, mapOverride: map);
      final result = _step(walk) as Blocked;
      expect(result.reason, GameplayMovementBlockReason.waterRequiresSurf);
      final surf = fixture.world(
          direction: Direction.south,
          mapOverride: map,
          mode: MovementMode.surf);
      expect(_step(surf), isA<Jumped>());
    });
  }

  test('a second non-jump Border owner in B remains solid during the jump', () {
    final fixture = BorderJumpFixture();
    final original = fixture.revision.definition;
    final revision = BorderBlueprintRevision(
        revision: 1,
        definition: BorderBlueprintPublishedDefinition(
          name: 'Independent wall',
          previewSeed: original.previewSeed,
          template: original.template,
          primitives: original.primitives,
          defaults: original.defaults,
          sortOrder: 1,
        ));
    final base = BorderFeature(
      id: 'ordinary-wall',
      name: 'Ordinary wall',
      blueprintId: 'non-jump-blueprint',
      seed: fixture.feature.seed,
      geometry: fixture.feature.geometry,
      overrides: const [],
      keepOutRegions: const [],
    );
    final resolved = resolveLedgeLineBorderWithEvidence(BorderResolutionRequest(
      mapSize: fixture.map.size,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: base.blueprintId,
      blueprintRevision: revision,
      feature: base,
      visualSnapshots: fixture.project.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    ));
    final feature = BorderFeature(
      id: base.id,
      name: base.name,
      blueprintId: base.blueprintId,
      seed: base.seed,
      geometry: base.geometry,
      overrides: base.overrides,
      keepOutRegions: base.keepOutRegions,
      materialization: resolved.result.materialization,
    );
    final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
      formatVersion: 7,
      records: [
        ...fixture.project.borderCatalog.records,
        BorderBlueprintRecord(
            id: base.blueprintId,
            draft: fixture.project.borderCatalog.records.single.draft,
            latestPublished: revision),
      ],
      visualSnapshots: fixture.project.borderCatalog.visualSnapshots,
    ));
    final map = fixture.map.copyWith(layers: [
      ...fixture.map.layers,
      MapLayer.border(
          id: 'other-border-owner',
          name: 'Other owner',
          content: BorderLayerContent(formatVersion: 4, features: [feature])),
    ]);
    final world = fixture.world(
        direction: Direction.south, mapOverride: map, projectOverride: project);
    expect(world.borderJumpBindings, hasLength(1));
    expect(_step(world), isA<Blocked>());
  });

  for (final useMask in [false, true]) {
    test(
        'a separate placed ${useMask ? 'pixel' : 'cell'} obstacle in B remains solid',
        () {
      final fixture = BorderJumpFixture();
      final profile = useMask
          ? ElementCollisionProfile(
              collisionMask: ElementCollisionPixelMask(
                  widthPx: 32,
                  heightPx: 32,
                  dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 32,
                    heightPx: 32,
                    solidPixels: List.filled(1024, true),
                  )))
          : const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]);
      final element = fixture.project.elements.first
          .copyWith(id: 'independent-wall', collisionProfile: profile);
      final project = fixture.project
          .copyWith(elements: [...fixture.project.elements, element]);
      final map = fixture.map.copyWith(placedElements: [
        MapPlacedElement(
            id: 'wall-placement',
            layerId: 'objects',
            elementId: element.id,
            pos: fixture.carrier),
      ]);
      final world = fixture.world(
          direction: Direction.south,
          mapOverride: map,
          projectOverride: project);
      expect(_step(world), isA<Blocked>());
    });
  }

  test(
      'a thin top edge at C outside the actual feet stays intact and allows landing',
      () {
    final fixture = BorderJumpFixture();
    final pixels = List.generate(1024, (i) => i < 32);
    final element = fixture.project.elements.first.copyWith(
      id: 'landing-top-edge',
      collisionProfile: ElementCollisionProfile(
        collisionMask: ElementCollisionPixelMask(
          widthPx: 32,
          heightPx: 32,
          dataBase64: ElementCollisionMaskCodec.encodePackedBits(
            widthPx: 32,
            heightPx: 32,
            solidPixels: pixels,
          ),
        ),
      ),
    );
    final project = fixture.project
        .copyWith(elements: [...fixture.project.elements, element]);
    final map = fixture.map.copyWith(placedElements: [
      MapPlacedElement(
          id: 'top-edge',
          layerId: 'objects',
          elementId: element.id,
          pos: _cell(fixture, 1)),
    ]);
    final world = fixture.world(
        direction: Direction.south, mapOverride: map, projectOverride: project);
    expect(_step(world), isA<Jumped>());
    expect(
        world.worldStaticObstaclesCollidePixelRect(PixelRect(
          leftPx: fixture.carrier.x * 32,
          topPx: (fixture.carrier.y + 1) * 32,
          widthPx: 32,
          heightPx: 1,
        )),
        isTrue);
    expect(world.map.placedElements.single, map.placedElements.single);
  });

  test(
      'neighbor collision hit by an off-center final footprint is not bypassed',
      () {
    final fixture = BorderJumpFixture();
    final neighbor =
        GridPos(x: fixture.carrier.x + 1, y: fixture.carrier.y + 1);
    final world = fixture.world(
        direction: Direction.south, mapOverride: _solid(fixture, neighbor));
    final offset = world.withPlayer(world.player.copyWith(
      playerPositionPx: PixelPosition(
        leftPx: world.player.playerPositionPx.leftPx + 13,
        topPx: world.player.playerPositionPx.topPx,
      ),
    ));
    expect(_step(offset), isA<Blocked>());
  });

  test('an entity moved into C is checked against the refreshed dynamic cache',
      () {
    final fixture = BorderJumpFixture();
    final map = fixture.map.copyWith(entities: [
      const MapEntity(
          id: 'moving-blocker',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 8, y: 8)),
    ]);
    final world = fixture.world(direction: Direction.south, mapOverride: map);
    expect(_step(world), isA<Jumped>());
    final updated =
        world.withEntityPosition('moving-blocker', _cell(fixture, 1));
    expect(updated.borderJumpBindings, same(world.borderJumpBindings));
    expect(_step(updated), isA<Blocked>());
  });

  test('out-of-bounds C refuses a selected jump instead of ordinary movement',
      () {
    final fixture = BorderJumpFixture(points: const [
      GridPos(x: 3, y: 11),
      GridPos(x: 4, y: 11),
    ]);
    final world = fixture.world(direction: Direction.south);
    final result = _step(world) as Blocked;
    expect(result.reason, GameplayMovementBlockReason.outOfBounds);
    expect(result.world.player.pos, world.player.pos);
  });

  test('source contact outside the map cannot use a clamped grid position', () {
    final fixture = BorderJumpFixture(points: const [
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ]);
    final world = fixture.world(direction: Direction.south);
    final offset = world.withPlayer(world.player.copyWith(
      playerPositionPx:
          PixelPosition(leftPx: -7, topPx: world.player.playerPositionPx.topPx),
    ));
    expect(_step(offset), isA<Blocked>());
  });

  test(
      'landing warp fires only on explicit arrival, never in the intermediate B',
      () {
    final fixture = BorderJumpFixture();
    final map = fixture.map.copyWith(warps: [
      MapWarp(
          id: 'intermediate',
          pos: fixture.carrier,
          targetMapId: 'wrong',
          targetPos: const GridPos(x: 0, y: 0)),
      MapWarp(
          id: 'landing',
          pos: _cell(fixture, 1),
          targetMapId: 'correct',
          targetPos: const GridPos(x: 1, y: 1)),
    ]);
    final jumped =
        _step(fixture.world(direction: Direction.south, mapOverride: map))
            as Jumped;
    final arrived = resolveGameplayArrival(jumped.world,
        previousPos: jumped.plan.sourcePos,
        direction: Direction.south) as WarpTriggered;
    expect(arrived.warp.warpId, 'landing');
    expect(arrived.world, same(jumped.world));
  });
}
