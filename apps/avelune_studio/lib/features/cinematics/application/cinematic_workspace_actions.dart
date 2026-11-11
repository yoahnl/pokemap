part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspaceActions on CinematicWorkspaceController {
  Future<String?> addAction(
    CinematicTimelineStepKind kind, {
    String? actorId,
    String? afterStepId,
    CinematicActorDisplayPreviewModel? actorDisplay,
    required Future<String?> Function(String title, Map<String, String> options)
    choose,
    bool Function()? isActive,
    bool flushInputs = false,
  }) async {
    final owner = _active;
    if (_closed || owner == null) return null;
    if (flushInputs) {
      final sourceProject = narrative.workspace.project;
      if (flushEdits?.call() == false ||
          _closed ||
          !identical(_active, owner) ||
          !identical(narrative.workspace.project, sourceProject) ||
          isActive?.call() == false) {
        return null;
      }
    }
    final asset = owner.asset;
    bool currentRequest() =>
        !_closed && identical(_active, owner) && (isActive?.call() ?? true);
    final after = afterStepId;
    String? id;
    switch (kind) {
      case CinematicTimelineStepKind.atmosphere:
        id = addCommand(
          kind,
          afterStepId: after,
          durationMs: 1000,
          visualSettings: SpatialVisualPatch({
            SpatialVisualParameter.depthOfFieldEnabled: true,
          }),
        );
      case CinematicTimelineStepKind.wait:
        id = addBasic(
          CinematicTimelineBasicBlockKind.wait,
          afterStepId: after,
          durationMs: 1000,
        );
      case CinematicTimelineStepKind.camera:
        id = addBasic(
          CinematicTimelineBasicBlockKind.camera,
          afterStepId: after,
          durationMs: 1000,
          cameraMode: CinematicTimelineCameraMode.focus,
          cameraFocusBinding: CinematicTimelineCameraFocusBinding(
            target: CinematicCameraTargetBinding.sceneCenter(),
            zoomPreset: CinematicCameraZoomPreset.medium,
          ),
        );
      case CinematicTimelineStepKind.fade:
        id = addBasic(
          CinematicTimelineBasicBlockKind.fade,
          afterStepId: after,
          durationMs: 600,
        );
      case CinematicTimelineStepKind.actorMove:
        final actor = actorId;
        if (actor == null) {
          _fail('Ajoutez et sélectionnez un acteur.');
          break;
        }
        final target =
            asset.movementTargets.firstOrNull?.targetId ??
            addTarget('Destination à choisir');
        if (target != null) {
          id = addMove(actor, target, afterStepId: after);
        }
      case CinematicTimelineStepKind.actorJump:
        final actor = actorId;
        if (actor == null) {
          _fail('Ajoutez et sélectionnez un acteur.');
          break;
        }
        final target =
            asset.movementTargets.firstOrNull?.targetId ??
            addTarget('Destination du saut');
        if (target != null) {
          id = addJump(actor, target, afterStepId: after);
        }
      case CinematicTimelineStepKind.actorFace:
        if (actorId == null) {
          _fail('Sélectionnez un acteur.');
          break;
        }
        id = addFace(
          actorId,
          CinematicTimelineActorFacingDirection.down,
          afterStepId: after,
        );
      case CinematicTimelineStepKind.actorEmote:
        if (actorId == null) {
          _fail('Sélectionnez un acteur.');
          break;
        }
        id = addEmote(actorId, afterStepId: after, durationMs: 1000);
      case CinematicTimelineStepKind.dialogueLine:
        final selected = await choose('Dialogue', {
          for (final d in project.dialogues) d.id: d.name,
        });
        if (selected != null && currentRequest()) {
          id = addCommand(kind, dialogueId: selected, afterStepId: after);
        }
      case CinematicTimelineStepKind.sound ||
          CinematicTimelineStepKind.music ||
          CinematicTimelineStepKind.fx:
        final type = kind == CinematicTimelineStepKind.sound
            ? CinematicMediaAssetKind.sound
            : kind == CinematicTimelineStepKind.music
            ? CinematicMediaAssetKind.music
            : CinematicMediaAssetKind.cinematicFx;
        final media = project.cinematicMediaAssets
            .where((m) => m.kind == type)
            .toList();
        final selected = await choose('Média disponible', {
          for (final m in media) m.id: m.label,
        });
        if (selected != null && currentRequest()) {
          id = addCommand(
            kind,
            mediaAsset: media.firstWhere((m) => m.id == selected),
            afterStepId: after,
          );
        }
      case CinematicTimelineStepKind.marker || CinematicTimelineStepKind.shake:
        id = addCommand(
          kind,
          afterStepId: after,
          durationMs: kind == CinematicTimelineStepKind.shake ? 600 : null,
          label: kind == CinematicTimelineStepKind.marker ? 'Repère' : null,
        );
      case CinematicTimelineStepKind.actorAnimation:
        final characterId =
            actorDisplay?.actorById(actorId ?? '')?.appearance.characterId ??
            asset.stageContext?.actorAppearanceBindings
                .where((b) => b.actorId == actorId)
                .firstOrNull
                ?.characterId;
        final character = project.characters
            .where((c) => c.id == characterId)
            .firstOrNull;
        final clips = character?.customAnimations ?? const [];
        final selected = await choose('Animation disponible', {
          for (var i = 0; i < clips.length; i++)
            '$i':
                '${project.characterStudioCatalog.customAnimationDefinitions.where((d) => d.id == clips[i].definitionId).firstOrNull?.displayName ?? clips[i].definitionId}${clips[i].direction == null ? '' : ' · ${clips[i].direction!.name}'}',
        });
        if (selected != null && currentRequest() && actorId != null) {
          final clip = clips[int.parse(selected)];
          id = addAnimation(
            CharacterCustomAnimationRuntimeCommand(
              actorId: actorId,
              definitionId: clip.definitionId,
              direction: clip.direction,
            ),
            afterStepId: after,
          );
        }
    }
    return id;
  }

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
      return updateCinematicTimelineCommandStep(
        a,
        stepId: stepId,
        durationMs: durationMs,
      ).cinematic;
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
