import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

import '../../theme/studio_tokens.dart';
import 'map_canvas_overlay.dart';
import 'map_canvas_stroke.dart';
import 'map_character_gesture.dart';
import 'map_workspace_view_state.dart';

MapCanvasOverlay buildEditingOverlay({
  required BuildContext context,
  required MapData map,
  required ProjectManifest project,
  required EditableMapDocument document,
  required MapWorkspaceViewState view,
  required MapCharacterGesture? gesture,
  required MapCanvasStroke? stroke,
  required GridPos? preview,
  required double cellWidth,
  required double cellHeight,
}) {
  final colors = Theme.of(context).colorScheme;
  return MapCanvasOverlay(
    map: map,
    project: project,
    selected: document.selected,
    selectedEntity: map.entities
        .where(
          (entity) =>
              entity.id ==
              view.selectedFor(map.id, MapSelectionFamily.character),
        )
        .firstOrNull,
    entityPreview: gesture?.destination,
    selectedWarpId: view.selectedFor(map.id, MapSelectionFamily.warp),
    warpPreview: gesture?.warp == null ? null : gesture?.destination,
    selectedMarkerId: view.selectedFor(map.id, MapSelectionFamily.marker),
    selectedZoneId: view.selectedFor(map.id, MapSelectionFamily.zone),
    markerPreview: gesture?.entity == null ? null : gesture?.destination,
    zone: gesture?.zone == true
        ? gesture!.rectangle
        : map.triggers
              .where(
                (trigger) =>
                    trigger.id ==
                    view.selectedFor(map.id, MapSelectionFamily.trigger),
              )
              .firstOrNull
              ?.area,
    preview: preview,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    grid: view.grid,
    color: StudioColors.of(context).canvasSelection,
    labelBackground: colors.surface,
    labelForeground: colors.onSurface,
    strokeCells: List.of(stroke?.cells ?? []),
  );
}
