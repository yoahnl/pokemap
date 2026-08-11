import 'package:map_core/map_core.dart';

import 'bag_operation_result.dart';

final class BagGiveRequest {
  const BagGiveRequest({
    required this.bag,
    required this.itemId,
    required this.quantity,
  });

  final Bag bag;
  final String itemId;
  final int quantity;
}

final class BagTakeRequest {
  const BagTakeRequest({
    required this.bag,
    required this.itemId,
    required this.quantity,
  });

  final Bag bag;
  final String itemId;
  final int quantity;
}

final class BagConsumeRequest {
  const BagConsumeRequest({
    required this.bag,
    required this.itemId,
    required this.quantity,
    required this.reason,
    this.itemTags = const <String>{},
    this.allowKeyItemConsumption = false,
  });

  final Bag bag;
  final String itemId;
  final int quantity;
  final ItemConsumptionReason reason;
  final Set<String> itemTags;
  final bool allowKeyItemConsumption;
}

final class BagOperations {
  const BagOperations();

  int quantityOf(Bag bag, String itemId) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) {
      return 0;
    }
    return bag.entries
        .where((entry) => entry.itemId.trim() == normalizedItemId)
        .fold(0, (total, entry) => total + entry.quantity);
  }

  BagOperationResult give(BagGiveRequest request) {
    final itemId = request.itemId.trim();
    final quantityBefore = quantityOf(request.bag, itemId);
    if (itemId.isEmpty) {
      return _failure(
        request.bag,
        itemId,
        quantityBefore,
        BagOperationFailure.invalidItemId,
      );
    }
    if (request.quantity <= 0) {
      return _failure(
        request.bag,
        itemId,
        quantityBefore,
        BagOperationFailure.invalidQuantity,
      );
    }
    if (quantityBefore > maximumBagEntryQuantity - request.quantity) {
      return _failure(
        request.bag,
        itemId,
        quantityBefore,
        BagOperationFailure.quantityOverflow,
      );
    }

    final quantityAfter = quantityBefore + request.quantity;
    return BagOperationResult.succeeded(
      originalBag: request.bag,
      bag: _replaceStack(request.bag, itemId, quantityAfter),
      itemId: itemId,
      quantityBefore: quantityBefore,
      quantityAfter: quantityAfter,
    );
  }

  BagOperationResult take(BagTakeRequest request) {
    return _take(
      bag: request.bag,
      itemId: request.itemId,
      quantity: request.quantity,
    );
  }

  BagOperationResult consume(BagConsumeRequest request) {
    final itemId = request.itemId.trim();
    final quantityBefore = quantityOf(request.bag, itemId);
    if (request.itemTags.contains('key-item') &&
        !request.allowKeyItemConsumption) {
      return _failure(
        request.bag,
        itemId,
        quantityBefore,
        BagOperationFailure.protectedKeyItem,
      );
    }

    final taken = _take(
      bag: request.bag,
      itemId: itemId,
      quantity: request.quantity,
    );
    if (!taken.isSuccess) {
      return taken;
    }
    return BagOperationResult.succeeded(
      originalBag: request.bag,
      bag: taken.bag,
      itemId: itemId,
      quantityBefore: taken.quantityBefore,
      quantityAfter: taken.quantityAfter,
      consumptionReceipt: ItemConsumptionReceipt(
        itemId: itemId,
        quantity: request.quantity,
        quantityBefore: taken.quantityBefore,
        quantityAfter: taken.quantityAfter,
        reason: request.reason,
      ),
    );
  }

  BagOperationResult _take({
    required Bag bag,
    required String itemId,
    required int quantity,
  }) {
    final normalizedItemId = itemId.trim();
    final quantityBefore = quantityOf(bag, normalizedItemId);
    if (normalizedItemId.isEmpty) {
      return _failure(
        bag,
        normalizedItemId,
        quantityBefore,
        BagOperationFailure.invalidItemId,
      );
    }
    if (quantity <= 0) {
      return _failure(
        bag,
        normalizedItemId,
        quantityBefore,
        BagOperationFailure.invalidQuantity,
      );
    }
    if (quantityBefore == 0) {
      return _failure(
        bag,
        normalizedItemId,
        quantityBefore,
        BagOperationFailure.itemMissing,
      );
    }
    if (quantity > quantityBefore) {
      return _failure(
        bag,
        normalizedItemId,
        quantityBefore,
        BagOperationFailure.insufficientQuantity,
      );
    }

    final quantityAfter = quantityBefore - quantity;
    return BagOperationResult.succeeded(
      originalBag: bag,
      bag: _replaceStack(bag, normalizedItemId, quantityAfter),
      itemId: normalizedItemId,
      quantityBefore: quantityBefore,
      quantityAfter: quantityAfter,
    );
  }

  BagOperationResult _failure(
    Bag bag,
    String itemId,
    int quantityBefore,
    BagOperationFailure failure,
  ) {
    return BagOperationResult.failed(
      originalBag: bag,
      itemId: itemId,
      quantityBefore: quantityBefore,
      failure: failure,
    );
  }

  Bag _replaceStack(Bag bag, String itemId, int quantity) {
    final entries = <BagEntry>[
      for (final entry in bag.entries)
        if (entry.itemId.trim() != itemId) entry,
      if (quantity > 0) BagEntry(itemId: itemId, quantity: quantity),
    ];
    return Bag(entries: entries).normalized();
  }
}
