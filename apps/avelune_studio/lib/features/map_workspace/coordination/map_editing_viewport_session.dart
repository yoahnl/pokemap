import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/map_workspace_editing_state.dart';
import 'map_workspace_viewport_state.dart';

export '../application/map_workspace_editing_state.dart';

class MapEditingViewportSession extends MapWorkspaceEditingState {
  SpatialSceneController? spatialSceneController;
  final spatialAnimations = SpatialAnimationPreviewController();
  TransformationController get transform => viewport.transform;
  double get scale => viewport.scale;
  bool spatialFreeView = false;
  bool grid = false;
  bool dimOtherTerrains = false;
  bool lockDecorProportions = false;
  bool showDecorCollision = false;
  final viewport = MapWorkspaceViewportState();
  bool get positioned => viewport.positioned;
  set positioned(bool value) => viewport.positioned = value;
  VoidCallback? get recenter => viewport.recenter;
  set recenter(VoidCallback? value) => viewport.recenter = value;
  void Function(GridPos)? get centerOn => viewport.centerOn;
  set centerOn(void Function(GridPos)? value) => viewport.centerOn = value;
  Offset? Function(GridPos)? get globalOfCell => viewport.globalOfCell;
  set globalOfCell(Offset? Function(GridPos)? value) =>
      viewport.globalOfCell = value;

  void fitViewport(Size size, Size content) =>
      viewport.fitViewport(size, content);

  void attachViewport(
    Size size,
    Size content,
    Size tile, {
    required bool Function() mounted,
    GlobalKey? surface,
  }) => viewport.attachViewport(
    size,
    content,
    tile,
    mounted: mounted,
    surface: surface,
  );

  void centerCell(GridPos cell, Size size, Size tile) =>
      viewport.centerCell(cell, size, tile);

  void dispose() {
    spatialAnimations.dispose();
    viewport.dispose();
  }
}
