part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspaceActions on CinematicWorkspaceController {
  bool rename(String title) => edit((a) => a.copyWith(title: title));
  String? _added(CinematicAsset Function(CinematicAsset) transform) {
    final old = _active?.asset.timeline.steps.map((s) => s.id).toSet() ?? {};
    if (!edit(transform)) return null;
    return _active!.asset.timeline.steps
        .where((s) => !old.contains(s.id))
        .firstOrNull
        ?.id;
  }

  String? addBasic(
    CinematicTimelineBasicBlockKind kind, {
    String? afterStepId,
    int? durationMs,
    CinematicTimelineFadeMode fadeMode = CinematicTimelineFadeMode.fadeIn,
    CinematicTimelineCameraMode cameraMode = CinematicTimelineCameraMode.reset,
    CinematicTimelineCameraFocusBinding? cameraFocusBinding,
  }) => _added(
    (a) => addCinematicTimelineBasicBlockStep(
      _with(a),
      cinematicId: a.id,
      blockKind: kind,
      afterStepId: afterStepId,
      durationMs: durationMs,
      fadeMode: fadeMode,
      cameraMode: cameraMode,
      cameraFocusBinding: cameraFocusBinding,
    ).cinematic,
  );
  String? addFace(
    String actorId,
    CinematicTimelineActorFacingDirection direction, {
    String? afterStepId,
  }) => _added(
    (a) => addCinematicTimelineActorFacingStep(
      _with(a),
      cinematicId: a.id,
      actorId: actorId,
      direction: direction,
      afterStepId: afterStepId,
    ).cinematic,
  );
  String? addMove(
    String actorId,
    String targetId, {
    String? afterStepId,
    int durationMs = 1000,
    CinematicTimelineActorMovementMode movementMode =
        CinematicTimelineActorMovementMode.walk,
    CinematicTimelineActorFacingMode facingMode =
        CinematicTimelineActorFacingMode.followMovement,
  }) => _added(
    (a) => addCinematicTimelineActorMoveStep(
      _with(a),
      cinematicId: a.id,
      actorId: actorId,
      targetId: targetId,
      afterStepId: afterStepId,
      durationMs: durationMs,
      movementMode: movementMode,
      facingMode: facingMode,
    ).cinematic,
  );
  String? addJump(
    String actorId,
    String targetId, {
    String? afterStepId,
    int durationMs = 1000,
    double heightCells = cinematicTimelineDefaultActorJumpHeightCells,
    CinematicTimelineActorFacingMode facingMode =
        CinematicTimelineActorFacingMode.followMovement,
  }) => _added(
    (a) => addCinematicTimelineActorJumpStep(
      _with(a),
      cinematicId: a.id,
      actorId: actorId,
      targetId: targetId,
      afterStepId: afterStepId,
      durationMs: durationMs,
      heightCells: heightCells,
      facingMode: facingMode,
    ).cinematic,
  );
  String? addEmote(
    String actorId, {
    String? afterStepId,
    String emoteId = cinematicDefaultActorEmoteId,
    int? durationMs,
  }) => _added(
    (a) => addCinematicTimelineActorEmoteStep(
      _with(a),
      cinematicId: a.id,
      actorId: actorId,
      emoteId: emoteId,
      durationMs: durationMs,
      afterStepId: afterStepId,
    ).cinematic,
  );
  String? addCommand(
    CinematicTimelineStepKind kind, {
    String? afterStepId,
    String? label,
    String? actorId,
    String? dialogueId,
    String? dialogueText,
    CinematicMediaAsset? mediaAsset,
    int? durationMs,
    SpatialVisualPatch? visualSettings,
    double volume = 1,
    int fadeMs = 0,
    bool loop = false,
    double intensity = .5,
  }) => _added(
    (a) => addCinematicTimelineCommandStep(
      a,
      kind: kind,
      afterStepId: afterStepId,
      label: label,
      actorId: actorId,
      dialogueId: dialogueId,
      dialogueText: dialogueText,
      mediaAsset: mediaAsset,
      durationMs: durationMs,
      visualSettings: visualSettings,
      volume: volume,
      fadeMs: fadeMs,
      loop: loop,
      intensity: intensity,
    ).cinematic,
  );
  bool updateDuration(String stepId, int durationMs) => edit((a) {
    if (durationMs <= 0) {
      throw ArgumentError('La durée doit être strictement positive.');
    }
    final s = a.timeline.steps.firstWhere((s) => s.id == stepId);
    if (s.kind == CinematicTimelineStepKind.atmosphere) {
      return updateCinematicTimelineCommandStep(a, stepId: stepId, durationMs: durationMs).cinematic;
    }
    if (isCinematicTimelineBasicBlockStep(s)) {
      return updateCinematicTimelineBasicBlockStep(
        _with(a),
        cinematicId: a.id,
        stepId: stepId,
        durationMs: durationMs,
      ).cinematic;
    }
    if (isCinematicTimelineActorJumpStep(s)) {
      return updateCinematicTimelineActorJumpStep(
        _with(a),
        cinematicId: a.id,
        stepId: stepId,
        durationMs: durationMs,
      ).cinematic;
    }
    if (isCinematicTimelineActorMoveStep(s)) {
      return updateCinematicTimelineActorMoveStep(
        _with(a),
        cinematicId: a.id,
        stepId: stepId,
        durationMs: durationMs,
      ).cinematic;
    }
    if (isCinematicTimelineActorEmoteStep(s)) {
      return updateCinematicTimelineActorEmoteStep(
        _with(a),
        cinematicId: a.id,
        stepId: stepId,
        durationMs: durationMs,
      ).cinematic;
    }
    if (isCinematicTimelineCommandStep(s)) {
      return updateCinematicTimelineCommandStep(
        a,
        stepId: stepId,
        durationMs: durationMs,
      ).cinematic;
    }
    throw ArgumentError(
      'Cette étape ne possède pas de durée éditable par ce contrat.',
    );
  });
}
