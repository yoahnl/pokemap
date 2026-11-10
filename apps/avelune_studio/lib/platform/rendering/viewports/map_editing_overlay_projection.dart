import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';

import 'package:avelune_studio/platform/rendering/viewports/map_editing_overlay.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_encounter_cell_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_character_gesture.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

MapEditingOverlay buildEditingOverlay({
  required BuildContext context,
  required MapData map,
  required ProjectManifest project,
  required EditableMapDocument document,
  required MapEditingViewportSession view,
  required MapCharacterGesture? gesture,
  required MapCanvasStroke? stroke,
  required MapEncounterCellStroke? encounterStroke,
  required MapBorderDrawingDraft? borderDraft,
  required GridPos? borderCursor,
  List<GridPos> borderStrokeCells = const [],
  required GridPos? preview,
  required double cellWidth,
  required double cellHeight,
}) {
  final colors = Theme.of(context).colorScheme;
  final hiddenBorder =
      view.borderFeature != null &&
      document.isElementHidden('layer', view.borderFeature!.layerId);
  return MapEditingOverlay(
    isHidden: document.isElementHidden,
    map: stroke?.collision == true ? stroke!.preview : map,
    project: project,
    selected: view.tool == StudioMapTool.select ? null : document.selected,
    extraSelected: [
      for (final element in map.placedElements)
        if (element.id != document.selectedId &&
            view.selectedDecorIds(map.id).contains(element.id))
          element,
    ],
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
    zone:
        document.isElementHidden(
          'trigger',
          view.selectedFor(map.id, MapSelectionFamily.trigger) ?? '',
        )
        ? null
        : gesture?.movesArea == true
        ? gesture!.armedArea
        : gesture?.zone == true
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
    transform: view.transform,
    color: Theme.of(context).colorScheme.primary,
    labelBackground: colors.surface,
    labelForeground: colors.onSurface,
    collisionColor:
        view.tool == StudioMapTool.collisionPaint ||
            view.tool == StudioMapTool.collisionErase
        ? colors.error
        : null,
    strokeCells: [
      ...?stroke?.cells,
      ...?encounterStroke?.cells,
      if (!hiddenBorder) ...borderStrokeCells,
    ],
    borderDraft: hiddenBorder ? null : borderDraft,
    borderCursor: hiddenBorder ? null : borderCursor,
  );
}
