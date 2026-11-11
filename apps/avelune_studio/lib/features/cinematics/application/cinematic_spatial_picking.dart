import 'dart:ui';

import 'package:map_core/map_core_domain.dart';

import 'cinematic_map_model.dart';

const cinematicPlayerContentId = 'hero';
const _actorContentPrefix = 'cinematic:';

String cinematicActorContentId(CinematicActorDisplayPreviewActor actor) =>
    actor.bindingKind == CinematicActorBindingKind.player
    ? cinematicPlayerContentId
    : '$_actorContentPrefix${actor.actorId}';

String? cinematicActorIdForContent(CinematicMapModel model, String contentId) =>
    contentId == cinematicPlayerContentId
    ? model.actors.actors
          .where(
            (actor) => actor.bindingKind == CinematicActorBindingKind.player,
          )
          .firstOrNull
          ?.actorId
    : contentId.startsWith(_actorContentPrefix)
    ? contentId.substring(_actorContentPrefix.length)
    : null;

Offset cinematicCellCentre(int x, int y) => Offset(x + .5, y + .5);

CinematicStagePoint? cinematicStagePointAtCell(
  CinematicAsset asset,
  int x,
  int y,
) => asset.stageContext?.stagePoints
    .where((point) => point.x.floor() == x && point.y.floor() == y)
    .firstOrNull;

Offset cinematicSpatialDragDestination(
  CinematicStagePoint point, {
  required Offset origin,
  required (int, int) cell,
}) => Offset(point.x + cell.$1 - origin.dx, point.y + cell.$2 - origin.dy);

Offset cinematicGridDragDestination(
  CinematicStagePoint point, {
  required Offset delta,
  required Size cell,
}) => Offset(
  (point.x + delta.dx / cell.width).roundToDouble(),
  (point.y + delta.dy / cell.height).roundToDouble(),
);

Offset? cinematicCommittedDragDestination(
  CinematicStagePoint? point,
  Offset? destination,
) => point != null &&
        destination != null &&
        destination != Offset(point.x, point.y)
    ? destination
    : null;
