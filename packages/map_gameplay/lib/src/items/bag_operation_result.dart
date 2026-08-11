import 'package:map_core/map_core.dart';

enum BagOperationFailure {
  invalidItemId,
  invalidQuantity,
  itemMissing,
  insufficientQuantity,
  quantityOverflow,
  protectedKeyItem,
}

enum ItemConsumptionReason {
  appliedEffect,
  captureAttempt,
  scriptedUse,
}

final class ItemConsumptionReceipt {
  const ItemConsumptionReceipt({
    required this.itemId,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
  });

  final String itemId;
  final int quantity;
  final int quantityBefore;
  final int quantityAfter;
  final ItemConsumptionReason reason;

  @override
  bool operator ==(Object other) {
    return other is ItemConsumptionReceipt &&
        other.itemId == itemId &&
        other.quantity == quantity &&
        other.quantityBefore == quantityBefore &&
        other.quantityAfter == quantityAfter &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(
        itemId,
        quantity,
        quantityBefore,
        quantityAfter,
        reason,
      );
}

final class BagOperationResult {
  const BagOperationResult._({
    required this.originalBag,
    required this.bag,
    required this.itemId,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.failure,
    required this.consumptionReceipt,
  });

  factory BagOperationResult.succeeded({
    required Bag originalBag,
    required Bag bag,
    required String itemId,
    required int quantityBefore,
    required int quantityAfter,
    ItemConsumptionReceipt? consumptionReceipt,
  }) {
    return BagOperationResult._(
      originalBag: originalBag,
      bag: bag,
      itemId: itemId,
      quantityBefore: quantityBefore,
      quantityAfter: quantityAfter,
      failure: null,
      consumptionReceipt: consumptionReceipt,
    );
  }

  factory BagOperationResult.failed({
    required Bag originalBag,
    required String itemId,
    required int quantityBefore,
    required BagOperationFailure failure,
  }) {
    return BagOperationResult._(
      originalBag: originalBag,
      bag: originalBag,
      itemId: itemId,
      quantityBefore: quantityBefore,
      quantityAfter: quantityBefore,
      failure: failure,
      consumptionReceipt: null,
    );
  }

  final Bag originalBag;
  final Bag bag;
  final String itemId;
  final int quantityBefore;
  final int quantityAfter;
  final BagOperationFailure? failure;
  final ItemConsumptionReceipt? consumptionReceipt;

  bool get isSuccess => failure == null;
}
