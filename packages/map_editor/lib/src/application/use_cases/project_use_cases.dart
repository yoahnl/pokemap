import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../ports/project_workspace.dart';
import '../../domain/repositories/repositories.dart';

part 'paint_use_cases.dart';
part 'collision_use_cases.dart';
part 'terrain_use_cases.dart';
part 'terrain_preset_use_cases.dart';
part 'layer_use_cases.dart';
part 'map_use_cases.dart';
part 'warp_use_cases.dart';

class CreateProjectUseCase {
  final ProjectRepository _repo;
  final ProjectWorkspaceFactory _workspaceFactory;

  CreateProjectUseCase(this._repo, this._workspaceFactory);

  Future<ProjectManifest> execute(String name, String directory) async {
    final manifest = ProjectManifest(
      name: name,
      maps: [],
      tilesets: [],
      groups: [],
      elementCategories: _defaultElementCategories(),
      elements: const [],
      terrainPresetCategories: _defaultTerrainPresetCategories(),
      terrainPresets: _defaultTerrainPresets(),
      pathPresets: _defaultPathPresets(),
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
  final ProjectRepository _repo;

  LoadProjectUseCase(this._repo);

  Future<ProjectManifest> execute(String manifestPath) async {
    final loaded = await _repo.loadProject(manifestPath);
    return _withDefaultProjectLibrary(loaded);
  }
}

class UpdateProjectSettingsUseCase {
  final ProjectRepository _repo;

  UpdateProjectSettingsUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String name,
    required ProjectSettings settings,
  }) async {
    final updated = project.copyWith(name: name, settings: settings);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class ImportProjectTilesetUseCase {
  final ProjectRepository _repo;

  ImportProjectTilesetUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Tileset name cannot be empty');
    }
    if (scope == TilesetScope.global) {
      groupId = null;
    } else if (groupId == null) {
      throw Exception('A group-scoped tileset must target a group');
    }
    if (scope != TilesetScope.global && isWorldTileset) {
      throw Exception('World tileset must be global');
    }

    final sourceExt = p.extension(sourcePath).toLowerCase();
    const allowedExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'};
    if (!allowedExtensions.contains(sourceExt)) {
      throw Exception('Unsupported tileset image format: $sourceExt');
    }

    final id = _generateUniqueTilesetId(project, trimmedName);
    final relativePath = await fs.importTilesetImage(
      sourcePath,
      preferredName: id,
    );

    final sortOrder = _nextTilesetSortOrder(project, scope, groupId);
    final entry = ProjectTilesetEntry(
      id: id,
      name: trimmedName,
      relativePath: relativePath,
      scope: scope,
      groupId: groupId,
      sortOrder: sortOrder,
      isWorldTileset: isWorldTileset,
    );

    final updatedProject = project.copyWith(
      tilesets: [...project.tilesets, entry],
    );

    try {
      await _repo.saveProject(updatedProject, fs.projectManifestPath);
      return updatedProject;
    } catch (e) {
      await fs.deleteRelativeFile(relativePath);
      rethrow;
    }
  }
}

class UpdateProjectTilesetUseCase {
  final ProjectRepository _repo;

  UpdateProjectTilesetUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
  }) async {
    final current = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    var nextScope = scope ?? current.scope;
    var nextGroupId = groupId ?? current.groupId;
    var nextWorld = isWorldTileset ?? current.isWorldTileset;

    if (nextScope == TilesetScope.global) {
      nextGroupId = null;
    } else if (nextGroupId == null) {
      throw Exception('A group-scoped tileset must target a group');
    }
    if (nextScope != TilesetScope.global) {
      nextWorld = false;
    }

    final updatedTilesets = project.tilesets.map((tileset) {
      if (tileset.id != tilesetId) return tileset;
      return tileset.copyWith(
        name: name?.trim().isNotEmpty == true ? name!.trim() : tileset.name,
        scope: nextScope,
        groupId: nextGroupId,
        isWorldTileset: nextWorld,
        sortOrder: sortOrder ?? tileset.sortOrder,
      );
    }).toList();

    final updatedProject = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class DeleteProjectTilesetUseCase {
  final ProjectRepository _projectRepo;
  final MapRepository _mapRepo;

  DeleteProjectTilesetUseCase(this._projectRepo, this._mapRepo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project,
    String tilesetId,
  ) async {
    final target = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    for (final mapEntry in project.maps) {
      final mapPath = fs.resolveMapPath(mapEntry.relativePath);
      final map = await _mapRepo.loadMap(mapPath);
      final hasLayerTilesetAssignments = map.layers.whereType<TileLayer>().any(
        (layer) {
          final layerTilesetId = layer.tilesetId?.trim();
          return layerTilesetId != null && layerTilesetId.isNotEmpty;
        },
      );
      final isUsedByLayer = map.layers.whereType<TileLayer>().any(
            (layer) => layer.tilesetId == tilesetId,
          );
      final isUsedByLegacyMapField =
          !hasLayerTilesetAssignments && map.tilesetId.trim() == tilesetId;
      if (isUsedByLayer || isUsedByLegacyMapField) {
        throw Exception(
            'Tileset "$tilesetId" is still used by map "${map.id}"');
      }
    }

    final remainingTilesets =
        project.tilesets.where((t) => t.id != tilesetId).toList();
    final updatedTerrainPresets = project.terrainPresets
        .map((preset) => preset.tilesetId == tilesetId
            ? preset.copyWith(tilesetId: '', variants: const [])
            : preset)
        .toList(growable: false);
    final updatedPathPresets = project.pathPresets
        .map((preset) => preset.tilesetId == tilesetId
            ? preset.copyWith(tilesetId: '', variants: const [])
            : preset)
        .toList(growable: false);
    final updatedProject = project.copyWith(
      tilesets: remainingTilesets,
      terrainPresets: updatedTerrainPresets,
      pathPresets: updatedPathPresets,
    );
    await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);

    final stillUsedPath =
        remainingTilesets.any((t) => t.relativePath == target.relativePath);
    if (!stillUsedPath) {
      await fs.deleteRelativeFile(target.relativePath);
    }

    return updatedProject;
  }
}

class ReorderProjectTilesetUseCase {
  final ProjectRepository _repo;

  ReorderProjectTilesetUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    required int direction,
  }) async {
    if (direction == 0) return project;
    final target = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    final bucket = project.tilesets.where((t) {
      if (t.scope != target.scope) return false;
      if (target.scope == TilesetScope.global) return true;
      return t.groupId == target.groupId;
    }).toList()
      ..sort(_tilesetSort);

    final index = bucket.indexWhere((t) => t.id == tilesetId);
    if (index < 0) return project;
    final nextIndex = (index + direction).clamp(0, bucket.length - 1);
    if (nextIndex == index) return project;

    final moving = bucket.removeAt(index);
    bucket.insert(nextIndex, moving);

    final orderById = <String, int>{};
    for (var i = 0; i < bucket.length; i++) {
      orderById[bucket[i].id] = i;
    }

    final updatedTilesets = project.tilesets.map((t) {
      final nextSort = orderById[t.id];
      if (nextSort == null) return t;
      return t.copyWith(sortOrder: nextSort);
    }).toList();

    final updatedProject = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class ResolveAssignableTilesetsForMapUseCase {
  List<ProjectTilesetEntry> execute(ProjectManifest project, String mapId) {
    final mapEntry = project.maps.firstWhere(
      (m) => m.id == mapId,
      orElse: () => throw Exception('Map not found in manifest: $mapId'),
    );

    final allowedGroupIds = <String>{};
    String? cursor = mapEntry.groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      allowedGroupIds.add(cursor);
      final nextGroup = project.groups.firstWhere(
        (g) => g.id == cursor,
        orElse: () =>
            throw Exception('Unknown group referenced by map: $cursor'),
      );
      cursor = nextGroup.parentGroupId;
    }

    final global = project.tilesets
        .where((t) => t.scope == TilesetScope.global)
        .toList(growable: false)
      ..sort(_tilesetSort);
    final grouped = project.tilesets
        .where((t) =>
            t.scope == TilesetScope.group &&
            t.groupId != null &&
            allowedGroupIds.contains(t.groupId))
        .toList(growable: false)
      ..sort(_tilesetSort);

    final result = <ProjectTilesetEntry>[];
    final added = <String>{};
    for (final tileset in [...global, ...grouped]) {
      if (added.add(tileset.id)) {
        result.add(tileset);
      }
    }
    return result;
  }
}

class AssignTilesetToMapUseCase {
  final MapRepository _mapRepo;
  final ResolveAssignableTilesetsForMapUseCase _resolver;

  AssignTilesetToMapUseCase(this._mapRepo, this._resolver);

  Future<MapData> execute(
    ProjectManifest project,
    MapData map,
    String mapPath,
    String layerId,
    String tilesetId,
  ) async {
    final assignable = _resolver.execute(project, map.id);
    final isAllowed = assignable.any((t) => t.id == tilesetId);
    if (!isAllowed) {
      throw Exception(
          'Tileset "$tilesetId" is not assignable to map "${map.id}"');
    }

    final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      throw Exception('Layer not found: $layerId');
    }
    final layer = map.layers[layerIndex];
    if (layer is! TileLayer) {
      throw Exception('Layer is not a tile layer: $layerId');
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: tilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? tilesetId : map.tilesetId,
    );
    MapValidator.validate(updatedMap);
    await _mapRepo.saveMap(updatedMap, mapPath);
    return updatedMap;
  }
}

class CreateElementCategoryUseCase {
  final ProjectRepository _repo;

  CreateElementCategoryUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String name,
    String? parentCategoryId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Category name cannot be empty');
    }
    if (parentCategoryId != null &&
        !project.elementCategories.any((c) => c.id == parentCategoryId)) {
      throw Exception('Parent category not found: $parentCategoryId');
    }

    final siblings = project.elementCategories
        .where((c) => c.parentCategoryId == parentCategoryId)
        .toList(growable: false);
    final id = _generateUniqueElementCategoryId(project, trimmedName);
    final category = ProjectElementCategory(
      id: id,
      name: trimmedName,
      parentCategoryId: parentCategoryId,
      sortOrder: siblings.length,
    );
    final updated = project.copyWith(
      elementCategories: [...project.elementCategories, category],
    );
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class CreateElementSubcategoryUseCase {
  final CreateElementCategoryUseCase _categoryUseCase;

  CreateElementSubcategoryUseCase(this._categoryUseCase);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String parentCategoryId,
    required String name,
  }) {
    return _categoryUseCase.execute(
      fs,
      project,
      name: name,
      parentCategoryId: parentCategoryId,
    );
  }
}

class RenameElementCategoryUseCase {
  final ProjectRepository _repo;

  RenameElementCategoryUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String categoryId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Category name cannot be empty');
    }
    final found = project.elementCategories.any((c) => c.id == categoryId);
    if (!found) {
      throw Exception('Category not found: $categoryId');
    }

    final updatedCategories = project.elementCategories.map((category) {
      if (category.id != categoryId) return category;
      return category.copyWith(name: trimmedName);
    }).toList(growable: false);
    final updated = project.copyWith(elementCategories: updatedCategories);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class CreateTilesetElementGroupUseCase {
  final ProjectRepository _repo;

  CreateTilesetElementGroupUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    required String name,
    String? parentGroupId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Tileset group name cannot be empty');
    }

    final tileset = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );
    if (parentGroupId != null &&
        !tileset.elementGroups.any((group) => group.id == parentGroupId)) {
      throw Exception('Parent tileset group not found: $parentGroupId');
    }

    final siblings = tileset.elementGroups
        .where((group) => group.parentGroupId == parentGroupId)
        .toList(growable: false);
    final group = TilesetElementGroup(
      id: _generateUniqueTilesetElementGroupId(tileset, trimmedName),
      name: trimmedName,
      parentGroupId: parentGroupId,
      sortOrder: siblings.length,
    );

    final updatedTilesets = project.tilesets.map((entry) {
      if (entry.id != tilesetId) return entry;
      return entry.copyWith(
        elementGroups: [...entry.elementGroups, group],
      );
    }).toList(growable: false);

    final updated = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class CreateTilesetElementSubgroupUseCase {
  final CreateTilesetElementGroupUseCase _groupUseCase;

  CreateTilesetElementSubgroupUseCase(this._groupUseCase);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    required String parentGroupId,
    required String name,
  }) {
    return _groupUseCase.execute(
      fs,
      project,
      tilesetId: tilesetId,
      parentGroupId: parentGroupId,
      name: name,
    );
  }
}

class RenameTilesetElementGroupUseCase {
  final ProjectRepository _repo;

  RenameTilesetElementGroupUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    required String groupId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Tileset group name cannot be empty');
    }

    final tileset = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );
    if (!tileset.elementGroups.any((group) => group.id == groupId)) {
      throw Exception('Tileset group not found: $groupId');
    }

    final updatedTilesets = project.tilesets.map((entry) {
      if (entry.id != tilesetId) return entry;
      final groups = entry.elementGroups.map((group) {
        if (group.id != groupId) return group;
        return group.copyWith(name: trimmedName);
      }).toList(growable: false);
      return entry.copyWith(elementGroups: groups);
    }).toList(growable: false);

    final updated = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class ResolveTilesetElementsUseCase {
  List<ProjectElementEntry> execute(
    ProjectManifest project, {
    required String tilesetId,
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final tileset = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    Set<String>? scope;
    if (tilesetGroupId != null) {
      if (!tileset.elementGroups.any((group) => group.id == tilesetGroupId)) {
        throw Exception('Tileset group not found: $tilesetGroupId');
      }
      if (includeDescendants) {
        scope = _collectTilesetGroupScope(
          groups: tileset.elementGroups,
          rootGroupId: tilesetGroupId,
        );
      } else {
        scope = {tilesetGroupId};
      }
    }

    final elements = project.elements.where((element) {
      if (element.tilesetId != tilesetId) return false;
      if (scope == null) return true;
      return element.tilesetGroupId != null &&
          scope.contains(element.tilesetGroupId);
    }).toList(growable: false)
      ..sort(_projectElementSort);
    return elements;
  }
}

class CreateProjectElementResult {
  final ProjectManifest project;
  final ProjectElementEntry element;

  const CreateProjectElementResult(this.project, this.element);
}

class CreateProjectElementUseCase {
  final ProjectRepository _repo;

  CreateProjectElementUseCase(this._repo);

  Future<CreateProjectElementResult> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String name,
    required String tilesetId,
    required String categoryId,
    required TilesetSourceRect source,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Element name cannot be empty');
    }
    final tileset = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );
    if (tilesetGroupId != null &&
        !tileset.elementGroups.any((group) => group.id == tilesetGroupId)) {
      throw Exception('Tileset group not found: $tilesetGroupId');
    }
    if (!project.elementCategories.any((c) => c.id == categoryId)) {
      throw Exception('Category not found: $categoryId');
    }
    if (groupId != null && !project.groups.any((g) => g.id == groupId)) {
      throw Exception('Group not found: $groupId');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw Exception('Element source rect must be positive');
    }
    if (source.x < 0 || source.y < 0) {
      throw Exception('Element source coordinates must be >= 0');
    }

    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final id = _generateUniqueProjectElementId(project, trimmedName);
    final siblingSort = project.elements
        .where((e) =>
            e.categoryId == categoryId &&
            e.groupId == groupId &&
            e.tilesetId == tilesetId &&
            e.tilesetGroupId == tilesetGroupId)
        .length;
    final element = ProjectElementEntry(
      id: id,
      name: trimmedName,
      tilesetId: tilesetId,
      categoryId: categoryId,
      tilesetGroupId: tilesetGroupId,
      source: source,
      groupId: groupId,
      recommendedLayerId: recommendedLayerId,
      tags: normalizedTags,
      sortOrder: siblingSort,
    );

    final updated = project.copyWith(elements: [...project.elements, element]);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return CreateProjectElementResult(updated, element);
  }
}

class UpdateProjectElementUseCase {
  final ProjectRepository _repo;

  UpdateProjectElementUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String elementId,
    String? name,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<String>? tags,
  }) async {
    final current = project.elements.firstWhere(
      (e) => e.id == elementId,
      orElse: () => throw Exception('Element not found: $elementId'),
    );

    final nextName = name?.trim();
    if (nextName != null && nextName.isEmpty) {
      throw Exception('Element name cannot be empty');
    }
    final nextCategoryId = categoryId ?? current.categoryId;
    if (!project.elementCategories.any((c) => c.id == nextCategoryId)) {
      throw Exception('Category not found: $nextCategoryId');
    }

    final ownerTileset = project.tilesets.firstWhere(
      (tileset) => tileset.id == current.tilesetId,
      orElse: () => throw Exception(
          'Tileset not found for element: ${current.tilesetId}'),
    );
    final nextTilesetGroupId =
        clearTilesetGroupId ? null : (tilesetGroupId ?? current.tilesetGroupId);
    if (nextTilesetGroupId != null &&
        !ownerTileset.elementGroups
            .any((group) => group.id == nextTilesetGroupId)) {
      throw Exception('Tileset group not found: $nextTilesetGroupId');
    }

    final nextGroupId = clearGroupId ? null : (groupId ?? current.groupId);
    if (nextGroupId != null &&
        !project.groups.any((g) => g.id == nextGroupId)) {
      throw Exception('Group not found: $nextGroupId');
    }

    final nextSource = source ?? current.source;
    if (nextSource.width <= 0 ||
        nextSource.height <= 0 ||
        nextSource.x < 0 ||
        nextSource.y < 0) {
      throw Exception('Element source rect is invalid');
    }

    final nextTags = tags == null
        ? current.tags
        : tags
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(growable: false);
    final nextRecommendedLayerId = clearRecommendedLayerId
        ? null
        : (recommendedLayerId ?? current.recommendedLayerId);

    final updatedElements = project.elements.map((element) {
      if (element.id != elementId) return element;
      return element.copyWith(
        name: nextName ?? element.name,
        categoryId: nextCategoryId,
        tilesetGroupId: nextTilesetGroupId,
        groupId: nextGroupId,
        source: nextSource,
        recommendedLayerId: nextRecommendedLayerId,
        tags: nextTags,
      );
    }).toList(growable: false);

    final updated = project.copyWith(elements: updatedElements);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class DeleteProjectElementUseCase {
  final ProjectRepository _repo;

  DeleteProjectElementUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String elementId,
  }) async {
    if (!project.elements.any((element) => element.id == elementId)) {
      throw Exception('Element not found: $elementId');
    }

    final updatedElements = project.elements
        .where((element) => element.id != elementId)
        .toList(growable: false);
    final updatedProject = project.copyWith(elements: updatedElements);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class ResolveVisibleProjectElementsUseCase {
  List<ProjectElementEntry> execute(
    ProjectManifest project, {
    String? tilesetId,
    String? mapId,
  }) {
    final groupScope = <String>{};
    if (mapId != null) {
      final mapEntry = project.maps.firstWhere(
        (m) => m.id == mapId,
        orElse: () => throw Exception('Map not found in manifest: $mapId'),
      );
      String? cursor = mapEntry.groupId;
      final visited = <String>{};
      while (cursor != null && visited.add(cursor)) {
        groupScope.add(cursor);
        final group = project.groups.firstWhere(
          (g) => g.id == cursor,
          orElse: () =>
              throw Exception('Unknown group referenced by map: $cursor'),
        );
        cursor = group.parentGroupId;
      }
    }

    final result = project.elements.where((element) {
      if (tilesetId != null && element.tilesetId != tilesetId) return false;
      if (element.groupId == null) return true;
      return groupScope.contains(element.groupId);
    }).toList(growable: false)
      ..sort(_projectElementSort);
    return result;
  }
}

class UpsertTilesetPaletteEntryUseCase {
  final ProjectRepository _repo;

  UpsertTilesetPaletteEntryUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    required TilesetPaletteEntry entry,
  }) async {
    final updatedTilesets = project.tilesets.map((tileset) {
      if (tileset.id != tilesetId) return tileset;
      final entries = List<TilesetPaletteEntry>.from(tileset.paletteEntries);
      final index = entries.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        entries[index] = entry;
      } else {
        entries.add(entry);
      }
      return tileset.copyWith(paletteEntries: entries);
    }).toList();

    final updated = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class CreateTilesetPaletteEntryResult {
  final ProjectManifest project;
  final TilesetPaletteEntry entry;

  const CreateTilesetPaletteEntryResult(this.project, this.entry);
}

class CreateTilesetPaletteEntryUseCase {
  final ProjectRepository _repo;

  CreateTilesetPaletteEntryUseCase(this._repo);

  Future<CreateTilesetPaletteEntryResult> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required String tilesetId,
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Palette entry name cannot be empty');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw Exception('Palette entry source size must be positive');
    }
    if (source.x < 0 || source.y < 0) {
      throw Exception('Palette entry source coordinates must be >= 0');
    }

    final tileset = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );
    final existingIds = tileset.paletteEntries.map((e) => e.id).toSet();
    final id = _generateUniquePaletteEntryId(existingIds, trimmedName);
    final entry = TilesetPaletteEntry(
      id: id,
      name: trimmedName,
      category: category,
      source: source,
      recommendedLayerId: recommendedLayerId,
    );

    final updatedTilesets = project.tilesets.map((t) {
      if (t.id != tilesetId) return t;
      return t.copyWith(paletteEntries: [...t.paletteEntries, entry]);
    }).toList(growable: false);
    final updated = project.copyWith(tilesets: updatedTilesets);

    await _repo.saveProject(updated, fs.projectManifestPath);
    return CreateTilesetPaletteEntryResult(updated, entry);
  }
}

class CreateGroupUseCase {
  final ProjectRepository _repo;

  CreateGroupUseCase(this._repo);

  Future<ProjectManifest> execute(ProjectWorkspace fs, ProjectManifest project,
      String name, MapGroupType type,
      {String? parentId}) async {
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final newGroup = ProjectMapGroup(
      id: id,
      name: name,
      type: type,
      parentGroupId: parentId,
      sortOrder: project.groups.length,
    );

    final updatedProject = project.copyWith(
      groups: [...project.groups, newGroup],
    );

    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class DeleteGroupUseCase {
  final ProjectRepository _repo;

  DeleteGroupUseCase(this._repo);

  Future<ProjectManifest> execute(
      ProjectWorkspace fs, ProjectManifest project, String groupId) async {
    // 1. Remove the group
    final updatedGroups = project.groups.where((g) => g.id != groupId).toList();

    // 2. Detach maps from this group
    final updatedMaps = project.maps.map((m) {
      if (m.groupId == groupId) return m.copyWith(groupId: null);
      return m;
    }).toList();

    // 3. Move child groups up one level (or to the same level as the deleted group)
    final parentId = project.groups.any((g) => g.id == groupId)
        ? project.groups.firstWhere((g) => g.id == groupId).parentGroupId
        : null;

    final finalGroups = updatedGroups.map((g) {
      if (g.parentGroupId == groupId) {
        return g.copyWith(parentGroupId: parentId);
      }
      return g;
    }).toList();

    final updatedProject =
        project.copyWith(groups: finalGroups, maps: updatedMaps);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class MoveMapToGroupUseCase {
  final ProjectRepository _repo;

  MoveMapToGroupUseCase(this._repo);

  Future<ProjectManifest> execute(ProjectWorkspace fs, ProjectManifest project,
      String mapId, String? groupId) async {
    final updatedMaps = project.maps.map((m) {
      if (m.id == mapId) return m.copyWith(groupId: groupId);
      return m;
    }).toList();

    final updatedProject = project.copyWith(maps: updatedMaps);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class RenameGroupUseCase {
  final ProjectRepository _repo;

  RenameGroupUseCase(this._repo);

  Future<ProjectManifest> execute(ProjectWorkspace fs, ProjectManifest project,
      String groupId, String newName) async {
    final updatedGroups = project.groups.map((g) {
      if (g.id == groupId) return g.copyWith(name: newName);
      return g;
    }).toList();

    final updatedProject = project.copyWith(groups: updatedGroups);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

String _generateUniqueTilesetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'tileset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existingIds = project.tilesets.map((t) => t.id).toSet();
  while (existingIds.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int _nextTilesetSortOrder(
  ProjectManifest project,
  TilesetScope scope,
  String? groupId,
) {
  final filtered = project.tilesets.where((t) {
    if (t.scope != scope) return false;
    if (scope == TilesetScope.global) return true;
    return t.groupId == groupId;
  });
  if (filtered.isEmpty) return 0;
  return filtered.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
}

int _tilesetSort(ProjectTilesetEntry a, ProjectTilesetEntry b) {
  if (a.isWorldTileset != b.isWorldTileset) {
    return a.isWorldTileset ? -1 : 1;
  }
  final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrderCompare != 0) return sortOrderCompare;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

String? _pickDefaultTilesetId(ProjectManifest project, String? groupId) {
  if (project.tilesets.isEmpty) return null;

  if (groupId != null) {
    final ancestors = <String>{};
    String? cursor = groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      ancestors.add(cursor);
      ProjectMapGroup? group;
      for (final candidate in project.groups) {
        if (candidate.id == cursor) {
          group = candidate;
          break;
        }
      }
      cursor = group?.parentGroupId;
    }

    final grouped = project.tilesets
        .where((t) =>
            t.scope == TilesetScope.group &&
            t.groupId != null &&
            ancestors.contains(t.groupId))
        .toList()
      ..sort(_tilesetSort);
    if (grouped.isNotEmpty) return grouped.first.id;
  }

  final world = project.tilesets.where((t) => t.isWorldTileset).toList()
    ..sort(_tilesetSort);
  if (world.isNotEmpty) return world.first.id;

  final global = project.tilesets
      .where((t) => t.scope == TilesetScope.global)
      .toList()
    ..sort(_tilesetSort);
  if (global.isNotEmpty) return global.first.id;

  return project.tilesets.first.id;
}

String _generateUniquePaletteEntryId(Set<String> existingIds, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'element' : normalized;

  var candidate = base;
  var suffix = 1;
  while (existingIds.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueElementCategoryId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'category' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.elementCategories.map((c) => c.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueTilesetElementGroupId(
  ProjectTilesetEntry tileset,
  String seed,
) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'group' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = tileset.elementGroups.map((group) => group.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueProjectElementId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'element' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.elements.map((e) => e.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueTerrainPresetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'terrain_preset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.terrainPresets.map((p) => p.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniquePathPresetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'path_preset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.pathPresets.map((p) => p.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int _nextTerrainPresetSortOrder(ProjectManifest project) {
  if (project.terrainPresets.isEmpty) return 0;
  return project.terrainPresets
          .map((preset) => preset.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

int _nextPathPresetSortOrder(ProjectManifest project) {
  if (project.pathPresets.isEmpty) return 0;
  return project.pathPresets
          .map((preset) => preset.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

int _projectElementSort(ProjectElementEntry a, ProjectElementEntry b) {
  final sortCompare = a.sortOrder.compareTo(b.sortOrder);
  if (sortCompare != 0) return sortCompare;
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (nameCompare != 0) return nameCompare;
  return a.id.compareTo(b.id);
}

Set<String> _collectTilesetGroupScope({
  required List<TilesetElementGroup> groups,
  required String rootGroupId,
}) {
  final byParent = <String?, List<TilesetElementGroup>>{};
  for (final group in groups) {
    byParent.putIfAbsent(group.parentGroupId, () => []).add(group);
  }

  final scope = <String>{rootGroupId};
  final queue = <String>[rootGroupId];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    final children = byParent[current] ?? const <TilesetElementGroup>[];
    for (final child in children) {
      if (scope.add(child.id)) {
        queue.add(child.id);
      }
    }
  }
  return scope;
}

List<ProjectElementCategory> _defaultElementCategories() {
  return const [
    ProjectElementCategory(
      id: 'nature',
      name: 'Nature',
      sortOrder: 0,
    ),
    ProjectElementCategory(
      id: 'nature_trees',
      name: 'Trees',
      parentCategoryId: 'nature',
      sortOrder: 0,
    ),
    ProjectElementCategory(
      id: 'nature_bushes',
      name: 'Bushes',
      parentCategoryId: 'nature',
      sortOrder: 1,
    ),
    ProjectElementCategory(
      id: 'nature_flowers',
      name: 'Flowers',
      parentCategoryId: 'nature',
      sortOrder: 2,
    ),
    ProjectElementCategory(
      id: 'nature_plants',
      name: 'Plants',
      parentCategoryId: 'nature',
      sortOrder: 3,
    ),
    ProjectElementCategory(
      id: 'ground',
      name: 'Ground',
      sortOrder: 1,
    ),
    ProjectElementCategory(
      id: 'ground_grass',
      name: 'Grass',
      parentCategoryId: 'ground',
      sortOrder: 0,
    ),
    ProjectElementCategory(
      id: 'ground_dirt',
      name: 'Dirt',
      parentCategoryId: 'ground',
      sortOrder: 1,
    ),
    ProjectElementCategory(
      id: 'ground_paths',
      name: 'Paths',
      parentCategoryId: 'ground',
      sortOrder: 2,
    ),
    ProjectElementCategory(
      id: 'ground_sand',
      name: 'Sand',
      parentCategoryId: 'ground',
      sortOrder: 3,
    ),
    ProjectElementCategory(
      id: 'ground_water_edges',
      name: 'WaterEdges',
      parentCategoryId: 'ground',
      sortOrder: 4,
    ),
    ProjectElementCategory(
      id: 'buildings',
      name: 'Buildings',
      sortOrder: 2,
    ),
    ProjectElementCategory(
      id: 'buildings_houses',
      name: 'Houses',
      parentCategoryId: 'buildings',
      sortOrder: 0,
    ),
    ProjectElementCategory(
      id: 'buildings_shops',
      name: 'Shops',
      parentCategoryId: 'buildings',
      sortOrder: 1,
    ),
    ProjectElementCategory(
      id: 'buildings_pokemon_center',
      name: 'PokemonCenter',
      parentCategoryId: 'buildings',
      sortOrder: 2,
    ),
    ProjectElementCategory(
      id: 'buildings_mart',
      name: 'Mart',
      parentCategoryId: 'buildings',
      sortOrder: 3,
    ),
    ProjectElementCategory(
      id: 'buildings_special',
      name: 'SpecialBuildings',
      parentCategoryId: 'buildings',
      sortOrder: 4,
    ),
    ProjectElementCategory(
      id: 'decorations',
      name: 'Decorations',
      sortOrder: 3,
    ),
    ProjectElementCategory(
      id: 'decorations_signs',
      name: 'Signs',
      parentCategoryId: 'decorations',
      sortOrder: 0,
    ),
    ProjectElementCategory(
      id: 'decorations_fences',
      name: 'Fences',
      parentCategoryId: 'decorations',
      sortOrder: 1,
    ),
    ProjectElementCategory(
      id: 'decorations_lamps',
      name: 'Lamps',
      parentCategoryId: 'decorations',
      sortOrder: 2,
    ),
    ProjectElementCategory(
      id: 'interior',
      name: 'Interior',
      sortOrder: 4,
    ),
    ProjectElementCategory(
      id: 'interior_furniture',
      name: 'Furniture',
      parentCategoryId: 'interior',
      sortOrder: 0,
    ),
    ProjectElementCategory(
      id: 'interior_walls',
      name: 'Walls',
      parentCategoryId: 'interior',
      sortOrder: 1,
    ),
    ProjectElementCategory(
      id: 'interior_floor_patterns',
      name: 'FloorPatterns',
      parentCategoryId: 'interior',
      sortOrder: 2,
    ),
  ];
}

List<ProjectTerrainPreset> _defaultTerrainPresets() {
  return const [
    ProjectTerrainPreset(
      id: 'terrain_normal',
      name: 'Normal Ground',
      terrainType: TerrainType.normal,
      categoryId: 'terrain_ground',
      sortOrder: 0,
    ),
    ProjectTerrainPreset(
      id: 'terrain_water',
      name: 'Water',
      terrainType: TerrainType.water,
      categoryId: 'terrain_ground',
      sortOrder: 1,
    ),
    ProjectTerrainPreset(
      id: 'terrain_tall_grass',
      name: 'Tall Grass',
      terrainType: TerrainType.tallGrass,
      categoryId: 'terrain_ground',
      sortOrder: 2,
    ),
    ProjectTerrainPreset(
      id: 'terrain_sand',
      name: 'Sand',
      terrainType: TerrainType.sand,
      categoryId: 'terrain_ground',
      sortOrder: 3,
    ),
    ProjectTerrainPreset(
      id: 'terrain_ice',
      name: 'Ice',
      terrainType: TerrainType.ice,
      categoryId: 'terrain_ground',
      sortOrder: 4,
    ),
  ];
}

List<ProjectTerrainPresetCategory> _defaultTerrainPresetCategories() {
  return const [
    ProjectTerrainPresetCategory(
      id: 'terrain',
      name: 'Terrains',
      kind: TerrainPresetCategoryKind.terrain,
      sortOrder: 0,
    ),
    ProjectTerrainPresetCategory(
      id: 'terrain_ground',
      name: 'Ground',
      kind: TerrainPresetCategoryKind.terrain,
      parentCategoryId: 'terrain',
      sortOrder: 0,
    ),
    ProjectTerrainPresetCategory(
      id: 'path',
      name: 'Paths',
      kind: TerrainPresetCategoryKind.path,
      sortOrder: 0,
    ),
    ProjectTerrainPresetCategory(
      id: 'path_main',
      name: 'Main Paths',
      kind: TerrainPresetCategoryKind.path,
      parentCategoryId: 'path',
      sortOrder: 0,
    ),
  ];
}

List<ProjectPathPreset> _defaultPathPresets() {
  return const [
    ProjectPathPreset(
      id: 'path_default',
      name: 'Default Path',
      categoryId: 'path_main',
      groundTerrainType: TerrainType.normal,
      sortOrder: 0,
    ),
  ];
}

ProjectManifest _withDefaultProjectLibrary(ProjectManifest project) {
  final categories = project.elementCategories.isEmpty
      ? _defaultElementCategories()
      : project.elementCategories;
  final terrainPresetCategories = project.terrainPresetCategories.isEmpty
      ? _defaultTerrainPresetCategories()
      : project.terrainPresetCategories;
  final terrainPresets = project.terrainPresets.isEmpty
      ? _defaultTerrainPresets()
      : project.terrainPresets;
  final pathPresets =
      project.pathPresets.isEmpty ? _defaultPathPresets() : project.pathPresets;
  if (identical(categories, project.elementCategories) &&
      identical(terrainPresetCategories, project.terrainPresetCategories) &&
      identical(terrainPresets, project.terrainPresets) &&
      identical(pathPresets, project.pathPresets)) {
    return project;
  }
  return project.copyWith(
    elementCategories: categories,
    terrainPresetCategories: terrainPresetCategories,
    terrainPresets: terrainPresets,
    pathPresets: pathPresets,
  );
}
