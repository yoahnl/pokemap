import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_commerce_references.dart';
import 'pokemon_item_effects.dart';
import 'pokemon_item_overview.dart';
import 'pokemon_shop_availability.dart';
import 'pokemon_shop_catalog.dart';
import 'pokemon_shop_overview.dart';
import 'pokemon_ui_parts.dart';

class PokemonCommerceDetail extends StatelessWidget {
  const PokemonCommerceDetail({
    super.key,
    required this.commerce,
    required this.items,
    required this.onOpenShop,
    this.onBack,
    this.onOpenReference,
  });

  final PokemonCommerceController commerce;
  final bool items;
  final void Function(ShopDefinition) onOpenShop;
  final VoidCallback? onBack;
  final Future<void> Function(String kind, String id)? onOpenReference;

  @override
  Widget build(BuildContext context) {
    final item = commerce.item;
    final shop = commerce.shop;
    if ((items && item == null) || (!items && shop == null)) {
      return PokemonEmptyState(
        title: items ? 'Ouvrez un objet' : 'Ouvrez une boutique',
        description: items
            ? 'Choisissez un objet pour consulter ses données, effets et références.'
            : 'Choisissez une boutique pour gérer son catalogue et sa disponibilité.',
        icon: items ? Icons.inventory_2_outlined : Icons.storefront_outlined,
      );
    }
    final sections = items
        ? const [
            (PokemonCommerceSection.overview, 'Vue d’ensemble'),
            (PokemonCommerceSection.effects, 'Effets'),
            (PokemonCommerceSection.references, 'Usages et références'),
          ]
        : const [
            (PokemonCommerceSection.overview, 'Vue d’ensemble'),
            (PokemonCommerceSection.catalog, 'Catalogue'),
            (PokemonCommerceSection.availability, 'Disponibilité'),
            (PokemonCommerceSection.references, 'Références'),
          ];
    final currentSection = sections.any((value) => value.$1 == commerce.section)
        ? commerce.section
        : PokemonCommerceSection.overview;
    final body = items
        ? switch (currentSection) {
            PokemonCommerceSection.effects => PokemonItemEffects(
              commerce: commerce,
            ),
            PokemonCommerceSection.references => PokemonCommerceReferences(
              commerce: commerce,
              items: true,
              onOpenShop: onOpenShop,
              onOpenReference: onOpenReference,
            ),
            _ => PokemonItemOverview(commerce: commerce),
          }
        : switch (currentSection) {
            PokemonCommerceSection.catalog => PokemonShopCatalog(
              commerce: commerce,
            ),
            PokemonCommerceSection.availability => PokemonShopAvailability(
              commerce: commerce,
            ),
            PokemonCommerceSection.references => PokemonCommerceReferences(
              commerce: commerce,
              items: false,
              onOpenShop: onOpenShop,
              onOpenReference: onOpenReference,
            ),
            _ => PokemonShopOverview(commerce: commerce),
          };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Retour à la liste',
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                items ? Icons.inventory_2_outlined : Icons.storefront_outlined,
                size: 29,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items ? item!.displayName : shop!.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      items ? item!.id : shop!.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (section, label) in sections)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: currentSection == section
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      onPressed: () {
                        commerce.section = section;
                        commerce.changed();
                      },
                      child: Text(label),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              key: PageStorageKey(
                'commerce-${items ? item!.id : shop!.id}-${currentSection.name}',
              ),
              child: AbsorbPointer(
                absorbing: commerce.saving || commerce.importing,
                child: body,
              ),
            ),
          ),
          const SizedBox(height: 10),
          PokemonSurface(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Text(
                  commerce.dirty
                      ? 'Modifications non enregistrées'
                      : 'Aucune modification',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                StudioButton(
                  label: 'Annuler les modifications',
                  secondary: true,
                  onPressed: commerce.dirty && !commerce.saving
                      ? commerce.discardSelected
                      : null,
                ),
                StudioButton(
                  label: commerce.saving ? 'Enregistrement…' : 'Enregistrer',
                  icon: Icons.save_outlined,
                  onPressed: commerce.dirty && !commerce.saving
                      ? commerce.save
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
