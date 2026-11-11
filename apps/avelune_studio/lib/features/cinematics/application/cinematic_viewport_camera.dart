import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

import 'cinematic_map_model.dart';

const cinematicInitialVisibleColumns = 15;
const cinematicInitialVisibleRows = 11;

CinematicViewportCamera cinematicInitialViewportCamera(
  CinematicMapModel model, {
  double cellWidth = 1,
  double cellHeight = 1,
  bool clampToMap = true,
}) {
  final player = model.actors.actors
      .where((actor) => actor.bindingKind == CinematicActorBindingKind.player)
      .firstOrNull;
  final origin = player?.position;
  final width = model.map.size.width, height = model.map.size.height;
  return CinematicViewportCamera(
    centerX: (origin?.x ?? width / 2) * cellWidth,
    centerY: (origin?.y ?? height / 2) * cellHeight,
    visibleWidth:
        (clampToMap
            ? math.min(cinematicInitialVisibleColumns, width)
            : cinematicInitialVisibleColumns) *
        cellWidth,
    visibleHeight:
        (clampToMap
            ? math.min(cinematicInitialVisibleRows, height)
            : cinematicInitialVisibleRows) *
        cellHeight,
  );
}

CinematicViewportProjection cinematicPlaybackProjection(
  CinematicPreviewPlaybackPlan plan,
  CinematicMapModel model, {
  double cellWidth = 1,
  double cellHeight = 1,
  bool clampToMap = true,
}) => CinematicViewportProjection(
  plan: plan,
  cellWidth: cellWidth,
  cellHeight: cellHeight,
  initialCamera: cinematicInitialViewportCamera(
    model,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    clampToMap: clampToMap,
  ),
);

double cinematicSpatialPreviewZoom(double authorZoom, double visibleWidth) =>
    authorZoom * cinematicInitialVisibleColumns / visibleWidth;
