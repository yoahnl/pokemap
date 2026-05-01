import 'package:map_core/map_core.dart';
import 'path_studio_edit_path_build_request.dart';
import 'path_studio_new_path_build_request.dart';

/// Helper pour appliquer la sauvegarde d'un ProjectPathPatternPreset dans le manifest.
///
/// Ce helper extrait la logique d'upsert utilisée par le callback de
/// [PathStudioWorkspace] pour la sauvegarde des PathPattern depuis un path existant.
///
/// Il prouve que :
/// 1. On reçoit un [ProjectPathPatternPreset]
/// 2. On appelle [upsertProjectPathPatternPreset] pour mettre à jour le manifest
/// 3. Le manifest est retourné avec la modification
///
/// **Note :** Ce helper ne gère pas la lecture/écriture du state Riverpod.
/// Il se concentre uniquement sur la transformation du manifest.
ProjectManifest applyLegacyPathPatternSaveToManifest({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
}) {
  return upsertProjectPathPatternPreset(
    manifest: manifest,
    preset: preset,
  );
}

ProjectManifest applyNewPathBuildRequestToManifest({
  required ProjectManifest manifest,
  required PathStudioNewPathBuildRequest request,
}) {
  if (manifest.pathPresets
      .any((preset) => preset.id == request.basePathPreset.id)) {
    throw ArgumentError(
      'ProjectPathPreset id collision: ${request.basePathPreset.id}',
    );
  }
  if (manifest.pathPatternPresets
      .any((preset) => preset.id == request.pathPatternPreset.id)) {
    throw ArgumentError(
      'ProjectPathPatternPreset id collision: ${request.pathPatternPreset.id}',
    );
  }
  return manifest.copyWith(
    pathPresets: [
      ...manifest.pathPresets,
      request.basePathPreset,
    ],
    pathPatternPresets: [
      ...manifest.pathPatternPresets,
      request.pathPatternPreset,
    ],
  );
}

ProjectManifest applyPathPatternEditRequestToManifest({
  required ProjectManifest manifest,
  required PathStudioEditPathBuildRequest request,
}) {
  final originalBaseIndex = manifest.pathPresets.indexWhere(
    (preset) => preset.id == request.originalBasePathPresetId,
  );
  if (originalBaseIndex < 0) {
    throw ArgumentError(
      'Original ProjectPathPreset not found: ${request.originalBasePathPresetId}',
    );
  }
  final originalPatternIndex = manifest.pathPatternPresets.indexWhere(
    (preset) => preset.id == request.originalPathPatternPresetId,
  );
  if (originalPatternIndex < 0) {
    throw ArgumentError(
      'Original ProjectPathPatternPreset not found: ${request.originalPathPatternPresetId}',
    );
  }
  final collidingBaseIndex = manifest.pathPresets.indexWhere(
    (preset) =>
        preset.id == request.updatedBasePathPreset.id &&
        preset.id != request.originalBasePathPresetId,
  );
  if (collidingBaseIndex >= 0) {
    throw ArgumentError(
      'ProjectPathPreset id collision: ${request.updatedBasePathPreset.id}',
    );
  }
  final collidingPatternIndex = manifest.pathPatternPresets.indexWhere(
    (preset) =>
        preset.id == request.updatedPathPatternPreset.id &&
        preset.id != request.originalPathPatternPresetId,
  );
  if (collidingPatternIndex >= 0) {
    throw ArgumentError(
      'ProjectPathPatternPreset id collision: ${request.updatedPathPatternPreset.id}',
    );
  }

  final nextPathPresets = List<ProjectPathPreset>.from(manifest.pathPresets);
  nextPathPresets[originalBaseIndex] = request.updatedBasePathPreset;
  final nextPathPatternPresets =
      List<ProjectPathPatternPreset>.from(manifest.pathPatternPresets);
  nextPathPatternPresets[originalPatternIndex] =
      request.updatedPathPatternPreset;
  return manifest.copyWith(
    pathPresets: nextPathPresets,
    pathPatternPresets: nextPathPatternPresets,
  );
}
