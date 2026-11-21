import 'dart:io';

import 'package:path/path.dart' as p;

enum RuntimeProjectPickOutcome {
  selected,
  cancelled,
  invalidSelection,
}

class RuntimeProjectPickResult {
  const RuntimeProjectPickResult._({
    required this.outcome,
    this.projectJsonPath,
    this.errorMessage,
  });

  const RuntimeProjectPickResult.selected(String projectJsonPath)
      : this._(
          outcome: RuntimeProjectPickOutcome.selected,
          projectJsonPath: projectJsonPath,
        );

  const RuntimeProjectPickResult.cancelled()
      : this._(outcome: RuntimeProjectPickOutcome.cancelled);

  const RuntimeProjectPickResult.invalidSelection(String errorMessage)
      : this._(
          outcome: RuntimeProjectPickOutcome.invalidSelection,
          errorMessage: errorMessage,
        );

  final RuntimeProjectPickOutcome outcome;
  final String? projectJsonPath;
  final String? errorMessage;

  bool get didSelectProject => outcome == RuntimeProjectPickOutcome.selected;
  bool get didCancel => outcome == RuntimeProjectPickOutcome.cancelled;
}

typedef RuntimeProjectDirectoryPicker = Future<String?> Function();
typedef RuntimeProjectImporter = Future<String> Function(String projectJsonPath);
typedef RuntimeProjectExists = Future<bool> Function(String path);

/// Sélectionne un dossier projet via le picker natif, puis valide qu'il expose
/// bien un `project.json`.
///
/// Frontière volontaire:
/// - on demande un dossier projet complet, pas un fichier isolé, pour garder
///   `maps/` et assets cohérents sur iOS;
/// - l'import/copie dans le sandbox applicatif reste injectable pour être
///   testable et pour conserver la persistance locale existante du host;
/// - on ne retombe pas automatiquement sur un scan de Documents quand
///   l'utilisateur annule, afin d'éviter un faux message d'erreur.
Future<RuntimeProjectPickResult> pickRuntimeProjectDirectory({
  required RuntimeProjectDirectoryPicker pickDirectoryPath,
  required RuntimeProjectImporter importProjectJsonPath,
  RuntimeProjectExists projectFileExists = _projectFileExists,
}) async {
  final selectedDirectoryPath = await pickDirectoryPath();
  if (selectedDirectoryPath == null || selectedDirectoryPath.trim().isEmpty) {
    return const RuntimeProjectPickResult.cancelled();
  }

  final normalizedDirectoryPath = selectedDirectoryPath.trim();
  final projectJsonPath = p.join(normalizedDirectoryPath, 'project.json');
  if (!await projectFileExists(projectJsonPath)) {
    return const RuntimeProjectPickResult.invalidSelection(
      'Le dossier sélectionné ne contient pas de project.json.',
    );
  }

  final importedProjectJsonPath = await importProjectJsonPath(projectJsonPath);
  return RuntimeProjectPickResult.selected(importedProjectJsonPath);
}

Future<bool> _projectFileExists(String path) async {
  return File(path).exists();
}
