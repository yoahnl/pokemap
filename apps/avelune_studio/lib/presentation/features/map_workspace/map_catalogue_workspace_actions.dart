import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'map_catalogue_creation_dialog.dart';
import 'map_catalogue_form_dialog.dart';

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
  final id = 'studio_map_${DateTime.now().microsecondsSinceEpoch}';
  bool published = false;
  await showNewMapDialog(
    context,
    project: project,
    initialGroupId: groupId,
    submitLabel: () => published ? 'Réouvrir' : 'Créer la carte',
    onCreate:
        ({
          required name,
          required width,
          required height,
          required role,
          groupId,
          tilesetId,
        }) async {
          if (controller.isDisposed) return 'Le projet a été fermé.';
          if (!published) {
            final result = await controller.mutateCatalog('map.create', {
              'mapId': id,
              'name': name,
              'width': width,
              'height': height,
              'role': role.name,
              'groupId': ?groupId,
              'tilesetId': ?tilesetId,
            });
            published = result.published || result.integrated;
            if (!result.integrated) {
              return published
                  ? 'La carte est créée sur disque. ${result.error ?? ''} Réouvrez-la pour reprendre la relecture.'
                  : result.error ?? 'La création a été refusée.';
            }
          } else if (controller.pendingCatalogReceipt != null) {
            final result = await controller.retryCatalogRefresh();
            if (!result.integrated) {
              return 'La carte est créée. ${result.error ?? 'Relecture impossible.'}';
            }
          }
          if (controller.isDisposed) {
            return 'La carte est créée, mais le projet a été fermé.';
          }
          final entry = controller.project?.maps
              .where((entry) => entry.id == id)
              .firstOrNull;
          if (entry == null) {
            return 'La carte est créée ; relisez le catalogue avant de la rouvrir.';
          }
          await controller.activate(entry);
          return controller.active?.base.mapId == id
              ? null
              : 'La carte est créée. ${controller.error ?? 'Ouverture impossible.'} Utilisez Réouvrir.';
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
  var name = entry.name, published = false;
  await showMapCatalogueForm(
    context,
    title: 'Renommer la carte',
    submitLabel: 'Enregistrer',
    currentSubmitLabel: () => published ? 'Relire le catalogue' : 'Enregistrer',
    valid: () => name.trim().isNotEmpty,
    fields: (refresh, busy) => StudioDraftField(
      key: const ValueKey('rename-map-name'),
      value: name,
      label: 'Nom de la carte',
      enabled: !busy,
      onChanged: (value) {
        name = value;
        refresh();
      },
    ),
    submit: () async {
      final result = published
          ? await controller.retryCatalogRefresh()
          : await controller.mutateCatalog('map.update_metadata', {
              'mapId': entry.id,
              'name': name.trim(),
            });
      published = result.published;
      return result.integrated
          ? null
          : result.published
          ? 'Le titre est enregistré sur disque. ${result.error ?? ''} Relisez le catalogue.'
          : result.error ?? 'Le renommage a été refusé.';
    },
  );
}
