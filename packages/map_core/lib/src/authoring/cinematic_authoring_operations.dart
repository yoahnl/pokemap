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
