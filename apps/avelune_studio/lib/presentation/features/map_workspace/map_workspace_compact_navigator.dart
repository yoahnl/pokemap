import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_library_navigator.dart';
import 'workspace_compact_panel.dart';

Future<void> showMapLibraryCompactPanel(
  BuildContext context, {
  required MapWorkspaceController controller,
  required ValueChanged<ProjectMapEntry> onActivate,
  required OrganizeMapLibrary? onOrganize,
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
    onActivate: (entry) {
      close();
      onActivate(entry);
    },
    onOrganize: onOrganize == null
        ? null
        : ({groups, required assignments}) async {
            final error = await onOrganize(
              groups: groups,
              assignments: assignments,
            );
            if (error == null) refresh();
            return error;
          },
    width: 360,
  ),
);
