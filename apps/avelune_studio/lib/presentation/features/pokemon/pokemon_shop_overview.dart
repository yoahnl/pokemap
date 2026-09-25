import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'pokemon_ui_parts.dart';

class PokemonShopOverview extends StatelessWidget {
  const PokemonShopOverview({super.key, required this.commerce});

  final PokemonCommerceController commerce;

  @override
  Widget build(BuildContext context) {
    final shop = commerce.shop!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokemonSectionHeading(
                title: 'Identité de la boutique',
                description:
                    'Le lien à une carte ou à une scène est créé dans son espace propriétaire.',
              ),
              PokemonDataRow(label: 'Identifiant', value: shop.id),
              const SizedBox(height: 10),
              StudioDraftField(
                key: ValueKey('shop-label-${shop.id}'),
                label: 'Nom affiché',
                value: shop.label,
                onChanged: (value) => commerce.editShop(
                  (current) => current.copyWith(label: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokemonSectionHeading(title: 'Fonctionnement'),
              PokemonDataRow(
                label: 'Catalogue',
                value: '${shop.entries.length} objet(s) de base',
              ),
              PokemonDataRow(
                label: 'États',
                value: '${shop.states.length} état(s) conditionnel(s)',
              ),
              const SizedBox(height: 8),
              const Text(
                'Les prix et le stock se règlent par ligne. Les états conditionnels contrôlent l’ouverture et peuvent remplacer le catalogue.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Marchand, zone, marge de rachat et tags ne sont pas des champs de cette définition.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
