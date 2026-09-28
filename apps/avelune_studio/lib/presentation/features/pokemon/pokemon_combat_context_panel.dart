import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import 'pokemon_combat_reference_list.dart';

class PokemonCombatContextPanel extends StatelessWidget {
  const PokemonCombatContextPanel({
    super.key,
    required this.combat,
    this.onOpenReference,
  });

  final PokemonCombatController combat;
  final Future<void> Function(String kind, String id)? onOpenReference;

  @override
  Widget build(BuildContext context) {
    final snapshot = combat.snapshot;
    final table = combat.table?.current;
    final trainer = combat.trainer?.current;
    final unique = combat.view == PokemonCombatView.unique;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            trainer != null
                ? 'Implantation et scène'
                : unique
                ? 'Déclenchement et suites'
                : 'Zones et cartes',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            trainer != null
                ? 'L’équipe se prépare ici. Associez un PNJ dans Carte ou un bloc Combat dans Histoire.'
                : unique
                ? 'Choisissez cette rencontre dans un bloc Combat de scène, puis liez la scène à un événement à usage unique.'
                : 'Assignez cette table à une zone rectangulaire ou à des cases peintes dans Carte.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Références du projet', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (snapshot != null && (trainer != null || table != null))
            PokemonCombatReferenceList(
              snapshot: snapshot,
              tableId: table?.id,
              trainerId: trainer?.id,
              onOpenReference: onOpenReference,
            )
          else
            const Text('Sélectionnez une fiche pour voir ses liens.'),
          if (unique && table != null) ...[
            const SizedBox(height: 20),
            Text('Après le combat', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'Victoire ou capture : la rencontre à usage unique est consommée. Défaite ou fuite : elle peut être retentée. Les suites se règlent dans Histoire.',
            ),
          ],
        ],
      ),
    );
  }
}
