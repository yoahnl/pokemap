import '../exceptions/map_exceptions.dart';
import '../models/environment.dart';
import '../models/project_manifest.dart';

/// Retourne la liste exposée par [ProjectManifest.environmentPresets].
List<EnvironmentPreset> readProjectEnvironmentPresets(
  ProjectManifest manifest,
) {
  return manifest.environmentPresets;
}

/// `true` lorsque le manifest contient au moins un preset environnement.
bool hasProjectEnvironmentPresets(ProjectManifest manifest) {
  return manifest.environmentPresets.isNotEmpty;
}

/// Retourne le preset dont [presetId] égale [EnvironmentPreset.id], ou `null`.
///
/// [presetId] est trimé ; `null` si vide / whitespace uniquement ou inconnu.
/// Ne lève pas si absent.
EnvironmentPreset? findProjectEnvironmentPresetById(
  ProjectManifest manifest,
  String presetId,
) {
  final key = presetId.trim();
  if (key.isEmpty) {
    return null;
  }
  for (final preset in manifest.environmentPresets) {
    if (preset.id == key) {
      return preset;
    }
  }
  return null;
}

/// Remplace toute la liste ; refuse deux [EnvironmentPreset.id] identiques.
ProjectManifest replaceProjectEnvironmentPresets(
  ProjectManifest manifest,
  List<EnvironmentPreset> presets,
) {
  _validateUniqueEnvironmentPresetIds(presets);
  return manifest.copyWith(
      environmentPresets: List<EnvironmentPreset>.from(presets));
}

/// Insère ou remplace par [EnvironmentPreset.id] à la même position si existant.
///
/// Exige que le manifest courant n’ait pas de doublons d’id (état corrompu).
ProjectManifest upsertProjectEnvironmentPreset(
  ProjectManifest manifest,
  EnvironmentPreset preset,
) {
  _validateUniqueEnvironmentPresetIds(manifest.environmentPresets);
  final next = List<EnvironmentPreset>.from(
    manifest.environmentPresets,
    growable: true,
  );
  final index = next.indexWhere((existing) => existing.id == preset.id);
  if (index < 0) {
    next.add(preset);
  } else {
    next[index] = preset;
  }
  return manifest.copyWith(environmentPresets: next);
}

/// Supprime le preset dont l’id correspond à [presetId] trimé.
///
/// Comme [removeProjectPathPatternPreset] : identifiant vide ⇒ [ArgumentError].
/// Si inconnu après trim : manifest inchangé.
ProjectManifest removeProjectEnvironmentPresetById(
  ProjectManifest manifest,
  String presetId,
) {
  _validatePresetIdArgument(presetId);
  _validateNoDuplicateEnvironmentPresetIds(
      manifest.environmentPresets, presetId);
  final next = [
    for (final preset in manifest.environmentPresets)
      if (preset.id != presetId.trim()) preset,
  ];
  return manifest.copyWith(environmentPresets: next);
}

/// Liste vide.
ProjectManifest clearProjectEnvironmentPresets(ProjectManifest manifest) {
  return manifest.copyWith(environmentPresets: const []);
}

void _validateUniqueEnvironmentPresetIds(List<EnvironmentPreset> presets) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ValidationException(
        'Duplicate EnvironmentPreset id: ${preset.id}',
      );
    }
  }
}

/// Détecte plusieurs entrées avec le même id que [presetId] (cohérence manifeste).
void _validateNoDuplicateEnvironmentPresetIds(
  List<EnvironmentPreset> presets,
  String presetId,
) {
  final key = presetId.trim();
  var count = 0;
  for (final preset in presets) {
    if (preset.id == key) {
      count += 1;
      if (count > 1) {
        throw ValidationException(
          'Duplicate EnvironmentPreset id: $key',
        );
      }
    }
  }
}

void _validatePresetIdArgument(String presetId) {
  if (presetId.trim().isEmpty) {
    throw ArgumentError.value(
      presetId,
      'presetId',
      'EnvironmentPreset id must not be blank.',
    );
  }
}
