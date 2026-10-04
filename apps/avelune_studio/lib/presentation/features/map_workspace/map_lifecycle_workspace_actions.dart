import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'map_library_row_actions.dart';
import 'map_duplicate_dialog.dart';
import 'map_resize_dialog.dart';
import 'map_delete_dialog.dart';
import 'map_workspace_visuals.dart';

final _lifecycleDialogs = Expando<bool>();

Future<void> manageWorkspaceMap(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry,
  MapLibraryAction action, {
  MapWorkspaceVisuals? visuals,
}) async {
  if (_lifecycleDialogs[controller] == true ||
      controller.catalogBusy ||
      controller.isDisposed) {
    return;
  }
  _lifecycleDialogs[controller] = true;
  final project = controller.project;
  try {
    if (!await _saveTarget(context, controller, entry, action) ||
        !context.mounted ||
        controller.isDisposed ||
        controller.project != project) {
      return;
    }
    switch (action) {
      case MapLibraryAction.duplicate:
        await showDuplicateMapDialog(context, controller, entry);
      case MapLibraryAction.resize:
        await showResizeMapDialog(context, controller, entry, visuals: visuals);
      case MapLibraryAction.deleteMap:
        await showDeleteMapDialog(context, controller, entry);
      default:
        break;
    }
  } finally {
    _lifecycleDialogs[controller] = false;
  }
}

Future<bool> _saveTarget(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry,
  MapLibraryAction action,
) async {
  final document = controller.documents[entry.id];
  if (document?.dirty != true) return document?.saving != true;
  final label = action == MapLibraryAction.duplicate
      ? 'Enregistrer et dupliquer'
      : 'Enregistrer puis poursuivre l’analyse';
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cette carte contient un brouillon'),
      content: Text(
        '« ${entry.name} » doit être enregistrée avant cette opération. '
        'Les autres documents ne seront pas enregistrés.',
      ),
      actions: [
        StudioButton(
          label: 'Annuler',
          secondary: true,
          onPressed: () => Navigator.pop(context, false),
        ),
        StudioButton(
          label: label,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted || controller.isDisposed) {
    return false;
  }
  return controller.save(document!);
}
