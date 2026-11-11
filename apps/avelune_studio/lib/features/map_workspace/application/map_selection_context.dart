import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

MapSelectionFamily selectionFamilyOf(MapContextFamily family) =>
    switch (family) {
      MapContextFamily.decor => MapSelectionFamily.decor,
      MapContextFamily.character => MapSelectionFamily.character,
      MapContextFamily.marker => MapSelectionFamily.marker,
      MapContextFamily.warp => MapSelectionFamily.warp,
      MapContextFamily.zone => MapSelectionFamily.zone,
      MapContextFamily.trigger => MapSelectionFamily.trigger,
      MapContextFamily.cell => MapSelectionFamily.decor,
    };

MapContextFamily contextFamilyOf(MapSelectionFamily family) => switch (family) {
  MapSelectionFamily.decor => MapContextFamily.decor,
  MapSelectionFamily.character => MapContextFamily.character,
  MapSelectionFamily.marker => MapContextFamily.marker,
  MapSelectionFamily.warp => MapContextFamily.warp,
  MapSelectionFamily.zone => MapContextFamily.zone,
  MapSelectionFamily.trigger => MapContextFamily.trigger,
};

MapContextPlacement? selectedContextTarget(
  EditableMapDocument document,
  ProjectManifest project,
  MapWorkspaceEditingState? view,
) {
  final target = view?.target;
  if (target != null && target.mapId == document.current.id) {
    return locateMapContextTarget(
      document,
      project,
      contextFamilyOf(target.family),
      target.id,
    );
  }
  final decor = document.selectedId;
  return decor == null
      ? null
      : locateMapContextTarget(
          document,
          project,
          MapContextFamily.decor,
          decor,
        );
}

const mapContextNoVisibleSelection =
    'Aucun élément visible n’est sélectionné sur cette carte : '
    'sélectionnez-en un pour ouvrir son menu.';

MapContextPlacement? keyboardContextTarget(
  EditableMapDocument document,
  ProjectManifest project,
  MapWorkspaceEditingState? view,
) {
  final selected = selectedContextTarget(document, project, view);
  if (selected == null) document.error = mapContextNoVisibleSelection;
  return selected;
}

void armMapContextMove({
  required EditableMapDocument document,
  required MapWorkspaceEditingState view,
  required MapContextTarget target,
  required GridPos anchor,
  String hint = '',
}) {
  final family = selectionFamilyOf(target.family);
  view
    ..tool = StudioMapTool.select
    ..select(document, family, target.id)
    ..armMove(
      MapSelectionTarget(
        mapId: document.current.id,
        family: family,
        id: target.id,
      ),
      hint,
    );
  document.stackPosition = anchor;
}

void releaseStaleMapMoves(
  Map<String, MapWorkspaceEditingState> views,
  EditableMapDocument? document,
) {
  for (final entry in views.entries) {
    if (entry.key != document?.base.mapId) entry.value.pendingMove = null;
  }
  final view = document == null ? null : views[document.base.mapId];
  final armed = view?.pendingMove;
  if (armed != null &&
      (view!.tool != StudioMapTool.select ||
          mapContextAnchorOf(
                document!.current,
                contextFamilyOf(armed.family),
                armed.id,
              ) ==
              null)) {
    view.pendingMove = null;
  }
}

void cancelMapInput(MapWorkspaceEditingState view) {
  view
    ..pendingMove = null
    ..tool = StudioMapTool.select;
}
