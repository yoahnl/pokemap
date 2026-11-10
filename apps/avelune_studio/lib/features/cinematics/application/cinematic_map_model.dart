import 'dart:math' as math;

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
  Map<String, ({double x, double y})> get actorOrigins => {
    for (final actor in actors.actors)
      if (actor.position.isResolved &&
          actor.position.x != null &&
          actor.position.y != null)
        actor.actorId: (
          x: actor.position.x!.toDouble(),
          y: actor.position.y!.toDouble(),
        ),
  };
  List<CinematicStagePoint> get resolvedStagePoints => [
    for (final point
        in asset.stageContext?.stagePoints ?? const <CinematicStagePoint>[])
      if (map.spatialScene == null || point.relativeToActorId == null)
        ?resolveCinematicStagePoint(point, actorOrigins),
  ];
  final targets = <String, CinematicPreviewPlaybackPoint>{};
  CinematicStagePoint rebasePoint(CinematicStagePoint point, String? actorId) {
    if (actorId != null && map.spatialScene != null) {
      throw StateError(
        'Les repères relatifs aux acteurs sont disponibles sur les cartes 2D.',
      );
    }
    final origin = actorId == null ? null : actorOrigins[actorId];
    final resolved = resolvedStagePoints
        .where((entry) => entry.id == point.id)
        .firstOrNull;
    if (resolved == null || (actorId != null && origin == null)) {
      throw StateError('L’acteur d’origine doit être présent dans l’aperçu.');
    }
    return CinematicStagePoint(
      id: point.id,
      label: point.label,
      description: point.description,
      x: resolved.x - (origin?.x ?? 0),
      y: resolved.y - (origin?.y ?? 0),
      relativeToActorId: actorId,
    );
  }

  CinematicStagePoint pointAt(CinematicStagePoint point, double x, double y) {
    if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
      throw StateError('Le repère doit rester dans la carte.');
    }
    final origin = point.relativeToActorId == null
        ? null
        : actorOrigins[point.relativeToActorId];
    if (point.relativeToActorId != null && origin == null) {
      throw StateError(
        'L’acteur d’origine doit être présent pour déplacer ce repère.',
      );
    }
    return CinematicStagePoint(
      id: point.id,
      label: point.label,
      description: point.description,
      x: x - (origin?.x ?? 0),
      y: y - (origin?.y ?? 0),
      relativeToActorId: point.relativeToActorId,
    );
  }

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

Set<(int, int)> cinematicPreviewCells(CinematicMapModel model) {
  final cells = <(int, int)>{};
  final points = {
    for (final point
        in model.asset.stageContext?.stagePoints ?? <CinematicStagePoint>[])
      point.id: (x: point.x, y: point.y),
  };
  void line(({double x, double y}) start, ({double x, double y}) end) {
    final count =
        math.max((end.x - start.x).abs(), (end.y - start.y).abs()).ceil() * 2;
    for (var i = 0; i <= count; i++) {
      final t = count == 0 ? 0.0 : i / count;
      final point = (
        x: start.x * (1.0 - t) + end.x * t,
        y: start.y * (1.0 - t) + end.y * t,
      );
      cells.add((point.x.floor(), point.y.floor()));
    }
  }

  final positions = {
    for (final actor in model.actors.actors)
      if (actor.position.isResolved)
        actor.actorId: (
          x: actor.position.x!.toDouble(),
          y: actor.position.y!.toDouble(),
        ),
  };
  for (final step in model.asset.timeline.steps.where(
    (step) =>
        step.kind == CinematicTimelineStepKind.actorMove ||
        step.kind == CinematicTimelineStepKind.actorJump,
  )) {
    var origin = positions[step.actorId];
    if (origin == null) continue;
    final path = model.asset.stageContext?.manualPaths
        .where((path) => path.ownerActorMoveStepId == step.id)
        .firstOrNull;
    for (final id in path?.waypointStagePointIds ?? <String>[]) {
      final point = points[id];
      if (point != null) {
        line(origin!, point);
        origin = point;
      }
    }
    final binding = model.asset.stageContext?.movementTargetBindings
        .where((binding) => binding.targetId == step.targetId)
        .firstOrNull;
    final target =
        binding?.kind == CinematicMovementTargetBindingKind.stagePoint
        ? points[binding?.sourceId]
        : null;
    final external = model.targets[step.targetId];
    final end =
        target ?? (external == null ? null : (x: external.x, y: external.y));
    if (end != null) {
      line(origin!, end);
      positions[step.actorId!] = end;
    }
  }
  cells.addAll(
    points.values.map((point) => (point.x.floor(), point.y.floor())),
  );
  return cells;
}
