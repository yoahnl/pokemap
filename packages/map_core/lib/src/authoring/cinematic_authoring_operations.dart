import '../models/cinematic_asset.dart';
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
}

const cinematicTimelineDraftMetadataKindKey = 'authoring.kind';
const cinematicTimelineDraftMetadataKindValue = 'draft';
const cinematicTimelineBasicBlockMetadataKindValue = 'basicBlock';
const cinematicTimelineDraftMetadataSourceKey = 'authoring.source';
const cinematicTimelineDraftMetadataSourceValue = 'cinematic-builder-v0';
const cinematicTimelineAuthoringBlockMetadataKey = 'authoring.block';
const cinematicTimelineFadeModeMetadataKey = 'fade.mode';
const cinematicTimelineCameraModeMetadataKey = 'camera.mode';
const cinematicTimelineActorDirectionMetadataKey = 'actor.direction';
const cinematicTimelineActorFaceBlockMetadataValue = 'actorFace';
const cinematicTimelineActorMoveBlockMetadataValue = 'actorMove';
const cinematicTimelineActorMovementModeMetadataKey = 'actor.movementMode';
const cinematicTimelineActorPathModeMetadataKey = 'actor.pathMode';

const cinematicTimelineDefaultWaitDurationMs = 1000;
const cinematicTimelineDefaultFadeDurationMs = 1000;
const cinematicTimelineDefaultCameraDurationMs = 500;
const cinematicTimelineDefaultActorMoveDurationMs = 1000;
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
}) {
  final cinematic = _requireCinematic(project, cinematicId);
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

CinematicTimelineStepUpdateResult updateCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
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
  final updatedStep = _copyBasicBlockStepWithParams(
    step,
    blockKind: blockKind,
    durationMs: durationMs,
    fadeMode: fadeMode,
    cameraMode: cameraMode,
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
      isCinematicTimelineActorMoveStep(step);
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
  return step.kind == CinematicTimelineStepKind.actorMove &&
      step.metadata[cinematicTimelineDraftMetadataSourceKey] ==
          cinematicTimelineDraftMetadataSourceValue &&
      step.metadata[cinematicTimelineDraftMetadataKindKey] ==
          cinematicTimelineBasicBlockMetadataKindValue &&
      step.metadata[cinematicTimelineAuthoringBlockMetadataKey] ==
          cinematicTimelineActorMoveBlockMetadataValue &&
      cinematicTimelineActorMovementModeOf(step) != null &&
      cinematicTimelineActorPathModeOf(step) ==
          CinematicTimelineActorPathMode.direct;
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
    _ => null,
  };
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
          cinematicTimelineCameraModeMetadataKey: cameraMode.name,
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

CinematicTimelineStep _copyBasicBlockStepWithParams(
  CinematicTimelineStep step, {
  required CinematicTimelineBasicBlockKind blockKind,
  required int? durationMs,
  required CinematicTimelineFadeMode? fadeMode,
  required CinematicTimelineCameraMode? cameraMode,
}) {
  final metadata = Map<String, String>.of(step.metadata);
  String? label = step.label;
  switch (blockKind) {
    case CinematicTimelineBasicBlockKind.wait:
      if (fadeMode != null || cameraMode != null) {
        throw ArgumentError(
          'Wait blocks only accept durationMs in Cinematic Builder V0.',
        );
      }
      break;
    case CinematicTimelineBasicBlockKind.fade:
      if (cameraMode != null) {
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
      if (mode != null) {
        metadata[cinematicTimelineCameraModeMetadataKey] = mode.name;
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
