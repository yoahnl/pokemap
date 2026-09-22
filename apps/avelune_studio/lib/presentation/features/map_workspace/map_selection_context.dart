import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';

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
  MapWorkspaceViewState? view,
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
