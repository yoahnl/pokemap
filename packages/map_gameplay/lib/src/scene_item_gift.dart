import 'package:map_core/map_core.dart';

import 'items/bag_operation_result.dart';
import 'items/bag_operations.dart';

enum SceneItemGiftOutcome { received, bagFull }

final class SceneItemGiftResult {
  const SceneItemGiftResult({required this.outcome, required this.gameState});

  final SceneItemGiftOutcome outcome;
  final GameState gameState;
}

SceneItemGiftResult executeSceneItemGift({
  required SceneGiveItemInteractiveCommand command,
  required GameState gameState,
}) {
  final result = const BagOperations().give(
    BagGiveRequest(
      bag: gameState.bag,
      itemId: command.itemId,
      quantity: command.quantity,
    ),
  );
  if (result.failure == BagOperationFailure.quantityOverflow) {
    return SceneItemGiftResult(
      outcome: SceneItemGiftOutcome.bagFull,
      gameState: gameState,
    );
  }
  if (!result.isSuccess) {
    throw StateError('Item gift was rejected: ${result.failure?.name}.');
  }
  return SceneItemGiftResult(
    outcome: SceneItemGiftOutcome.received,
    gameState: gameState.copyWith(bag: result.bag),
  );
}
