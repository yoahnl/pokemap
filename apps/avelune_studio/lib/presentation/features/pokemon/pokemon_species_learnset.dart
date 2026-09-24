import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesLearnsetEditor extends StatelessWidget {
  const PokemonSpeciesLearnsetEditor({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final json = controller.selectedDraft?.document(
      PokemonDocumentFamily.learnset,
    );
    if (json == null) {
      return const PokemonSurface(
        child: Text('Aucun document d’apprentissage associé à cette espèce.'),
      );
    }
    const groups = {
      'startingMoves': 'Attaques de départ',
      'relearnMoves': 'Réapprentissage',
      'levelUp': 'Montée de niveau',
      'tm': 'CT',
      'hm': 'CS',
      'tutor': 'Tutorat',
      'egg': 'Reproduction',
      'event': 'Événement',
      'transfer': 'Transfert',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokemonSectionHeading(
          title: 'Apprentissages',
          description:
              'Choisissez les attaques dans le catalogue du projet. Les références non résolues restent visibles.',
        ),
        for (final group in groups.entries) ...[
          _LearnsetGroup(
            controller: controller,
            key: PageStorageKey('pokemon-learnset-${group.key}'),
            group: group.key,
            label: group.value,
            entries: json[group.key] as List? ?? const [],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LearnsetGroup extends StatelessWidget {
  const _LearnsetGroup({
    super.key,
    required this.controller,
    required this.group,
    required this.label,
    required this.entries,
  });

  final PokemonWorkspaceController controller;
  final String group;
  final String label;
  final List entries;

  @override
  Widget build(BuildContext context) => PokemonSurface(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      initiallyExpanded: group == 'startingMoves' || group == 'levelUp',
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('${entries.length} attaque(s)'),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entries.isEmpty
                    ? 'Aucune attaque renseignée.'
                    : 'Sélectionnez une ligne pour consulter ses détails.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            StudioButton(
              label: 'Ajouter une attaque',
              icon: Icons.add,
              secondary: true,
              onPressed: controller.index?.moves.available == true
                  ? () => controller.beginMoveSelection(group)
                  : null,
            ),
          ],
        ),
        if (controller.index?.moves.available != true)
          Text(controller.index?.moves.problem ?? 'Catalogue indisponible.'),
        for (var i = 0; i < entries.length; i++)
          _LearnsetEntry(
            controller: controller,
            group: group,
            index: i,
            value: entries[i],
          ),
      ],
    ),
  );
}

class _LearnsetEntry extends StatelessWidget {
  const _LearnsetEntry({
    required this.controller,
    required this.group,
    required this.index,
    required this.value,
  });

  final PokemonWorkspaceController controller;
  final String group;
  final int index;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final data = value is Map ? (value as Map).cast<String, dynamic>() : null;
    final id = value is String ? value as String : '${data?['moveId'] ?? ''}';
    final known = controller.index?.moves.entries
        .where((entry) => entry.id == id)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: PokemonSurface(
        emphasized: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ExpansionTile(
          key: PageStorageKey('pokemon-learnset-$group-$index'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 9),
          title: Text(known?.name ?? 'Référence non résolue : $id'),
          subtitle: Text(
            [
              if (group == 'levelUp') 'Niveau ${data?['level'] ?? '—'}',
              if (known?.type != null) pokemonTypeLabel(known!.type!),
              id,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Row(
              children: [
                StudioButton(
                  label: 'Changer l’attaque',
                  secondary: true,
                  icon: Icons.swap_horiz,
                  onPressed: controller.index?.moves.available == true
                      ? () => controller.beginMoveSelection(
                          group,
                          replaceIndex: index,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Retirer cette attaque',
                  onPressed: () => controller.removeLearnsetMove(group, index),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (known != null) ...[
              PokemonDataRow(
                label: 'Catégorie',
                value: known.category ?? 'Non renseignée',
              ),
              PokemonDataRow(
                label: 'Puissance',
                value: known.power?.toString() ?? 'Non renseignée',
              ),
              PokemonDataRow(
                label: 'PP',
                value: known.pp?.toString() ?? 'Non renseignés',
              ),
            ],
            if (data != null) ...[
              if (group == 'levelUp') ...[
                StudioDraftField(
                  key: ValueKey('$group-$index-level'),
                  label: 'Niveau',
                  value: '${data['level'] ?? ''}',
                  onChanged: (value) => controller.editLearnsetField(
                    group,
                    index,
                    'level',
                    value,
                  ),
                ),
                StudioDraftField(
                  key: ValueKey('$group-$index-source'),
                  label: 'Source',
                  value: '${data['source'] ?? ''}',
                  onChanged: (value) => controller.editLearnsetField(
                    group,
                    index,
                    'source',
                    value,
                  ),
                ),
              ],
              StudioDraftField(
                key: ValueKey('$group-$index-versionGroup'),
                label: 'Groupe de version',
                value: '${data['versionGroup'] ?? ''}',
                onChanged: (value) => controller.editLearnsetField(
                  group,
                  index,
                  'versionGroup',
                  value,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
