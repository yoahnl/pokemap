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
  });
}

MapData _mapWithBehavior({
  required bool applyCollision,
  required MapPlacedElementBehavior behavior,
}) {
  return MapData(
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
    placedElements: [
      MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'tree',
        pos: const GridPos(x: 1, y: 1),
        applyCollision: applyCollision,
        behaviors: [behavior],
      ),
    ],
  );
}

ProjectManifest _project({
  bool includeCollisionProfile = true,
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
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
        collisionProfile: includeCollisionProfile
            ? const ElementCollisionProfile(
                cells: [
                  GridPos(x: 0, y: 0),
                  GridPos(x: 1, y: 0),
                ],
              )
            : null,
      ),
    ],
  );
}
