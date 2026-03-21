import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:map_core/map_core.dart';
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
        statusMessage: 'Project "$name" created successfully',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> createMap(String id, int width, int height) async {
    debugPrint('EditorNotifier: createMap($id, $width, $height)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) {
      debugPrint('EditorNotifier: Cannot create map, missing filesystem or project');
      return;
    }

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height);

      state = state.copyWith(
        project: project.copyWith(
          maps: [...project.maps, ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json')]
        ),
        activeMap: map,
        activeMapPath: fs.resolveMapPath('maps/$id.json'),
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
