import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'pokemon_combat_reference_list.dart';
import '../../../features/pokemon/application/pokemon_combat_references.dart';

class PokemonCombatContextPanel extends StatelessWidget {
  const PokemonCombatContextPanel({
    super.key,
    required this.combat,
    this.index,
    this.onOpenReference,
  });

  final PokemonCombatController combat;
  final PokemonWorkspaceIndex? index;
  final Future<void> Function(String kind, String id, [String? detailId])?
  onOpenReference;

  @override
  Widget build(BuildContext context) {
    final snapshot = combat.snapshot;
    final table = combat.table?.current;
    final trainer = combat.trainer?.current;
    final unique = combat.view == PokemonCombatView.unique;
    final theme = Theme.of(context);
    final complete = snapshot?.referencesComplete == true;
    final usages = !complete
        ? null
        : table != null
        ? combatTableReferences(snapshot!, table)
        : trainer != null
        ? combatTrainerReferences(snapshot!, trainer)
        : null;
    final problem = index == null || (table == null && trainer == null)
        ? null
        : combat.validationProblem(index!);
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
          if (problem != null) ...[
            const SizedBox(height: 12),
            StudioNotice(
              key: ValueKey(
                trainer != null
                    ? 'combat-trainer-invalid'
                    : 'combat-table-invalid',
              ),
              '${trainer != null ? 'Dresseur' : 'Table'} invalide : $problem',
              isError: true,
            ),
          ],
          if (usages != null && usages.isEmpty) ...[
            const SizedBox(height: 12),
            StudioNotice(
              key: ValueKey(
                trainer != null
                    ? 'combat-trainer-unassigned'
                    : 'combat-table-unassigned',
              ),
              trainer != null
                  ? 'Aucune carte ni scène n’utilise ce dresseur : il ne combattra pas en jeu. Pour le placer : Carte → sélectionner un personnage → Combat de dresseur, ou un bloc Combat dans une scène.'
                  : unique
                  ? 'Aucune scène n’utilise cette rencontre : elle ne se déclenchera pas en jeu. Pour l’utiliser : Histoire → scène → bloc Combat.'
                  : 'Aucune carte ni scène n’utilise cette table : elle ne se déclenchera pas en jeu. Pour l’affecter : Carte → outil Zones de jeu → zone de rencontre → choisir « ${table!.name} ».',
            ),
          ],
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
