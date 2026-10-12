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
            if (workspace.project!.resourceLibraryCatalog.availableForMap(
              item.canonicalKind,
              item.id,
              entry.id,
            ))
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
  if (target == null ||
      !workspace.project!.resourceLibraryCatalog.availableForMap(
        item.canonicalKind,
        item.id,
        target.current.id,
      )) {
    return false;
  }
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
    state.model3d = null;
    state.terrain = null;
    state.tool = StudioMapTool.paint;
  } else if (item.terrain != null) {
    state.prepareTerrainPainting(item.terrain!);
    state.revealPalette = true;
  } else if (item.border != null) {
    state.paletteTab = 'Bordures';
    state.revealPalette = true;
    state.borderBlueprintId = item.id;
    state.borderDraft = null;
    state.brush = null;
    state.model3d = null;
    state.tile = null;
    state.terrain = null;
    state.tool = StudioMapTool.border;
  } else if (item.character != null) {
    state.prepareCharacterPlacement();
    state.character = item.character;
    state.tool = StudioMapTool.character;
    return true;
  } else {
    state.paletteTab = 'Décors';
    state.revealPalette = true;
    state.brush = item.element;
    state.model3d = item.model3d;
    state.tile = null;
    state.terrain = null;
    state.tool = StudioMapTool.place;
  }
  state.character = null;
  return true;
}
