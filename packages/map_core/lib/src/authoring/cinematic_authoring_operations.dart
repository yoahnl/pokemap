import '../models/cinematic_asset.dart';
import '../models/cinematic_emote_catalog.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';

final class CinematicAssetAuthoringResult {
  const CinematicAssetAuthoringResult({
    required this.updatedProject,
    required this.cinematic,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
}

final class CinematicAssetRemovalResult {
  const CinematicAssetRemovalResult({
    required this.updatedProject,
    required this.removedCinematic,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset removedCinematic;
}

final class CinematicRequiredActorResult {
  const CinematicRequiredActorResult({
    required this.updatedProject,
    required this.cinematic,
    required this.actor,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicActorRef actor;
}

final class CinematicMovementTargetResult {
  const CinematicMovementTargetResult({
    required this.updatedProject,
    required this.cinematic,
    required this.target,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicMovementTargetRef target;
}

final class CinematicMovementTargetRemovalResult {
  const CinematicMovementTargetRemovalResult({
    required this.updatedProject,
    required this.cinematic,
    required this.removedTarget,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicMovementTargetRef removedTarget;
}

final class CinematicStageContextAuthoringResult {
  const CinematicStageContextAuthoringResult({
    required this.updatedProject,
    required this.cinematic,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
}

final class CinematicTimelineDraftStepResult {
  const CinematicTimelineDraftStepResult({
    required this.updatedProject,
    required this.cinematic,
    required this.step,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep step;
}

final class CinematicTimelineDraftStepRemovalResult {
  const CinematicTimelineDraftStepRemovalResult({
    required this.updatedProject,
    required this.cinematic,
    required this.removedStep,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep removedStep;
}

final class CinematicTimelineBasicBlockStepResult {
  const CinematicTimelineBasicBlockStepResult({
    required this.updatedProject,
    required this.cinematic,
    required this.step,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep step;
}

final class CinematicTimelineActorMoveStepResult {
  const CinematicTimelineActorMoveStepResult({
    required this.updatedProject,
    required this.cinematic,
    required this.step,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep step;
}

final class CinematicTimelineActorEmoteStepResult {
  const CinematicTimelineActorEmoteStepResult({
    required this.updatedProject,
    required this.cinematic,
    required this.step,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep step;
}

final class CinematicTimelineStepUpdateResult {
  const CinematicTimelineStepUpdateResult({
    required this.updatedProject,
    required this.cinematic,
    required this.step,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep step;
}

final class CinematicTimelineAuthoringStepRemovalResult {
  const CinematicTimelineAuthoringStepRemovalResult({
    required this.updatedProject,
    required this.cinematic,
    required this.removedStep,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
  final CinematicTimelineStep removedStep;
}

enum CinematicTimelineBasicBlockKind {
  wait,
  fade,
  camera,
}

enum CinematicTimelineFadeMode {
  fadeIn,
  fadeOut,
}

enum CinematicTimelineCameraMode {
  reset,
  hold,
  focus,
}

enum CinematicCameraTargetKind {
  sceneCenter,
  actor,
  stagePoint,
}

enum CinematicCameraZoomPreset {
  wide,
  medium,
  close,
}

final class CinematicCameraTargetBinding {
  const CinematicCameraTargetBinding._({
    required this.kind,
    this.actorId,
    this.stagePointId,
    this.label,
  });

  factory CinematicCameraTargetBinding.sceneCenter({
    String? label,
  }) {
    return CinematicCameraTargetBinding._(
      kind: CinematicCameraTargetKind.sceneCenter,
      label: _trimOptional(label),
    );
  }

  factory CinematicCameraTargetBinding.actor({
    required String actorId,
    String? label,
  }) {
    return CinematicCameraTargetBinding._(
      kind: CinematicCameraTargetKind.actor,
      actorId: _trimRequired(
        actorId,
        'actorId',
        'Camera actor focus requires an actorId.',
      ),
      label: _trimOptional(label),
    );
  }

  factory CinematicCameraTargetBinding.stagePoint({
    required String stagePointId,
    String? label,
  }) {
    return CinematicCameraTargetBinding._(
      kind: CinematicCameraTargetKind.stagePoint,
      stagePointId: _trimRequired(
        stagePointId,
        'stagePointId',
        'Camera stage point focus requires a stagePointId.',
      ),
      label: _trimOptional(label),
    );
  }

  final CinematicCameraTargetKind kind;
  final String? actorId;
  final String? stagePointId;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicCameraTargetBinding &&
          other.kind == kind &&
          other.actorId == actorId &&
          other.stagePointId == stagePointId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, actorId, stagePointId, label);
}

final class CinematicTimelineCameraFocusBinding {
  const CinematicTimelineCameraFocusBinding({
    required this.target,
    required this.zoomPreset,
  });

  final CinematicCameraTargetBinding target;
  final CinematicCameraZoomPreset zoomPreset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicTimelineCameraFocusBinding &&
          other.target == target &&
          other.zoomPreset == zoomPreset;

  @override
  int get hashCode => Object.hash(target, zoomPreset);
}

enum CinematicTimelineActorFacingDirection {
  up,
  down,
  left,
  right,
}

enum CinematicTimelineActorMovementMode {
  walk,
  run,
}

enum CinematicTimelineActorPathMode {
  direct,
  manual,
}

const cinematicTimelineDraftMetadataKindKey = 'authoring.kind';
const cinematicTimelineDraftMetadataKindValue = 'draft';
const cinematicTimelineBasicBlockMetadataKindValue = 'basicBlock';
const cinematicTimelineDraftMetadataSourceKey = 'authoring.source';
const cinematicTimelineDraftMetadataSourceValue = 'cinematic-builder-v0';
const cinematicTimelineAuthoringBlockMetadataKey = 'authoring.block';
const cinematicTimelineFadeModeMetadataKey = 'fade.mode';
const cinematicTimelineCameraModeMetadataKey = 'camera.mode';
const cinematicTimelineCameraTargetKindMetadataKey = 'camera.targetKind';
const cinematicTimelineCameraTargetActorIdMetadataKey = 'camera.targetActorId';
const cinematicTimelineCameraTargetStagePointIdMetadataKey =
    'camera.targetStagePointId';
const cinematicTimelineCameraZoomPresetMetadataKey = 'camera.zoomPreset';
const cinematicTimelineActorDirectionMetadataKey = 'actor.direction';
const cinematicTimelineActorFaceBlockMetadataValue = 'actorFace';
const cinematicTimelineActorMoveBlockMetadataValue = 'actorMove';
const cinematicTimelineActorEmoteBlockMetadataValue = 'actorEmote';
const cinematicTimelineActorMovementModeMetadataKey = 'actor.movementMode';
const cinematicTimelineActorPathModeMetadataKey = 'actor.pathMode';
const cinematicTimelineActorEmoteEmoteIdMetadataKey = 'actor.emoteId';

const cinematicTimelineDefaultWaitDurationMs = 1000;
const cinematicTimelineDefaultFadeDurationMs = 1000;
const cinematicTimelineDefaultCameraDurationMs = 500;
const cinematicTimelineDefaultActorMoveDurationMs = 1000;
const cinematicTimelineDefaultActorEmoteDurationMs = 800;
const cinematicTimelineMinimumDurationMs = 100;
const cinematicTimelineActorMoveMinimumDurationMs = 200;
const cinematicTimelineMaximumDurationMs = 30000;

CinematicAssetAuthoringResult addCinematicAsset(
  ProjectManifest project,
  CinematicAsset cinematic,
) {
  _validateCinematicShape(cinematic);
  _throwIfDuplicateId(
    cinematic.id,
    project.cinematics.map((asset) => asset.id),
  );

  return CinematicAssetAuthoringResult(
    updatedProject: project.copyWith(
      cinematics: [...project.cinematics, cinematic],
    ),
    cinematic: cinematic,
  );
}

CinematicAssetAuthoringResult updateCinematicAsset(
  ProjectManifest project,
  CinematicAsset cinematic,
) {
  _validateCinematicShape(cinematic);
  var found = false;
  final updatedCinematics = <CinematicAsset>[];
  for (final existing in project.cinematics) {
    if (existing.id == cinematic.id) {
      updatedCinematics.add(cinematic);
      found = true;
    } else {
      updatedCinematics.add(existing);
    }
  }
  if (!found) {
    throw ArgumentError.value(
      cinematic.id,
      'cinematic.id',
      'CinematicAsset update references an unknown cinematic.',
    );
  }

  return CinematicAssetAuthoringResult(
    updatedProject: project.copyWith(cinematics: updatedCinematics),
    cinematic: cinematic,
  );
}

CinematicAssetRemovalResult removeCinematicAsset(
  ProjectManifest project,
  String cinematicId,
) {
  final id = _trimRequired(
    cinematicId,
    'cinematicId',
    'Cinematic removal requires a cinematic id.',
  );
  final referencedSceneIds = _sceneIdsReferencingCinematic(project, id);
  if (referencedSceneIds.isNotEmpty) {
    throw ArgumentError.value(
      cinematicId,
      'cinematicId',
      'CinematicAsset is still referenced by Scene(s): '
          '${referencedSceneIds.join(', ')}.',
    );
  }

  CinematicAsset? removed;
  final remaining = <CinematicAsset>[];
  for (final cinematic in project.cinematics) {
    if (cinematic.id == id) {
      removed = cinematic;
    } else {
      remaining.add(cinematic);
    }
  }
  final removedCinematic = removed;
  if (removedCinematic == null) {
    throw ArgumentError.value(
      cinematicId,
      'cinematicId',
      'CinematicAsset removal references an unknown cinematic.',
    );
  }

  return CinematicAssetRemovalResult(
    updatedProject: project.copyWith(cinematics: remaining),
    removedCinematic: removedCinematic,
  );
}

ProjectManifest replaceCinematics(
  ProjectManifest project,
  List<CinematicAsset> cinematics,
) {
  _validateCinematics(cinematics);
  return project.copyWith(cinematics: [...cinematics]);
}

CinematicAsset? findCinematicById(
  ProjectManifest project,
  String cinematicId,
) {
  final id = cinematicId.trim();
  for (final cinematic in project.cinematics) {
    if (cinematic.id == id) {
      return cinematic;
    }
  }
  return null;
}

CinematicStageContextAuthoringResult updateCinematicStageMap(
  ProjectManifest project, {
  required String cinematicId,
  String? mapId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final updatedCinematic = _copyCinematicWithStageMap(
    cinematic,
    _trimOptional(mapId),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult updateCinematicStageContext(
  ProjectManifest project, {
  required String cinematicId,
  CinematicStageContext? stageContext,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  if (stageContext != null) {
    _validateStageContextForAuthoring(cinematic, stageContext);
  }
  final updatedCinematic = _copyCinematicWithStageContext(
    cinematic,
    stageContext,
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult upsertCinematicActorBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorBinding binding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  _requireActor(cinematic, binding.actorId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = <CinematicActorBinding>[];
  var replaced = false;
  for (final existing in context.actorBindings) {
    if (existing.actorId == binding.actorId) {
      bindings.add(binding);
      replaced = true;
    } else {
      bindings.add(existing);
    }
  }
  if (!replaced) {
    bindings.add(binding);
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: bindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicActorBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor binding removal requires an actor id.',
  );
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = context.actorBindings
      .where((binding) => binding.actorId != id)
      .toList(growable: false);
  if (bindings.length == context.actorBindings.length) {
    throw ArgumentError.value(
      actorId,
      'actorId',
      'Actor binding removal references an unknown binding.',
    );
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: bindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult upsertCinematicActorAppearanceBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  _requireActor(cinematic, binding.actorId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  _requireCinematicOnlyActorBinding(context, binding.actorId);

  final bindings = <CinematicActorAppearanceBinding>[];
  var replaced = false;
  for (final existing in context.actorAppearanceBindings) {
    if (existing.actorId == binding.actorId) {
      bindings.add(binding);
      replaced = true;
    } else {
      bindings.add(existing);
    }
  }
  if (!replaced) {
    bindings.add(binding);
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: bindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicActorAppearanceBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor appearance binding removal requires an actor id.',
  );
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = context.actorAppearanceBindings
      .where((binding) => binding.actorId != id)
      .toList(growable: false);
  if (bindings.length == context.actorAppearanceBindings.length) {
    throw ArgumentError.value(
      actorId,
      'actorId',
      'Actor appearance binding removal references an unknown binding.',
    );
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: bindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult upsertCinematicActorInitialPlacement(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorInitialPlacement placement,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  _requireActor(cinematic, placement.actorId);
  if (placement.kind == CinematicActorInitialPlacementKind.fromMovementTarget) {
    _requireMovementTarget(cinematic, placement.targetId ?? '');
  }
  final context = cinematic.stageContext ?? CinematicStageContext();
  final placements = <CinematicActorInitialPlacement>[];
  var replaced = false;
  for (final existing in context.initialPlacements) {
    if (existing.actorId == placement.actorId) {
      placements.add(placement);
      replaced = true;
    } else {
      placements.add(existing);
    }
  }
  if (!replaced) {
    placements.add(placement);
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: placements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicActorInitialPlacement(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor initial placement removal requires an actor id.',
  );
  final context = cinematic.stageContext ?? CinematicStageContext();
  final placements = context.initialPlacements
      .where((placement) => placement.actorId != id)
      .toList(growable: false);
  if (placements.length == context.initialPlacements.length) {
    throw ArgumentError.value(
      actorId,
      'actorId',
      'Actor initial placement removal references an unknown placement.',
    );
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: placements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult upsertCinematicMovementTargetBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicMovementTargetBinding binding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  _requireMovementTarget(cinematic, binding.targetId);
  if (_movementTargetBindingRequiresSource(binding) &&
      binding.sourceId == null) {
    throw ArgumentError.value(
      binding.sourceId,
      'sourceId',
      'Map-aware movement target bindings require a source id.',
    );
  }
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = <CinematicMovementTargetBinding>[];
  var replaced = false;
  for (final existing in context.movementTargetBindings) {
    if (existing.targetId == binding.targetId) {
      bindings.add(binding);
      replaced = true;
    } else {
      bindings.add(existing);
    }
  }
  if (!replaced) {
    bindings.add(binding);
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: bindings,
    stagePoints: context.stagePoints,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicMovementTargetBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String targetId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    targetId,
    'targetId',
    'Movement target binding removal requires a target id.',
  );
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = context.movementTargetBindings
      .where((binding) => binding.targetId != id)
      .toList(growable: false);
  if (bindings.length == context.movementTargetBindings.length) {
    throw ArgumentError.value(
      targetId,
      'targetId',
      'Movement target binding removal references an unknown binding.',
    );
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: bindings,
    stagePoints: context.stagePoints,
  );
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult addCinematicStagePoint(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicStagePoint point,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  final id = point.id.trim();
  final label = point.label.trim();
  if (id.isEmpty) {
    throw ArgumentError('Stage point ID must not be empty.');
  }
  if (label.isEmpty) {
    throw ArgumentError('Stage point label must not be empty.');
  }
  if (!point.x.isFinite || !point.y.isFinite) {
    throw ArgumentError('Stage point coordinates must be finite.');
  }
  if (context.stagePoints.any((p) => p.id == id)) {
    throw ArgumentError('Duplicate stage point ID: $id');
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: [...context.stagePoints, point],
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult updateCinematicStagePoint(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicStagePoint point,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  final id = point.id.trim();
  final label = point.label.trim();
  if (id.isEmpty) {
    throw ArgumentError('Stage point ID must not be empty.');
  }
  if (label.isEmpty) {
    throw ArgumentError('Stage point label must not be empty.');
  }
  if (!point.x.isFinite || !point.y.isFinite) {
    throw ArgumentError('Stage point coordinates must be finite.');
  }
  final updatedPoints = <CinematicStagePoint>[];
  var found = false;
  for (final p in context.stagePoints) {
    if (p.id == id) {
      updatedPoints.add(point);
      found = true;
    } else {
      updatedPoints.add(p);
    }
  }
  if (!found) {
    throw ArgumentError('Stage point ID "$id" not found in cinematic.');
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: updatedPoints,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicStagePoint(
  ProjectManifest project, {
  required String cinematicId,
  required String stagePointId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  final id = stagePointId.trim();
  if (id.isEmpty) {
    throw ArgumentError('Stage point ID must not be empty.');
  }
  final updatedPoints = context.stagePoints.where((p) => p.id != id).toList();
  if (updatedPoints.length == context.stagePoints.length) {
    throw ArgumentError('Stage point ID "$id" not found in cinematic.');
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: updatedPoints,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicRequiredActorResult addCinematicRequiredActor(
  ProjectManifest project, {
  required String cinematicId,
  String label = 'Acteur',
  String? role,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final actorLabel = _trimRequired(
    label,
    'label',
    'Required actor authoring requires a readable label.',
  );
  final actor = CinematicActorRef(
    actorId: _nextRequiredActorId(cinematic),
    label: actorLabel,
    role: role,
  );
  final updatedCinematic = _copyCinematicWithActors(
    cinematic,
    [...cinematic.requiredActors, actor],
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicRequiredActorResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    actor: actor,
  );
}

CinematicRequiredActorResult renameCinematicRequiredActor(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
  required String label,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final currentActor = _requireActor(cinematic, actorId);
  final actorLabel = _trimRequired(
    label,
    'label',
    'Required actor authoring requires a readable label.',
  );
  final renamedActor = CinematicActorRef(
    actorId: currentActor.actorId,
    label: actorLabel,
    entityId: currentActor.entityId,
    role: currentActor.role,
  );
  final updatedActors = [
    for (final actor in cinematic.requiredActors)
      if (actor.actorId == currentActor.actorId) renamedActor else actor,
  ];
  final updatedCinematic = _copyCinematicWithActors(
    cinematic,
    updatedActors,
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicRequiredActorResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    actor: renamedActor,
  );
}

CinematicRequiredActorResult removeCinematicRequiredActor(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final actor = _requireActor(cinematic, actorId);
  _requireActorUnusedByTimeline(cinematic, actor.actorId);
  final updatedCinematic = _copyCinematicWithStageContext(
    _copyCinematicWithActors(
      cinematic,
      cinematic.requiredActors
          .where((candidate) => candidate.actorId != actor.actorId)
          .toList(growable: false),
    ),
    _stageContextWithoutActor(cinematic.stageContext, actor.actorId),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicRequiredActorResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    actor: actor,
  );
}

CinematicMovementTargetResult addCinematicMovementTarget(
  ProjectManifest project, {
  required String cinematicId,
  String label = 'Cible',
  String? description,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final targetLabel = _trimRequired(
    label,
    'label',
    'Movement target authoring requires a readable label.',
  );
  final target = CinematicMovementTargetRef(
    targetId: _nextMovementTargetId(cinematic),
    label: targetLabel,
    description: description,
  );
  final updatedCinematic = _copyCinematicWithMovementTargets(
    cinematic,
    [...cinematic.movementTargets, target],
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicMovementTargetResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    target: target,
  );
}

CinematicMovementTargetResult updateCinematicMovementTarget(
  ProjectManifest project, {
  required String cinematicId,
  required String targetId,
  required String label,
  String? description,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    targetId,
    'targetId',
    'Movement target update requires a target id.',
  );
  final targetLabel = _trimRequired(
    label,
    'label',
    'Movement target update requires a readable label.',
  );
  final targets = <CinematicMovementTargetRef>[];
  CinematicMovementTargetRef? updatedTarget;
  for (final existing in cinematic.movementTargets) {
    if (existing.targetId == id) {
      updatedTarget = CinematicMovementTargetRef(
        targetId: existing.targetId,
        label: targetLabel,
        description: description,
      );
      targets.add(updatedTarget);
    } else {
      targets.add(existing);
    }
  }
  final target = updatedTarget;
  if (target == null) {
    throw ArgumentError.value(
      targetId,
      'targetId',
      'Movement target update references an unknown target.',
    );
  }

  final updatedCinematic = _copyCinematicWithMovementTargets(
    cinematic,
    targets,
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicMovementTargetResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    target: target,
  );
}

CinematicMovementTargetRemovalResult removeCinematicMovementTarget(
  ProjectManifest project, {
  required String cinematicId,
  required String targetId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    targetId,
    'targetId',
    'Movement target removal requires a target id.',
  );
  final isUsed = cinematic.timeline.steps.any(
    (step) =>
        step.kind == CinematicTimelineStepKind.actorMove && step.targetId == id,
  );
  if (isUsed) {
    throw ArgumentError.value(
      targetId,
      'targetId',
      'Movement target is still used by an actorMove step.',
    );
  }

  CinematicMovementTargetRef? removedTarget;
  final targets = <CinematicMovementTargetRef>[];
  for (final target in cinematic.movementTargets) {
    if (target.targetId == id) {
      removedTarget = target;
    } else {
      targets.add(target);
    }
  }
  final removed = removedTarget;
  if (removed == null) {
    throw ArgumentError.value(
      targetId,
      'targetId',
      'Movement target removal references an unknown target.',
    );
  }

  final updatedCinematic = _copyCinematicWithMovementTargets(
    cinematic,
    targets,
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicMovementTargetRemovalResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    removedTarget: removed,
  );
}

CinematicMovementTargetRef? findCinematicMovementTargetById(
  CinematicAsset cinematic,
  String targetId,
) {
  final id = targetId.trim();
  for (final target in cinematic.movementTargets) {
    if (target.targetId == id) {
      return target;
    }
  }
  return null;
}

CinematicTimelineDraftStepResult addCinematicTimelineDraftStep(
  ProjectManifest project, {
  required String cinematicId,
  String? afterStepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final steps = cinematic.timeline.steps.toList();
  final insertIndex = _timelineInsertIndex(
    steps,
    afterStepId,
    argumentName: 'afterStepId',
    message: 'Draft insertion references an unknown timeline step.',
  );

  final draft = CinematicTimelineStep(
    id: _nextTimelineStepId(cinematic, 'step_draft'),
    kind: CinematicTimelineStepKind.marker,
    label: 'Bloc brouillon',
    metadata: const {
      cinematicTimelineDraftMetadataKindKey:
          cinematicTimelineDraftMetadataKindValue,
      cinematicTimelineDraftMetadataSourceKey:
          cinematicTimelineDraftMetadataSourceValue,
    },
  );
  steps.insert(insertIndex, draft);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineDraftStepResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: draft,
  );
}

CinematicTimelineDraftStepRemovalResult removeCinematicTimelineDraftStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    stepId,
    'stepId',
    'Draft removal requires a timeline step id.',
  );
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == id);
  if (index == -1) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Draft removal references an unknown timeline step.',
    );
  }
  final removedStep = steps[index];
  if (!isCinematicTimelineDraftStep(removedStep)) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Only authoring draft timeline steps can be removed here.',
    );
  }
  steps.removeAt(index);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineDraftStepRemovalResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    removedStep: removedStep,
  );
}

CinematicTimelineBasicBlockStepResult addCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicTimelineBasicBlockKind blockKind,
  String? afterStepId,
  int? durationMs,
  CinematicTimelineFadeMode fadeMode = CinematicTimelineFadeMode.fadeIn,
  CinematicTimelineCameraMode cameraMode = CinematicTimelineCameraMode.reset,
  CinematicTimelineCameraFocusBinding? cameraFocusBinding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  if (blockKind != CinematicTimelineBasicBlockKind.camera &&
      cameraFocusBinding != null) {
    throw ArgumentError(
      'Only camera blocks can receive a camera focus binding.',
    );
  }
  if (blockKind == CinematicTimelineBasicBlockKind.camera &&
      cameraMode == CinematicTimelineCameraMode.focus) {
    _validateCameraFocusBinding(cinematic, cameraFocusBinding);
  }
  final steps = cinematic.timeline.steps.toList();
  final insertIndex = _timelineInsertIndex(
    steps,
    afterStepId,
    argumentName: 'afterStepId',
    message: 'Basic block insertion references an unknown timeline step.',
  );
  final step = _buildBasicBlockStep(
    cinematic,
    blockKind: blockKind,
    durationMs: durationMs,
    fadeMode: fadeMode,
    cameraMode: cameraMode,
    cameraFocusBinding: cameraFocusBinding,
  );
  steps.insert(insertIndex, step);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineBasicBlockStepResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: step,
  );
}

CinematicTimelineBasicBlockStepResult addCinematicTimelineCameraFocusStep(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicCameraTargetBinding target,
  required CinematicCameraZoomPreset zoomPreset,
  String? afterStepId,
  int? durationMs,
}) {
  return addCinematicTimelineBasicBlockStep(
    project,
    cinematicId: cinematicId,
    blockKind: CinematicTimelineBasicBlockKind.camera,
    afterStepId: afterStepId,
    durationMs: durationMs,
    cameraMode: CinematicTimelineCameraMode.focus,
    cameraFocusBinding: CinematicTimelineCameraFocusBinding(
      target: target,
      zoomPreset: zoomPreset,
    ),
  );
}

CinematicTimelineStepUpdateResult updateCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
  CinematicTimelineCameraFocusBinding? cameraFocusBinding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    stepId,
    'stepId',
    'Basic block update requires a timeline step id.',
  );
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == id);
  if (index == -1) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Basic block update references an unknown timeline step.',
    );
  }
  final step = steps[index];
  final blockKind = cinematicTimelineBasicBlockKindOf(step);
  if (blockKind == null) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Only Cinematic Builder V0 basic blocks can be updated here.',
    );
  }
  if (blockKind != CinematicTimelineBasicBlockKind.camera &&
      cameraFocusBinding != null) {
    throw ArgumentError(
      'Only camera blocks can receive a camera focus binding.',
    );
  }
  if (blockKind == CinematicTimelineBasicBlockKind.camera &&
      (cameraMode == CinematicTimelineCameraMode.focus ||
          cameraFocusBinding != null)) {
    _validateCameraFocusBinding(cinematic, cameraFocusBinding);
  }
  final updatedStep = _copyBasicBlockStepWithParams(
    step,
    blockKind: blockKind,
    durationMs: durationMs,
    fadeMode: fadeMode,
    cameraMode: cameraMode,
    cameraFocusBinding: cameraFocusBinding,
  );
  steps[index] = updatedStep;

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineStepUpdateResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: updatedStep,
  );
}

CinematicTimelineBasicBlockStepResult addCinematicTimelineActorFacingStep(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
  required CinematicTimelineActorFacingDirection direction,
  String? afterStepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final actor = _requireActor(cinematic, actorId);
  final steps = cinematic.timeline.steps.toList();
  final insertIndex = _timelineInsertIndex(
    steps,
    afterStepId,
    argumentName: 'afterStepId',
    message: 'Actor facing insertion references an unknown timeline step.',
  );
  final step = _buildActorFacingStep(
    cinematic,
    actor: actor,
    direction: direction,
  );
  steps.insert(insertIndex, step);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineBasicBlockStepResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: step,
  );
}

CinematicTimelineStepUpdateResult updateCinematicTimelineActorFacingStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  String? actorId,
  CinematicTimelineActorFacingDirection? direction,
  int? durationMs,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    stepId,
    'stepId',
    'Actor facing update requires a timeline step id.',
  );
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == id);
  if (index == -1) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Actor facing update references an unknown timeline step.',
    );
  }
  final step = steps[index];
  if (!isCinematicTimelineActorFacingStep(step)) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Only Cinematic Builder V0 actor facing blocks can be updated here.',
    );
  }

  final actor = actorId == null
      ? _requireActor(cinematic, step.actorId ?? '')
      : _requireActor(cinematic, actorId);
  final updatedDirection = direction ??
      cinematicTimelineActorFacingDirectionOf(
        step,
      );
  if (updatedDirection == null) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Actor facing update requires a valid current direction.',
    );
  }

  final metadata = Map<String, String>.of(step.metadata)
    ..[cinematicTimelineActorDirectionMetadataKey] = updatedDirection.name;
  final updatedStep = CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: _actorFacingLabel(actor),
    durationMs: durationMs == null
        ? step.durationMs
        : _validateDuration(
            durationMs,
            argumentName: 'durationMs',
            minMs: cinematicTimelineMinimumDurationMs,
          ),
    actorId: actor.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: metadata,
  );
  steps[index] = updatedStep;

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineStepUpdateResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: updatedStep,
  );
}

CinematicTimelineActorMoveStepResult addCinematicTimelineActorMoveStep(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
  required String targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode movementMode =
      CinematicTimelineActorMovementMode.walk,
  String? afterStepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final actor = _requireActor(cinematic, actorId);
  final target = _requireMovementTarget(cinematic, targetId);
  final steps = cinematic.timeline.steps.toList();
  final insertIndex = _timelineInsertIndex(
    steps,
    afterStepId,
    argumentName: 'afterStepId',
    message: 'Actor move insertion references an unknown timeline step.',
  );
  final step = _buildActorMoveStep(
    cinematic,
    actor: actor,
    target: target,
    durationMs: durationMs ?? cinematicTimelineDefaultActorMoveDurationMs,
    movementMode: movementMode,
  );
  steps.insert(insertIndex, step);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineActorMoveStepResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: step,
  );
}

CinematicTimelineStepUpdateResult updateCinematicTimelineActorMoveStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode? movementMode,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    stepId,
    'stepId',
    'Actor move update requires a timeline step id.',
  );
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == id);
  if (index == -1) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Actor move update references an unknown timeline step.',
    );
  }
  final step = steps[index];
  if (!isCinematicTimelineActorMoveStep(step)) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Only Cinematic Builder V0 actor move blocks can be updated here.',
    );
  }

  final actor = actorId == null
      ? _requireActor(cinematic, step.actorId ?? '')
      : _requireActor(cinematic, actorId);
  final target = targetId == null
      ? _requireMovementTarget(cinematic, step.targetId ?? '')
      : _requireMovementTarget(cinematic, targetId);
  final updatedMovementMode =
      movementMode ?? cinematicTimelineActorMovementModeOf(step);
  if (updatedMovementMode == null) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Actor move update requires a valid current movement mode.',
    );
  }

  final metadata = Map<String, String>.of(step.metadata)
    ..[cinematicTimelineActorMovementModeMetadataKey] = updatedMovementMode.name
    ..[cinematicTimelineActorPathModeMetadataKey] =
        CinematicTimelineActorPathMode.direct.name;
  final updatedStep = CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: _actorMoveLabel(actor),
    durationMs: durationMs == null
        ? step.durationMs
        : _validateDuration(
            durationMs,
            argumentName: 'durationMs',
            minMs: cinematicTimelineActorMoveMinimumDurationMs,
          ),
    actorId: actor.actorId,
    targetId: target.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: metadata,
  );
  steps[index] = updatedStep;

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineStepUpdateResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: updatedStep,
  );
}

CinematicTimelineActorEmoteStepResult addCinematicTimelineActorEmoteStep(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
  String emoteId = cinematicDefaultActorEmoteId,
  int? durationMs,
  String? afterStepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final actor = _requireActor(cinematic, actorId);
  final emote = _requireEmoteEntry(emoteId);
  final steps = cinematic.timeline.steps.toList();
  final insertIndex = _timelineInsertIndex(
    steps,
    afterStepId,
    argumentName: 'afterStepId',
    message: 'Actor emote insertion references an unknown timeline step.',
  );
  final step = _buildActorEmoteStep(
    cinematic,
    actor: actor,
    emote: emote,
    durationMs: durationMs ?? cinematicTimelineDefaultActorEmoteDurationMs,
  );
  steps.insert(insertIndex, step);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineActorEmoteStepResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: step,
  );
}

CinematicTimelineStepUpdateResult updateCinematicTimelineActorEmoteStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? emoteId,
  int? durationMs,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    stepId,
    'stepId',
    'Actor emote update requires a timeline step id.',
  );
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == id);
  if (index == -1) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Actor emote update references an unknown timeline step.',
    );
  }
  final step = steps[index];
  if (!isCinematicTimelineActorEmoteStep(step)) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Only Cinematic Builder V0 actor emote blocks can be updated here.',
    );
  }

  final actor = actorId == null
      ? _requireActor(cinematic, step.actorId ?? '')
      : _requireActor(cinematic, actorId);
  final emote = emoteId == null
      ? _requireEmoteEntry(cinematicTimelineActorEmoteEmoteIdOf(step) ?? '')
      : _requireEmoteEntry(emoteId);
  final metadata = Map<String, String>.of(step.metadata)
    ..[cinematicTimelineActorEmoteEmoteIdMetadataKey] = emote.id;
  final updatedStep = CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: _actorEmoteLabel(actor, emote),
    durationMs: durationMs == null
        ? step.durationMs
        : _validateDuration(
            durationMs,
            argumentName: 'durationMs',
            minMs: cinematicTimelineMinimumDurationMs,
          ),
    actorId: actor.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: metadata,
  );
  steps[index] = updatedStep;

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineStepUpdateResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: updatedStep,
  );
}

CinematicTimelineAuthoringStepRemovalResult
    removeCinematicTimelineAuthoringStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    stepId,
    'stepId',
    'Authoring step removal requires a timeline step id.',
  );
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == id);
  if (index == -1) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Authoring step removal references an unknown timeline step.',
    );
  }
  final removedStep = steps[index];
  if (!isCinematicTimelineAuthoringStep(removedStep)) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Only Cinematic Builder V0 authoring steps can be removed here.',
    );
  }
  steps.removeAt(index);

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: steps),
  );
  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineAuthoringStepRemovalResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    removedStep: removedStep,
  );
}

bool isCinematicTimelineDraftStep(CinematicTimelineStep step) {
  return step.kind == CinematicTimelineStepKind.marker &&
      step.metadata[cinematicTimelineDraftMetadataKindKey] ==
          cinematicTimelineDraftMetadataKindValue &&
      step.metadata[cinematicTimelineDraftMetadataSourceKey] ==
          cinematicTimelineDraftMetadataSourceValue;
}

bool isCinematicTimelineAuthoringStep(CinematicTimelineStep step) {
  return isCinematicTimelineDraftStep(step) ||
      isCinematicTimelineBasicBlockStep(step) ||
      isCinematicTimelineActorFacingStep(step) ||
      isCinematicTimelineActorMoveStep(step) ||
      isCinematicTimelineActorEmoteStep(step);
}

bool isCinematicTimelineBasicBlockStep(CinematicTimelineStep step) {
  return cinematicTimelineBasicBlockKindOf(step) != null;
}

CinematicTimelineBasicBlockKind? cinematicTimelineBasicBlockKindOf(
  CinematicTimelineStep step,
) {
  if (step.metadata[cinematicTimelineDraftMetadataSourceKey] !=
          cinematicTimelineDraftMetadataSourceValue ||
      step.metadata[cinematicTimelineDraftMetadataKindKey] !=
          cinematicTimelineBasicBlockMetadataKindValue) {
    return null;
  }
  final block = step.metadata[cinematicTimelineAuthoringBlockMetadataKey];
  return switch (block) {
    'wait' when step.kind == CinematicTimelineStepKind.wait =>
      CinematicTimelineBasicBlockKind.wait,
    'fade' when step.kind == CinematicTimelineStepKind.fade =>
      CinematicTimelineBasicBlockKind.fade,
    'camera' when step.kind == CinematicTimelineStepKind.camera =>
      CinematicTimelineBasicBlockKind.camera,
    _ => null,
  };
}

CinematicTimelineCameraMode? cinematicTimelineCameraModeOf(
  CinematicTimelineStep step,
) {
  if (step.kind != CinematicTimelineStepKind.camera) {
    return null;
  }
  return switch (step.metadata[cinematicTimelineCameraModeMetadataKey]) {
    'reset' => CinematicTimelineCameraMode.reset,
    'hold' => CinematicTimelineCameraMode.hold,
    'focus' => CinematicTimelineCameraMode.focus,
    _ => null,
  };
}

CinematicCameraTargetKind? cinematicTimelineCameraTargetKindOf(
  CinematicTimelineStep step,
) {
  if (step.kind != CinematicTimelineStepKind.camera) {
    return null;
  }
  return switch (step.metadata[cinematicTimelineCameraTargetKindMetadataKey]) {
    'sceneCenter' => CinematicCameraTargetKind.sceneCenter,
    'actor' => CinematicCameraTargetKind.actor,
    'stagePoint' => CinematicCameraTargetKind.stagePoint,
    _ => null,
  };
}

CinematicCameraZoomPreset? cinematicTimelineCameraZoomPresetOf(
  CinematicTimelineStep step,
) {
  if (step.kind != CinematicTimelineStepKind.camera) {
    return null;
  }
  return switch (step.metadata[cinematicTimelineCameraZoomPresetMetadataKey]) {
    'wide' => CinematicCameraZoomPreset.wide,
    'medium' => CinematicCameraZoomPreset.medium,
    'close' => CinematicCameraZoomPreset.close,
    _ => null,
  };
}

CinematicCameraTargetBinding? cinematicTimelineCameraTargetBindingOf(
  CinematicTimelineStep step,
) {
  final kind = cinematicTimelineCameraTargetKindOf(step);
  if (kind == null) {
    return null;
  }
  switch (kind) {
    case CinematicCameraTargetKind.sceneCenter:
      return CinematicCameraTargetBinding.sceneCenter();
    case CinematicCameraTargetKind.actor:
      final actorId = _trimOptional(
          step.metadata[cinematicTimelineCameraTargetActorIdMetadataKey]);
      if (actorId == null) {
        return null;
      }
      return CinematicCameraTargetBinding.actor(actorId: actorId);
    case CinematicCameraTargetKind.stagePoint:
      final stagePointId = _trimOptional(
        step.metadata[cinematicTimelineCameraTargetStagePointIdMetadataKey],
      );
      if (stagePointId == null) {
        return null;
      }
      return CinematicCameraTargetBinding.stagePoint(
          stagePointId: stagePointId);
  }
}

CinematicTimelineCameraFocusBinding? cinematicTimelineCameraFocusBindingOf(
  CinematicTimelineStep step,
) {
  if (cinematicTimelineCameraModeOf(step) !=
      CinematicTimelineCameraMode.focus) {
    return null;
  }
  final target = cinematicTimelineCameraTargetBindingOf(step);
  final zoomPreset = cinematicTimelineCameraZoomPresetOf(step);
  if (target == null || zoomPreset == null) {
    return null;
  }
  return CinematicTimelineCameraFocusBinding(
    target: target,
    zoomPreset: zoomPreset,
  );
}

bool isCinematicTimelineActorFacingStep(CinematicTimelineStep step) {
  return step.kind == CinematicTimelineStepKind.actorFace &&
      step.metadata[cinematicTimelineDraftMetadataSourceKey] ==
          cinematicTimelineDraftMetadataSourceValue &&
      step.metadata[cinematicTimelineDraftMetadataKindKey] ==
          cinematicTimelineBasicBlockMetadataKindValue &&
      step.metadata[cinematicTimelineAuthoringBlockMetadataKey] ==
          cinematicTimelineActorFaceBlockMetadataValue &&
      cinematicTimelineActorFacingDirectionOf(step) != null;
}

CinematicTimelineActorFacingDirection? cinematicTimelineActorFacingDirectionOf(
  CinematicTimelineStep step,
) {
  final direction = step.metadata[cinematicTimelineActorDirectionMetadataKey];
  return switch (direction) {
    'up' => CinematicTimelineActorFacingDirection.up,
    'down' => CinematicTimelineActorFacingDirection.down,
    'left' => CinematicTimelineActorFacingDirection.left,
    'right' => CinematicTimelineActorFacingDirection.right,
    _ => null,
  };
}

bool isCinematicTimelineActorMoveStep(CinematicTimelineStep step) {
  if (step.kind != CinematicTimelineStepKind.actorMove ||
      step.metadata[cinematicTimelineDraftMetadataSourceKey] !=
          cinematicTimelineDraftMetadataSourceValue ||
      step.metadata[cinematicTimelineDraftMetadataKindKey] !=
          cinematicTimelineBasicBlockMetadataKindValue ||
      step.metadata[cinematicTimelineAuthoringBlockMetadataKey] !=
          cinematicTimelineActorMoveBlockMetadataValue ||
      cinematicTimelineActorMovementModeOf(step) == null) {
    return false;
  }
  final pathMode = cinematicTimelineActorPathModeOf(step);
  return pathMode == CinematicTimelineActorPathMode.direct ||
      pathMode == CinematicTimelineActorPathMode.manual;
}

CinematicTimelineActorMovementMode? cinematicTimelineActorMovementModeOf(
  CinematicTimelineStep step,
) {
  final mode = step.metadata[cinematicTimelineActorMovementModeMetadataKey];
  return switch (mode) {
    'walk' => CinematicTimelineActorMovementMode.walk,
    'run' => CinematicTimelineActorMovementMode.run,
    _ => null,
  };
}

CinematicTimelineActorPathMode? cinematicTimelineActorPathModeOf(
  CinematicTimelineStep step,
) {
  final mode = step.metadata[cinematicTimelineActorPathModeMetadataKey];
  return switch (mode) {
    'direct' => CinematicTimelineActorPathMode.direct,
    'manual' => CinematicTimelineActorPathMode.manual,
    _ => null,
  };
}

bool isCinematicTimelineActorEmoteStep(CinematicTimelineStep step) {
  return step.kind == CinematicTimelineStepKind.actorEmote &&
      step.metadata[cinematicTimelineDraftMetadataSourceKey] ==
          cinematicTimelineDraftMetadataSourceValue &&
      step.metadata[cinematicTimelineDraftMetadataKindKey] ==
          cinematicTimelineBasicBlockMetadataKindValue &&
      step.metadata[cinematicTimelineAuthoringBlockMetadataKey] ==
          cinematicTimelineActorEmoteBlockMetadataValue;
}

String? cinematicTimelineActorEmoteActorIdOf(CinematicTimelineStep step) {
  final actorId = step.actorId?.trim();
  if (actorId == null || actorId.isEmpty) {
    return null;
  }
  return actorId;
}

String? cinematicTimelineActorEmoteEmoteIdOf(CinematicTimelineStep step) {
  final emoteId =
      step.metadata[cinematicTimelineActorEmoteEmoteIdMetadataKey]?.trim();
  if (emoteId == null || emoteId.isEmpty) {
    return null;
  }
  return emoteId;
}

/// Ajoute un chemin manuel owned par un bloc actorMove existant et bascule le step en mode manual.
/// Protège la frontière de V1-107 en restant purement d'authoring (sans playback ni interpolation).
CinematicStageContextAuthoringResult addCinematicManualPathForActorMove(
  ProjectManifest project, {
  required String cinematicId,
  required String actorMoveStepId,
  String? label,
  String? description,
  List<String> waypointStagePointIds = const <String>[],
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final steps = cinematic.timeline.steps;
  final stepIndex = steps.indexWhere((s) => s.id == actorMoveStepId);
  if (stepIndex == -1) {
    throw ArgumentError('Step ID "$actorMoveStepId" not found in cinematic.');
  }
  final step = steps[stepIndex];
  if (!isCinematicTimelineActorMoveStep(step)) {
    throw ArgumentError('Step "$actorMoveStepId" is not an actorMove step.');
  }

  if (context.manualPaths
      .any((p) => p.ownerActorMoveStepId == actorMoveStepId)) {
    throw ArgumentError(
        'A manual path already exists for step "$actorMoveStepId".');
  }

  final existingPointIds = context.stagePoints.map((p) => p.id).toSet();
  for (final wpId in waypointStagePointIds) {
    if (!existingPointIds.contains(wpId)) {
      throw ArgumentError('Stage Point ID "$wpId" not found in stagePoints.');
    }
  }

  final existingPathIds = context.manualPaths.map((p) => p.id).toSet();
  const base = 'path';
  var pathId = base;
  var pathIndex = 2;
  while (existingPathIds.contains(pathId)) {
    pathId = '${base}_$pathIndex';
    pathIndex++;
  }

  final resolvedLabel = label ?? 'Chemin de déplacement';
  final newPath = CinematicManualPath(
    id: pathId,
    label: resolvedLabel,
    description: description,
    ownerActorMoveStepId: actorMoveStepId,
    waypointStagePointIds: waypointStagePointIds,
  );

  final updatedStepMetadata = Map<String, String>.from(step.metadata)
    ..[cinematicTimelineActorPathModeMetadataKey] =
        CinematicTimelineActorPathMode.manual.name;

  final updatedStep = CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: step.label,
    durationMs: step.durationMs,
    actorId: step.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: updatedStepMetadata,
  );

  final updatedSteps = List<CinematicTimelineStep>.from(steps);
  updatedSteps[stepIndex] = updatedStep;

  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: [...context.manualPaths, newPath],
  );

  final updatedCinematic = _copyCinematicWithStageContext(
    _copyCinematicWithTimeline(
      cinematic,
      CinematicTimeline(steps: updatedSteps),
    ),
    updatedContext,
  );

  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

/// Met à jour les métadonnées ou les repères intermédiaires d'un chemin manuel existant.
/// Limité à l'authoring pur.
CinematicStageContextAuthoringResult updateCinematicManualPath(
  ProjectManifest project, {
  required String cinematicId,
  required String manualPathId,
  String? label,
  String? description,
  List<String>? waypointStagePointIds,
  bool clearDescription = false,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final pathIndex = context.manualPaths.indexWhere((p) => p.id == manualPathId);
  if (pathIndex == -1) {
    throw ArgumentError('Manual path ID "$manualPathId" not found.');
  }
  final existingPath = context.manualPaths[pathIndex];

  if (label != null && label.trim().isEmpty) {
    throw ArgumentError('Manual path label must not be empty.');
  }

  if (waypointStagePointIds != null) {
    final existingPointIds = context.stagePoints.map((p) => p.id).toSet();
    for (final wpId in waypointStagePointIds) {
      if (!existingPointIds.contains(wpId)) {
        throw ArgumentError('Stage Point ID "$wpId" not found in stagePoints.');
      }
    }
  }

  final updatedPath = existingPath.copyWith(
    label: label,
    description: description,
    waypointStagePointIds: waypointStagePointIds,
    clearDescription: clearDescription,
  );

  final updatedPaths = List<CinematicManualPath>.from(context.manualPaths);
  updatedPaths[pathIndex] = updatedPath;

  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: updatedPaths,
  );

  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

/// Supprime un chemin manuel existant du contexte.
/// Si le bloc owner était en mode manual, il est automatiquement repassé en mode direct.
CinematicStageContextAuthoringResult removeCinematicManualPath(
  ProjectManifest project, {
  required String cinematicId,
  required String manualPathId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final path = context.manualPaths.firstWhere(
    (p) => p.id == manualPathId,
    orElse: () => throw ArgumentError('Manual path ID "$manualPathId" not found.'),
  );

  var updatedCinematic = cinematic;
  final ownerStepId = path.ownerActorMoveStepId;
  final steps = cinematic.timeline.steps;
  final stepIndex = steps.indexWhere((s) => s.id == ownerStepId);
  if (stepIndex != -1) {
    final step = steps[stepIndex];
    if (isCinematicTimelineActorMoveStep(step)) {
      final updatedStepMetadata = Map<String, String>.from(step.metadata)
        ..[cinematicTimelineActorPathModeMetadataKey] =
            CinematicTimelineActorPathMode.direct.name;
      final updatedStep = CinematicTimelineStep(
        id: step.id,
        kind: step.kind,
        label: step.label,
        durationMs: step.durationMs,
        actorId: step.actorId,
        targetId: step.targetId,
        dialogueText: step.dialogueText,
        assetRef: step.assetRef,
        metadata: updatedStepMetadata,
      );
      final updatedSteps = List<CinematicTimelineStep>.from(steps);
      updatedSteps[stepIndex] = updatedStep;
      updatedCinematic = _copyCinematicWithTimeline(
        cinematic,
        CinematicTimeline(steps: updatedSteps),
      );
    }
  }

  final updatedPaths =
      context.manualPaths.where((p) => p.id != manualPathId).toList();
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: updatedPaths,
  );

  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(updatedCinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

/// Ajoute un repère de passage (Waypoint) à la fin d'un chemin manuel.
CinematicStageContextAuthoringResult addCinematicManualPathWaypoint(
  ProjectManifest project, {
  required String cinematicId,
  required String manualPathId,
  required String stagePointId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final pathIndex = context.manualPaths.indexWhere((p) => p.id == manualPathId);
  if (pathIndex == -1) {
    throw ArgumentError('Manual path ID "$manualPathId" not found.');
  }
  final existingPath = context.manualPaths[pathIndex];

  final hasPoint = context.stagePoints.any((p) => p.id == stagePointId);
  if (!hasPoint) {
    throw ArgumentError(
        'Stage Point ID "$stagePointId" not found in stagePoints.');
  }

  final updatedPath = existingPath.copyWith(
    waypointStagePointIds: [
      ...existingPath.waypointStagePointIds,
      stagePointId,
    ],
  );

  final updatedPaths = List<CinematicManualPath>.from(context.manualPaths);
  updatedPaths[pathIndex] = updatedPath;

  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: updatedPaths,
  );

  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

/// Retire un repère de passage d'un chemin manuel à un index donné.
CinematicStageContextAuthoringResult removeCinematicManualPathWaypointAt(
  ProjectManifest project, {
  required String cinematicId,
  required String manualPathId,
  required int index,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final pathIndex = context.manualPaths.indexWhere((p) => p.id == manualPathId);
  if (pathIndex == -1) {
    throw ArgumentError('Manual path ID "$manualPathId" not found.');
  }
  final existingPath = context.manualPaths[pathIndex];

  if (index < 0 || index >= existingPath.waypointStagePointIds.length) {
    throw ArgumentError(
        'Index $index out of bounds for manual path waypoints.');
  }

  final updatedWaypoints = List<String>.from(existingPath.waypointStagePointIds)
    ..removeAt(index);
  final updatedPath = existingPath.copyWith(
    waypointStagePointIds: updatedWaypoints,
  );

  final updatedPaths = List<CinematicManualPath>.from(context.manualPaths);
  updatedPaths[pathIndex] = updatedPath;

  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: updatedPaths,
  );

  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

/// Réordonne la liste des repères intermédiaires (waypoints) d'un chemin manuel.
CinematicStageContextAuthoringResult reorderCinematicManualPathWaypoint(
  ProjectManifest project, {
  required String cinematicId,
  required String manualPathId,
  required int fromIndex,
  required int toIndex,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final pathIndex = context.manualPaths.indexWhere((p) => p.id == manualPathId);
  if (pathIndex == -1) {
    throw ArgumentError('Manual path ID "$manualPathId" not found.');
  }
  final existingPath = context.manualPaths[pathIndex];

  final len = existingPath.waypointStagePointIds.length;
  if (fromIndex < 0 || fromIndex >= len || toIndex < 0 || toIndex >= len) {
    throw ArgumentError(
      'Reorder indices out of bounds (fromIndex: $fromIndex, toIndex: $toIndex, length: $len).',
    );
  }

  final updatedWaypoints =
      List<String>.from(existingPath.waypointStagePointIds);
  final pointId = updatedWaypoints.removeAt(fromIndex);
  updatedWaypoints.insert(toIndex, pointId);

  final updatedPath = existingPath.copyWith(
    waypointStagePointIds: updatedWaypoints,
  );

  final updatedPaths = List<CinematicManualPath>.from(context.manualPaths);
  updatedPaths[pathIndex] = updatedPath;

  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: updatedPaths,
  );

  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

/// Bascule le mode de déplacement d'un actorMove (direct / manual).
CinematicTimelineStepUpdateResult setActorMovePathMode(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  required CinematicTimelineActorPathMode pathMode,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final steps = cinematic.timeline.steps;
  final index = steps.indexWhere((s) => s.id == stepId);
  if (index == -1) {
    throw ArgumentError('Step ID "$stepId" not found.');
  }
  final step = steps[index];
  if (!isCinematicTimelineActorMoveStep(step)) {
    throw ArgumentError('Step "$stepId" is not an actorMove step.');
  }

  final currentPathMode = cinematicTimelineActorPathModeOf(step);
  if (currentPathMode == pathMode) {
    return CinematicTimelineStepUpdateResult(
      updatedProject: project,
      cinematic: cinematic,
      step: step,
    );
  }

  final updatedMetadata = Map<String, String>.from(step.metadata)
    ..[cinematicTimelineActorPathModeMetadataKey] = pathMode.name;

  final updatedStep = CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: step.label,
    durationMs: step.durationMs,
    actorId: step.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: updatedMetadata,
  );

  final updatedSteps = List<CinematicTimelineStep>.from(steps);
  updatedSteps[index] = updatedStep;

  final updatedCinematic = _copyCinematicWithTimeline(
    cinematic,
    CinematicTimeline(steps: updatedSteps),
  );

  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicTimelineStepUpdateResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
    step: updatedStep,
  );
}

/// Repasse un step actorMove en mode direct et supprime ses chemins manuels associés.
/// Évite d'avoir des chemins orphelins dans le Stage Context.
CinematicStageContextAuthoringResult clearActorMoveManualPath(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final context = cinematic.stageContext ?? CinematicStageContext();

  final steps = cinematic.timeline.steps;
  final index = steps.indexWhere((s) => s.id == stepId);
  if (index == -1) {
    throw ArgumentError('Step ID "$stepId" not found.');
  }
  final step = steps[index];
  if (!isCinematicTimelineActorMoveStep(step)) {
    throw ArgumentError('Step "$stepId" is not an actorMove step.');
  }

  final updatedMetadata = Map<String, String>.from(step.metadata)
    ..[cinematicTimelineActorPathModeMetadataKey] =
        CinematicTimelineActorPathMode.direct.name;

  final updatedStep = CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: step.label,
    durationMs: step.durationMs,
    actorId: step.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: updatedMetadata,
  );

  final updatedSteps = List<CinematicTimelineStep>.from(steps);
  updatedSteps[index] = updatedStep;

  final updatedPaths = context.manualPaths
      .where((p) => p.ownerActorMoveStepId != stepId)
      .toList();

  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: context.actorAppearanceBindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
    manualPaths: updatedPaths,
  );

  final updatedCinematic = _copyCinematicWithStageContext(
    _copyCinematicWithTimeline(
      cinematic,
      CinematicTimeline(steps: updatedSteps),
    ),
    updatedContext,
  );

  final result = updateCinematicAsset(project, updatedCinematic);
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

void _validateCinematics(List<CinematicAsset> cinematics) {
  final ids = <String>{};
  for (final cinematic in cinematics) {
    _validateCinematicShape(cinematic);
    if (!ids.add(cinematic.id)) {
      throw ArgumentError.value(
        cinematic.id,
        'cinematics',
        'Duplicate CinematicAsset id.',
      );
    }
  }
}

void _validateCinematicShape(CinematicAsset cinematic) {
  _trimRequired(
    cinematic.id,
    'cinematic.id',
    'CinematicAsset id is required.',
  );
  _trimRequired(
    cinematic.title,
    'cinematic.title',
    'CinematicAsset title is required.',
  );
}

void _throwIfDuplicateId(String id, Iterable<String> existingIds) {
  if (existingIds.contains(id)) {
    throw ArgumentError.value(
      id,
      'cinematic.id',
      'Duplicate CinematicAsset id.',
    );
  }
}

CinematicAsset _requireCinematic(
  ProjectManifest project,
  String cinematicId,
) {
  final id = _trimRequired(
    cinematicId,
    'cinematicId',
    'Timeline draft authoring requires a cinematic id.',
  );
  final cinematic = findCinematicById(project, id);
  if (cinematic == null) {
    throw ArgumentError.value(
      cinematicId,
      'cinematicId',
      'Timeline draft authoring references an unknown cinematic.',
    );
  }
  return cinematic;
}

CinematicAsset _copyCinematicWithTimeline(
  CinematicAsset cinematic,
  CinematicTimeline timeline,
) {
  return CinematicAsset(
    id: cinematic.id,
    title: cinematic.title,
    description: cinematic.description,
    storylineId: cinematic.storylineId,
    chapterId: cinematic.chapterId,
    mapId: cinematic.mapId,
    tags: cinematic.tags,
    requiredActors: cinematic.requiredActors,
    movementTargets: cinematic.movementTargets,
    stageContext: cinematic.stageContext,
    timeline: timeline,
    notes: cinematic.notes,
    metadata: cinematic.metadata,
    legacyBridge: cinematic.legacyBridge,
  );
}

CinematicAsset _copyCinematicWithActors(
  CinematicAsset cinematic,
  List<CinematicActorRef> requiredActors,
) {
  return CinematicAsset(
    id: cinematic.id,
    title: cinematic.title,
    description: cinematic.description,
    storylineId: cinematic.storylineId,
    chapterId: cinematic.chapterId,
    mapId: cinematic.mapId,
    tags: cinematic.tags,
    requiredActors: requiredActors,
    movementTargets: cinematic.movementTargets,
    stageContext: cinematic.stageContext,
    timeline: cinematic.timeline,
    notes: cinematic.notes,
    metadata: cinematic.metadata,
    legacyBridge: cinematic.legacyBridge,
  );
}

CinematicAsset _copyCinematicWithMovementTargets(
  CinematicAsset cinematic,
  List<CinematicMovementTargetRef> movementTargets,
) {
  return CinematicAsset(
    id: cinematic.id,
    title: cinematic.title,
    description: cinematic.description,
    storylineId: cinematic.storylineId,
    chapterId: cinematic.chapterId,
    mapId: cinematic.mapId,
    tags: cinematic.tags,
    requiredActors: cinematic.requiredActors,
    movementTargets: movementTargets,
    stageContext: cinematic.stageContext,
    timeline: cinematic.timeline,
    notes: cinematic.notes,
    metadata: cinematic.metadata,
    legacyBridge: cinematic.legacyBridge,
  );
}

CinematicAsset _copyCinematicWithStageMap(
  CinematicAsset cinematic,
  String? mapId,
) {
  return CinematicAsset(
    id: cinematic.id,
    title: cinematic.title,
    description: cinematic.description,
    storylineId: cinematic.storylineId,
    chapterId: cinematic.chapterId,
    mapId: mapId,
    tags: cinematic.tags,
    requiredActors: cinematic.requiredActors,
    movementTargets: cinematic.movementTargets,
    stageContext: cinematic.stageContext,
    timeline: cinematic.timeline,
    notes: cinematic.notes,
    metadata: cinematic.metadata,
    legacyBridge: cinematic.legacyBridge,
  );
}

CinematicAsset _copyCinematicWithStageContext(
  CinematicAsset cinematic,
  CinematicStageContext? stageContext,
) {
  return CinematicAsset(
    id: cinematic.id,
    title: cinematic.title,
    description: cinematic.description,
    storylineId: cinematic.storylineId,
    chapterId: cinematic.chapterId,
    mapId: cinematic.mapId,
    tags: cinematic.tags,
    requiredActors: cinematic.requiredActors,
    movementTargets: cinematic.movementTargets,
    stageContext: stageContext,
    timeline: cinematic.timeline,
    notes: cinematic.notes,
    metadata: cinematic.metadata,
    legacyBridge: cinematic.legacyBridge,
  );
}

int _timelineInsertIndex(
  List<CinematicTimelineStep> steps,
  String? afterStepId, {
  required String argumentName,
  required String message,
}) {
  final trimmedAfterStepId = afterStepId?.trim();
  if (trimmedAfterStepId == null || trimmedAfterStepId.isEmpty) {
    return steps.length;
  }
  final selectedIndex =
      steps.indexWhere((step) => step.id == trimmedAfterStepId);
  if (selectedIndex == -1) {
    throw ArgumentError.value(afterStepId, argumentName, message);
  }
  return selectedIndex + 1;
}

CinematicTimelineStep _buildBasicBlockStep(
  CinematicAsset cinematic, {
  required CinematicTimelineBasicBlockKind blockKind,
  required int? durationMs,
  required CinematicTimelineFadeMode fadeMode,
  required CinematicTimelineCameraMode cameraMode,
  required CinematicTimelineCameraFocusBinding? cameraFocusBinding,
}) {
  return switch (blockKind) {
    CinematicTimelineBasicBlockKind.wait => CinematicTimelineStep(
        id: _nextTimelineStepId(cinematic, 'step_wait'),
        kind: CinematicTimelineStepKind.wait,
        label: 'Attente',
        durationMs: _validateDuration(
          durationMs ?? cinematicTimelineDefaultWaitDurationMs,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
        ),
        metadata: _basicBlockMetadata(CinematicTimelineBasicBlockKind.wait),
      ),
    CinematicTimelineBasicBlockKind.fade => CinematicTimelineStep(
        id: _nextTimelineStepId(cinematic, 'step_fade'),
        kind: CinematicTimelineStepKind.fade,
        label: _fadeLabel(fadeMode),
        durationMs: _validateDuration(
          durationMs ?? cinematicTimelineDefaultFadeDurationMs,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
        ),
        metadata: {
          ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.fade),
          cinematicTimelineFadeModeMetadataKey: fadeMode.name,
        },
      ),
    CinematicTimelineBasicBlockKind.camera => CinematicTimelineStep(
        id: _nextTimelineStepId(cinematic, 'step_camera'),
        kind: CinematicTimelineStepKind.camera,
        label: 'Caméra',
        durationMs: _validateDuration(
          durationMs ?? cinematicTimelineDefaultCameraDurationMs,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
        ),
        metadata: {
          ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.camera),
          ..._cameraMetadata(
            cameraMode,
            focusBinding: cameraFocusBinding,
          ),
        },
      ),
  };
}

CinematicTimelineStep _buildActorFacingStep(
  CinematicAsset cinematic, {
  required CinematicActorRef actor,
  required CinematicTimelineActorFacingDirection direction,
}) {
  return CinematicTimelineStep(
    id: _nextTimelineStepId(cinematic, 'step_actor_face'),
    kind: CinematicTimelineStepKind.actorFace,
    label: _actorFacingLabel(actor),
    actorId: actor.actorId,
    metadata: {
      cinematicTimelineDraftMetadataKindKey:
          cinematicTimelineBasicBlockMetadataKindValue,
      cinematicTimelineDraftMetadataSourceKey:
          cinematicTimelineDraftMetadataSourceValue,
      cinematicTimelineAuthoringBlockMetadataKey:
          cinematicTimelineActorFaceBlockMetadataValue,
      cinematicTimelineActorDirectionMetadataKey: direction.name,
    },
  );
}

CinematicTimelineStep _buildActorMoveStep(
  CinematicAsset cinematic, {
  required CinematicActorRef actor,
  required CinematicMovementTargetRef target,
  required int durationMs,
  required CinematicTimelineActorMovementMode movementMode,
}) {
  return CinematicTimelineStep(
    id: _nextTimelineStepId(cinematic, 'step_actor_move'),
    kind: CinematicTimelineStepKind.actorMove,
    label: _actorMoveLabel(actor),
    durationMs: _validateDuration(
      durationMs,
      argumentName: 'durationMs',
      minMs: cinematicTimelineActorMoveMinimumDurationMs,
    ),
    actorId: actor.actorId,
    targetId: target.targetId,
    metadata: {
      cinematicTimelineDraftMetadataKindKey:
          cinematicTimelineBasicBlockMetadataKindValue,
      cinematicTimelineDraftMetadataSourceKey:
          cinematicTimelineDraftMetadataSourceValue,
      cinematicTimelineAuthoringBlockMetadataKey:
          cinematicTimelineActorMoveBlockMetadataValue,
      cinematicTimelineActorMovementModeMetadataKey: movementMode.name,
      cinematicTimelineActorPathModeMetadataKey:
          CinematicTimelineActorPathMode.direct.name,
    },
  );
}

CinematicTimelineStep _buildActorEmoteStep(
  CinematicAsset cinematic, {
  required CinematicActorRef actor,
  required CinematicEmoteCatalogEntry emote,
  required int durationMs,
}) {
  return CinematicTimelineStep(
    id: _nextTimelineStepId(cinematic, 'step_actor_emote'),
    kind: CinematicTimelineStepKind.actorEmote,
    label: _actorEmoteLabel(actor, emote),
    durationMs: _validateDuration(
      durationMs,
      argumentName: 'durationMs',
      minMs: cinematicTimelineMinimumDurationMs,
    ),
    actorId: actor.actorId,
    metadata: {
      cinematicTimelineDraftMetadataKindKey:
          cinematicTimelineBasicBlockMetadataKindValue,
      cinematicTimelineDraftMetadataSourceKey:
          cinematicTimelineDraftMetadataSourceValue,
      cinematicTimelineAuthoringBlockMetadataKey:
          cinematicTimelineActorEmoteBlockMetadataValue,
      cinematicTimelineActorEmoteEmoteIdMetadataKey: emote.id,
    },
  );
}

CinematicTimelineStep _copyBasicBlockStepWithParams(
  CinematicTimelineStep step, {
  required CinematicTimelineBasicBlockKind blockKind,
  required int? durationMs,
  required CinematicTimelineFadeMode? fadeMode,
  required CinematicTimelineCameraMode? cameraMode,
  required CinematicTimelineCameraFocusBinding? cameraFocusBinding,
}) {
  final metadata = Map<String, String>.of(step.metadata);
  String? label = step.label;
  switch (blockKind) {
    case CinematicTimelineBasicBlockKind.wait:
      if (fadeMode != null ||
          cameraMode != null ||
          cameraFocusBinding != null) {
        throw ArgumentError(
          'Wait blocks only accept durationMs in Cinematic Builder V0.',
        );
      }
      break;
    case CinematicTimelineBasicBlockKind.fade:
      if (cameraMode != null || cameraFocusBinding != null) {
        throw ArgumentError(
          'Fade blocks cannot receive camera mode in Cinematic Builder V0.',
        );
      }
      final mode = fadeMode;
      if (mode != null) {
        metadata[cinematicTimelineFadeModeMetadataKey] = mode.name;
        label = _fadeLabel(mode);
      }
      break;
    case CinematicTimelineBasicBlockKind.camera:
      if (fadeMode != null) {
        throw ArgumentError(
          'Camera blocks cannot receive fade mode in Cinematic Builder V0.',
        );
      }
      final mode = cameraMode;
      if (mode != null || cameraFocusBinding != null) {
        final updatedMetadata = _cameraMetadata(
          mode ?? CinematicTimelineCameraMode.focus,
          focusBinding: cameraFocusBinding,
          existing: metadata,
        );
        metadata
          ..clear()
          ..addAll(updatedMetadata);
      }
      break;
  }

  return CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: label,
    durationMs: durationMs == null
        ? step.durationMs
        : _validateDuration(
            durationMs,
            argumentName: 'durationMs',
            minMs: cinematicTimelineMinimumDurationMs,
          ),
    actorId: step.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: metadata,
  );
}

Map<String, String> _basicBlockMetadata(
  CinematicTimelineBasicBlockKind blockKind,
) {
  return {
    cinematicTimelineDraftMetadataKindKey:
        cinematicTimelineBasicBlockMetadataKindValue,
    cinematicTimelineDraftMetadataSourceKey:
        cinematicTimelineDraftMetadataSourceValue,
    cinematicTimelineAuthoringBlockMetadataKey: blockKind.name,
  };
}

Map<String, String> _cameraMetadata(
  CinematicTimelineCameraMode mode, {
  CinematicTimelineCameraFocusBinding? focusBinding,
  Map<String, String>? existing,
}) {
  if (mode == CinematicTimelineCameraMode.focus && focusBinding == null) {
    throw ArgumentError('Camera focus mode requires a focus binding.');
  }
  final metadata =
      existing == null ? <String, String>{} : Map<String, String>.of(existing);
  _removeCameraFocusMetadata(metadata);
  metadata[cinematicTimelineCameraModeMetadataKey] = mode.name;
  if (mode != CinematicTimelineCameraMode.focus) {
    return metadata;
  }

  final binding = focusBinding!;
  metadata[cinematicTimelineCameraTargetKindMetadataKey] =
      binding.target.kind.name;
  metadata[cinematicTimelineCameraZoomPresetMetadataKey] =
      binding.zoomPreset.name;
  switch (binding.target.kind) {
    case CinematicCameraTargetKind.sceneCenter:
      break;
    case CinematicCameraTargetKind.actor:
      metadata[cinematicTimelineCameraTargetActorIdMetadataKey] =
          binding.target.actorId!;
      break;
    case CinematicCameraTargetKind.stagePoint:
      metadata[cinematicTimelineCameraTargetStagePointIdMetadataKey] =
          binding.target.stagePointId!;
      break;
  }
  return metadata;
}

void _removeCameraFocusMetadata(Map<String, String> metadata) {
  metadata
    ..remove(cinematicTimelineCameraTargetKindMetadataKey)
    ..remove(cinematicTimelineCameraTargetActorIdMetadataKey)
    ..remove(cinematicTimelineCameraTargetStagePointIdMetadataKey)
    ..remove(cinematicTimelineCameraZoomPresetMetadataKey);
}

String _fadeLabel(CinematicTimelineFadeMode mode) {
  return switch (mode) {
    CinematicTimelineFadeMode.fadeIn => 'Fondu entrant',
    CinematicTimelineFadeMode.fadeOut => 'Fondu sortant',
  };
}

String _actorFacingLabel(CinematicActorRef actor) {
  final label = actor.label ?? actor.actorId;
  return 'Orientation $label';
}

String _actorMoveLabel(CinematicActorRef actor) {
  final label = actor.label ?? actor.actorId;
  return 'Déplacement $label';
}

String _actorEmoteLabel(
  CinematicActorRef actor,
  CinematicEmoteCatalogEntry emote,
) {
  final actorLabel = actor.label ?? actor.actorId;
  return '$actorLabel affiche ${emote.label}';
}

int validateCinematicTimelineDurationMs(
  num durationMs, {
  required String argumentName,
  required int minMs,
}) {
  if (durationMs.isNaN || durationMs.isInfinite || durationMs is! int) {
    throw ArgumentError.value(
      durationMs,
      argumentName,
      'Cinematic Builder V0 durations must be whole milliseconds.',
    );
  }
  if (durationMs < minMs || durationMs > cinematicTimelineMaximumDurationMs) {
    throw ArgumentError.value(
      durationMs,
      argumentName,
      'Cinematic Builder V0 durations must be between '
      '$minMs and $cinematicTimelineMaximumDurationMs ms.',
    );
  }
  return durationMs;
}

int _validateDuration(
  int durationMs, {
  required String argumentName,
  required int minMs,
}) {
  validateCinematicTimelineDurationMs(
    durationMs,
    argumentName: argumentName,
    minMs: minMs,
  );
  return durationMs;
}

String _nextTimelineStepId(CinematicAsset cinematic, String base) {
  final existingIds = cinematic.timeline.steps.map((step) => step.id).toSet();
  if (!existingIds.contains(base)) {
    return base;
  }
  var index = 2;
  while (existingIds.contains('${base}_$index')) {
    index++;
  }
  return '${base}_$index';
}

String _nextRequiredActorId(CinematicAsset cinematic) {
  final existingIds =
      cinematic.requiredActors.map((actor) => actor.actorId).toSet();
  const base = 'actor';
  if (!existingIds.contains(base)) {
    return base;
  }
  var index = 2;
  while (existingIds.contains('${base}_$index')) {
    index++;
  }
  return '${base}_$index';
}

String _nextMovementTargetId(CinematicAsset cinematic) {
  final existingIds =
      cinematic.movementTargets.map((target) => target.targetId).toSet();
  const base = 'target';
  if (!existingIds.contains(base)) {
    return base;
  }
  var index = 2;
  while (existingIds.contains('${base}_$index')) {
    index++;
  }
  return '${base}_$index';
}

CinematicActorRef _requireActor(CinematicAsset cinematic, String actorId) {
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor authoring requires a CinematicActorRef actorId.',
  );
  for (final actor in cinematic.requiredActors) {
    if (actor.actorId == id) {
      return actor;
    }
  }
  throw ArgumentError.value(
    actorId,
    'actorId',
    'Actor authoring references an unknown required actor.',
  );
}

void _validateCameraFocusBinding(
  CinematicAsset cinematic,
  CinematicTimelineCameraFocusBinding? binding,
) {
  if (binding == null) {
    throw ArgumentError('Camera focus mode requires a focus binding.');
  }
  switch (binding.target.kind) {
    case CinematicCameraTargetKind.sceneCenter:
      return;
    case CinematicCameraTargetKind.actor:
      _requireActor(cinematic, binding.target.actorId!);
      return;
    case CinematicCameraTargetKind.stagePoint:
      _requireStagePoint(cinematic, binding.target.stagePointId!);
      return;
  }
}

CinematicStagePoint _requireStagePoint(
  CinematicAsset cinematic,
  String stagePointId,
) {
  final id = _trimRequired(
    stagePointId,
    'stagePointId',
    'Camera stage point focus requires a stagePointId.',
  );
  final stageContext = cinematic.stageContext;
  if (stageContext != null) {
    for (final point in stageContext.stagePoints) {
      if (point.id == id) {
        return point;
      }
    }
  }
  throw ArgumentError.value(
    stagePointId,
    'stagePointId',
    'Camera focus references an unknown stage point.',
  );
}

void _requireActorUnusedByTimeline(CinematicAsset cinematic, String actorId) {
  for (final step in cinematic.timeline.steps) {
    if (step.actorId == actorId) {
      throw ArgumentError.value(
        actorId,
        'actorId',
        'Cannot remove a required actor used by cinematic timeline steps.',
      );
    }
  }
}

CinematicStageContext? _stageContextWithoutActor(
  CinematicStageContext? context,
  String actorId,
) {
  if (context == null) {
    return null;
  }
  return CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings
        .where((binding) => binding.actorId != actorId)
        .toList(growable: false),
    actorAppearanceBindings: context.actorAppearanceBindings
        .where((binding) => binding.actorId != actorId)
        .toList(growable: false),
    initialPlacements: context.initialPlacements
        .where((placement) => placement.actorId != actorId)
        .toList(growable: false),
    movementTargetBindings: context.movementTargetBindings,
    stagePoints: context.stagePoints,
  );
}

CinematicMovementTargetRef _requireMovementTarget(
  CinematicAsset cinematic,
  String targetId,
) {
  final id = _trimRequired(
    targetId,
    'targetId',
    'Actor move authoring requires a movement targetId.',
  );
  final target = findCinematicMovementTargetById(cinematic, id);
  if (target != null) {
    return target;
  }
  throw ArgumentError.value(
    targetId,
    'targetId',
    'Actor move authoring references an unknown movement target.',
  );
}

CinematicEmoteCatalogEntry _requireEmoteEntry(String emoteId) {
  final id = _trimRequired(
    emoteId,
    'emoteId',
    'Actor emote authoring requires an emote id.',
  );
  final emote = cinematicEmoteCatalogEntryById(id);
  if (emote != null) {
    return emote;
  }
  throw ArgumentError.value(
    emoteId,
    'emoteId',
    'Actor emote authoring references an unknown emote.',
  );
}

CinematicActorBinding _requireCinematicOnlyActorBinding(
  CinematicStageContext context,
  String actorId,
) {
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor appearance binding requires an actor id.',
  );
  for (final binding in context.actorBindings) {
    if (binding.actorId == id) {
      if (binding.kind == CinematicActorBindingKind.cinematicOnly) {
        return binding;
      }
      throw ArgumentError.value(
        binding.kind.name,
        'binding.kind',
        'Actor appearance binding is only supported for cinematicOnly '
            'actor bindings in V0.',
      );
    }
  }
  throw ArgumentError.value(
    actorId,
    'actorId',
    'Actor appearance binding requires an existing cinematicOnly actor binding.',
  );
}

void _validateStageContextForAuthoring(
  CinematicAsset cinematic,
  CinematicStageContext stageContext,
) {
  final playerActorIds = <String>{};
  for (final binding in stageContext.actorBindings) {
    _requireActor(cinematic, binding.actorId);
    if (binding.kind == CinematicActorBindingKind.player &&
        !playerActorIds.add(binding.actorId)) {
      throw ArgumentError.value(
        binding.actorId,
        'actorId',
        'Duplicate player actor binding.',
      );
    }
  }
  final playerBindings = stageContext.actorBindings
      .where((binding) => binding.kind == CinematicActorBindingKind.player)
      .toList();
  if (playerBindings.length > 1) {
    throw ArgumentError.value(
      playerBindings.last.actorId,
      'actorId',
      'Only one player actor binding is allowed in a cinematic.',
    );
  }

  final appearanceActorIds = <String>{};
  for (final binding in stageContext.actorAppearanceBindings) {
    _requireActor(cinematic, binding.actorId);
    if (!appearanceActorIds.add(binding.actorId)) {
      throw ArgumentError.value(
        binding.actorId,
        'actorId',
        'Only one actor appearance binding is allowed per actor.',
      );
    }
    _requireCinematicOnlyActorBinding(stageContext, binding.actorId);
  }

  for (final placement in stageContext.initialPlacements) {
    _requireActor(cinematic, placement.actorId);
    if (placement.kind ==
        CinematicActorInitialPlacementKind.fromMovementTarget) {
      _requireMovementTarget(cinematic, placement.targetId ?? '');
    }
    if (placement.kind == CinematicActorInitialPlacementKind.stagePoint) {
      if ((placement.stagePointId ?? '').trim().isEmpty) {
        throw ArgumentError.value(
          placement.stagePointId,
          'stagePointId',
          'Stage point initial placement requires a stage point id.',
        );
      }
    }
  }

  for (final binding in stageContext.movementTargetBindings) {
    _requireMovementTarget(cinematic, binding.targetId);
    if (_movementTargetBindingRequiresSource(binding) &&
        binding.sourceId == null) {
      throw ArgumentError.value(
        binding.sourceId,
        'sourceId',
        'Map-aware movement target bindings require a source id.',
      );
    }
  }

  final seenPointIds = <String>{};
  for (final point in stageContext.stagePoints) {
    if (point.id.trim().isEmpty) {
      throw ArgumentError('Stage point ID must not be empty.');
    }
    if (!seenPointIds.add(point.id)) {
      throw ArgumentError('Duplicate stage point ID: ${point.id}');
    }
    if (point.label.trim().isEmpty) {
      throw ArgumentError('Stage point label must not be empty.');
    }
    if (!point.x.isFinite || !point.y.isFinite) {
      throw ArgumentError('Stage point coordinates must be finite.');
    }
  }
}

bool _movementTargetBindingRequiresSource(
  CinematicMovementTargetBinding binding,
) {
  return binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
      binding.kind == CinematicMovementTargetBindingKind.mapEvent ||
      binding.kind == CinematicMovementTargetBindingKind.stagePoint;
}

List<String> _sceneIdsReferencingCinematic(
  ProjectManifest project,
  String cinematicId,
) {
  final sceneIds = <String>[];
  for (final scene in project.scenes) {
    final referencesCinematic = scene.graph.nodes.any((node) {
      final payload = node.payload;
      return payload is SceneCinematicPayload &&
          payload.cinematicId == cinematicId;
    });
    if (referencesCinematic) {
      sceneIds.add(scene.id);
    }
  }
  return List<String>.unmodifiable(sceneIds);
}

String _trimRequired(String value, String fieldName, String message) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, message);
  }
  return trimmed;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
