import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../ports/project_workspace.dart';

class CreateProjectUseCase {
  CreateProjectUseCase(this._repo, this._workspaceFactory);

  final ProjectRepository _repo;
  final ProjectWorkspaceFactory _workspaceFactory;

  Future<ProjectManifest> execute(String name, String directory) async {
    final manifest = ProjectManifest(
      version: ProjectVersion.v8,
      name: name,
      maps: [],
      tilesets: [],
      groups: [],
      elementCategories: const [],
      elements: const [],
      settings: const ProjectSettings(),
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
  UpdateProjectSettingsUseCase(this._repo, this._maps);

  final ProjectRepository _repo;
  final MapRepository _maps;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required ProjectSettings settings,
    MapData? activeMap,
  }) async {
    final updated = project.copyWith(name: name, settings: settings);
    if (settings.tileWidth != project.settings.tileWidth ||
        settings.tileHeight != project.settings.tileHeight) {
      void validateGrid(MapData map, ProjectMapEntry entry) {
        try {
          if (map.id != entry.id) {
            throw const ValidationException('Identité de carte incohérente');
          }
          MapValidator.validate(map, projectDialogueContext: project);
          for (final instance in map.placedElements) {
            try {
              validateMapPlacedElementPixelGeometry(instance, tileSize: PixelSize(width: settings.tileWidth, height: settings.tileHeight));
            } on ValidationException catch (error) {
              throw ValidationException('Décor ${instance.id} : ${error.message}');
            }
          }
          MapValidator.validate(map, projectDialogueContext: updated);
        } on ValidationException catch (error) {
          throw ValidationException('La nouvelle grille invalide la carte « ${entry.name} » (${entry.id}) : ${error.message}');
        }
      }
      if (activeMap != null) {
        final entry = project.maps.where((entry) => entry.id == activeMap.id).firstOrNull;
        if (entry == null) {
          throw ValidationException('La carte active ${activeMap.id} ne fait pas partie du projet');
        }
        validateGrid(activeMap, entry);
      }
      for (final entry in project.maps) {
        final map = await _maps.loadMap(workspace.resolveMapPath(entry.relativePath));
        validateGrid(map, entry);
      }
    }
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
