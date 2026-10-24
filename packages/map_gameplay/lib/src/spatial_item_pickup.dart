import 'package:map_core/map_core.dart';

import 'items/item_catalog_snapshot.dart';
import 'scene_item_gift.dart';

enum SpatialItemPickupOutcome { received, bagFull, alreadyCollected }

final class SpatialItemPickupResult {
  const SpatialItemPickupResult(
      {required this.outcome, required this.gameState});
  final SpatialItemPickupOutcome outcome;
  final GameState gameState;
}

String spatialItemConsumptionId(String mapId, String entityId) =>
    'item:${mapId.length}:$mapId:${entityId.length}:$entityId';

bool spatialItemIsCollected(
        {required GameState gameState,
        required String mapId,
        required MapEntity entity}) =>
    gameState.consumedEventIds
        .contains(spatialItemConsumptionId(mapId, entity.id));

SpatialItemPickupResult executeSpatialItemPickup({
  required GameState gameState,
  required String mapId,
  required MapEntity entity,
  ProjectBagCapacity bagCapacity = const ProjectBagCapacity.unlimited(),
  ItemCatalogSnapshot? itemCatalog,
}) {
  final item = entity.item;
  if (entity.kind != MapEntityKind.item ||
      item == null ||
      item.pickupMode != ItemPickupMode.once ||
      item.respawnPolicy != ItemRespawnPolicy.none) {
    throw StateError(
        'Native 3D pickups require a once-only item without respawn.');
  }
  if (spatialItemIsCollected(
      gameState: gameState, mapId: mapId, entity: entity)) {
    return SpatialItemPickupResult(
        outcome: SpatialItemPickupOutcome.alreadyCollected,
        gameState: gameState);
  }
  final result = executeSceneItemGift(
      command: SceneGiveItemInteractiveCommand(
          itemId: item.gameItemId, quantity: item.quantity),
      gameState: gameState,
      bagCapacity: bagCapacity,
      itemCatalog: itemCatalog);
  if (result.outcome == SceneItemGiftOutcome.bagFull) {
    return SpatialItemPickupResult(
        outcome: SpatialItemPickupOutcome.bagFull, gameState: gameState);
  }
  return SpatialItemPickupResult(
      outcome: SpatialItemPickupOutcome.received,
      gameState: result.gameState.copyWith(consumedEventIds: {
        ...result.gameState.consumedEventIds,
        spatialItemConsumptionId(mapId, entity.id),
      }));
}
