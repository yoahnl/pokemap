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
    if (!terrainType.isBackgroundPaintable) {
      throw const EditorInvalidOperationException(
        'Terrain presets are reserved for base ground only',
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
      TerrainPresetCategoryKind.terrain,
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
    if (terrainType != null && !nextTerrainType.isBackgroundPaintable) {
      throw const EditorInvalidOperationException(
        'Terrain presets are reserved for base ground only',
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
      TerrainPresetCategoryKind.terrain,
    );

    final nextVariants = clearVariants
        ? const <TerrainPresetVariant>[]
        : (variants != null
            ? _normalizeTerrainPresetVariants(variants)
            : current.variants);
    _validateTerrainPresetVariants(nextVariants);

    final updatedPresets = project.terrainPresets.map((preset) {
      if (preset.id != presetId) return preset;
      return preset.copyWith(
        name: nextName ?? preset.name,
        terrainType: nextTerrainType,
        categoryId: nextCategoryId,
        tilesetId: nextTilesetId,
        variants: nextVariants,
        sortOrder: sortOrder ?? preset.sortOrder,
      );
    }).toList(growable: false);

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
      TerrainPresetCategoryKind.path,
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
    final nextSurfaceKind = surfaceKind ?? current.surfaceKind;

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
      TerrainPresetCategoryKind.path,
    );

    final nextVariants = clearVariants
        ? const <PathPresetVariantMapping>[]
        : (variants != null
            ? _normalizePathPresetVariants(variants)
            : current.variants);
    _validatePathPresetVariants(nextVariants);

    final updatedPresets = project.pathPresets.map((preset) {
      if (preset.id != presetId) return preset;
      return preset.copyWith(
        name: nextName ?? preset.name,
        surfaceKind: nextSurfaceKind,
        categoryId: nextCategoryId,
        tilesetId: nextTilesetId,
        variants: nextVariants,
        sortOrder: sortOrder ?? preset.sortOrder,
      );
    }).toList(growable: false);

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

class CreateTerrainPresetCategoryUseCase {
  CreateTerrainPresetCategoryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required TerrainPresetCategoryKind kind,
    String? parentCategoryId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Category name cannot be empty');
    }
    final normalizedParentId = _normalizeOptionalId(parentCategoryId);
    if (normalizedParentId != null) {
      final parent = project.terrainPresetCategories.firstWhere(
        (category) => category.id == normalizedParentId,
        orElse: () => throw EditorNotFoundException(
          'Parent category not found: $normalizedParentId',
        ),
      );
      if (parent.kind != kind) {
        throw const EditorInvalidOperationException(
          'Parent category kind mismatch',
        );
      }
    }
    final category = ProjectTerrainPresetCategory(
      id: _generateUniquePresetCategoryId(project, trimmedName),
      name: trimmedName,
      kind: kind,
      parentCategoryId: normalizedParentId,
      sortOrder: _nextPresetCategorySortOrder(
        project,
        kind: kind,
        parentCategoryId: normalizedParentId,
      ),
    );
    final updated = project.copyWith(
      terrainPresetCategories: [
        ...project.terrainPresetCategories,
        category,
      ],
    );
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class RenameTerrainPresetCategoryUseCase {
  RenameTerrainPresetCategoryUseCase(this._repo);

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
    final exists = project.terrainPresetCategories.any(
      (category) => category.id == categoryId,
    );
    if (!exists) {
      throw EditorNotFoundException('Category not found: $categoryId');
    }
    final updated = project.copyWith(
      terrainPresetCategories: project.terrainPresetCategories
          .map((category) => category.id == categoryId
              ? category.copyWith(name: trimmedName)
              : category)
          .toList(growable: false),
    );
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

void _ensurePresetCategory(
  ProjectManifest project,
  String? categoryId,
  TerrainPresetCategoryKind expectedKind,
) {
  final normalized = _normalizeOptionalId(categoryId);
  if (normalized == null) return;
  final category = project.terrainPresetCategories.firstWhere(
    (item) => item.id == normalized,
    orElse: () =>
        throw EditorNotFoundException('Category not found: $normalized'),
  );
  if (category.kind != expectedKind) {
    throw EditorInvalidOperationException(
      'Category kind mismatch for ${expectedKind.name} preset',
    );
  }
}

String? _normalizeOptionalId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _generateUniquePresetCategoryId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'category' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing =
      project.terrainPresetCategories.map((category) => category.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int _nextPresetCategorySortOrder(
  ProjectManifest project, {
  required TerrainPresetCategoryKind kind,
  required String? parentCategoryId,
}) {
  final siblings = project.terrainPresetCategories.where(
    (category) =>
        category.kind == kind && category.parentCategoryId == parentCategoryId,
  );
  if (siblings.isEmpty) return 0;
  return siblings
          .map((category) => category.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
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
