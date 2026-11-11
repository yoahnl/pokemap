import 'package:map_core/map_core_domain.dart';

class PokemonShopEditing {
  static const priceBounds = (minimum: 1, optional: false);
  static const sellPriceBounds = (minimum: 1, optional: true);
  static const stockBounds = (minimum: 0, optional: true);

  static List<ShopEntryDefinition> unresolvedEntries(
    ShopDefinition shop,
    ProjectItemCatalog? catalog,
  ) => [
    for (final entry in shop.entries)
      if (catalog?.entries.any((item) => item.id == entry.itemId) != true)
        entry,
  ];

  static List<ProjectItemDefinition> candidates(
    ShopDefinition shop,
    Iterable<ProjectItemDefinition> items,
  ) => [
    for (final item in items)
      if (!shop.entries.any((entry) => entry.itemId == item.id)) item,
  ];

  static ShopDefinition add(ShopDefinition shop, ProjectItemDefinition item) =>
      shop.copyWith(
        entries: [
          ...shop.entries,
          ShopEntryDefinition(
            itemId: item.id,
            price: item.buyPrice != null && item.buyPrice! > 0
                ? item.buyPrice!
                : 1,
          ),
        ],
      );

  static ShopDefinition replace(
    ShopDefinition shop,
    int index,
    ShopEntryDefinition value,
  ) => shop.copyWith(
    entries: [
      for (var position = 0; position < shop.entries.length; position++)
        if (position == index) value else shop.entries[position],
    ],
  );

  static ShopDefinition remove(ShopDefinition shop, int index) => shop.copyWith(
    entries: [
      for (var position = 0; position < shop.entries.length; position++)
        if (position != index) shop.entries[position],
    ],
  );

  static ShopDefinition move(ShopDefinition shop, int index, int delta) {
    final entries = [...shop.entries];
    final value = entries.removeAt(index);
    entries.insert(index + delta, value);
    return shop.copyWith(entries: entries);
  }

  static ShopDefinition editState(
    ShopDefinition shop,
    int index,
    ShopStateDefinition Function(ShopStateDefinition) update,
  ) => shop.copyWith(
    states: [
      for (var position = 0; position < shop.states.length; position++)
        if (position == index)
          update(shop.states[position])
        else
          shop.states[position],
    ],
  );
}
