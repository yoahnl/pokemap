import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'map_library_row_actions.dart';
import 'map_duplicate_dialog.dart';
import 'map_resize_dialog.dart';
import 'map_delete_dialog.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

Future<void> manageWorkspaceMap(
  BuildContext context,
  MapWorkspaceController controller,
  ProjectMapEntry entry,
  MapLibraryAction action, {
  MapWorkspaceVisuals? visuals,
}) async {
  await runMapLifecycleOperation(
    controller: controller,
    entry: entry,
    isActive: () => context.mounted,
    confirmSave: () => _confirmTargetSave(context, entry, action),
    operation: () async {
      switch (action) {
        case MapLibraryAction.duplicate:
          await showDuplicateMapDialog(context, controller, entry);
        case MapLibraryAction.resize:
          await showResizeMapDialog(
            context,
            controller,
            entry,
            visuals: visuals,
          );
        case MapLibraryAction.deleteMap:
          await showDeleteMapDialog(context, controller, entry);
        default:
          break;
      }
    },
  );
}

Future<bool> _confirmTargetSave(
  BuildContext context,
  ProjectMapEntry entry,
  MapLibraryAction action,
) async {
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
  return accepted == true;
}
