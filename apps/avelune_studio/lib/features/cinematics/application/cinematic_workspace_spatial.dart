part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspaceSpatial on CinematicWorkspaceController {
  CinematicAsset _keepPaths(CinematicAsset old, CinematicAsset next) {
    final context = next.stageContext,
        paths = old.stageContext?.manualPaths ?? [];
    if (context == null || paths.isEmpty) return next;
    return next.copyWith(
      stageContext: CinematicStageContext(
        backdropMode: context.backdropMode,
        actorBindings: context.actorBindings,
        actorAppearanceBindings: context.actorAppearanceBindings,
        initialPlacements: context.initialPlacements,
        movementTargetBindings: context.movementTargetBindings,
        stagePoints: context.stagePoints,
        manualPaths: paths,
      ),
    );
  }

  bool setMap(String? mapId) => edit(
    (a) => _keepPaths(
      a,
      updateCinematicStageMap(
        _with(a),
        cinematicId: a.id,
        mapId: mapId,
      ).cinematic,
    ),
  );
  String? addActor(String label) {
    String? id;
    final ok = edit((a) {
      final result = addCinematicRequiredActor(
        _with(a),
        cinematicId: a.id,
        label: label,
      );
      id = result.actor.actorId;
      return result.cinematic;
    });
    return ok ? id : null;
  }

  bool bindActor(CinematicActorBinding binding) => edit(
    (a) => _keepPaths(
      a,
      upsertCinematicActorBinding(
        _with(a),
        cinematicId: a.id,
        binding: binding,
      ).cinematic,
    ),
  );
  bool setAppearance(CinematicActorAppearanceBinding binding) => edit(
    (a) => _keepPaths(
      a,
      upsertCinematicActorAppearanceBinding(
        _with(a),
        cinematicId: a.id,
        binding: binding,
      ).cinematic,
    ),
  );
  bool setPlacement(CinematicActorInitialPlacement placement) => edit(
    (a) => _keepPaths(
      a,
      upsertCinematicActorInitialPlacement(
        _with(a),
        cinematicId: a.id,
        placement: placement,
      ).cinematic,
    ),
  );
  bool setStagePoint(CinematicStagePoint point) => edit(
    (a) => _keepPaths(
      a,
      ((a.stageContext?.stagePoints.any((p) => p.id == point.id) ?? false)
              ? updateCinematicStagePoint(
                  _with(a),
                  cinematicId: a.id,
                  point: point,
                )
              : addCinematicStagePoint(
                  _with(a),
                  cinematicId: a.id,
                  point: point,
                ))
          .cinematic,
    ),
  );
  String? addTarget(String label) {
    String? id;
    final ok = edit((a) {
      final result = addCinematicMovementTarget(
        _with(a),
        cinematicId: a.id,
        label: label,
      );
      id = result.target.targetId;
      return result.cinematic;
    });
    return ok ? id : null;
  }

  bool setDestination(
    String stepId,
    double x,
    double y, {
    required int width,
    required int height,
  }) => edit((a) {
    if (!x.isFinite ||
        !y.isFinite ||
        x < 0 ||
        y < 0 ||
        x >= width ||
        y >= height) {
      throw ArgumentError('La destination doit être dans la carte.');
    }
    final step = a.timeline.steps.firstWhere((s) => s.id == stepId);
    if (!isCinematicTimelineActorMoveStep(step)) {
      throw ArgumentError('Sélectionnez un déplacement.');
    }
    final target = addCinematicMovementTarget(
      _with(a),
      cinematicId: a.id,
      label: 'Destination',
    );
    final point = CinematicStagePoint(
      id: narrative.identity('point'),
      label: 'Destination',
      x: x,
      y: y,
    );
    var next = addCinematicStagePoint(
      target.updatedProject,
      cinematicId: a.id,
      point: point,
    ).cinematic;
    next = upsertCinematicMovementTargetBinding(
      _with(next),
      cinematicId: a.id,
      binding: CinematicMovementTargetBinding(
        targetId: target.target.targetId,
        kind: CinematicMovementTargetBindingKind.stagePoint,
        sourceId: point.id,
      ),
    ).cinematic;
    next = updateCinematicTimelineActorMoveStep(
      _with(next),
      cinematicId: a.id,
      stepId: stepId,
      targetId: target.target.targetId,
    ).cinematic;
    return _keepPaths(a, next);
  });
  bool setManualPath(String stepId, List<String> waypointIds) => edit((a) {
    final existing = a.stageContext?.manualPaths
        .where((p) => p.ownerActorMoveStepId == stepId)
        .firstOrNull;
    if (existing == null) {
      return addCinematicManualPathForActorMove(
        _with(a),
        cinematicId: a.id,
        actorMoveStepId: stepId,
        waypointStagePointIds: waypointIds,
      ).cinematic;
    }
    return updateCinematicManualPath(
      _with(a),
      cinematicId: a.id,
      manualPathId: existing.id,
      waypointStagePointIds: waypointIds,
    ).cinematic;
  });
  void _checkPoint(double x, double y, int width, int height) {
    if (!x.isFinite ||
        !y.isFinite ||
        x < 0 ||
        y < 0 ||
        x >= width ||
        y >= height) {
      throw ArgumentError('Le point doit être dans la carte.');
    }
  }

  bool placeActorAt(
    String actorId,
    double x,
    double y, {
    required int width,
    required int height,
  }) => edit((a) {
    _checkPoint(x, y, width, height);
    final point = CinematicStagePoint(
      id: narrative.identity('point'),
      label: 'Départ',
      x: x,
      y: y,
    );
    var next = addCinematicStagePoint(
      _with(a),
      cinematicId: a.id,
      point: point,
    ).cinematic;
    next = upsertCinematicActorInitialPlacement(
      _with(next),
      cinematicId: a.id,
      placement: CinematicActorInitialPlacement(
        actorId: actorId,
        kind: CinematicActorInitialPlacementKind.stagePoint,
        stagePointId: point.id,
      ),
    ).cinematic;
    return _keepPaths(a, next);
  });
  bool appendWaypoint(
    String stepId,
    double x,
    double y, {
    required int width,
    required int height,
  }) => edit((a) {
    _checkPoint(x, y, width, height);
    final point = CinematicStagePoint(
      id: narrative.identity('point'),
      label: 'Point de trajet',
      x: x,
      y: y,
    );
    final path = a.stageContext?.manualPaths
        .where((p) => p.ownerActorMoveStepId == stepId)
        .firstOrNull;
    final next = _keepPaths(
      a,
      addCinematicStagePoint(
        _with(a),
        cinematicId: a.id,
        point: point,
      ).cinematic,
    );
    if (path == null) {
      return addCinematicManualPathForActorMove(
        _with(next),
        cinematicId: a.id,
        actorMoveStepId: stepId,
        waypointStagePointIds: [point.id],
      ).cinematic;
    }
    return updateCinematicManualPath(
      _with(next),
      cinematicId: a.id,
      manualPathId: path.id,
      waypointStagePointIds: [...path.waypointStagePointIds, point.id],
    ).cinematic;
  });
}
