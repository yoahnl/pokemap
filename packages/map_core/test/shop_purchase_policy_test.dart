import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'purchase bonus references prevent deletion in default and conditional catalogs',
    () {
      const entry = ShopEntryDefinition(
        itemId: 'ball',
        price: 200,
        purchaseBonus: ShopPurchaseBonus(
          itemId: 'premier',
          everyQuantity: 10,
          quantity: 1,
        ),
      );
      final project = ProjectManifest(
        name: 'Bonus',
        maps: const [],
        tilesets: const [],
        shops: [
          ShopDefinition(
            id: 'mart',
            label: 'Mart',
            entries: const [entry],
            states: [
              ShopStateDefinition(
                id: 'later',
                label: 'Later',
                priority: 1,
                activation: ScriptConditionFactory.flagIsSet('later'),
                entries: const [entry],
              ),
            ],
          ),
        ],
      );
      final index = buildProjectItemReferenceIndex(
        project: project,
        maps: const [],
      );
      expect(index.blockingReferencesFor('premier'), hasLength(2));
      expect(
        index
            .referencesFor('premier')
            .every(
              (entry) => entry.editablePath.endsWith('.purchaseBonus.itemId'),
            ),
        isTrue,
      );
    },
  );
  test(
    'shop validation diagnoses invalid caps and bonus references before play',
    () {
      final project = ProjectManifest(
        name: 'Bonus',
        maps: const [],
        tilesets: const [],
        shops: const [
          ShopDefinition(
            id: 'mart',
            label: 'Mart',
            entries: [
              ShopEntryDefinition(
                itemId: 'ball',
                price: 200,
                maximumOwnedQuantity: 0,
                purchaseBonus: ShopPurchaseBonus(
                  itemId: 'missing',
                  everyQuantity: 0,
                  quantity: 1,
                ),
              ),
            ],
          ),
        ],
      );
      final diagnostics = ShopStateValidator(
        project: project,
        knownItemIds: const {'ball'},
      ).validate();
      expect(
        diagnostics.map((entry) => entry.code),
        containsAll([
          'SHOP_STATE_INVALID_OWNERSHIP_LIMIT',
          'SHOP_STATE_UNKNOWN_BONUS_ITEM',
          'SHOP_STATE_INVALID_PURCHASE_BONUS',
        ]),
      );
    },
  );
  test(
    'shop ownership and purchase bonus policies survive JSON and normalization',
    () {
      const shop = ShopDefinition(
        id: 'mart',
        label: 'Mart',
        sellPolicy: ShopSellPolicy.catalogPrices,
        entries: [
          ShopEntryDefinition(
            itemId: 'ball',
            price: 200,
            maximumOwnedQuantity: 999,
            purchaseBonus: ShopPurchaseBonus(
              itemId: 'premier',
              everyQuantity: 10,
              quantity: 1,
              maximumOwnedQuantity: 999,
            ),
          ),
        ],
      );
      final restored = ShopDefinition.fromJson(
        jsonDecode(jsonEncode(shop.toJson())),
      );
      expect(restored, shop);
      expect(restored.normalized(knownItemIds: {'ball', 'premier'}), shop);
    },
  );
  for (final bonus in [
    const ShopPurchaseBonus(itemId: 'premier', everyQuantity: 0, quantity: 1),
    const ShopPurchaseBonus(itemId: 'premier', everyQuantity: 10, quantity: 0),
    const ShopPurchaseBonus(
      itemId: 'premier',
      everyQuantity: 10,
      quantity: 1,
      maximumOwnedQuantity: 0,
    ),
  ]) {
    test('bonus rejects invalid quantities ${bonus.toJson()}', () {
      expect(() => bonus.normalized(), throwsStateError);
    });
  }
  test('bonus item is validated with canonical catalog references', () {
    expect(
      () => const ShopEntryDefinition(
        itemId: 'ball',
        price: 200,
        purchaseBonus: ShopPurchaseBonus(
          itemId: 'missing',
          everyQuantity: 10,
          quantity: 1,
        ),
      ).normalized(knownItemIds: {'ball'}),
      throwsStateError,
    );
  });
  test('ownership limit must be strictly positive', () {
    expect(
      () => const ShopEntryDefinition(
        itemId: 'ball',
        price: 200,
        maximumOwnedQuantity: 0,
      ).normalized(),
      throwsStateError,
    );
  });
}
