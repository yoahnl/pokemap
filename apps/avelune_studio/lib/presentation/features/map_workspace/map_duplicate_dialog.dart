import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_catalog_preparation.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_catalogue_form_dialog.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';

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
  final operation = preparation == null
      ? null
      : WorkspaceMapDuplicate(controller, preparation);
  await showMapCatalogueForm(
    context,
    title: 'Dupliquer la carte',
    submitLabel: 'Dupliquer la carte',
    currentSubmitLabel: () => operation?.published == true
        ? 'Réouvrir la copie'
        : 'Dupliquer la carte',
    valid: () =>
        operation?.published == true ||
        (preparation?.canApply == true && name.trim().isNotEmpty),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Source : ${source.name}'),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('duplicate-map-name'),
          value: name,
          label: 'Nom de la copie',
          enabled: !busy && operation?.published != true,
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
          onChanged: busy || operation?.published == true
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
    submit: () =>
        operation!.submit(name: name, groupId: group.isEmpty ? null : group),
  );
}
