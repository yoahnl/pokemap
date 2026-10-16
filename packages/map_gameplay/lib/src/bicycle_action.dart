import 'package:map_core/map_core.dart';

import 'items/bag_operations.dart';
import 'movement_terrain_policy.dart';

enum BicycleBlockReason {
  unsupportedMap,
  unavailableContext,
  forbiddenMap,
  incompatibleTerrain,
  invalidItem,
  insufficientQuantity,
  missingAnimations,
}

bool isBicycleItem(ProjectItemDefinition item) {
  final uses = item.uses
      .where((use) => use.contexts.contains(ProjectItemUseContext.overworld));
  return item.tags.contains('key-item') &&
      uses.length == 1 &&
      uses.single.contexts.length == 1 &&
      uses.single.target == ProjectItemTargetKind.world &&
      uses.single.consumption == ProjectItemConsumptionPolicy.never &&
      uses.single.effect is ProjectItemBicycleEffectDefinition;
}

MovementMode bicycleArrivalMode(MapData map, MovementMode mode) =>
    mode == MovementMode.bicycle &&
            (map.spatialScene != null ||
                map.mapMetadata.isIndoor ||
                !map.mapMetadata.allowBicycle)
        ? MovementMode.walk
        : mode;

BicycleBlockReason? evaluateBicycleToggle({
  required MapData map,
  required GameState state,
  required ProjectItemDefinition item,
  required bool hasAnimations,
}) {
  if (map.version != ProjectVersion.v8 || map.spatialScene != null) {
    return BicycleBlockReason.unsupportedMap;
  }
  if (state.currentMapId != map.id ||
      (state.playerMovementMode != MovementMode.walk &&
          state.playerMovementMode != MovementMode.bicycle)) {
    return BicycleBlockReason.unavailableContext;
  }
  if (!isBicycleItem(item)) return BicycleBlockReason.invalidItem;
  if (const BagOperations().quantityOf(state.bag, item.id) < 1) {
    return BicycleBlockReason.insufficientQuantity;
  }
  if (state.playerPosition.x < 0 ||
      state.playerPosition.y < 0 ||
      state.playerPosition.x >= map.size.width ||
      state.playerPosition.y >= map.size.height ||
      movementTerrainAt(map, state.playerPosition.x, state.playerPosition.y) !=
          GameplayMovementTerrain.land) {
    return BicycleBlockReason.incompatibleTerrain;
  }
  if (state.playerMovementMode == MovementMode.bicycle) return null;
  if (map.mapMetadata.isIndoor || !map.mapMetadata.allowBicycle) {
    return BicycleBlockReason.forbiddenMap;
  }
  if (!hasAnimations) return BicycleBlockReason.missingAnimations;
  return null;
}
