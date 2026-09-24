import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_external_import_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_import_document_row.dart';
import 'pokemon_ui_parts.dart';

class PokemonExternalPreviewPane extends StatelessWidget {
  const PokemonExternalPreviewPane({
    super.key,
    required this.preview,
    required this.policy,
    required this.busy,
    required this.onPolicyChanged,
    required this.onBack,
    required this.onApply,
  });

  final PokemonExternalImportPreview preview;
  final PokemonExternalConflictPolicy policy;
  final bool busy;
  final ValueChanged<PokemonExternalConflictPolicy> onPolicyChanged;
  final VoidCallback? onBack;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final conflicts = preview.documents.where((item) => item.conflict).length;
    final plan = preview.plan(policy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StudioButton(
                label: 'Retour à la recherche',
                icon: Icons.arrow_back,
                secondary: true,
                onPressed: busy ? null : onBack,
              ),
              Text(
                'Aperçu · ${preview.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
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
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_download_outlined,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preview.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              preview.speciesId,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        PokemonPill(
                          label: '${preview.documents.length} document(s)',
                        ),
                        if (conflicts > 0)
                          PokemonPill(
                            label: '$conflicts conflit(s)',
                            warning: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, bounds) {
                      final documents = PokemonSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PokemonSectionHeading(
                              title: 'Documents préparés',
                              description:
                                  'Le contenu métier est prêt, mais aucun '
                                  'fichier du projet n’a encore été écrit.',
                            ),
                            for (final item in preview.documents)
                              PokemonImportDocumentRow(
                                family: item.family,
                                relativePath: item.relativePath,
                                conflict: item.conflict,
                              ),
                          ],
                        ),
                      );
                      final decisions = _decisions(
                        context,
                        created: plan.created,
                        conflicts: conflicts,
                        overwritten: plan.overwritten,
                        kept: plan.kept,
                        excluded: plan.excluded.length,
                      );
                      if (bounds.maxWidth < 800) {
                        return Column(
                          children: [
                            documents,
                            const SizedBox(height: 12),
                            decisions,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 60, child: documents),
                          const SizedBox(width: 12),
                          Expanded(flex: 40, child: decisions),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: StudioButton(
              label: plan.selected.isEmpty
                  ? 'Terminer sans importer'
                  : 'Appliquer l’import',
              icon: Icons.file_download_outlined,
              loading: busy,
              onPressed: onApply,
            ),
          ),
        ),
      ],
    );
  }

  Widget _decisions(
    BuildContext context, {
    required int created,
    required int conflicts,
    required int overwritten,
    required int kept,
    required int excluded,
  }) {
    return Column(
      children: [
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokemonSectionHeading(title: 'Résumé selon votre choix'),
              PokemonDataRow(label: 'Nouveaux', value: '$created'),
              PokemonDataRow(label: 'À remplacer', value: '$overwritten'),
              PokemonDataRow(label: 'À conserver', value: '$kept'),
              if (excluded > 0)
                PokemonDataRow(
                  label: 'Sans rattachement enregistré',
                  value: '$excluded exclu(s)',
                ),
              if (conflicts > 0) ...[
                const SizedBox(height: 10),
                StudioSelect(
                  label: 'Gestion des conflits',
                  value: policy.name,
                  options: const {
                    'failOnConflict': 'Refuser les conflits',
                    'skipExisting': 'Garder les fichiers existants',
                    'overwriteExisting': 'Remplacer après confirmation',
                  },
                  onChanged: (value) => onPolicyChanged(
                    PokemonExternalConflictPolicy.values.byName(value),
                  ),
                ),
                if (policy == PokemonExternalConflictPolicy.failOnConflict)
                  const Text(
                    'L’application reste bloquée tant que les conflits '
                    'ne sont pas traités.',
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
              const PokemonSectionHeading(title: 'À savoir'),
              const Text(
                'La préparation distante fournit les documents Pokémon. '
                'Elle ne télécharge pas les images ni les cris. '
                'Après import, associez les PNG disponibles dans Médias.',
              ),
              for (final warning in preview.warnings)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(warning),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
