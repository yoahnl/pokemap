import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

/// Génère un identifiant de scénario stable, lisible, et unique dans le projet.
///
/// Pourquoi cette fonction existe:
/// - l'authoring no-code doit éviter les conflits d'IDs;
/// - l'utilisateur doit pouvoir saisir un nom humain, puis laisser l'outil
///   fabriquer un `id` valide automatiquement;
/// - on garde une convention simple (`snake_case`) pour les fichiers/projections.
String generateUniqueScenarioId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'cutscene' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.scenarios.map((scenario) => scenario.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

/// Crée un scénario dans le manifest projet.
///
/// Frontière de responsabilité:
/// - cette classe ne fait PAS de logique UI;
/// - elle valide et persiste une mutation métier;
/// - elle laisse l'assemblage "template -> scénario" au niveau application/UI.
class CreateProjectScenarioUseCase {
  CreateProjectScenarioUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required ScenarioAsset scenario,
  }) async {
    final id = scenario.id.trim();
    final name = scenario.name.trim();
    if (id.isEmpty) {
      throw const EditorValidationException('Scenario id cannot be empty');
    }
    if (name.isEmpty) {
      throw const EditorValidationException('Scenario name cannot be empty');
    }
    if (project.scenarios.any((entry) => entry.id == id)) {
      throw EditorConflictException('Scenario id already exists: $id');
    }

    final updated = project.copyWith(
      scenarios: <ScenarioAsset>[...project.scenarios, scenario],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

/// Met à jour un scénario existant du manifest.
///
/// On passe le `scenarioId` "source" séparément de `nextScenario.id` pour
/// supporter un renommage d'identifiant si nécessaire, tout en conservant des
/// validations explicites de collision.
class UpdateProjectScenarioUseCase {
  UpdateProjectScenarioUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required ScenarioAsset nextScenario,
  }) async {
    final sourceId = scenarioId.trim();
    final targetId = nextScenario.id.trim();
    final targetName = nextScenario.name.trim();
    if (sourceId.isEmpty) {
      throw const EditorValidationException('Scenario id cannot be empty');
    }
    if (targetId.isEmpty) {
      throw const EditorValidationException('Scenario next id cannot be empty');
    }
    if (targetName.isEmpty) {
      throw const EditorValidationException('Scenario name cannot be empty');
    }

    final index = project.scenarios.indexWhere((entry) => entry.id == sourceId);
    if (index < 0) {
      throw EditorNotFoundException('Scenario not found: $sourceId');
    }
    if (sourceId != targetId &&
        project.scenarios.any((entry) => entry.id == targetId)) {
      throw EditorConflictException('Scenario id already exists: $targetId');
    }

    final nextList = List<ScenarioAsset>.from(project.scenarios);
    nextList[index] = nextScenario;
    final updated = project.copyWith(scenarios: nextList);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

/// Supprime un scénario du manifest projet.
class DeleteProjectScenarioUseCase {
  DeleteProjectScenarioUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
  }) async {
    final id = scenarioId.trim();
    if (id.isEmpty) {
      throw const EditorValidationException('Scenario id cannot be empty');
    }
    final exists = project.scenarios.any((entry) => entry.id == id);
    if (!exists) {
      throw EditorNotFoundException('Scenario not found: $id');
    }

    final updated = project.copyWith(
      scenarios: project.scenarios.where((entry) => entry.id != id).toList(),
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
