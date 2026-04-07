import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('placed element behaviors', () {
    test('onAction triggers when facing covered element cell', () {
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: true,
          behavior: const MapPlacedElementBehavior(
            enabled: true,
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'hi',
            ),
          ),
        ),
        playerPos: const GridPos(x: 0, y: 1),
        playerFacing: Direction.east,
        project: _project(),
      );

      final result = stepGameplayWorld(world, const InteractIntent());
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onAction);
      expect(interacted.element.id, 'layer::1::1');
    });

    test('onEnter triggers after successful movement', () {
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          behavior: const MapPlacedElementBehavior(
            enabled: true,
            trigger: MapPlacedElementTriggerType.onEnter,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'entered',
            ),
          ),
        ),
        playerPos: const GridPos(x: 0, y: 1),
        playerFacing: Direction.east,
        project: _project(includeCollisionProfile: false),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onEnter);
      expect(interacted.world.player.pos, const GridPos(x: 1, y: 1));
    });

    test('onBump triggers when blocked by element collision', () {
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: true,
          behavior: const MapPlacedElementBehavior(
            enabled: true,
            trigger: MapPlacedElementTriggerType.onBump,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'bump',
            ),
          ),
        ),
        playerPos: const GridPos(x: 0, y: 1),
        playerFacing: Direction.east,
        project: _project(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onBump);
      expect(interacted.world.player.pos, const GridPos(x: 0, y: 1));
    });

    test('onExit triggers when leaving covered cells', () {
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          elementPos: const GridPos(x: 1, y: 1),
          elementSize: const GridSize(width: 2, height: 1),
          playerPos: const GridPos(x: 2, y: 1),
          behavior: const MapPlacedElementBehavior(
            enabled: true,
            trigger: MapPlacedElementTriggerType.onExit,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'exit',
            ),
          ),
        ),
        playerPos: const GridPos(x: 2, y: 1),
        playerFacing: Direction.east,
        project: _project(
          includeCollisionProfile: false,
          elementSize: const GridSize(width: 2, height: 1),
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onExit);
      expect(interacted.world.player.pos, const GridPos(x: 3, y: 1));
    });

    test('onExit does not trigger while still inside covered area', () {
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          elementPos: const GridPos(x: 1, y: 1),
          elementSize: const GridSize(width: 2, height: 1),
          playerPos: const GridPos(x: 1, y: 1),
          behavior: const MapPlacedElementBehavior(
            enabled: true,
            trigger: MapPlacedElementTriggerType.onExit,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'exit',
            ),
          ),
        ),
        playerPos: const GridPos(x: 1, y: 1),
        playerFacing: Direction.east,
        project: _project(
          includeCollisionProfile: false,
          elementSize: const GridSize(width: 2, height: 1),
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
    });

    test('onNear triggers only on outside->near transition', () {
      final behavior = const MapPlacedElementBehavior(
        enabled: true,
        trigger: MapPlacedElementTriggerType.onNear,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'near',
        ),
      );
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          mapSize: const GridSize(width: 8, height: 6),
          elementPos: const GridPos(x: 2, y: 2),
          elementSize: const GridSize(width: 2, height: 2),
          playerPos: const GridPos(x: 0, y: 2),
          behavior: behavior,
        ),
        playerPos: const GridPos(x: 0, y: 2),
        playerFacing: Direction.east,
        project: _project(
          includeCollisionProfile: false,
          elementSize: const GridSize(width: 2, height: 2),
        ),
      );

      final first = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(first, isA<PlacedElementInteracted>());
      final firstInteracted = first as PlacedElementInteracted;
      expect(firstInteracted.trigger, MapPlacedElementTriggerType.onNear);
      expect(firstInteracted.world.player.pos, const GridPos(x: 1, y: 2));

      final second = stepGameplayWorld(
        firstInteracted.world,
        const MoveIntent(Direction.south),
      );
      expect(second, isA<Moved>());
      final secondMoved = second as Moved;
      expect(secondMoved.world.player.pos, const GridPos(x: 1, y: 3));

      final third = stepGameplayWorld(
        secondMoved.world,
        const MoveIntent(Direction.west),
      );
      expect(third, isA<Moved>());
      final thirdMoved = third as Moved;
      expect(thirdMoved.world.player.pos, const GridPos(x: 0, y: 3));

      final fourth = stepGameplayWorld(
        thirdMoved.world,
        const MoveIntent(Direction.east),
      );
      expect(fourth, isA<PlacedElementInteracted>());
      final fourthInteracted = fourth as PlacedElementInteracted;
      expect(fourthInteracted.trigger, MapPlacedElementTriggerType.onNear);
      expect(fourthInteracted.world.player.pos, const GridPos(x: 1, y: 3));
    });

    test('oncePerEnter scope does not retrigger while still inside footprint',
        () {
      final behavior = const MapPlacedElementBehavior(
        enabled: true,
        triggerScope: MapPlacedElementTriggerScope.oncePerEnter,
        trigger: MapPlacedElementTriggerType.onEnter,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'enter_once',
        ),
      );
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          mapSize: const GridSize(width: 7, height: 4),
          elementPos: const GridPos(x: 1, y: 1),
          elementSize: const GridSize(width: 2, height: 1),
          playerPos: const GridPos(x: 0, y: 1),
          behavior: behavior,
        ),
        playerPos: const GridPos(x: 0, y: 1),
        playerFacing: Direction.east,
        project: _project(
          includeCollisionProfile: false,
          elementSize: const GridSize(width: 2, height: 1),
        ),
      );

      final first = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(first, isA<PlacedElementInteracted>());
      final firstInteracted = first as PlacedElementInteracted;
      expect(firstInteracted.world.player.pos, const GridPos(x: 1, y: 1));

      final second = stepGameplayWorld(
        firstInteracted.world,
        const MoveIntent(Direction.east),
      );
      expect(second, isA<Moved>());
      final secondMoved = second as Moved;
      expect(secondMoved.world.player.pos, const GridPos(x: 2, y: 1));

      final third = stepGameplayWorld(
        secondMoved.world,
        const MoveIntent(Direction.east),
      );
      expect(third, isA<Moved>());
      final thirdMoved = third as Moved;
      expect(thirdMoved.world.player.pos, const GridPos(x: 3, y: 1));

      final fourth = stepGameplayWorld(
        thirdMoved.world,
        const MoveIntent(Direction.west),
      );
      expect(fourth, isA<PlacedElementInteracted>());
      final fourthInteracted = fourth as PlacedElementInteracted;
      expect(fourthInteracted.world.player.pos, const GridPos(x: 2, y: 1));
      expect(fourthInteracted.trigger, MapPlacedElementTriggerType.onEnter);
    });

    test('facingOnly scope filters onNear by player facing', () {
      final behavior = const MapPlacedElementBehavior(
        enabled: true,
        triggerScope: MapPlacedElementTriggerScope.facingOnly,
        trigger: MapPlacedElementTriggerType.onNear,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'near_facing',
        ),
      );
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          mapSize: const GridSize(width: 6, height: 6),
          elementPos: const GridPos(x: 2, y: 2),
          elementSize: const GridSize(width: 1, height: 1),
          playerPos: const GridPos(x: 1, y: 3),
          behavior: behavior,
        ),
        playerPos: const GridPos(x: 1, y: 3),
        playerFacing: Direction.east,
        project: _project(
          includeCollisionProfile: false,
          elementSize: const GridSize(width: 1, height: 1),
        ),
      );

      final first = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(first, isA<Moved>());
      final firstMoved = first as Moved;
      expect(firstMoved.world.player.pos, const GridPos(x: 2, y: 3));

      final second = stepGameplayWorld(
        firstMoved.world,
        const MoveIntent(Direction.south),
      );
      expect(second, isA<Moved>());
      final secondMoved = second as Moved;
      expect(secondMoved.world.player.pos, const GridPos(x: 2, y: 4));

      final third = stepGameplayWorld(
        secondMoved.world,
        const MoveIntent(Direction.north),
      );
      expect(third, isA<PlacedElementInteracted>());
      final thirdInteracted = third as PlacedElementInteracted;
      expect(thirdInteracted.trigger, MapPlacedElementTriggerType.onNear);
      expect(thirdInteracted.world.player.pos, const GridPos(x: 2, y: 3));
    });

    test('nearCardinalOnly scope keeps cardinal near behavior deterministic',
        () {
      final behavior = const MapPlacedElementBehavior(
        enabled: true,
        triggerScope: MapPlacedElementTriggerScope.nearCardinalOnly,
        trigger: MapPlacedElementTriggerType.onNear,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'near_cardinal',
        ),
      );
      final world = GameplayWorldState.initial(
        map: _mapWithBehavior(
          applyCollision: false,
          mapSize: const GridSize(width: 6, height: 6),
          elementPos: const GridPos(x: 2, y: 2),
          elementSize: const GridSize(width: 1, height: 1),
          playerPos: const GridPos(x: 0, y: 2),
          behavior: behavior,
        ),
        playerPos: const GridPos(x: 0, y: 2),
        playerFacing: Direction.east,
        project: _project(
          includeCollisionProfile: false,
          elementSize: const GridSize(width: 1, height: 1),
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onNear);
      expect(interacted.world.player.pos, const GridPos(x: 1, y: 2));
    });

    test('movement trigger priority resolves onExit before onNear', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 6, height: 4),
        layers: const [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tiles: [
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
            applyCollision: false,
            behaviors: [
              MapPlacedElementBehavior(
                id: 'exit_behavior',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onExit,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'exit',
                ),
              ),
              MapPlacedElementBehavior(
                id: 'near_behavior',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onNear,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'near',
                ),
              ),
            ],
          ),
        ],
        entities: const [
          MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 2, y: 1),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 2, y: 1),
        playerFacing: Direction.east,
        project: _project(includeCollisionProfile: false),
      );
      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onExit);
      expect(interacted.behavior.id, 'exit_behavior');
    });

    test('overlapping elements on same trigger resolve by map order', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 5, height: 4),
        layers: const [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tiles: [
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'first',
            layerId: 'layer',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
            applyCollision: false,
            behaviors: [
              MapPlacedElementBehavior(
                id: 'first_enter',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onEnter,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'first',
                ),
              ),
            ],
          ),
          MapPlacedElement(
            id: 'second',
            layerId: 'layer',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
            applyCollision: false,
            behaviors: [
              MapPlacedElementBehavior(
                id: 'second_enter',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onEnter,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'second',
                ),
              ),
            ],
          ),
        ],
        entities: const [
          MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 0, y: 1),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 1),
        playerFacing: Direction.east,
        project: _project(includeCollisionProfile: false),
      );
      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.behavior.id, 'first_enter');
      expect(interacted.element.id, 'first');
    });

    test('same element same trigger resolves by behavior order', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 5, height: 4),
        layers: const [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tiles: [
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'instance',
            layerId: 'layer',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
            applyCollision: false,
            behaviors: [
              MapPlacedElementBehavior(
                id: 'first_behavior',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onEnter,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'first',
                ),
              ),
              MapPlacedElementBehavior(
                id: 'second_behavior',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onEnter,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'second',
                ),
              ),
            ],
          ),
        ],
        entities: const [
          MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 0, y: 1),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 1),
        playerFacing: Direction.east,
        project: _project(includeCollisionProfile: false),
      );
      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.behavior.id, 'first_behavior');
    });
  });
}

MapData _mapWithBehavior({
  required bool applyCollision,
  GridSize mapSize = const GridSize(width: 6, height: 4),
  GridPos elementPos = const GridPos(x: 1, y: 1),
  GridSize elementSize = const GridSize(width: 2, height: 1),
  GridPos playerPos = const GridPos(x: 0, y: 1),
  required MapPlacedElementBehavior behavior,
}) {
  final tileCount = mapSize.width * mapSize.height;
  return MapData(
    id: 'map',
    name: 'Map',
    size: mapSize,
    layers: [
      MapLayer.tile(
        id: 'layer',
        name: 'Layer',
        tiles: List<int>.filled(tileCount, 0, growable: false),
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'layer::${elementPos.x}::${elementPos.y}',
        layerId: 'layer',
        elementId: 'tree',
        pos: elementPos,
        applyCollision: applyCollision,
        behaviors: [behavior],
      ),
    ],
    entities: [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: playerPos,
      ),
    ],
  );
}

ElementCollisionPixelMask _solidMaskForElementFootprint({
  required GridSize elementSize,
  int tilePx = 16,
}) {
  final w = elementSize.width * tilePx;
  final h = elementSize.height * tilePx;
  final solid = List<bool>.filled(w * h, true);
  return ElementCollisionPixelMask(
    widthPx: w,
    heightPx: h,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: w,
      heightPx: h,
      solidPixels: solid,
    ),
  );
}

ProjectManifest _project({
  bool includeCollisionProfile = true,
  GridSize elementSize = const GridSize(width: 2, height: 1),
}) {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'cat'),
    ],
    elements: [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'ts',
        categoryId: 'cat',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(
              x: 0,
              y: 0,
              width: elementSize.width,
              height: elementSize.height,
            ),
          ),
        ],
        collisionProfile: includeCollisionProfile
            ? ElementCollisionProfile(
                collisionMask: _solidMaskForElementFootprint(
                  elementSize: elementSize,
                ),
                cells: const <GridPos>[],
              )
            : null,
      ),
    ],
  );
}
