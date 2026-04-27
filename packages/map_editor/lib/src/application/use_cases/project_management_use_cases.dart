import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../ports/project_workspace.dart';

class CreateProjectUseCase {
  CreateProjectUseCase(this._repo, this._workspaceFactory);

  final ProjectRepository _repo;
  final ProjectWorkspaceFactory _workspaceFactory;

  Future<ProjectManifest> execute(String name, String directory) async {
    final manifest = ProjectManifest(
      name: name,
      maps: [],
      tilesets: [],
      groups: [],
      elementCategories: const [],
      elements: const [],
      terrainCategories: const [],
      pathCategories: const [],
      terrainPresets: const [],
      pathPresets: const [],
      settings: const ProjectSettings(),
      surfaceCatalog: const ProjectSurfaceCatalog(),
    );
    final workspace = _workspaceFactory.create(directory);
    final projectFile = workspace.projectManifestPath;
    await workspace.ensureDirectoryExists(projectFile);

    await _repo.saveProject(manifest, projectFile);
    return manifest;
  }
}

class LoadProjectUseCase {
  LoadProjectUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(String manifestPath) async {
    return _repo.loadProject(manifestPath);
  }
}

class UpdateProjectSettingsUseCase {
  UpdateProjectSettingsUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required ProjectSettings settings,
  }) async {
    final updated = project.copyWith(name: name, settings: settings);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
