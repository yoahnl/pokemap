import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../stories/story_metadata_fields.dart';
import 'pokemon_ui_parts.dart';

class PokemonShopAvailability extends StatelessWidget {
  const PokemonShopAvailability({super.key, required this.commerce});

  final PokemonCommerceController commerce;

  @override
  Widget build(BuildContext context) {
    final shop = commerce.shop!;
    final diagnostics = commerce.snapshot!.shopDiagnostics
        .where((value) => value.shopId == shop.id)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokemonSectionHeading(
                title: 'Disponibilité conditionnelle',
                description:
                    'Le runtime choisit un état selon sa condition et sa priorité.',
              ),
              if (shop.states.isEmpty)
                const Text(
                  'Aucun état conditionnel : le catalogue de base est utilisé.',
                ),
              for (var index = 0; index < shop.states.length; index++) ...[
                if (index > 0) const Divider(height: 24),
                Text(
                  shop.states[index].label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                PokemonDataRow(
                  label: 'Identifiant',
                  value: shop.states[index].id,
                ),
                PokemonDataRow(
                  label: 'Priorité',
                  value: '${shop.states[index].priority}',
                ),
                PokemonDataRow(
                  label: 'Condition',
                  value: storyConditionText(
                    shop.states[index].activation,
                    commerce.snapshot!.project,
                  ),
                ),
                StudioToggleRow(
                  label: 'Boutique ouverte dans cet état',
                  value: shop.states[index].isOpen,
                  onChanged: (value) =>
                      _edit(index, (state) => state.copyWith(isOpen: value)),
                ),
                StudioDraftField(
                  key: ValueKey('shop-${shop.id}-state-$index-welcome'),
                  label: 'Message d’accueil',
                  value: shop.states[index].welcomeMessage,
                  onChanged: (value) => _edit(
                    index,
                    (state) => state.copyWith(welcomeMessage: value),
                  ),
                ),
                const SizedBox(height: 8),
                StudioDraftField(
                  key: ValueKey('shop-${shop.id}-state-$index-closed'),
                  label: 'Message de fermeture',
                  value: shop.states[index].closedMessage,
                  onChanged: (value) => _edit(
                    index,
                    (state) => state.copyWith(closedMessage: value),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Catalogue propre à cet état : ${shop.states[index].entries.length} ligne(s).',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokemonSectionHeading(
                title: 'Diagnostic · ${diagnostics.length} constat(s)',
              ),
              if (diagnostics.isEmpty)
                const Text('Aucun diagnostic structurel pour cette boutique.'),
              for (final diagnostic in diagnostics)
                ListTile(
                  dense: true,
                  leading: Icon(
                    diagnostic.severity.name == 'error'
                        ? Icons.error_outline
                        : Icons.info_outline,
                  ),
                  title: Text(diagnostic.message),
                  subtitle: Text(diagnostic.path),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _edit(
    int index,
    ShopStateDefinition Function(ShopStateDefinition) update,
  ) {
    commerce.editShop(
      (shop) => shop.copyWith(
        states: [
          for (var position = 0; position < shop.states.length; position++)
            if (position == index)
              update(shop.states[position])
            else
              shop.states[position],
        ],
      ),
    );
  }
}
