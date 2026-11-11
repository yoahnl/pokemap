import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_shop_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/pokemon_commerce_owner_fixture.dart';

void main() {
  test('shop lines keep unresolved items visible without dropping them', () {
    const shop = ShopDefinition(
      id: 'gare',
      label: 'Gare',
      entries: [
        ShopEntryDefinition(itemId: 'custom_tool', price: 5),
        ShopEntryDefinition(itemId: 'introuvable', price: 7),
      ],
    );
    final catalog = ProjectItemCatalog(
      schemaVersion: 1,
      entries: [RecordingItemCommercePort().item],
    );
    expect(
      PokemonShopEditing.unresolvedEntries(shop, catalog).map((e) => e.itemId),
      ['introuvable'],
    );
    expect(
      PokemonShopEditing.unresolvedEntries(shop, null).map((e) => e.itemId),
      ['custom_tool', 'introuvable'],
    );
  });

  test(
    'shop prices require a positive buy price and allow blank resale and stock',
    () async {
      final commerce = PokemonCommerceController(
        RecordingItemCommercePort(),
        changed: () {},
      );
      addTearDown(commerce.dispose);
      String? input(({int minimum, bool optional}) bounds, String raw) =>
          commerce.setIntegerInput(
            fieldId: 'field',
            value: raw,
            minimum: bounds.minimum,
            optional: bounds.optional,
            onChanged: (_) {},
          );
      expect(input(PokemonShopEditing.priceBounds, ''), isNotNull);
      expect(input(PokemonShopEditing.priceBounds, '0'), isNotNull);
      expect(input(PokemonShopEditing.priceBounds, '1'), isNull);
      expect(input(PokemonShopEditing.sellPriceBounds, ''), isNull);
      expect(input(PokemonShopEditing.sellPriceBounds, '0'), isNotNull);
      expect(input(PokemonShopEditing.stockBounds, ''), isNull);
      expect(input(PokemonShopEditing.stockBounds, '0'), isNull);
      expect(input(PokemonShopEditing.stockBounds, '-1'), isNotNull);
    },
  );
}
