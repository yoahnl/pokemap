import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_catalog_preparation.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_catalogue_form_dialog.dart';
import 'map_library_tree.dart';

Future<void> showDuplicateMapDialog(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry source,
) async {
  final project = controller.project!;
  var name = '${source.name} — copie', group = source.groupId ?? '';
  MapCatalogPreparation? preparation;
  String? analysisError;
  try {
    preparation = await controller.prepareCatalog('map.duplicate', {
      'sourceMapId': source.id,
      'name': name,
      'groupId': source.groupId,
    });
  } on Object catch (error) {
    analysisError = '$error';
  }
  if (!context.mounted || controller.isDisposed) return;
  var published = false;
  String? createdId;
  await showMapCatalogueForm(
    context,
    title: 'Dupliquer la carte',
    submitLabel: 'Dupliquer la carte',
    currentSubmitLabel: () =>
        published ? 'Réouvrir la copie' : 'Dupliquer la carte',
    valid: () =>
        published || (preparation?.canApply == true && name.trim().isNotEmpty),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Source : ${source.name}'),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('duplicate-map-name'),
          value: name,
          label: 'Nom de la copie',
          enabled: !busy && !published,
          onChanged: (value) {
            name = value;
            refresh();
          },
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Dossier de destination',
          value: group,
          options: mapLibraryFolderLabels(project.groups),
          onChanged: busy || published
              ? null
              : (value) {
                  group = value;
                  refresh();
                },
        ),
        const SizedBox(height: 16),
        const Text(
          'La version enregistrée sera copiée, avec une nouvelle identité. '
          'Les ressources partagées restent communes. Les passages conservent '
          'leurs destinations, y compris ceux qui reviennent vers la source. '
          'Les accès venant des autres cartes ne changent pas.',
        ),
        if (preparation != null)
          Text(
            '${preparation.sourceMap.warps.length} passages · '
            '${preparation.sourceMap.placedElements.length} décors',
          ),
        if (analysisError != null) Text(analysisError),
        for (final issue in preparation?.issues ?? const <MapCatalogIssue>[])
          Text(issue.message),
      ],
    ),
    submit: () async {
      if (!published) {
        final result = await controller.applyPreparedCatalog(
          preparation!.withDuplicateDestination(
            name: name.trim(),
            groupId: group.isEmpty ? null : group,
          ),
        );
        published = result.published;
        createdId = result.receipt?.createdMapId;
        if (!result.integrated) {
          return published
              ? 'La copie est créée sur disque. ${result.error ?? ''} Réouvrez cette copie.'
              : result.error ?? 'La duplication a été refusée.';
        }
      } else if (controller.pendingCatalogReceipt != null) {
        final result = await controller.retryCatalogRefresh();
        if (!result.integrated) return 'La copie existe. ${result.error ?? ''}';
      }
      if (controller.isDisposed) {
        return 'La copie existe ; le projet a été fermé.';
      }
      final copy = controller.project?.maps
          .where((entry) => entry.id == createdId)
          .firstOrNull;
      if (copy == null) {
        return 'La copie existe ; relisez le catalogue pour la retrouver.';
      }
      await controller.activate(copy);
      return controller.active?.base.mapId == copy.id
          ? null
          : 'La copie existe. ${controller.error ?? 'Ouverture impossible.'} Réouvrez-la.';
    },
  );
}
