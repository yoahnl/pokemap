import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonSpeciesLearnsetEditor extends StatelessWidget {
  const PokemonSpeciesLearnsetEditor({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final json = controller.selectedDraft?.document(
      PokemonDocumentFamily.learnset,
    );
    if (json == null) {
      return const StudioPanel(
        children: [
          Text('Aucun document d’apprentissage associé à cette espèce.'),
        ],
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
      children: [
        for (final group in groups.entries) ...[
          StudioPanel(
            title: group.value,
            actions: [
              StudioButton(
                label: 'Ajouter une attaque',
                icon: Icons.add,
                secondary: true,
                onPressed: controller.index?.moves.available == true
                    ? () => controller.beginMoveSelection(group.key)
                    : null,
              ),
            ],
            children: [
              if ((json[group.key] as List?)?.isNotEmpty != true)
                const Text('Aucune attaque renseignée.'),
              for (
                var index = 0;
                index < (json[group.key] as List? ?? const []).length;
                index++
              )
                _LearnsetEntry(
                  controller: controller,
                  group: group.key,
                  index: index,
                  value: (json[group.key] as List)[index],
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(known?.name ?? 'Référence non résolue : $id'),
            subtitle: Text(id),
            trailing: Wrap(
              spacing: 2,
              children: [
                IconButton(
                  tooltip: 'Changer l’attaque',
                  onPressed: controller.index?.moves.available == true
                      ? () => controller.beginMoveSelection(
                          group,
                          replaceIndex: index,
                        )
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                ),
                IconButton(
                  tooltip: 'Retirer cette attaque',
                  onPressed: () => controller.removeLearnsetMove(group, index),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (data != null) ...[
            if (group == 'levelUp') ...[
              StudioDraftField(
                key: ValueKey('$group-$index-level'),
                label: 'Niveau',
                value: '${data['level'] ?? ''}',
                onChanged: (value) =>
                    controller.editLearnsetField(group, index, 'level', value),
              ),
              StudioDraftField(
                key: ValueKey('$group-$index-source'),
                label: 'Source',
                value: '${data['source'] ?? ''}',
                onChanged: (value) =>
                    controller.editLearnsetField(group, index, 'source', value),
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
    );
  }
}
