import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_ui_parts.dart';

class PokemonMovesSyncPanel extends StatelessWidget {
  const PokemonMovesSyncPanel({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final catalog = controller.index!.moves;
    final preview = controller.movesPreview;
    return PokemonSurface(
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PokemonSectionHeading(
            title: 'Catalogue des attaques',
            description:
                catalog.problem ??
                '${catalog.entries.length} attaque(s) locales. '
                    'La recherche externe démarre uniquement sur demande.',
          ),
          if (controller.hasPendingChanges)
            const Text(
              'Enregistrez ou annulez la fiche ouverte avant la synchronisation.',
            ),
          if (preview == null)
            StudioButton(
              label: 'Prévisualiser la synchronisation',
              icon: Icons.sync,
              loading: controller.syncing,
              onPressed:
                  controller.operationActive || controller.hasPendingChanges
                  ? null
                  : controller.previewMovesSync,
            )
          else ...[
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                PokemonPill(label: '${preview.createdIds.length} créations'),
                PokemonPill(label: '${preview.updatedIds.length} mises à jour'),
                PokemonPill(label: '${preview.unchangedIds.length} inchangées'),
                PokemonPill(
                  label:
                      '${preview.preservedLocalOnlyIds.length} locales conservées',
                  success: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioButton(
                  label: 'Fermer l’aperçu',
                  secondary: true,
                  onPressed: controller.syncing
                      ? null
                      : controller.clearMovesPreview,
                ),
                StudioButton(
                  label: 'Appliquer la synchronisation',
                  loading: controller.syncing,
                  onPressed: controller.syncing || controller.hasPendingChanges
                      ? null
                      : controller.applyMovesSync,
                ),
              ],
            ),
          ],
          if (preview != null)
            for (final (label, ids) in [
              ('Créées', preview.createdIds),
              ('Mises à jour', preview.updatedIds),
              ('Inchangées', preview.unchangedIds),
              ('Locales conservées', preview.preservedLocalOnlyIds),
            ])
              if (ids.isNotEmpty)
                ExpansionTile(
                  title: Text('$label · ${ids.length}'),
                  children: [
                    for (final id in ids)
                      ListTile(dense: true, title: Text(id)),
                  ],
                ),
          for (final diagnostic in catalog.diagnostics)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(diagnostic),
            ),
        ],
      ),
    );
  }
}
