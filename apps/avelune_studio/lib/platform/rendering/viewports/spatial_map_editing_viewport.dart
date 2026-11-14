import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';

import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_character_gesture.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_encounter_cell_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

import 'package:avelune_studio/features/rendering/contracts/map_canvas_readiness.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

part 'spatial_map_editing_overlays.dart';
part 'spatial_map_editing_environment.dart';
part 'spatial_map_editing_borders.dart';
part 'spatial_map_editing_border_erase.dart';
part 'spatial_map_editing_camera.dart';
part 'spatial_map_editing_cell_overlays.dart';
part 'spatial_map_editing_exterior.dart';
part 'spatial_map_editing_gesture_start.dart';
part 'spatial_map_editing_gestures.dart';
part 'spatial_map_editing_keyboard.dart';
part 'spatial_map_editing_scene.dart';
part 'spatial_map_editing_viewport_state.dart';

class SpatialMapEditingViewport extends StatefulWidget {
  const SpatialMapEditingViewport({
    super.key,
    required this.document,
    required this.controller,
    required this.project,
    required this.visuals,
    required this.view,
    required this.onChanged,
    this.onContextMenu,
    this.onZoneDrawn,
    this.neighbors = const [],
    this.neighborDecorations = const [],
    this.exteriorContextReady = true,
  });
  final EditableMapDocument document;
  final List<SpatialSceneNeighbor> neighbors;
  final List<SpatialSceneDecoration> neighborDecorations;
  final bool exteriorContextReady;
  final MapWorkspaceController controller;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapEditingViewportSession view;
  final VoidCallback onChanged;
  final void Function(GridPos, Offset)? onContextMenu;
  final ValueChanged<MapRect>? onZoneDrawn;
  @override
  State<SpatialMapEditingViewport> createState() =>
      _SpatialMapEditingViewportState();
}

bool _previewOrderOnlyChange(MapData before, MapData after) {
  if (!mapSharesNonVisualOrderStorage(before, after) ||
      before.layers.length != after.layers.length ||
      before.placedElements.length != after.placedElements.length) {
    return false;
  }
  final layers = {for (final layer in before.layers) layer.id: layer};
  for (final layer in after.layers) {
    if (layers[layer.id] != layer) return false;
  }
  for (var index = 0; index < before.placedElements.length; index++) {
    final previous = before.placedElements[index],
        next = after.placedElements[index];
    if (!identical(previous, next) &&
        previous.copyWith(visualOrder: next.visualOrder) != next) {
      return false;
    }
  }
  return true;
}
