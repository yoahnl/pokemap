import 'package:map_core/map_core_domain.dart';

class CinematicMapModel {
  CinematicMapModel(this.asset, this.project, this.map) {
    actors = buildCinematicActorDisplayPreviewModel(
      cinematic: asset,
      project: project,
      stageMap: project.maps.where((m) => m.id == asset.mapId).firstOrNull,
      mapData: map,
    );
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
        final focus = cinematicEntityFocusPoint(
          entity: entity,
          project: project,
        );
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
