import 'package:avelune_studio/features/pokemon/application/pokemon_shop_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const _potion = ProjectItemDefinition(
  id: 'potion',
  displayName: 'Potion',
  pocketId: 'medicine',
  buyPrice: 300,
);
const _repel = ProjectItemDefinition(
  id: 'repel',
  displayName: 'Repousse',
  pocketId: 'items',
  buyPrice: 0,
);

void main() {
  test('shop candidates exclude items already sold', () {
    const shop = ShopDefinition(
      id: 'shop',
      label: 'Boutique',
      entries: [ShopEntryDefinition(itemId: 'potion', price: 200)],
    );
    expect(
      PokemonShopEditing.candidates(shop, [
        _potion,
        _repel,
      ]).map((item) => item.id),
      ['repel'],
    );
    expect(shop.entries.single.price, 200);
  });

  for (final item in [
    _potion,
    _repel,
    const ProjectItemDefinition(
      id: 'unpriced',
      displayName: 'Sans prix',
      pocketId: 'items',
    ),
  ]) {
    test(
      'new shop entry uses a positive catalogue price or the fallback for ${item.id} ${item.buyPrice}',
      () {
        const shop = ShopDefinition(id: 'shop', label: 'Boutique');
        final updated = PokemonShopEditing.add(shop, item);
        expect(updated.entries.single.itemId, item.id);
        expect(
          updated.entries.single.price,
          item.buyPrice != null && item.buyPrice! > 0 ? item.buyPrice : 1,
        );
        expect(shop.entries, isEmpty);
      },
    );
  }

  test('replace remove and move affect only the requested shop line', () {
    const shop = ShopDefinition(
      id: 'shop',
      label: 'Boutique',
      entries: [
        ShopEntryDefinition(itemId: 'potion', price: 200, stock: 5),
        ShopEntryDefinition(itemId: 'repel', price: 300),
      ],
    );
    final replaced = PokemonShopEditing.replace(
      shop,
      0,
      shop.entries.first.copyWith(stock: 10),
    );
    expect(replaced.entries.first.stock, 10);
    expect(replaced.entries.last, shop.entries.last);
    final reordered = PokemonShopEditing.move(replaced, 0, 1);
    expect(reordered.entries.map((entry) => entry.itemId), ['repel', 'potion']);
    expect(reordered.entries.last.stock, 10);
    expect(
      PokemonShopEditing.remove(reordered, 0).entries.single.itemId,
      'potion',
    );
    expect(shop.entries.first.stock, 5);
  });

  test('editing a conditional shop state preserves its activation and other states', () {
    final shop = ShopDefinition(
      id: 'shop',
      label: 'Boutique',
      states: [
        ShopStateDefinition(
          id: 'ready',
          label: 'Prêt',
          activation: ScriptConditionFactory.flagIsSet('ready'),
        ),
        ShopStateDefinition(
          id: 'closed',
          label: 'Fermé',
          activation: ScriptConditionFactory.flagIsSet('closed'),
        ),
      ],
    );
    final edited = PokemonShopEditing.editState(
      shop,
      0,
      (state) => state.copyWith(welcomeMessage: 'Bienvenue'),
    );
    expect(edited.states.first.welcomeMessage, 'Bienvenue');
    expect(edited.states.first.activation, shop.states.first.activation);
    expect(edited.states.last, shop.states.last);
    expect(shop.states.first.welcomeMessage, isEmpty);
  });
}
