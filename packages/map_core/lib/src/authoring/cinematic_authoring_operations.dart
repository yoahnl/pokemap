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

const cinematicTimelineDraftMetadataKindKey = 'authoring.kind';
const cinematicTimelineDraftMetadataKindValue = 'draft';
const cinematicTimelineDraftMetadataSourceKey = 'authoring.source';
const cinematicTimelineDraftMetadataSourceValue = 'cinematic-builder-v0';

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
  final trimmedAfterStepId = afterStepId?.trim();
  var insertIndex = steps.length;
  if (trimmedAfterStepId != null && trimmedAfterStepId.isNotEmpty) {
    final selectedIndex =
        steps.indexWhere((step) => step.id == trimmedAfterStepId);
    if (selectedIndex == -1) {
      throw ArgumentError.value(
        afterStepId,
        'afterStepId',
        'Draft insertion references an unknown timeline step.',
      );
    }
    insertIndex = selectedIndex + 1;
  }

  final draft = CinematicTimelineStep(
    id: _nextDraftStepId(cinematic),
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

bool isCinematicTimelineDraftStep(CinematicTimelineStep step) {
  return step.kind == CinematicTimelineStepKind.marker &&
      step.metadata[cinematicTimelineDraftMetadataKindKey] ==
          cinematicTimelineDraftMetadataKindValue &&
      step.metadata[cinematicTimelineDraftMetadataSourceKey] ==
          cinematicTimelineDraftMetadataSourceValue;
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

String _nextDraftStepId(CinematicAsset cinematic) {
  final existingIds = cinematic.timeline.steps.map((step) => step.id).toSet();
  const base = 'step_draft';
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
