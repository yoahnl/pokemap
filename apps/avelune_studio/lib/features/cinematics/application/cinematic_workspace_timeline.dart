part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspaceTimeline on CinematicWorkspaceController {
  bool moveSteps(Set<String> ids, int insertionIndex) => edit(
    (a) => moveCinematicTimelineSteps(
      a,
      stepIds: ids,
      insertionIndex: insertionIndex,
    ).cinematic,
  );
  CinematicAsset _withPaths(
    CinematicAsset asset,
    List<CinematicManualPath> paths,
  ) {
    final c = asset.stageContext;
    if (c == null) return asset;
    return asset.copyWith(
      stageContext: CinematicStageContext(
        backdropMode: c.backdropMode,
        actorBindings: c.actorBindings,
        actorAppearanceBindings: c.actorAppearanceBindings,
        initialPlacements: c.initialPlacements,
        movementTargetBindings: c.movementTargetBindings,
        stagePoints: c.stagePoints,
        manualPaths: paths,
      ),
    );
  }

  CinematicAsset _restoreCopiedPaths(
    CinematicAsset source,
    CinematicTimelineEditResult result,
  ) {
    var next = result.cinematic;
    for (final path
        in source.stageContext?.manualPaths ?? <CinematicManualPath>[]) {
      final owner = result.idRewrites[path.ownerActorMoveStepId];
      if (owner == null) continue;
      if (!path.waypointStagePointIds.every(
        (id) => next.stageContext?.stagePoints.any((p) => p.id == id) == true,
      )) {
        throw ArgumentError(
          'Les repères du chemin copié ne sont pas présents dans cette cinématique.',
        );
      }
      next = addCinematicManualPathForActorMove(
        _with(next),
        cinematicId: next.id,
        actorMoveStepId: owner,
        label: path.label,
        description: path.description,
        waypointStagePointIds: path.waypointStagePointIds,
      ).cinematic;
    }
    return next;
  }

  bool duplicateSteps(Set<String> ids) => edit(
    (a) => _restoreCopiedPaths(
      a,
      duplicateCinematicTimelineSteps(a, stepIds: ids),
    ),
  );
  bool deleteSteps(Set<String> ids) => edit(
    (a) => _withPaths(deleteCinematicTimelineSteps(a, stepIds: ids).cinematic, [
      ...?a.stageContext?.manualPaths.where(
        (p) => !ids.contains(p.ownerActorMoveStepId),
      ),
    ]),
  );
  CinematicTimelineClipboard? copySteps(Set<String> ids) {
    final a = _active?.asset;
    if (a == null) return null;
    try {
      _clipboardSource = a;
      return _clipboard = copyCinematicTimelineSteps(a, stepIds: ids);
    } catch (failure) {
      _fail(failure);
      return null;
    }
  }

  bool pasteSteps(
    CinematicTimelineClipboard clipboard,
    int insertionIndex,
  ) => edit((a) {
    for (final s in clipboard.steps) {
      if (s.actorId != null &&
          !a.requiredActors.any((r) => r.actorId == s.actorId)) {
        throw ArgumentError(
          'Le rôle de cette étape manque dans la cinématique cible.',
        );
      }
      if (s.targetId != null &&
          !a.movementTargets.any((r) => r.targetId == s.targetId)) {
        throw ArgumentError(
          'La destination de cette étape manque dans la cinématique cible.',
        );
      }
      if (s.kind == CinematicTimelineStepKind.dialogueLine &&
          s.assetRef != null &&
          !project.dialogues.any((d) => d.id == s.assetRef)) {
        throw ArgumentError(
          'Le dialogue de cette étape manque dans ce projet.',
        );
      }
      if ({
            CinematicTimelineStepKind.sound,
            CinematicTimelineStepKind.music,
            CinematicTimelineStepKind.fx,
          }.contains(s.kind) &&
          s.assetRef != null &&
          !project.cinematicMediaAssets.any((m) => m.id == s.assetRef)) {
        throw ArgumentError('Le média de cette étape manque dans ce projet.');
      }
    }
    final result = pasteCinematicTimelineSteps(
      a,
      clipboard: clipboard,
      insertionIndex: insertionIndex,
    );
    if (identical(clipboard, _clipboard) && _clipboardSource != null) {
      return _restoreCopiedPaths(_clipboardSource!, result);
    }
    if (clipboard.steps.any(
      (s) =>
          cinematicTimelineActorPathModeOf(s) ==
          CinematicTimelineActorPathMode.manual,
    )) {
      throw ArgumentError(
        'Le presse-papiers ne transporte pas les repères de ce chemin manuel.',
      );
    }
    return result.cinematic;
  });
}

CinematicAsset joinCinematicParallelSteps(CinematicAsset asset, String stepId) {
  final steps = asset.timeline.steps;
  final index = steps.indexWhere((step) => step.id == stepId);
  if (index <= 0) throw ArgumentError('Une étape précédente est nécessaire.');
  final previous = steps[index - 1];
  final current = steps[index];
  final groups = {
    if (previous.parallelGroupId != null) previous.parallelGroupId!,
    if (current.parallelGroupId != null) current.parallelGroupId!,
  };
  final ids = {
    previous.id,
    current.id,
    for (final step in steps)
      if (groups.contains(step.parallelGroupId)) step.id,
  };
  final used = steps.map((step) => step.parallelGroupId).toSet();
  var number = 1;
  while (used.contains('parallel_$number')) {
    number++;
  }
  final groupId =
      previous.parallelGroupId ?? current.parallelGroupId ?? 'parallel_$number';
  return setCinematicTimelineParallelGroup(
    asset,
    stepIds: ids,
    parallelGroupId: groupId,
  ).cinematic;
}

CinematicAsset dissolveCinematicParallelSteps(
  CinematicAsset asset,
  String stepId,
) {
  final group = asset.timeline.steps
      .firstWhere((step) => step.id == stepId)
      .parallelGroupId;
  if (group == null) {
    return asset;
  }
  return setCinematicTimelineParallelGroup(
    asset,
    stepIds: {
      for (final step in asset.timeline.steps)
        if (step.parallelGroupId == group) step.id,
    },
    parallelGroupId: null,
  ).cinematic;
}
