import '../../../features/pokemon/application/pokemon_shop_editing.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import 'pokemon_commerce_integer_field.dart';
import '../../../features/pokemon/application/pokemon_pocket_label.dart';
import 'pokemon_ui_parts.dart';

class PokemonShopCatalog extends StatelessWidget {
  const PokemonShopCatalog({super.key, required this.commerce});

  final PokemonCommerceController commerce;

  Future<void> _add(BuildContext context) async {
    final catalog = commerce.snapshot?.catalog;
    if (catalog == null) return;
    final candidates = PokemonShopEditing.candidates(
      commerce.shop!,
      catalog.entries,
    );
    final selected = await showDialog<ProjectItemDefinition>(
      context: context,
      builder: (dialog) => _ItemPicker(items: candidates),
    );
    if (selected == null) return;
    commerce.editShop((shop) => PokemonShopEditing.add(shop, selected));
  }

  void _replace(int index, ShopEntryDefinition value) => commerce.editShop(
    (shop) => PokemonShopEditing.replace(shop, index, value),
  );

  void _remove(int index) =>
      commerce.editShop((shop) => PokemonShopEditing.remove(shop, index));

  void _move(int index, int delta) =>
      commerce.editShop((shop) => PokemonShopEditing.move(shop, index, delta));

  @override
  Widget build(BuildContext context) {
    final shop = commerce.shop!;
    final catalog = commerce.snapshot?.catalog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokemonSectionHeading(
                title: 'Catalogue · ${shop.entries.length} objet(s)',
                description: 'La boutique référence les objets. Le prix et le stock sont propres à chaque ligne.',
                trailing: StudioButton(
                  label: 'Ajouter un objet',
                  icon: Icons.add,
                  onPressed: catalog == null ? null : () => _add(context),
                ),
              ),
              if (catalog == null)
                const Text(
                  'Catalogue d’objets indisponible : ajout désactivé, références conservées.',
                ),
              if (shop.entries.isEmpty)
                const Text('Aucun objet vendu pour le moment.'),
              for (var index = 0; index < shop.entries.length; index++) ...[
                if (index > 0) const Divider(height: 22),
                _entry(context, index, shop.entries[index], catalog),
              ],
            ],
          ),
        ),
        if (shop.states.any((state) => state.entries.isNotEmpty)) ...[
          const SizedBox(height: 12),
          PokemonSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokemonSectionHeading(title: 'Catalogues conditionnels'),
                for (final state in shop.states.where(
                  (state) => state.entries.isNotEmpty,
                ))
                  PokemonDataRow(
                    label: state.label,
                    value:
                        '${state.entries.length} objet(s) · conservés sans modification',
                  ),
                const Text(
                  'Ces listes remplacent le catalogue de base selon la condition de l’état. Leur édition reste dans le propriétaire existant.',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _entry(
    BuildContext context,
    int index,
    ShopEntryDefinition entry,
    ProjectItemCatalog? catalog,
  ) {
    final item = catalog?.entries
        .where((value) => value.id == entry.itemId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item?.displayName ?? 'Objet introuvable : ${entry.itemId}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              onPressed: index == 0 ? null : () => _move(index, -1),
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Monter',
            ),
            IconButton(
              onPressed: index == commerce.shop!.entries.length - 1
                  ? null
                  : () => _move(index, 1),
              icon: const Icon(Icons.arrow_downward),
              tooltip: 'Descendre',
            ),
            IconButton(
              onPressed: () => _remove(index),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Retirer du catalogue',
            ),
          ],
        ),
        Text(
          '${entry.itemId} · ${item == null ? 'Référence non résolue' : pokemonPocketLabel(item.pocketId)}',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 150,
              child: PokemonCommerceIntegerField(
                key: ValueKey(
                  'shop-${commerce.shop!.id}-$index-price-${commerce.formVersion}',
                ),
                commerce: commerce,
                fieldId: 'shop-${commerce.shop!.id}-$index-price',
                label: 'Prix d’achat',
                value: entry.price,
                minimum: PokemonShopEditing.priceBounds.minimum,
                optional: PokemonShopEditing.priceBounds.optional,
                onChanged: (value) =>
                    _replace(index, entry.copyWith(price: value!)),
              ),
            ),
            SizedBox(
              width: 150,
              child: PokemonCommerceIntegerField(
                key: ValueKey(
                  'shop-${commerce.shop!.id}-$index-sell-${commerce.formVersion}',
                ),
                commerce: commerce,
                fieldId: 'shop-${commerce.shop!.id}-$index-sell',
                label: 'Prix de revente',
                value: entry.sellPrice,
                minimum: PokemonShopEditing.sellPriceBounds.minimum,
                optional: PokemonShopEditing.sellPriceBounds.optional,
                onChanged: (value) =>
                    _replace(index, entry.copyWith(sellPrice: value)),
              ),
            ),
            SizedBox(
              width: 150,
              child: PokemonCommerceIntegerField(
                key: ValueKey(
                  'shop-${commerce.shop!.id}-$index-stock-${commerce.formVersion}',
                ),
                commerce: commerce,
                fieldId: 'shop-${commerce.shop!.id}-$index-stock',
                label: 'Stock',
                value: entry.stock,
                minimum: PokemonShopEditing.stockBounds.minimum,
                optional: PokemonShopEditing.stockBounds.optional,
                onChanged: (value) =>
                    _replace(index, entry.copyWith(stock: value)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemPicker extends StatefulWidget {
  const _ItemPicker({required this.items});
  final List<ProjectItemDefinition> items;
  @override
  State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final item in widget.items)
        if (pokemonItemMatchesSearch(item, search.text)) item,
    ];
    return AlertDialog(
      title: const Text('Choisir un objet du projet'),
      content: SizedBox(
        width: 420,
        height: 400,
        child: Column(
          children: [
            StudioSearchField(
              controller: search,
              label: 'Rechercher un objet',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(entries[index].displayName),
                  subtitle: Text(entries[index].id),
                  onTap: () => Navigator.pop(context, entries[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        StudioButton(
          label: 'Annuler',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
