import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/items/bag_operation_result.dart';
import 'package:map_gameplay/src/items/bag_operations.dart';
import 'package:test/test.dart';

void main() {
  const operations = BagOperations();

  group('BagOperations.give', () {
    test('merges by itemId and reports the before and after quantities', () {
      const bag = Bag(entries: [BagEntry(itemId: 'potion', quantity: 2)]);

      final result = operations.give(
        const BagGiveRequest(bag: bag, itemId: ' potion ', quantity: 3),
      );

      expect(result.isSuccess, isTrue);
      expect(result.itemId, 'potion');
      expect(result.quantityBefore, 2);
      expect(result.quantityAfter, 5);
      expect(result.bag.entries, const [
        BagEntry(itemId: 'potion', quantity: 5),
      ]);
    });

    test('rejects invalid quantities and overflow without mutation', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', quantity: maximumBagEntryQuantity),
        ],
      );

      final invalid = operations.give(
        const BagGiveRequest(bag: bag, itemId: 'potion', quantity: 0),
      );
      final overflow = operations.give(
        const BagGiveRequest(bag: bag, itemId: 'potion', quantity: 1),
      );

      expect(invalid.failure, BagOperationFailure.invalidQuantity);
      expect(overflow.failure, BagOperationFailure.quantityOverflow);
      expect(invalid.bag, same(bag));
      expect(overflow.bag, same(bag));
    });
  });

  group('BagOperations.take', () {
    test('decrements or removes a stack atomically', () {
      const bag = Bag(entries: [BagEntry(itemId: 'potion', quantity: 3)]);

      final decremented = operations.take(
        const BagTakeRequest(bag: bag, itemId: 'potion', quantity: 2),
      );
      final removed = operations.take(
        const BagTakeRequest(bag: bag, itemId: 'potion', quantity: 3),
      );

      expect(decremented.quantityAfter, 1);
      expect(decremented.bag.entries.single.quantity, 1);
      expect(removed.quantityAfter, 0);
      expect(removed.bag.entries, isEmpty);
    });

    test('preserves the original bag on missing or excessive quantity', () {
      const bag = Bag(entries: [BagEntry(itemId: 'potion', quantity: 1)]);

      final missing = operations.take(
        const BagTakeRequest(bag: bag, itemId: 'ether', quantity: 1),
      );
      final excessive = operations.take(
        const BagTakeRequest(bag: bag, itemId: 'potion', quantity: 2),
      );

      expect(missing.failure, BagOperationFailure.itemMissing);
      expect(excessive.failure, BagOperationFailure.insufficientQuantity);
      expect(missing.bag, same(bag));
      expect(excessive.bag, same(bag));
    });
  });

  group('BagOperations.consume', () {
    test('returns an exact receipt for an applied consumption', () {
      const bag = Bag(entries: [BagEntry(itemId: 'potion', quantity: 2)]);

      final result = operations.consume(
        const BagConsumeRequest(
          bag: bag,
          itemId: 'potion',
          quantity: 1,
          reason: ItemConsumptionReason.appliedEffect,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.consumptionReceipt,
        const ItemConsumptionReceipt(
          itemId: 'potion',
          quantity: 1,
          quantityBefore: 2,
          quantityAfter: 1,
          reason: ItemConsumptionReason.appliedEffect,
        ),
      );
    });

    test('protects key items unless consumption is explicitly authorized', () {
      const bag = Bag(entries: [BagEntry(itemId: 'door-key', quantity: 1)]);
      const protectedRequest = BagConsumeRequest(
        bag: bag,
        itemId: 'door-key',
        quantity: 1,
        itemTags: {'key-item'},
        reason: ItemConsumptionReason.scriptedUse,
      );

      final refused = operations.consume(protectedRequest);
      final authorized = operations.consume(
        const BagConsumeRequest(
          bag: bag,
          itemId: 'door-key',
          quantity: 1,
          itemTags: {'key-item'},
          reason: ItemConsumptionReason.scriptedUse,
          allowKeyItemConsumption: true,
        ),
      );

      expect(refused.failure, BagOperationFailure.protectedKeyItem);
      expect(refused.bag, same(bag));
      expect(authorized.isSuccess, isTrue);
      expect(authorized.bag.entries, isEmpty);
    });

    test('failed consumption is idempotent and never emits a receipt', () {
      const bag = Bag(entries: [BagEntry(itemId: 'potion', quantity: 1)]);
      const request = BagConsumeRequest(
        bag: bag,
        itemId: 'potion',
        quantity: 2,
        reason: ItemConsumptionReason.appliedEffect,
      );

      final first = operations.consume(request);
      final second = operations.consume(request);

      expect(first.failure, BagOperationFailure.insufficientQuantity);
      expect(second.failure, first.failure);
      expect(first.bag, same(bag));
      expect(second.bag, same(bag));
      expect(first.consumptionReceipt, isNull);
      expect(second.consumptionReceipt, isNull);
    });
  });

  test('inspect returns the normalized stack quantity without mutation', () {
    const bag = Bag(entries: [BagEntry(itemId: 'potion', quantity: 4)]);

    expect(operations.quantityOf(bag, ' potion '), 4);
    expect(operations.quantityOf(bag, 'ether'), 0);
    expect(operations.quantityOf(bag, '   '), 0);
    expect(bag.entries.single.quantity, 4);
  });
}
