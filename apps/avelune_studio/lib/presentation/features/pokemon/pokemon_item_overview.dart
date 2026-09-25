import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'pokemon_commerce_integer_field.dart';
import 'pokemon_ui_parts.dart';

class PokemonItemOverview extends StatelessWidget {
  const PokemonItemOverview({super.key, required this.commerce});

  final PokemonCommerceController commerce;

  @override
  Widget build(BuildContext context) {
    final item = commerce.item!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokemonSectionHeading(
                title: 'Identité et présentation',
                description:
                    'Les champs ci-dessous alimentent le catalogue canonique.',
              ),
              PokemonDataRow(label: 'Identifiant', value: item.id),
              const SizedBox(height: 9),
              StudioDraftField(
                key: ValueKey('item-name-${item.id}'),
                label: 'Nom affiché',
                value: item.displayName,
                onChanged: (value) => commerce.editItem(
                  (current) => current.copyWith(displayName: value),
                ),
              ),
              const SizedBox(height: 12),
              StudioDraftField(
                key: ValueKey('item-description-${item.id}'),
                label: 'Description',
                value: item.description ?? '',
                lines: 3,
                onChanged: (value) => commerce.editItem(
                  (current) => current.copyWith(description: value),
                ),
              ),
              const SizedBox(height: 12),
              StudioDraftField(
                key: ValueKey('item-pocket-${item.id}'),
                label: 'Poche',
                value: item.pocketId,
                onChanged: (value) => commerce.editItem(
                  (current) => current.copyWith(pocketId: value),
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
              const PokemonSectionHeading(
                title: 'Commerce',
                description:
                    'Prix par défaut. Une boutique peut fixer son propre prix.',
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: PokemonCommerceIntegerField(
                      key: ValueKey(
                        'item-buy-${item.id}-${commerce.formVersion}',
                      ),
                      commerce: commerce,
                      fieldId: 'item-buy-${item.id}',
                      label: 'Prix d’achat',
                      value: item.buyPrice,
                      onChanged: (value) => commerce.editItem(
                        (current) => current.copyWith(buyPrice: value),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: PokemonCommerceIntegerField(
                      key: ValueKey(
                        'item-sell-${item.id}-${commerce.formVersion}',
                      ),
                      commerce: commerce,
                      fieldId: 'item-sell-${item.id}',
                      label: 'Prix de revente',
                      value: item.sellPrice,
                      onChanged: (value) => commerce.editItem(
                        (current) => current.copyWith(sellPrice: value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'La présence dans une boutique se règle dans son catalogue.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokemonSectionHeading(title: 'Capacités réelles'),
              PokemonDataRow(
                label: 'Utilisation',
                value: item.uses.isEmpty
                    ? 'Aucun usage direct'
                    : '${item.uses.length} contexte(s)',
              ),
              PokemonDataRow(
                label: 'Capture',
                value: item.capture == null ? 'Non configurée' : 'Configurée',
              ),
              PokemonDataRow(
                label: 'CT / CS',
                value: item.machine?.moveId ?? 'Non configurée',
              ),
              PokemonDataRow(
                label: 'Effet porté',
                value: item.heldEffectId ?? 'Non configuré',
              ),
              const SizedBox(height: 8),
              const Text(
                'Icône, rareté, quantité maximale et activation individuelle ne sont pas définies par ce catalogue.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
