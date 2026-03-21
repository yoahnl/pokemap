import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import '../../../app/providers/use_case_providers.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';

part 'editor_notifier.g.dart';

@riverpod
class EditorNotifier extends _$EditorNotifier {
  @override
  EditorState build() {
    return const EditorState();
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      
      state = state.copyWith(
        project: manifest,
        fileSystem: ProjectFileSystem(directory),
        activeMap: null,
        activeMapPath: null,
        statusMessage: 'Project "$name" created successfully',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> loadProject(String manifestPath) async {
    debugPrint('EditorNotifier: loadProject($manifestPath)');
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      
      state = state.copyWith(
        project: manifest,
        fileSystem: ProjectFileSystem(projectDir),
        activeMap: null,
        activeMapPath: null,
        statusMessage: 'Project "${manifest.name}" loaded',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error loading project: $e');
      state = state.copyWith(errorMessage: 'Failed to load project: $e');
    }
  }

  Future<void> saveActiveMap() async {
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = state.copyWith(isSaving: true);
    
    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(map, path);
      
      state = state.copyWith(
        isSaving: false,
        isDirty: false,
        statusMessage: 'Map "${map.id}" saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save map: $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height) async {
    debugPrint('EditorNotifier: createMap($id, $width, $height)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height);

      state = state.copyWith(
        project: project.copyWith(
          maps: [...project.maps, ProjectMapEntry(id: id, name: id, relativePath: fs.getMapRelativePath(id))]
        ),
        activeMap: map,
        activeMapPath: fs.getMapPath(id),
        activeLayerId: map.layers.isNotEmpty ? map.layers.first.id : null,
        statusMessage: 'Map "$id" created successfully',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Failed to create map: $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = state.fileSystem;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final map = await useCase.execute(fs, relativePath);
      
      state = state.copyWith(
        activeMap: map,
        activeMapPath: fs.resolveMapPath(relativePath),
        activeLayerId: map.layers.isNotEmpty ? map.layers.first.id : null,
        statusMessage: 'Map "${map.id}" loaded',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      
      // If the renamed map was active, update state
      MapData? activeMap = state.activeMap;
      String? activePath = state.activeMapPath;
      if (activeMap?.id == oldId) {
        activeMap = activeMap?.copyWith(id: newId, name: newId);
        activePath = fs.getMapPath(newId);
      }

      state = state.copyWith(
        project: updatedProject,
        activeMap: activeMap,
        activeMapPath: activePath,
        statusMessage: 'Map renamed to "$newId"',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state = state.copyWith(errorMessage: 'Failed to rename map: $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      
      // If the deleted map was active, clear it
      MapData? activeMap = state.activeMap;
      String? activePath = state.activeMapPath;
      if (activeMap?.id == mapId) {
        activeMap = null;
        activePath = null;
      }

      state = state.copyWith(
        project: updatedProject,
        activeMap: activeMap,
        activeMapPath: activePath,
        statusMessage: 'Map "$mapId" deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state = state.copyWith(errorMessage: 'Failed to delete map: $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);
      
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map "$sourceId" duplicated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state = state.copyWith(errorMessage: 'Failed to duplicate map: $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = state.copyWith(activeTool: tool);
  }

  void setActiveLayer(String layerId) {
    state = state.copyWith(activeLayerId: layerId);
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }
}
