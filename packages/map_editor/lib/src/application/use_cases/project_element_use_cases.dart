import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_use_case_support.dart';

class CreateElementCategoryUseCase {
  CreateElementCategoryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    String? parentCategoryId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Category name cannot be empty');
    }
    if (parentCategoryId != null &&
        !project.elementCategories
            .any((category) => category.id == parentCategoryId)) {
      throw EditorNotFoundException(
        'Parent category not found: $parentCategoryId',
      );
    }

    final siblings = project.elementCategories
        .where((category) => category.parentCategoryId == parentCategoryId)
        .toList(growable: false);
    final id = generateUniqueElementCategoryId(project, trimmedName);
    final category = ProjectElementCategory(
      id: id,
      name: trimmedName,
      parentCategoryId: parentCategoryId,
      sortOrder: siblings.length,
    );
    final updated = project.copyWith(
      elementCategories: [...project.elementCategories, category],
    );
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreateElementSubcategoryUseCase {
  CreateElementSubcategoryUseCase(this._categoryUseCase);

  final CreateElementCategoryUseCase _categoryUseCase;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String parentCategoryId,
    required String name,
  }) {
    return _categoryUseCase.execute(
      workspace,
      project,
      name: name,
      parentCategoryId: parentCategoryId,
    );
  }
}

class RenameElementCategoryUseCase {
  RenameElementCategoryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String categoryId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Category name cannot be empty');
    }
    final found =
        project.elementCategories.any((category) => category.id == categoryId);
    if (!found) {
      throw EditorNotFoundException('Category not found: $categoryId');
    }

    final updatedCategories = project.elementCategories.map((category) {
      if (category.id != categoryId) return category;
      return category.copyWith(name: trimmedName);
    }).toList(growable: false);
    final updated = project.copyWith(elementCategories: updatedCategories);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreateTilesetElementGroupUseCase {
  CreateTilesetElementGroupUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required String name,
    String? parentGroupId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException(
        'Tileset group name cannot be empty',
      );
    }

    final tileset = project.tilesets.firstWhere(
      (tileset) => tileset.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );
    if (parentGroupId != null &&
        !tileset.elementGroups.any((group) => group.id == parentGroupId)) {
      throw EditorNotFoundException(
        'Parent tileset group not found: $parentGroupId',
      );
    }

    final siblings = tileset.elementGroups
        .where((group) => group.parentGroupId == parentGroupId)
        .toList(growable: false);
    final group = TilesetElementGroup(
      id: generateUniqueTilesetElementGroupId(tileset, trimmedName),
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
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreateTilesetElementSubgroupUseCase {
  CreateTilesetElementSubgroupUseCase(this._groupUseCase);

  final CreateTilesetElementGroupUseCase _groupUseCase;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required String parentGroupId,
    required String name,
  }) {
    return _groupUseCase.execute(
      workspace,
      project,
      tilesetId: tilesetId,
      parentGroupId: parentGroupId,
      name: name,
    );
  }
}

class RenameTilesetElementGroupUseCase {
  RenameTilesetElementGroupUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required String groupId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException(
        'Tileset group name cannot be empty',
      );
    }

    final tileset = project.tilesets.firstWhere(
      (tileset) => tileset.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );
    if (!tileset.elementGroups.any((group) => group.id == groupId)) {
      throw EditorNotFoundException('Tileset group not found: $groupId');
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
    await _repo.saveProject(updated, workspace.projectManifestPath);
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
      (entry) => entry.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );

    Set<String>? scope;
    if (tilesetGroupId != null) {
      if (!tileset.elementGroups.any((group) => group.id == tilesetGroupId)) {
        throw EditorNotFoundException(
            'Tileset group not found: $tilesetGroupId');
      }
      scope = includeDescendants
          ? collectTilesetGroupScope(
              groups: tileset.elementGroups,
              rootGroupId: tilesetGroupId,
            )
          : {tilesetGroupId};
    }

    final elements = project.elements.where((element) {
      if (element.tilesetId != tilesetId) return false;
      if (scope == null) return true;
      return element.tilesetGroupId != null &&
          scope.contains(element.tilesetGroupId);
    }).toList(growable: false)
      ..sort(compareProjectElements);
    return elements;
  }
}

class CreateProjectElementResult {
  const CreateProjectElementResult(this.project, this.element);

  final ProjectManifest project;
  final ProjectElementEntry element;
}

class CreateProjectElementUseCase {
  CreateProjectElementUseCase(this._repo);

  final ProjectRepository _repo;

  Future<CreateProjectElementResult> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required String tilesetId,
    required String categoryId,
    required TilesetSourceRect source,
    List<TilesetVisualFrame>? frames,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Element name cannot be empty');
    }
    final tileset = project.tilesets.firstWhere(
      (entry) => entry.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );
    if (tilesetGroupId != null &&
        !tileset.elementGroups.any((group) => group.id == tilesetGroupId)) {
      throw EditorNotFoundException('Tileset group not found: $tilesetGroupId');
    }
    if (!project.elementCategories
        .any((category) => category.id == categoryId)) {
      throw EditorNotFoundException('Category not found: $categoryId');
    }
    if (groupId != null &&
        !project.groups.any((group) => group.id == groupId)) {
      throw EditorNotFoundException('Group not found: $groupId');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw const EditorValidationException(
        'Element source rect must be positive',
      );
    }
    if (source.x < 0 || source.y < 0) {
      throw const EditorValidationException(
        'Element source coordinates must be >= 0',
      );
    }
    final normalizedFrames = _normalizeElementFrames(
      frames ?? [TilesetVisualFrame(source: source)],
    );

    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final id = generateUniqueProjectElementId(project, trimmedName);
    final siblingSort = project.elements
        .where((element) =>
            element.categoryId == categoryId &&
            element.groupId == groupId &&
            element.tilesetId == tilesetId &&
            element.tilesetGroupId == tilesetGroupId)
        .length;
    final element = ProjectElementEntry(
      id: id,
      name: trimmedName,
      tilesetId: tilesetId,
      categoryId: categoryId,
      tilesetGroupId: tilesetGroupId,
      frames: normalizedFrames,
      presetKind: presetKind,
      collisionProfile: collisionProfile,
      groupId: groupId,
      recommendedLayerId: recommendedLayerId,
      tags: normalizedTags,
      sortOrder: siblingSort,
    );

    final updated = project.copyWith(elements: [...project.elements, element]);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return CreateProjectElementResult(updated, element);
  }
}

class UpdateProjectElementUseCase {
  UpdateProjectElementUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final current = project.elements.firstWhere(
      (element) => element.id == elementId,
      orElse: () =>
          throw EditorNotFoundException('Element not found: $elementId'),
    );

    final nextName = name?.trim();
    if (nextName != null && nextName.isEmpty) {
      throw const EditorValidationException('Element name cannot be empty');
    }
    final nextCategoryId = categoryId ?? current.categoryId;
    if (!project.elementCategories
        .any((category) => category.id == nextCategoryId)) {
      throw EditorNotFoundException('Category not found: $nextCategoryId');
    }

    final ownerTileset = project.tilesets.firstWhere(
      (tileset) => tileset.id == current.tilesetId,
      orElse: () => throw EditorNotFoundException(
        'Tileset not found for element: ${current.tilesetId}',
      ),
    );
    final nextTilesetGroupId =
        clearTilesetGroupId ? null : (tilesetGroupId ?? current.tilesetGroupId);
    if (nextTilesetGroupId != null &&
        !ownerTileset.elementGroups
            .any((group) => group.id == nextTilesetGroupId)) {
      throw EditorNotFoundException(
        'Tileset group not found: $nextTilesetGroupId',
      );
    }

    final nextGroupId = clearGroupId ? null : (groupId ?? current.groupId);
    if (nextGroupId != null &&
        !project.groups.any((group) => group.id == nextGroupId)) {
      throw EditorNotFoundException('Group not found: $nextGroupId');
    }

    final nextFrames = (() {
      if (frames != null) {
        return _normalizeElementFrames(
          frames,
        );
      }
      if (source != null) {
        final nextSource = source;
        if (nextSource.width <= 0 ||
            nextSource.height <= 0 ||
            nextSource.x < 0 ||
            nextSource.y < 0) {
          throw const EditorValidationException(
              'Element source rect is invalid');
        }
        return [
          TilesetVisualFrame(
            tilesetId: current.frames.first.tilesetId,
            source: nextSource,
            durationMs: current.frames.first.durationMs,
          ),
          ...current.frames.skip(1),
        ];
      }
      return current.frames;
    })();

    final nextTags = tags == null
        ? current.tags
        : tags
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(growable: false);
    final nextPresetKind = presetKind ?? current.presetKind;
    final nextCollisionProfile = clearCollisionProfile
        ? null
        : (collisionProfile ?? current.collisionProfile);
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
        frames: nextFrames,
        presetKind: nextPresetKind,
        collisionProfile: nextCollisionProfile,
        recommendedLayerId: nextRecommendedLayerId,
        tags: nextTags,
      );
    }).toList(growable: false);

    final updated = project.copyWith(elements: updatedElements);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

List<TilesetVisualFrame> _normalizeElementFrames(
  List<TilesetVisualFrame> frames,
) {
  if (frames.isEmpty) {
    throw const EditorValidationException(
      'Element must have at least one visual frame',
    );
  }
  final normalized = <TilesetVisualFrame>[];
  for (var i = 0; i < frames.length; i++) {
    final frame = frames[i];
    final src = frame.source;
    if (src.x < 0 || src.y < 0 || src.width <= 0 || src.height <= 0) {
      throw EditorValidationException(
        'Element frame $i has invalid source rectangle',
      );
    }
    final durationMs = frame.durationMs;
    if (durationMs != null && durationMs <= 0) {
      throw EditorValidationException(
        'Element frame $i has invalid durationMs: $durationMs',
      );
    }
    normalized.add(
      frame.copyWith(
        tilesetId: frame.tilesetId.trim().isEmpty ? '' : frame.tilesetId.trim(),
      ),
    );
  }
  final width = normalized.first.source.width;
  final height = normalized.first.source.height;
  for (var i = 1; i < normalized.length; i++) {
    final src = normalized[i].source;
    if (src.width != width || src.height != height) {
      throw const EditorValidationException(
        'All element animation frames must share the same size',
      );
    }
  }
  return List<TilesetVisualFrame>.unmodifiable(normalized);
}

class DeleteProjectElementUseCase {
  DeleteProjectElementUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String elementId,
  }) async {
    if (!project.elements.any((element) => element.id == elementId)) {
      throw EditorNotFoundException('Element not found: $elementId');
    }

    final updatedElements = project.elements
        .where((element) => element.id != elementId)
        .toList(growable: false);
    final updatedProject = project.copyWith(elements: updatedElements);
    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
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
        (entry) => entry.id == mapId,
        orElse: () =>
            throw EditorNotFoundException('Map not found in manifest: $mapId'),
      );
      String? cursor = mapEntry.groupId;
      final visited = <String>{};
      while (cursor != null && visited.add(cursor)) {
        groupScope.add(cursor);
        final group = project.groups.firstWhere(
          (candidate) => candidate.id == cursor,
          orElse: () => throw EditorNotFoundException(
            'Unknown group referenced by map: $cursor',
          ),
        );
        cursor = group.parentGroupId;
      }
    }

    final result = project.elements.where((element) {
      if (tilesetId != null && element.tilesetId != tilesetId) return false;
      if (element.groupId == null) return true;
      return groupScope.contains(element.groupId);
    }).toList(growable: false)
      ..sort(compareProjectElements);
    return result;
  }
}
