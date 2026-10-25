import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_time_window.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_ui_parts.dart';
import 'pokemon_combat_detail_header.dart';
import 'pokemon_combat_reference_list.dart';
import 'pokemon_combat_species_picker.dart';
part 'pokemon_combat_table_entry.dart';
part 'pokemon_combat_table_variants.dart';
part 'pokemon_combat_variant_conditions.dart';
part 'pokemon_combat_variant_time_windows.dart';

class PokemonCombatTableDetail extends StatelessWidget {
  const PokemonCombatTableDetail({
    super.key,
    required this.combat,
    required this.index,
    required this.onDelete,
    this.onOpenReference,
    this.onBack,
  });

  final PokemonCombatController combat;
  final PokemonWorkspaceIndex index;
  final VoidCallback? onDelete;
  final Future<void> Function(String kind, String id)? onOpenReference;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final draft = combat.table;
    if (draft == null) {
      return const PokemonEmptyState(
        title: 'Sélectionnez une rencontre',
        description:
            'Choisissez une table ou créez-en une pour préparer le combat.',
      );
    }
    final table = draft.current;
    final unique = table.tags.contains('studio:unique');
    final fishing = {
      EncounterKind.oldRod,
      EncounterKind.goodRod,
      EncounterKind.superRod,
    }.contains(table.encounterKind);
    final species = {
      for (final entry in index.entries)
        if (entry.enabled) entry.id: entry.name,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokemonCombatDetailHeader(
          title: unique ? 'Rencontre unique' : 'Table de rencontres',
          id: table.id,
          dirty: draft.dirty,
          created: draft.created,
          saving: combat.saving,
          onSave: () => combat.save(index),
          onDiscard: combat.discard,
          onDelete: onDelete,
          onBack: onBack,
        ),
        if (combat.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              combat.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StudioDraftField(
                key: ValueKey('${table.id}:name'),
                label: unique ? 'Nom de la rencontre' : 'Nom de la table',
                value: table.name,
                onChanged: (value) => combat.editTable(
                  (current) => current.copyWith(name: value),
                ),
              ),
              const SizedBox(height: 12),
              if (!unique) ...[
                StudioSelect(
                  label: 'Déclenchement',
                  value: table.encounterKind.name,
                  options: {
                    for (final kind in EncounterKind.values)
                      kind.name: switch (kind) {
                        EncounterKind.walk => 'Marche',
                        EncounterKind.surf => 'Surf',
                        EncounterKind.oldRod => 'Canne',
                        EncounterKind.goodRod => 'Super Canne',
                        EncounterKind.superRod => 'Méga Canne',
                        EncounterKind.headbutt => 'Coup d’Boule',
                        EncounterKind.gift => 'Cadeau',
                        EncounterKind.special => 'Spéciale',
                      },
                  },
                  onChanged: (value) => combat.editTable(
                    (current) => current.copyWith(
                      encounterKind: EncounterKind.values.singleWhere(
                        (kind) => kind.name == value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StudioDraftField(
                  key: ValueKey('${table.id}:chance'),
                  label:
                      (fishing ||
                          table.encounterKind == EncounterKind.headbutt ||
                          table.encounterKind == EncounterKind.special)
                      ? 'Probabilité par tentative (0 à 100 %)'
                      : 'Probabilité par pas (0 à 100 %)',
                  value: combat.numericValue(
                    'chance',
                    (table.chancePerStep * 100).round(),
                  ),
                  onChanged: (raw) => combat.editNumber('chance', raw, (value) {
                    combat.editTable(
                      (current) => current.copyWith(chancePerStep: value / 100),
                    );
                  }),
                ),
                if (table.encounterKind == EncounterKind.headbutt ||
                    table.encounterKind == EncounterKind.special) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Associez cette table à un objet dans son inspecteur : Coud’Boule sur un arbre ou rencontre après Éclate-Roc sur un rocher. Un seul tirage par tentative.',
                  ),
                ],
                if (fishing) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Associez cette table à une zone d’eau. La canne correspondante utilise la case devant le joueur et un seul tirage par tentative.',
                  ),
                ],
              ] else
                const Text(
                  'Combat sauvage fixe lancé par une scène. Liez-la à un événement à usage unique dans Histoire : la victoire ou la capture consomme la rencontre ; la défaite et la fuite permettent une nouvelle tentative.',
                ),
              const SizedBox(height: 20),
              Text(
                unique ? 'Pokémon rencontré' : 'Rencontres par défaut',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!unique) ...[
                const SizedBox(height: 6),
                const Text(
                  'Cette liste est utilisée si aucune variante ne correspond. Sans liste par défaut, aucune rencontre ne se produit dans ce cas.',
                ),
              ],
              const SizedBox(height: 10),
              for (var i = 0; i < table.entries.length; i++) ...[
                _buildCombatTableEntry(
                  combat,
                  context,
                  table,
                  i,
                  species,
                  unique,
                ),
                const SizedBox(height: 12),
              ],
              if (!unique || table.entries.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: StudioButton(
                    label: 'Ajouter une espèce',
                    secondary: true,
                    icon: Icons.add,
                    onPressed: species.isEmpty
                        ? null
                        : () async {
                            final chosen = await chooseCombatSpecies(
                              context,
                              index,
                            );
                            if (chosen == null) return;
                            combat.editTable(
                              (current) => current.copyWith(
                                entries: [
                                  ...current.entries,
                                  ProjectEncounterEntry(
                                    speciesId: chosen,
                                    minLevel: 5,
                                    maxLevel: 5,
                                  ),
                                ],
                              ),
                            );
                          },
                  ),
                ),
              if (!unique) ...[
                const SizedBox(height: 24),
                _buildCombatTableVariants(
                  context,
                  combat,
                  index,
                  table,
                  species,
                ),
              ],
              if (onBack != null) ...[
                const SizedBox(height: 18),
                Text(
                  'Utilisations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                PokemonCombatReferenceList(
                  snapshot: combat.snapshot!,
                  tableId: table.id,
                  onOpenReference: onOpenReference,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
