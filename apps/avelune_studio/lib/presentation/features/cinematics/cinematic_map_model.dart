import 'package:map_core/map_core_domain.dart';

class CinematicMapModel {
  CinematicMapModel(this.asset, this.project, this.map) {
    final actorPreview = buildCinematicActorDisplayPreviewModel(
      cinematic: asset,
      project: project,
      stageMap: project.maps.where((m) => m.id == asset.mapId).firstOrNull,
      mapData: map,
    );
    actors = map.spatialScene == null
        ? actorPreview
        : _spatialActors(actorPreview, map, asset);
    final hidden =
        asset.stageContext?.actorBindings
            .where((b) => b.kind == CinematicActorBindingKind.mapEntity)
            .map((b) => b.mapEntityId)
            .toSet() ??
        <String?>{};
    background = map.copyWith(
      entities: map.entities.where((e) => !hidden.contains(e.id)).toList(),
    );
    for (final binding
        in asset.stageContext?.movementTargetBindings ??
            <CinematicMovementTargetBinding>[]) {
      final entity = map.entities
          .where((e) => e.id == binding.sourceId)
          .firstOrNull;
      final trigger = map.triggers
          .where((e) => e.id == binding.sourceId)
          .firstOrNull;
      if (binding.kind == CinematicMovementTargetBindingKind.mapEntity &&
          entity != null) {
        final focus = map.spatialScene != null
            ? (x: entity.pos.x + .5, y: entity.pos.y + .5)
            : cinematicEntityFocusPoint(entity: entity, project: project);
        targets[binding.targetId] = CinematicPreviewPlaybackPoint(
          x: focus.x,
          y: focus.y,
          source: CinematicPreviewPlaybackPointSource.resolvedMovementTarget,
        );
      }
      if (binding.kind == CinematicMovementTargetBindingKind.mapEvent &&
          trigger != null) {
        targets[binding.targetId] = CinematicPreviewPlaybackPoint(
          x: trigger.area.pos.x.toDouble(),
          y: trigger.area.pos.y.toDouble(),
          source: CinematicPreviewPlaybackPointSource.resolvedMovementTarget,
        );
      }
    }
  }
  final CinematicAsset asset;
  final ProjectManifest project;
  final MapData map;
  late final MapData background;
  late final CinematicActorDisplayPreviewModel actors;
  final targets = <String, CinematicPreviewPlaybackPoint>{};
  CinematicPreviewPlaybackStageBounds get bounds =>
      CinematicPreviewPlaybackStageBounds(
        width: map.size.width.toDouble(),
        height: map.size.height.toDouble(),
      );
}

CinematicActorDisplayPreviewModel _spatialActors(
  CinematicActorDisplayPreviewModel source,
  MapData map,
  CinematicAsset asset,
) => CinematicActorDisplayPreviewModel(
  status: source.status,
  summary: source.summary,
  diagnostics: source.diagnostics,
  actors: [
    for (final actor in source.actors)
      if (actor.position.isResolved)
        _spatialActor(actor, map, asset)
      else
        actor,
  ],
);

CinematicActorDisplayPreviewActor _spatialActor(
  CinematicActorDisplayPreviewActor actor,
  MapData map,
  CinematicAsset asset,
) {
  ({double x, double y})? ground;
  if (actor.position.sourceKind ==
      CinematicActorPreviewPositionSourceKind.mapEntity) {
    final entity = map.entities
        .where((entity) => entity.id == actor.position.sourceId)
        .firstOrNull;
    if (entity != null) ground = (x: entity.pos.x + .5, y: entity.pos.y + .5);
  } else {
    var pointId = actor.position.sourceId;
    if (actor.position.sourceKind ==
        CinematicActorPreviewPositionSourceKind.movementTarget) {
      final target = asset.stageContext?.movementTargetBindings
          .where((binding) => binding.targetId == pointId)
          .firstOrNull;
      pointId = target?.kind == CinematicMovementTargetBindingKind.stagePoint
          ? target?.sourceId
          : null;
    } else if (actor.position.sourceKind !=
        CinematicActorPreviewPositionSourceKind.stagePoint) {
      pointId = null;
    }
    final point = asset.stageContext?.stagePoints
        .where((point) => point.id == pointId)
        .firstOrNull;
    if (point != null) ground = (x: point.x, y: point.y);
  }
  if (ground == null) return actor;
  return CinematicActorDisplayPreviewActor(
    actorId: actor.actorId,
    label: actor.label,
    role: actor.role,
    bindingStatus: actor.bindingStatus,
    bindingKind: actor.bindingKind,
    bindingSourceId: actor.bindingSourceId,
    bindingSourceLabel: actor.bindingSourceLabel,
    appearance: actor.appearance,
    direction: actor.direction,
    directionSource: actor.directionSource,
    renderHint: actor.renderHint,
    diagnostics: actor.diagnostics,
    position: CinematicActorPreviewPosition(
      status: actor.position.status,
      sourceKind: actor.position.sourceKind,
      sourceId: actor.position.sourceId,
      sourceLabel: actor.position.sourceLabel,
      x: ground.x,
      y: ground.y,
    ),
  );
}

List<String> cinematicPointUses(CinematicAsset asset, String id) => [
  for (final p
      in asset.stageContext?.initialPlacements ??
          <CinematicActorInitialPlacement>[])
    if (p.stagePointId == id) 'le départ de ${p.actorId}',
  for (final path in asset.stageContext?.manualPaths ?? <CinematicManualPath>[])
    if (path.waypointStagePointIds.contains(id)) 'le trajet ${path.label}',
  for (final target
      in asset.stageContext?.movementTargetBindings ??
          <CinematicMovementTargetBinding>[])
    if (target.kind == CinematicMovementTargetBindingKind.stagePoint &&
        target.sourceId == id)
      for (final step in asset.timeline.steps)
        if (step.targetId == target.targetId)
          'la destination de ${step.label ?? step.actorId ?? step.id}',
  for (final step in asset.timeline.steps)
    if (cinematicTimelineCameraFocusBindingOf(step)?.target.stagePointId == id)
      'la caméra ${step.label ?? step.id}',
];
