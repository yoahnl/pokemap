import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('a bound model blocks only while its item is present', () {
    var present = true;
    final model = ProjectModel3dEntry(
        id: 'orb-model',
        name: 'Orb',
        sourceAssetId: 'source',
        relativePath: 'assets/models3d/orb-model.glb',
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -.4, y: 0, z: -.4),
                max: Model3dVector3(x: .4, y: 1, z: .4)),
            meshCount: 1,
            triangleCount: 4));
    final instance = SpatialModelInstance(
        id: 'orb-model-1',
        modelId: model.id,
        entityId: 'orb',
        position: Model3dVector3(x: 2.5, y: 0, z: 2.5));
    final entity = MapEntity(
        id: 'orb',
        kind: MapEntityKind.item,
        pos: const GridPos(x: 2, y: 2),
        blocksMovement: false,
        item: const MapEntityItemData(gameItemId: 'resource'));
    final scene = MapSpatialScene(
        width: 6,
        depth: 6,
        instances: [instance],
        navigation:
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 2.5, z: 4.5)));
    final movement = SpatialMovementController(
        scene: scene,
        models: [model],
        entities: [entity],
        entityPresencePredicate: (_) => present);
    movement.setInput(x: 0, z: -1);
    for (var i = 0; i < 12; i++) {
      movement.update(.05);
    }
    expect(movement.z, greaterThan(3));
    present = false;
    for (var i = 0; i < 12; i++) {
      movement.update(.05);
    }
    expect(movement.z, lessThan(2.5));
  });
  final item = MapEntity(
      id: 'orb',
      kind: MapEntityKind.item,
      pos: const GridPos(x: 2, y: 2),
      item: const MapEntityItemData(gameItemId: 'resource', quantity: 1));
  final state = GameState(
      saveId: 'save',
      currentMapId: 'field',
      playerPosition: const GridPos(x: 2, y: 3));
  test('native once pickup grants exactly once and survives save JSON', () {
    final first = executeSpatialItemPickup(
        gameState: state, mapId: 'field', entity: item);
    expect(first.outcome.name, 'received');
    expect(first.gameState.bag.entries.single.quantity, 1);
    final loaded = GameState.fromJson(first.gameState.toJson());
    final again = executeSpatialItemPickup(
        gameState: loaded, mapId: 'field', entity: item);
    expect(again.outcome.name, 'alreadyCollected');
    expect(again.gameState, same(loaded));
  });
  test('bag-full pickup keeps both item presence and bag unchanged', () {
    final full = state.copyWith(
        bag: const Bag(entries: [
      BagEntry(itemId: 'resource', quantity: maximumBagEntryQuantity)
    ]));
    final result =
        executeSpatialItemPickup(gameState: full, mapId: 'field', entity: item);
    expect(result.outcome.name, 'bagFull');
    expect(result.gameState, same(full));
    expect(
        spatialItemIsCollected(
            gameState: result.gameState, mapId: 'field', entity: item),
        isFalse);
  });
  test('native pickup refuses unsupported respawn modes without mutation', () {
    final unsupported = item.copyWith(
        item: item.item!.copyWith(pickupMode: ItemPickupMode.always));
    expect(
        () => executeSpatialItemPickup(
            gameState: state, mapId: 'field', entity: unsupported),
        throwsStateError);
    expect(state.bag.entries, isEmpty);
  });
}
