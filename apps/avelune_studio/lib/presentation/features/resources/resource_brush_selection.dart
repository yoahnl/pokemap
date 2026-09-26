import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import '../map_workspace/map_workspace_view_state.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';
import 'tile_selection_dialog.dart';

Future<bool> useResourceOnMap({
  required BuildContext context,
  required MapWorkspaceController workspace,
  required ResourceItem item,
  required MapWorkspaceVisuals visuals,
  required MapWorkspaceViewState? Function() view,
}) async {
  if (workspace.project == null || workspace.project!.maps.isEmpty) {
    return false;
  }
  if (workspace.active == null) {
    final entry = await showDialog<ProjectMapEntry>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choisir une carte'),
        children: [
          for (final entry in workspace.project!.maps)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry),
              child: Text(entry.name),
            ),
        ],
      ),
    );
    if (entry == null) return false;
    await workspace.activate(entry);
  }
  if (!context.mounted || view() == null) return false;
  final target = workspace.active;
  final state = view()!;
  if (item.tileset != null) {
    final tile = await chooseResourceTile(context, item.tileset!, visuals);
    if (tile == null ||
        !context.mounted ||
        !identical(target, workspace.active)) {
      return false;
    }
    state.tile = tile;
    state.brush = null;
    state.terrain = null;
    state.tool = StudioMapTool.paint;
  } else if (item.terrain != null) {
    state.paletteTab = 'Terrains';
    state.revealPalette = true;
    state.terrain = item.terrain;
    state.tile = null;
    state.brush = null;
    state.tool = StudioMapTool.terrain;
  } else {
    state.paletteTab = 'Décors';
    state.revealPalette = true;
    state.brush = item.element;
    state.tile = null;
    state.terrain = null;
    state.tool = StudioMapTool.place;
  }
  state.character = null;
  return true;
}
