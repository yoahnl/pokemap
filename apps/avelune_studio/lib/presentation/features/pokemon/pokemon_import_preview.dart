import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonImportPreviewPanel extends StatelessWidget {
  const PokemonImportPreviewPanel({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.importPreview!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: StudioPanel(
        title: 'Aperçu de l’import · ${preview.name}',
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: controller.importing ? null : controller.clearImport,
          ),
          StudioButton(
            label: 'Importer ${preview.speciesId}',
            loading: controller.importing,
            onPressed: controller.importing ? null : () => _apply(context),
          ),
        ],
        children: [
          Text(
            '${preview.items.length} document(s) retenu(s) · aucun fichier écrit pendant l’aperçu.',
          ),
          for (final item in preview.items)
            Text(
              '${item.family.name} → ${item.relativePath}'
              '${item.conflicts ? ' · Remplacement requis' : ' · Nouveau'}',
            ),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context) async {
    final preview = controller.importPreview!;
    var confirmed = false;
    if (preview.hasConflicts) {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Remplacer les documents existants ?'),
              content: const Text(
                'Les conflits affichés dans l’aperçu seront remplacés après un nouveau contrôle de révision.',
              ),
              actions: [
                StudioButton(
                  label: 'Annuler',
                  secondary: true,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                StudioButton(
                  label: 'Confirmer le remplacement',
                  onPressed: () => Navigator.pop(dialogContext, true),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }
    await controller.applyJsonImport(confirmOverwrite: confirmed);
  }
}
