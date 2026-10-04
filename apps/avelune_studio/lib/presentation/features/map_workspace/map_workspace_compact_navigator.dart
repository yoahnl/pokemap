import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_library_navigator.dart';
import 'workspace_compact_panel.dart';
import 'map_catalogue_workspace_actions.dart';
import 'map_lifecycle_workspace_actions.dart';
import 'map_workspace_visuals.dart';

Future<void> showMapLibraryCompactPanel(
  BuildContext context, {
  required MapWorkspaceController controller,
  required ValueChanged<ProjectMapEntry> onActivate,
  required OrganizeMapLibrary? onOrganize,
  MapWorkspaceVisuals? visuals,
}) => showWorkspaceCompactPanel(
  context,
  title: 'Dossiers de cartes',
  builder: (context, refresh, close) => MapLibraryNavigator(
    project: controller.project!,
    activeMapId: controller.active?.base.mapId,
    dirtyMapIds: {
      for (final entry in controller.documents.entries)
        if (entry.value.dirty) entry.key,
    },
    onRetryCatalogue: controller.pendingCatalogReceipt == null
        ? null
        : () async {
            await controller.retryCatalogRefresh();
            refresh();
          },
    onActivate: (entry) {
      close();
      onActivate(entry);
    },
    onCreateMap: controller.catalogPort == null
        ? null
        : (groupId) async {
            await createWorkspaceMap(context, controller, groupId: groupId);
            refresh();
          },
    onRenameMap: controller.catalogPort == null
        ? null
        : (entry) async {
            await renameWorkspaceMap(context, controller, entry);
            refresh();
          },
    onLifecycleMap: controller.catalogPort == null
        ? null
        : (entry, action) async {
            await manageWorkspaceMap(
              context,
              controller,
              entry,
              action,
              visuals: visuals,
            );
            refresh();
          },
    onOrganize: onOrganize == null
        ? null
        : ({groups, required assignments}) async {
            final error = await onOrganize(
              groups: groups,
              assignments: assignments,
            );
            refresh();
            return error;
          },
    width: 360,
  ),
);
