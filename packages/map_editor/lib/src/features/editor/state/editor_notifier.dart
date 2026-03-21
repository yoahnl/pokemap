import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
        selectedTileId: null,
        selectedPaletteEntryId: null,
        selectedProjectElementId: null,
        paletteCategoryFilter: null,
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
        selectedTileId: null,
        selectedPaletteEntryId: null,
        selectedProjectElementId: null,
        paletteCategoryFilter: null,
        statusMessage: 'Project "${manifest.name}" loaded',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error loading project: $e');
      state = state.copyWith(errorMessage: 'Failed to load project: $e');
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
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

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);

      state = state.copyWith(
        project: project.copyWith(maps: [
          ...project.maps,
          ProjectMapEntry(
            id: id,
            name: id,
            relativePath: fs.getMapRelativePath(id),
            groupId: groupId,
            role: role,
          )
        ]),
        activeMap: map,
        activeMapPath: fs.getMapPath(id),
        activeLayerId: map.layers.isNotEmpty ? map.layers.first.id : null,
        selectedTileId: null,
        selectedPaletteEntryId: null,
        selectedProjectElementId: null,
        paletteCategoryFilter: null,
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
        selectedTileId: null,
        selectedPaletteEntryId: null,
        selectedProjectElementId: null,
        paletteCategoryFilter: null,
        statusMessage: 'Map "${map.id}" loaded',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);

      if (resized == map) {
        state = state.copyWith(
          statusMessage: 'Map "${map.id}" is already ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;

      state = state.copyWith(
        activeMap: resized,
        hoveredTile: nextHovered,
        isDirty: true,
        statusMessage: 'Map "${map.id}" resized to ${width}x$height',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(errorMessage: 'Failed to resize map: $e');
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

      MapData? activeMap = state.activeMap;
      String? activePath = state.activeMapPath;
      int? selectedTileId = state.selectedTileId;
      String? selectedPaletteEntryId = state.selectedPaletteEntryId;
      String? selectedProjectElementId = state.selectedProjectElementId;
      PaletteCategory? paletteCategoryFilter = state.paletteCategoryFilter;
      if (activeMap?.id == mapId) {
        activeMap = null;
        activePath = null;
        selectedTileId = null;
        selectedPaletteEntryId = null;
        selectedProjectElementId = null;
        paletteCategoryFilter = null;
      }

      state = state.copyWith(
        project: updatedProject,
        activeMap: activeMap,
        activeMapPath: activePath,
        selectedTileId: selectedTileId,
        selectedPaletteEntryId: selectedPaletteEntryId,
        selectedProjectElementId: selectedProjectElementId,
        paletteCategoryFilter: paletteCategoryFilter,
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

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    if (project == null || map == null || mapPath == null) return;

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap =
          await useCase.execute(project, map, mapPath, tilesetId);
      state = state.copyWith(
        activeMap: updatedMap,
        selectedTileId: null,
        selectedPaletteEntryId: null,
        selectedProjectElementId: null,
        paletteCategoryFilter: null,
        isDirty: false,
        statusMessage:
            'Tileset "${updatedMap.tilesetId}" assigned to "${map.id}"',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning map tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to assign map tileset: $e');
    }
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == map.tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = state.fileSystem;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = map.tilesetId;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: map.tilesetId,
        categoryId: categoryId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        selectedProjectElementId: result.element.id,
        selectedPaletteEntryId: null,
        selectedTileId: null,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    String? categoryId,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<String>? tags,
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        categoryId: categoryId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        source: source,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tileset = getActiveTilesetEntry();
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tileset = getActiveTilesetEntry();
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId, {String? paletteEntryId}) {
    state = state.copyWith(
      selectedTileId: tileId,
      selectedPaletteEntryId: paletteEntryId,
      selectedProjectElementId: null,
    );
  }

  void selectPaletteEntry(
    String entryId, {
    int? tilesetColumns,
  }) {
    final entry = getActivePaletteEntryById(entryId);
    if (entry == null) return;
    int? tileId = state.selectedTileId;
    if (entry.source.width == 1 && entry.source.height == 1) {
      if (tilesetColumns != null && tilesetColumns > 0) {
        tileId = entry.source.y * tilesetColumns + entry.source.x + 1;
      }
    } else {
      tileId = null;
    }
    state = state.copyWith(
      selectedPaletteEntryId: entryId,
      selectedTileId: tileId,
      selectedProjectElementId: null,
    );
  }

  void selectProjectElement(
    String elementId, {
    int? tilesetColumns,
  }) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    int? tileId;
    if (element.source.width == 1 &&
        element.source.height == 1 &&
        tilesetColumns != null &&
        tilesetColumns > 0) {
      tileId = element.source.y * tilesetColumns + element.source.x + 1;
    }
    state = state.copyWith(
      selectedProjectElementId: element.id,
      selectedPaletteEntryId: null,
      selectedTileId: tileId,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    final tileset = getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        selectedPaletteEntryId: result.entry.id,
        selectedProjectElementId: null,
        selectedTileId: null,
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = state.fileSystem;
    final project = state.project;
    final tileset = getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      if (entry.source.width == 1 &&
          entry.source.height == 1 &&
          entry.source.x == sourceX &&
          entry.source.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      source: TilesetSourceRect(x: sourceX, y: sourceY),
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        selectedPaletteEntryId: entry.id,
        selectedProjectElementId: null,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(GridPos pos, {required int tilesetColumns}) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return;

    final selectedProjectElementId = state.selectedProjectElementId;
    if (selectedProjectElementId != null) {
      final element = getProjectElementById(selectedProjectElementId);
      if (element != null) {
        if (element.tilesetId != map.tilesetId) {
          state = state.copyWith(
            errorMessage:
                'Element "${element.name}" belongs to another tileset',
          );
          return;
        }
        if (tilesetColumns <= 0) {
          state = state.copyWith(
            errorMessage: 'Active tileset image is not available',
          );
          return;
        }
        final width = element.source.width;
        final height = element.source.height;
        final pattern = List<int>.filled(width * height, 0, growable: false);
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final sourceX = element.source.x + x;
            final sourceY = element.source.y + y;
            pattern[y * width + x] = sourceY * tilesetColumns + sourceX + 1;
          }
        }
        try {
          final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
          final painted = useCase.execute(
            map,
            layerId: layerId,
            pos: pos,
            patternSize: GridSize(width: width, height: height),
            tiles: pattern,
            clipToMapBounds: true,
          );
          state = state.copyWith(
            activeMap: painted,
            isDirty: true,
            errorMessage: null,
          );
          return;
        } catch (e) {
          state = state.copyWith(errorMessage: 'Failed to paint element: $e');
          return;
        }
      }
    }

    final entryId = state.selectedPaletteEntryId;
    if (entryId != null) {
      final entry = getActivePaletteEntryById(entryId);
      if (entry != null && tilesetColumns > 0) {
        final width = entry.source.width;
        final height = entry.source.height;
        final pattern = List<int>.filled(width * height, 0, growable: false);
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final sourceX = entry.source.x + x;
            final sourceY = entry.source.y + y;
            pattern[y * width + x] = sourceY * tilesetColumns + sourceX + 1;
          }
        }
        try {
          final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
          final painted = useCase.execute(
            map,
            layerId: layerId,
            pos: pos,
            patternSize: GridSize(width: width, height: height),
            tiles: pattern,
            clipToMapBounds: true,
          );
          state = state.copyWith(
            activeMap: painted,
            isDirty: true,
            errorMessage: null,
          );
          return;
        } catch (e) {
          state = state.copyWith(errorMessage: 'Failed to paint element: $e');
          return;
        }
      }
    }

    final tileId = state.selectedTileId;
    if (tileId == null) return;
    try {
      final useCase = ref.read(paintTileOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        tileId: tileId,
      );
      state = state.copyWith(
        activeMap: painted,
        isDirty: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to paint tile: $e');
    }
  }

  void paintSelectedTileAt(GridPos pos) {
    paintSelectedBrushAt(pos, tilesetColumns: 0);
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
