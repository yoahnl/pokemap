import '../exceptions/map_exceptions.dart';
import '../models/project_manifest.dart';
import '../models/project_path_pattern_preset.dart';

/// Returns the manifest PathPattern presets as exposed by [ProjectManifest].
List<ProjectPathPatternPreset> readProjectPathPatternPresets(
  ProjectManifest manifest,
) {
  return manifest.pathPatternPresets;
}

/// Returns the PathPattern preset with [presetId], or `null` when absent.
ProjectPathPatternPreset? projectPathPatternPresetById({
  required ProjectManifest manifest,
  required String presetId,
}) {
  _validatePresetId(presetId);
  ProjectPathPatternPreset? found;
  for (final preset in manifest.pathPatternPresets) {
    if (preset.id != presetId) {
      continue;
    }
    if (found != null) {
      throw ValidationException(
          'Duplicate ProjectPathPatternPreset id: $presetId');
    }
    found = preset;
  }
  return found;
}

/// True when [manifest] contains exactly one PathPattern preset with [presetId].
bool containsProjectPathPatternPreset({
  required ProjectManifest manifest,
  required String presetId,
}) {
  return projectPathPatternPresetById(
        manifest: manifest,
        presetId: presetId,
      ) !=
      null;
}

/// Replaces the full manifest PathPattern preset list.
ProjectManifest replaceProjectPathPatternPresets({
  required ProjectManifest manifest,
  required List<ProjectPathPatternPreset> presets,
}) {
  _validateUniqueProjectPathPatternPresetIds(presets);
  return manifest.copyWith(pathPatternPresets: presets);
}

/// Inserts [preset] or replaces the existing preset with the same exact id.
ProjectManifest upsertProjectPathPatternPreset({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
}) {
  _validateUniqueProjectPathPatternPresetIds(manifest.pathPatternPresets);
  final next = List<ProjectPathPatternPreset>.from(
    manifest.pathPatternPresets,
    growable: true,
  );
  final index = next.indexWhere((existing) => existing.id == preset.id);
  if (index < 0) {
    next.add(preset);
  } else {
    next[index] = preset;
  }
  return manifest.copyWith(pathPatternPresets: next);
}

/// Removes the preset with [presetId], if present.
ProjectManifest removeProjectPathPatternPreset({
  required ProjectManifest manifest,
  required String presetId,
}) {
  _validatePresetId(presetId);
  _validateDuplicateMatches(manifest.pathPatternPresets, presetId);
  final next = [
    for (final preset in manifest.pathPatternPresets)
      if (preset.id != presetId) preset,
  ];
  return manifest.copyWith(pathPatternPresets: next);
}

/// Clears all manifest PathPattern presets.
ProjectManifest clearProjectPathPatternPresets(ProjectManifest manifest) {
  return manifest.copyWith(pathPatternPresets: const []);
}

void _validateUniqueProjectPathPatternPresetIds(
  List<ProjectPathPatternPreset> presets,
) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ValidationException(
        'Duplicate ProjectPathPatternPreset id: ${preset.id}',
      );
    }
  }
}

void _validateDuplicateMatches(
  List<ProjectPathPatternPreset> presets,
  String presetId,
) {
  var count = 0;
  for (final preset in presets) {
    if (preset.id == presetId) {
      count += 1;
      if (count > 1) {
        throw ValidationException(
          'Duplicate ProjectPathPatternPreset id: $presetId',
        );
      }
    }
  }
}

void _validatePresetId(String presetId) {
  if (presetId.trim().isEmpty) {
    throw ArgumentError.value(
      presetId,
      'presetId',
      'ProjectPathPatternPreset id must not be blank.',
    );
  }
}
