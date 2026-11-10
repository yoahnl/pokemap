import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'map_catalogue_creation_dialog.dart';
import 'map_catalogue_form_dialog.dart';
import 'map_escape_rope_settings.dart';

ValueChanged<String> mapLibraryOpenAction(
  ProjectManifest project,
  ValueChanged<ProjectMapEntry> activate,
  VoidCallback? close,
) => (id) {
  final entry = project.maps.where((entry) => entry.id == id).firstOrNull;
  if (entry == null) return;
  close?.call();
  activate(entry);
};

VoidCallback? mapCatalogueRenameAction(
  BuildContext context,
  MapWorkspaceController controller,
) {
  final id = controller.active?.base.mapId;
  final entry = controller.project?.maps
      .where((entry) => entry.id == id)
      .firstOrNull;
  return entry == null || controller.catalogPort == null
      ? null
      : () => renameWorkspaceMap(context, controller, entry);
}

VoidCallback? mapCatalogueEscapeRopeAction(
  BuildContext context,
  MapWorkspaceController controller, {
  Future<Map<String, String>> Function()? loadItems,
}) {
  final document = controller.active;
  final project = controller.project;
  if (document == null || project == null || controller.catalogPort == null) {
    return null;
  }
  return () => _withCatalogueDialog(
    controller,
    () => showEscapeRopeMapSettings(
      context,
      map: document.current,
      project: project,
      loadItems: loadItems,
      save: (values) => saveWorkspaceMapMetadata(
        controller: controller,
        document: document,
        values: values,
      ),
    ),
  );
}

Future<void> createWorkspaceMap(
  BuildContext context,
  MapWorkspaceController controller, {
  String? groupId,
}) => _withCatalogueDialog(
  controller,
  () => _createWorkspaceMap(context, controller, groupId: groupId),
);

final _openCatalogueDialogs = Expando<bool>();
Future<void> _withCatalogueDialog(
  MapWorkspaceController controller,
  Future<void> Function() open,
) async {
  if (_openCatalogueDialogs[controller] == true) return;
  _openCatalogueDialogs[controller] = true;
  try {
    await open();
  } finally {
    _openCatalogueDialogs[controller] = false;
  }
}

Future<void> _createWorkspaceMap(
  BuildContext context,
  MapWorkspaceController controller, {
  String? groupId,
}) async {
  final project = controller.project;
  if (project == null || controller.catalogBusy || controller.isDisposed) {
    return;
  }
  final operation = WorkspaceMapCreation(controller, groupId: groupId);
  await showNewMapDialog(
    context,
    project: project,
    initialGroupId: groupId,
    submitLabel: () => operation.published ? 'Réouvrir' : 'Créer la carte',
    onCreate:
        ({
          required name,
          required width,
          required height,
          required role,
          groupId,
          tilesetId,
        }) async {
          operation
            ..name = name
            ..width = '$width'
            ..height = '$height'
            ..role = role
            ..groupId = groupId
            ..tilesetId = tilesetId;
          return operation.submit();
        },
  );
}

Future<void> renameWorkspaceMap(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry,
) => _withCatalogueDialog(
  controller,
  () => _renameWorkspaceMap(context, controller, entry),
);

Future<void> _renameWorkspaceMap(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry,
) async {
  if (controller.catalogBusy || controller.isDisposed) return;
  final document = controller.documents[entry.id];
  if (document?.dirty == true) {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer cette carte avant de la renommer ?'),
        content: Text(
          '« ${entry.name} » contient des modifications. Seule cette carte sera enregistrée.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Enregistrer cette carte puis renommer',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (accepted != true ||
        !context.mounted ||
        !await controller.save(document!)) {
      return;
    }
  }
  if (!context.mounted || controller.isDisposed) return;
  final operation = WorkspaceMapRename(controller, entry);
  await showMapCatalogueForm(
    context,
    title: 'Renommer la carte',
    submitLabel: 'Enregistrer',
    currentSubmitLabel: () =>
        operation.published ? 'Relire le catalogue' : 'Enregistrer',
    valid: () => operation.name.trim().isNotEmpty,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioDraftField(
          key: const ValueKey('rename-map-name'),
          value: operation.name,
          label: 'Nom de la carte',
          enabled: !busy,
          onChanged: (value) {
            operation.name = value;
            refresh();
          },
        ),
        const SizedBox(height: 8),
        Text(
          mapRenameIdentityNote(entry),
          key: const ValueKey('rename-map-identity'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
    submit: operation.submit,
  );
}

String mapRenameIdentityNote(ProjectMapEntry entry) =>
    'Seul le nom affiché change. L’identité de la carte, « ${entry.id} », reste la même : ses passages, connexions et sauvegardes restent valables.';
