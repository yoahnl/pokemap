import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_use_case_support.dart';

class CreateTerrainPresetUseCase {
  CreateTerrainPresetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException(
        'Terrain preset name cannot be empty',
      );
    }
    if (terrainType == TerrainType.none) {
      throw const EditorInvalidOperationException(
        'Terrain preset cannot target "none"',
      );
    }

    final normalizedTilesetId = tilesetId.trim();
    if (normalizedTilesetId.isNotEmpty &&
        !project.tilesets.any((tileset) => tileset.id == normalizedTilesetId)) {
      throw EditorNotFoundException('Tileset not found: $normalizedTilesetId');
    }
    _ensureTerrainTilesetIsNotUsedByPathPresets(project, normalizedTilesetId);
    _ensurePresetCategory(
      project,
      categoryId,
      PresetLibraryKind.terrain,
    );
    _validateTerrainPresetVariants(variants);

    final preset = ProjectTerrainPreset(
      id: generateUniqueTerrainPresetId(project, trimmedName),
      name: trimmedName,
      terrainType: terrainType,
      categoryId: _normalizeOptionalId(categoryId),
      tilesetId: normalizedTilesetId,
      variants: _normalizeTerrainPresetVariants(variants),
      sortOrder: nextTerrainPresetSortOrder(project),
    );
    final updated =
        project.copyWith(terrainPresets: [...project.terrainPresets, preset]);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateTerrainPresetUseCase {
  UpdateTerrainPresetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
    int? sortOrder,
  }) async {
    final current = project.terrainPresets.firstWhere(
      (preset) => preset.id == presetId,
      orElse: () =>
          throw EditorNotFoundException('Terrain preset not found: $presetId'),
    );

    final nextName = name?.trim();
    if (nextName != null && nextName.isEmpty) {
      throw const EditorValidationException(
        'Terrain preset name cannot be empty',
      );
    }

    final nextTerrainType = terrainType ?? current.terrainType;
    if (nextTerrainType == TerrainType.none) {
      throw const EditorInvalidOperationException(
        'Terrain preset cannot target "none"',
      );
    }

    final nextTilesetId = clearTilesetId
        ? ''
        : (tilesetId != null ? tilesetId.trim() : current.tilesetId);
    if (nextTilesetId.isNotEmpty &&
        !project.tilesets.any((tileset) => tileset.id == nextTilesetId)) {
      throw EditorNotFoundException('Tileset not found: $nextTilesetId');
    }
    _ensureTerrainTilesetIsNotUsedByPathPresets(project, nextTilesetId);

    final nextCategoryId = clearCategoryId
        ? null
        : (categoryId != null
            ? _normalizeOptionalId(categoryId)
            : current.categoryId);
    _ensurePresetCategory(
      project,
      nextCategoryId,
      PresetLibraryKind.terrain,
    );

    final nextVariants = clearVariants
        ? const <TerrainPresetVariant>[]
        : (variants != null
            ? _normalizeTerrainPresetVariants(variants)
            : current.variants);
    _validateTerrainPresetVariants(nextVariants);

    final updatedPresets = project.terrainPresets
        .map((preset) => preset.id != presetId
            ? preset
            : preset.copyWith(
                name: nextName ?? preset.name,
                terrainType: nextTerrainType,
                categoryId: nextCategoryId,
                tilesetId: nextTilesetId,
                variants: nextVariants,
                sortOrder: sortOrder ?? preset.sortOrder,
              ))
        .toList(growable: false);

    final updated = project.copyWith(terrainPresets: updatedPresets);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteTerrainPresetUseCase {
  DeleteTerrainPresetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String presetId,
  }) async {
    if (!project.terrainPresets.any((preset) => preset.id == presetId)) {
      throw EditorNotFoundException('Terrain preset not found: $presetId');
    }
    final updated = project.copyWith(
      terrainPresets: project.terrainPresets
          .where((preset) => preset.id != presetId)
          .toList(growable: false),
    );
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreatePathPresetUseCase {
  CreatePathPresetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Path preset name cannot be empty');
    }

    final normalizedTilesetId = tilesetId.trim();
    if (normalizedTilesetId.isNotEmpty &&
        !project.tilesets.any((tileset) => tileset.id == normalizedTilesetId)) {
      throw EditorNotFoundException('Tileset not found: $normalizedTilesetId');
    }
    _ensurePathTilesetIsNotUsedByTerrainPresets(project, normalizedTilesetId);
    _ensurePresetCategory(
      project,
      categoryId,
      PresetLibraryKind.path,
    );
    _validatePathPresetVariants(variants);

    final preset = ProjectPathPreset(
      id: generateUniquePathPresetId(project, trimmedName),
      name: trimmedName,
      surfaceKind: surfaceKind,
      categoryId: _normalizeOptionalId(categoryId),
      tilesetId: normalizedTilesetId,
      variants: _normalizePathPresetVariants(variants),
      sortOrder: nextPathPresetSortOrder(project),
    );
    final updated =
        project.copyWith(pathPresets: [...project.pathPresets, preset]);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdatePathPresetUseCase {
  UpdatePathPresetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
    int? sortOrder,
  }) async {
    final current = project.pathPresets.firstWhere(
      (preset) => preset.id == presetId,
      orElse: () =>
          throw EditorNotFoundException('Path preset not found: $presetId'),
    );

    final nextName = name?.trim();
    if (nextName != null && nextName.isEmpty) {
      throw const EditorValidationException('Path preset name cannot be empty');
    }

    final nextTilesetId = clearTilesetId
        ? ''
        : (tilesetId != null ? tilesetId.trim() : current.tilesetId);
    if (nextTilesetId.isNotEmpty &&
        !project.tilesets.any((tileset) => tileset.id == nextTilesetId)) {
      throw EditorNotFoundException('Tileset not found: $nextTilesetId');
    }
    _ensurePathTilesetIsNotUsedByTerrainPresets(project, nextTilesetId);

    final nextCategoryId = clearCategoryId
        ? null
        : (categoryId != null
            ? _normalizeOptionalId(categoryId)
            : current.categoryId);
    _ensurePresetCategory(
      project,
      nextCategoryId,
      PresetLibraryKind.path,
    );

    final nextVariants = clearVariants
        ? const <PathPresetVariantMapping>[]
        : (variants != null
            ? _normalizePathPresetVariants(variants)
            : current.variants);
    _validatePathPresetVariants(nextVariants);

    final updatedPresets = project.pathPresets
        .map((preset) => preset.id != presetId
            ? preset
            : preset.copyWith(
                name: nextName ?? preset.name,
                surfaceKind: surfaceKind ?? preset.surfaceKind,
                categoryId: nextCategoryId,
                tilesetId: nextTilesetId,
                variants: nextVariants,
                sortOrder: sortOrder ?? preset.sortOrder,
              ))
        .toList(growable: false);

    final updated = project.copyWith(pathPresets: updatedPresets);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeletePathPresetUseCase {
  DeletePathPresetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String presetId,
  }) async {
    if (!project.pathPresets.any((preset) => preset.id == presetId)) {
      throw EditorNotFoundException('Path preset not found: $presetId');
    }
    final updated = project.copyWith(
      pathPresets: project.pathPresets
          .where((preset) => preset.id != presetId)
          .toList(growable: false),
    );
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreatePresetCategoryUseCase {
  CreatePresetCategoryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Category name cannot be empty');
    }

    final categories = _categoriesFor(project, kind);
    final normalizedParentId = _normalizeOptionalId(parentCategoryId);
    if (normalizedParentId != null &&
        !categories.any((category) => category.id == normalizedParentId)) {
      throw EditorNotFoundException(
        'Parent category not found: $normalizedParentId',
      );
    }

    final category = ProjectPresetCategory(
      id: _generateUniquePresetCategoryId(project, kind, trimmedName),
      name: trimmedName,
      parentCategoryId: normalizedParentId,
      sortOrder: _nextPresetCategorySortOrder(
        project,
        kind: kind,
        parentCategoryId: normalizedParentId,
      ),
    );

    final updated = _copyProjectWithCategories(
      project,
      kind: kind,
      categories: [...categories, category],
    );
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class RenamePresetCategoryUseCase {
  RenamePresetCategoryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Category name cannot be empty');
    }

    final categories = _categoriesFor(project, kind);
    if (!categories.any((category) => category.id == categoryId)) {
      throw EditorNotFoundException('Category not found: $categoryId');
    }

    final updated = _copyProjectWithCategories(
      project,
      kind: kind,
      categories: categories
          .map(
            (category) => category.id == categoryId
                ? category.copyWith(name: trimmedName)
                : category,
          )
          .toList(growable: false),
    );
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeletePresetCategoryUseCase {
  DeletePresetCategoryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final categories = _categoriesFor(project, kind);
    if (!categories.any((category) => category.id == categoryId)) {
      throw EditorNotFoundException('Category not found: $categoryId');
    }

    final removedIds = <String>{categoryId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final category in categories) {
        if (category.parentCategoryId != null &&
            removedIds.contains(category.parentCategoryId) &&
            removedIds.add(category.id)) {
          changed = true;
        }
      }
    }

    final updatedCategories = categories
        .where((category) => !removedIds.contains(category.id))
        .toList(growable: false);

    var updated = _copyProjectWithCategories(
      project,
      kind: kind,
      categories: updatedCategories,
    );

    if (kind == PresetLibraryKind.terrain) {
      updated = updated.copyWith(
        terrainPresets: updated.terrainPresets
            .map(
              (preset) => removedIds.contains(preset.categoryId)
                  ? preset.copyWith(categoryId: null)
                  : preset,
            )
            .toList(growable: false),
      );
    } else {
      updated = updated.copyWith(
        pathPresets: updated.pathPresets
            .map(
              (preset) => removedIds.contains(preset.categoryId)
                  ? preset.copyWith(categoryId: null)
                  : preset,
            )
            .toList(growable: false),
      );
    }

    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

List<TerrainPresetVariant> _normalizeTerrainPresetVariants(
  List<TerrainPresetVariant> variants,
) {
  return variants
      .where((variant) => variant.source.width > 0 && variant.source.height > 0)
      .map(
        (variant) => variant.copyWith(
          weight: variant.weight <= 0 ? 1 : variant.weight,
        ),
      )
      .toList(growable: false);
}

void _validateTerrainPresetVariants(List<TerrainPresetVariant> variants) {
  for (final variant in variants) {
    if (variant.source.x < 0 ||
        variant.source.y < 0 ||
        variant.source.width <= 0 ||
        variant.source.height <= 0) {
      throw const EditorValidationException(
        'Terrain preset variant source is invalid',
      );
    }
    if (variant.weight <= 0) {
      throw const EditorValidationException(
        'Terrain preset variant weight must be positive',
      );
    }
  }
}

List<PathPresetVariantMapping> _normalizePathPresetVariants(
  List<PathPresetVariantMapping> variants,
) {
  final ordered =
      List<PathPresetVariantMapping>.from(variants, growable: false);
  ordered.sort((a, b) => a.variant.index.compareTo(b.variant.index));
  return ordered;
}

void _validatePathPresetVariants(List<PathPresetVariantMapping> variants) {
  final covered = <TerrainPathVariant>{};
  for (final variant in variants) {
    if (!covered.add(variant.variant)) {
      throw EditorConflictException(
        'Duplicate path variant mapping: ${variant.variant.name}',
      );
    }
    if (variant.source.x < 0 ||
        variant.source.y < 0 ||
        variant.source.width <= 0 ||
        variant.source.height <= 0) {
      throw const EditorValidationException(
        'Path preset variant source is invalid',
      );
    }
  }
}

void _ensureTerrainTilesetIsNotUsedByPathPresets(
  ProjectManifest project,
  String tilesetId,
) {
  final normalized = tilesetId.trim();
  if (normalized.isEmpty) return;
  final conflict = project.pathPresets.any(
    (preset) => preset.tilesetId.trim() == normalized,
  );
  if (conflict) {
    throw const EditorConflictException(
      'This tileset is already used by a path preset. Terrain and path presets must use different tilesets.',
    );
  }
}

void _ensurePathTilesetIsNotUsedByTerrainPresets(
  ProjectManifest project,
  String tilesetId,
) {
  final normalized = tilesetId.trim();
  if (normalized.isEmpty) return;
  final conflict = project.terrainPresets.any(
    (preset) => preset.tilesetId.trim() == normalized,
  );
  if (conflict) {
    throw const EditorConflictException(
      'This tileset is already used by a terrain preset. Terrain and path presets must use different tilesets.',
    );
  }
}

void _ensurePresetCategory(
  ProjectManifest project,
  String? categoryId,
  PresetLibraryKind kind,
) {
  final normalized = _normalizeOptionalId(categoryId);
  if (normalized == null) return;
  final categories = _categoriesFor(project, kind);
  if (!categories.any((category) => category.id == normalized)) {
    throw EditorNotFoundException('Category not found: $normalized');
  }
}

List<ProjectPresetCategory> _categoriesFor(
  ProjectManifest project,
  PresetLibraryKind kind,
) {
  return kind == PresetLibraryKind.terrain
      ? project.terrainCategories
      : project.pathCategories;
}

ProjectManifest _copyProjectWithCategories(
  ProjectManifest project, {
  required PresetLibraryKind kind,
  required List<ProjectPresetCategory> categories,
}) {
  return kind == PresetLibraryKind.terrain
      ? project.copyWith(terrainCategories: categories)
      : project.copyWith(pathCategories: categories);
}

String? _normalizeOptionalId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _generateUniquePresetCategoryId(
  ProjectManifest project,
  PresetLibraryKind kind,
  String seed,
) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'category' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = _categoriesFor(project, kind).map((category) => category.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int _nextPresetCategorySortOrder(
  ProjectManifest project, {
  required PresetLibraryKind kind,
  required String? parentCategoryId,
}) {
  final siblings = _categoriesFor(project, kind).where(
    (category) => category.parentCategoryId == parentCategoryId,
  );
  if (siblings.isEmpty) {
    return 0;
  }
  return siblings
          .map((category) => category.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}
