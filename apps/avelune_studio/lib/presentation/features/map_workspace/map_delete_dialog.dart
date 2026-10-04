import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_catalog_preparation.dart';
import 'map_catalogue_form_dialog.dart';
import 'map_lifecycle_issues.dart';

Future<void> showDeleteMapDialog(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry,
) async {
  MapCatalogPreparation? preparation;
  String? analysisError;
  try {
    preparation = await controller.prepareCatalog('map.delete_apply', {
      'mapId': entry.id,
    });
  } on Object catch (error) {
    analysisError = '$error';
  }
  if (!context.mounted || controller.isDisposed) return;
  var published = false;
  await showMapCatalogueForm(
    context,
    title: 'Supprimer la carte',
    cancelLabel: 'Fermer',
    submitLabel: 'Supprimer définitivement',
    currentSubmitLabel: () =>
        published ? 'Relire le catalogue' : 'Supprimer définitivement',
    valid: () => published || preparation?.canApply == true,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
        Text('Identité : ${entry.id}'),
        Text(
          'Dossier : ${controller.project?.groups.where((group) => group.id == entry.groupId).firstOrNull?.name ?? 'Sans dossier'}',
        ),
        const SizedBox(height: 16),
        const Text(
          'Cette confirmation retire uniquement la carte et son entrée '
          'dans le projet. Les ressources partagées et les sauvegardes du joueur '
          'ne seront pas supprimées. Cette opération ne peut pas être annulée '
          'depuis l’historique de la carte.',
        ),
        const SizedBox(height: 16),
        if (analysisError != null) Text('Analyse impossible : $analysisError'),
        if (preparation?.canApply == true)
          const Text(
            'Aucune référence entrante bloquante trouvée dans l’inventaire analysé.',
          ),
        if (preparation != null)
          Text(
            'Contenu retiré : ${preparation.sourceMap.placedElements.length} décors · '
            '${preparation.sourceMap.warps.length} passages sortants',
          ),
        if (preparation != null)
          MapLifecycleIssues(
            issues: preparation.issues,
            controller: controller,
          ),
      ],
    ),
    submit: () async {
      final result = published
          ? await controller.retryCatalogRefresh()
          : await controller.applyPreparedCatalog(
              preparation!,
              confirmDestructive: true,
            );
      published = result.published;
      return result.integrated
          ? null
          : published
          ? 'La carte a été retirée sur disque. ${result.error ?? ''} Relisez le catalogue.'
          : result.error ?? 'La suppression a été refusée.';
    },
  );
}
