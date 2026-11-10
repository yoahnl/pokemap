import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';

import '../map_workspace/map_workspace_view_state.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'tile_selection_dialog.dart';

Future<bool> useResourceOnMap({
  required BuildContext context,
  required MapWorkspaceController workspace,
  required ResourceItem item,
  required MapWorkspaceVisuals visuals,
  required MapWorkspaceViewState? Function() view,
}) async {
  final used = await useMapResource(
    workspace: workspace,
    item: item,
    view: view,
    isActive: () => context.mounted,
    chooseMap: (entries) => showDialog<ProjectMapEntry>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choisir une carte'),
        children: [
          for (final entry in entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry),
              child: Text(entry.name),
            ),
        ],
      ),
    ),
    chooseTile: (tileset) => chooseResourceTile(context, tileset, visuals),
  );
  if (!used) return false;
  final state = view()!;
  if (item.terrain != null) {
    state.revealPalette = true;
  } else if (item.border != null) {
    state.paletteTab = 'Bordures';
    state.revealPalette = true;
  } else if (item.tileset == null && item.character == null) {
    state.paletteTab = 'Décors';
    state.revealPalette = true;
  }
  return true;
}
