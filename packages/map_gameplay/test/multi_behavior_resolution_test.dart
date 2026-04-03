import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _kTestFrame = TilesetVisualFrame(
  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
);

void main() {
  group('Multi-behavior resolution policy', () {
    test('Single winner: first behavior in first instance wins for onAction', () {
      final element1 = ProjectElementEntry(
        id: 'element1',
        name: 'Element 1',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );
      final element2 = ProjectElementEntry(
        id: 'element2',
        name: 'Element 2',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );

      final instance1 = MapPlacedElement(
        id: 'inst1',
        layerId: 'objects',
        elementId: 'element1',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior1a',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'First behavior wins',
            ),
          ),
          const MapPlacedElementBehavior(
            id: 'behavior1b',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Second behavior loses',
            ),
          ),
        ],
      );

      final instance2 = MapPlacedElement(
        id: 'inst2',
        layerId: 'objects',
        elementId: 'element2',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior2',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Second instance loses',
            ),
          ),
        ],
      );

      final map = MapData(
        id: 'test_map',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
        placedElements: [instance1, instance2],
      );

      final manifest = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        elements: [element1, element2],
      );

      final world = GameplayWorldState.initial(
        map: map,
        project: manifest,
        playerPos: const GridPos(x: 0, y: 0),
      );

      final activation = world.placedElementBehaviorOnActionAt(5, 5);

      expect(activation, isNotNull);
      expect(activation!.element.id, equals('inst1'));
      expect(activation.behavior.id, equals('behavior1a'));
    });

    test('Single winner: first instance wins when behaviors overlap', () {
      final element1 = ProjectElementEntry(
        id: 'element1',
        name: 'Element 1',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );
      final element2 = ProjectElementEntry(
        id: 'element2',
        name: 'Element 2',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );

      final instance1 = MapPlacedElement(
        id: 'inst1',
        layerId: 'objects',
        elementId: 'element1',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior1',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'First instance wins',
            ),
          ),
        ],
      );

      final instance2 = MapPlacedElement(
        id: 'inst2',
        layerId: 'objects',
        elementId: 'element2',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior2',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Second instance loses',
            ),
          ),
        ],
      );

      final map = MapData(
        id: 'test_map',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
        placedElements: [instance2, instance1],
      );

      final manifest = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        elements: [element1, element2],
      );

      final world = GameplayWorldState.initial(
        map: map,
        project: manifest,
        playerPos: const GridPos(x: 0, y: 0),
      );

      final activation = world.placedElementBehaviorOnActionAt(5, 5);

      expect(activation, isNotNull);
      expect(activation!.element.id, equals('inst2'));
      expect(activation.behavior.id, equals('behavior2'));
    });

    test('Movement trigger priority: onEnter > onExit > onNear', () {
      final element = ProjectElementEntry(
        id: 'element1',
        name: 'Element 1',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );

      final instance = MapPlacedElement(
        id: 'inst1',
        layerId: 'objects',
        elementId: 'element1',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'onEnter_beh',
            trigger: MapPlacedElementTriggerType.onEnter,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'onEnter',
            ),
          ),
          const MapPlacedElementBehavior(
            id: 'onExit_beh',
            trigger: MapPlacedElementTriggerType.onExit,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'onExit',
            ),
          ),
          const MapPlacedElementBehavior(
            id: 'onNear_beh',
            trigger: MapPlacedElementTriggerType.onNear,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'onNear',
            ),
          ),
        ],
      );

      final map = MapData(
        id: 'test_map',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
        placedElements: [instance],
      );

      final manifest = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        elements: [element],
      );

      // Start OUTSIDE the element cell, then move INTO it
      final world = GameplayWorldState.initial(
        map: map,
        project: manifest,
        playerPos: const GridPos(x: 3, y: 5),
      );

      // Move east twice: first to (4,5), then to (5,5) which is the element cell
      final movedWorld1 = world.withPlayer(
        world.player.copyWith(pos: const GridPos(x: 4, y: 5)),
      );

      final result = stepGameplayWorld(
        movedWorld1,
        MoveIntent(Direction.east),
      );

      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, equals(MapPlacedElementTriggerType.onEnter));
      expect(interacted.behavior.id, equals('onEnter_beh'));
    });

    test('Determinism: same input produces same winner', () {
      final element = ProjectElementEntry(
        id: 'element1',
        name: 'Element 1',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );

      final instance1 = MapPlacedElement(
        id: 'inst1',
        layerId: 'objects',
        elementId: 'element1',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior1',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Winner',
            ),
          ),
        ],
      );

      final instance2 = MapPlacedElement(
        id: 'inst2',
        layerId: 'objects',
        elementId: 'element1',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior2',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Loser',
            ),
          ),
        ],
      );

      final map = MapData(
        id: 'test_map',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
        placedElements: [instance1, instance2],
      );

      final manifest = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        elements: [element],
      );

      final world1 = GameplayWorldState.initial(
        map: map,
        project: manifest,
        playerPos: const GridPos(x: 0, y: 0),
      );
      final world2 = GameplayWorldState.initial(
        map: map,
        project: manifest,
        playerPos: const GridPos(x: 0, y: 0),
      );

      final activation1 = world1.placedElementBehaviorOnActionAt(5, 5);
      final activation2 = world2.placedElementBehaviorOnActionAt(5, 5);

      expect(activation1, isNotNull);
      expect(activation2, isNotNull);
      expect(activation1!.element.id, equals(activation2!.element.id));
      expect(activation1.behavior.id, equals(activation2.behavior.id));
    });

    test('onAction interaction returns single behavior', () {
      final element = ProjectElementEntry(
        id: 'element1',
        name: 'Element 1',
        tilesetId: 'ts1',
        categoryId: 'cat1',
        frames: [_kTestFrame],
      );

      final instance = MapPlacedElement(
        id: 'inst1',
        layerId: 'objects',
        elementId: 'element1',
        pos: const GridPos(x: 5, y: 5),
        behaviors: [
          const MapPlacedElementBehavior(
            id: 'behavior1',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Message 1',
            ),
          ),
          const MapPlacedElementBehavior(
            id: 'behavior2',
            trigger: MapPlacedElementTriggerType.onAction,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Message 2',
            ),
          ),
        ],
      );

      final map = MapData(
        id: 'test_map',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
        placedElements: [instance],
      );

      final manifest = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        elements: [element],
      );

      // Player at (4,5) facing EAST towards element at (5,5)
      final world = GameplayWorldState.initial(
        map: map,
        project: manifest,
        playerPos: const GridPos(x: 4, y: 5),
      );
      final facingWorld = world.withPlayer(
        world.player.copyWith(facing: Direction.east),
      );

      final result = stepGameplayWorld(facingWorld, InteractIntent());

      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, equals(MapPlacedElementTriggerType.onAction));
      expect(interacted.behavior.id, equals('behavior1'));
    });
  });
}
