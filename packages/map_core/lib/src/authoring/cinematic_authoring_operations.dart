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

const cinematicTimelineDraftMetadataKindKey = 'authoring.kind';
const cinematicTimelineDraftMetadataKindValue = 'draft';
const cinematicTimelineBasicBlockMetadataKindValue = 'basicBlock';
const cinematicTimelineDraftMetadataSourceKey = 'authoring.source';
const cinematicTimelineDraftMetadataSourceValue = 'cinematic-builder-v0';
const cinematicTimelineAuthoringBlockMetadataKey = 'authoring.block';
const cinematicTimelineFadeModeMetadataKey = 'fade.mode';
const cinematicTimelineCameraModeMetadataKey = 'camera.mode';

const cinematicTimelineDefaultWaitDurationMs = 1000;
const cinematicTimelineDefaultFadeDurationMs = 1000;
const cinematicTimelineDefaultCameraDurationMs = 500;

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
      isCinematicTimelineBasicBlockStep(step);
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
    timeline: timeline,
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
        ),
        metadata: {
          ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.camera),
          cinematicTimelineCameraModeMetadataKey: cameraMode.name,
        },
      ),
  };
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
        : _validateDuration(durationMs, argumentName: 'durationMs'),
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

int _validateDuration(int durationMs, {required String argumentName}) {
  if (durationMs <= 0) {
    throw ArgumentError.value(
      durationMs,
      argumentName,
      'Cinematic Builder V0 basic block durations must be positive.',
    );
  }
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
