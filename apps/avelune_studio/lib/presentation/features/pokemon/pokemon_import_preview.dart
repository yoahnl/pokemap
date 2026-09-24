import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_import_document_row.dart';
import 'pokemon_ui_parts.dart';

class PokemonImportPreviewPanel extends StatelessWidget {
  const PokemonImportPreviewPanel({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.importPreview!;
    final newCount = preview.items.where((item) => !item.conflicts).length;
    final conflicts = preview.items.length - newCount;
    final species = preview.items
        .where((item) => item.family == PokemonDocumentFamily.species)
        .firstOrNull
        ?.document;
    final dex = species?['nationalDex'];
    final types =
        (species?['types'] as List?)?.whereType<String>() ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: PokemonSectionHeading(
            title: 'Aperçu de l’import · ${preview.name}',
            description:
                'Vérifiez les documents avant application. Aucun fichier '
                'du projet n’est écrit pendant cette préparation.',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PokemonSurface(
                    emphasized: true,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.pets_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preview.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (dex != null) '#$dex',
                                preview.speciesId,
                                ...types,
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        PokemonPill(
                          label: conflicts == 0
                              ? 'Nouveau contenu'
                              : '$conflicts conflit(s)',
                          success: conflicts == 0,
                          warning: conflicts > 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PokemonPill(
                        label: '${preview.items.length} document(s) retenu(s)',
                      ),
                      PokemonPill(label: '$newCount nouveau(x)', success: true),
                      if (conflicts > 0)
                        PokemonPill(
                          label: '$conflicts à confirmer',
                          warning: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const PokemonSectionHeading(
                    title: 'Documents à appliquer',
                    description:
                        'Les chemins exacts sont disponibles dans le détail '
                        'de chaque document.',
                  ),
                  for (final item in preview.items)
                    PokemonImportDocumentRow(
                      family: item.family,
                      relativePath: item.relativePath,
                      conflict: item.conflicts,
                    ),
                  if (conflicts > 0) ...[
                    const SizedBox(height: 6),
                    PokemonSurface(
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'Le remplacement exige une confirmation et '
                              'un nouveau contrôle de révision.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              StudioButton(
                label: 'Annuler',
                secondary: true,
                onPressed: controller.importing ? null : controller.clearImport,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: StudioButton(
                  label: 'Importer ${preview.speciesId}',
                  loading: controller.importing,
                  onPressed: controller.importing
                      ? null
                      : () => _apply(context),
                ),
              ),
            ],
          ),
        ),
      ],
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
                'Les conflits affichés dans l’aperçu seront remplacés après '
                'un nouveau contrôle de révision.',
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
