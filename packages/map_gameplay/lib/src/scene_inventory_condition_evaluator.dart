import 'package:map_core/map_core.dart';

import 'items/bag_operations.dart';

bool evaluateSceneInventoryCondition({
  required SceneConditionSource source,
  required GameState gameState,
}) {
  final quantity = source.inventoryQuantityThreshold;
  if (quantity == null) {
    throw ArgumentError.value(source, 'source', 'Invalid inventory condition.');
  }
  final hasEnough =
      const BagOperations().quantityOf(gameState.bag, source.sourceId) >= quantity;
  return source.operator == SceneConditionOperator.isTrue ? hasEnough : !hasEnough;
}
