import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_use_case_support.dart';

class ImportProjectTilesetUseCase {
  ImportProjectTilesetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Tileset name cannot be empty');
    }
    if (scope == TilesetScope.global) {
      groupId = null;
    } else if (groupId == null) {
      throw const EditorInvalidOperationException(
        'A group-scoped tileset must target a group',
      );
    }
    if (scope != TilesetScope.global && isWorldTileset) {
      throw const EditorInvalidOperationException(
        'World tileset must be global',
      );
    }

    final sourceExt = p.extension(sourcePath).toLowerCase();
    const allowedExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'};
    if (!allowedExtensions.contains(sourceExt)) {
      throw EditorValidationException(
        'Unsupported tileset image format: $sourceExt',
      );
    }

    final id = generateUniqueTilesetId(project, trimmedName);
    final relativePath = await workspace.importTilesetImage(
      sourcePath,
      preferredName: id,
    );

    final sortOrder = nextTilesetSortOrder(project, scope, groupId);
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
      await _repo.saveProject(updatedProject, workspace.projectManifestPath);
      return updatedProject;
    } catch (_) {
      await workspace.deleteRelativeFile(relativePath);
      rethrow;
    }
  }
}

class UpdateProjectTilesetUseCase {
  UpdateProjectTilesetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
  }) async {
    final current = project.tilesets.firstWhere(
      (tileset) => tileset.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );

    final nextScope = scope ?? current.scope;
    var nextGroupId = groupId ?? current.groupId;
    var nextWorld = isWorldTileset ?? current.isWorldTileset;

    if (nextScope == TilesetScope.global) {
      nextGroupId = null;
    } else if (nextGroupId == null) {
      throw const EditorInvalidOperationException(
        'A group-scoped tileset must target a group',
      );
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
    }).toList(growable: false);

    final updatedProject = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
    return updatedProject;
  }
}

class DeleteProjectTilesetUseCase {
  DeleteProjectTilesetUseCase(this._projectRepo, this._mapRepo);

  final ProjectRepository _projectRepo;
  final MapRepository _mapRepo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
    String tilesetId,
  ) async {
    final target = project.tilesets.firstWhere(
      (tileset) => tileset.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );

    for (final mapEntry in project.maps) {
      final mapPath = workspace.resolveMapPath(mapEntry.relativePath);
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
        throw EditorConflictException(
          'Tileset "$tilesetId" is still used by map "${map.id}"',
        );
      }
    }

    final remainingTilesets =
        project.tilesets.where((tileset) => tileset.id != tilesetId).toList();
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
    await _projectRepo.saveProject(
        updatedProject, workspace.projectManifestPath);

    final stillUsedPath = remainingTilesets.any(
      (tileset) => tileset.relativePath == target.relativePath,
    );
    if (!stillUsedPath) {
      await workspace.deleteRelativeFile(target.relativePath);
    }

    return updatedProject;
  }
}

class ReorderProjectTilesetUseCase {
  ReorderProjectTilesetUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required int direction,
  }) async {
    if (direction == 0) return project;
    final target = project.tilesets.firstWhere(
      (tileset) => tileset.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );

    final bucket = project.tilesets.where((tileset) {
      if (tileset.scope != target.scope) return false;
      if (target.scope == TilesetScope.global) return true;
      return tileset.groupId == target.groupId;
    }).toList()
      ..sort(compareTilesets);

    final index = bucket.indexWhere((tileset) => tileset.id == tilesetId);
    if (index < 0) return project;
    final nextIndex = (index + direction).clamp(0, bucket.length - 1);
    if (nextIndex == index) return project;

    final moving = bucket.removeAt(index);
    bucket.insert(nextIndex, moving);

    final orderById = <String, int>{};
    for (var i = 0; i < bucket.length; i++) {
      orderById[bucket[i].id] = i;
    }

    final updatedTilesets = project.tilesets.map((tileset) {
      final nextSort = orderById[tileset.id];
      if (nextSort == null) return tileset;
      return tileset.copyWith(sortOrder: nextSort);
    }).toList(growable: false);

    final updatedProject = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
    return updatedProject;
  }
}

class ResolveAssignableTilesetsForMapUseCase {
  List<ProjectTilesetEntry> execute(ProjectManifest project, String mapId) {
    final mapEntry = project.maps.firstWhere(
      (mapEntry) => mapEntry.id == mapId,
      orElse: () =>
          throw EditorNotFoundException('Map not found in manifest: $mapId'),
    );

    final allowedGroupIds = <String>{};
    String? cursor = mapEntry.groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      allowedGroupIds.add(cursor);
      final nextGroup = project.groups.firstWhere(
        (group) => group.id == cursor,
        orElse: () => throw EditorNotFoundException(
            'Unknown group referenced by map: $cursor'),
      );
      cursor = nextGroup.parentGroupId;
    }

    final global = project.tilesets
        .where((tileset) => tileset.scope == TilesetScope.global)
        .toList(growable: false)
      ..sort(compareTilesets);
    final grouped = project.tilesets
        .where((tileset) =>
            tileset.scope == TilesetScope.group &&
            tileset.groupId != null &&
            allowedGroupIds.contains(tileset.groupId))
        .toList(growable: false)
      ..sort(compareTilesets);

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
  AssignTilesetToMapUseCase(this._mapRepo, this._resolver);

  final MapRepository _mapRepo;
  final ResolveAssignableTilesetsForMapUseCase _resolver;

  Future<MapData> execute(
    ProjectManifest project,
    MapData map,
    String mapPath,
    String layerId,
    String tilesetId,
  ) async {
    final assignable = _resolver.execute(project, map.id);
    final isAllowed = assignable.any((tileset) => tileset.id == tilesetId);
    if (!isAllowed) {
      throw EditorInvalidOperationException(
        'Tileset "$tilesetId" is not assignable to map "${map.id}"',
      );
    }

    final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      throw EditorNotFoundException('Layer not found: $layerId');
    }
    final layer = map.layers[layerIndex];
    if (layer is! TileLayer) {
      throw EditorInvalidOperationException(
        'Layer is not a tile layer: $layerId',
      );
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

class UpsertTilesetPaletteEntryUseCase {
  UpsertTilesetPaletteEntryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required TilesetPaletteEntry entry,
  }) async {
    final updatedTilesets = project.tilesets.map((tileset) {
      if (tileset.id != tilesetId) return tileset;
      final entries = List<TilesetPaletteEntry>.from(tileset.paletteEntries);
      final index =
          entries.indexWhere((paletteEntry) => paletteEntry.id == entry.id);
      if (index >= 0) {
        entries[index] = entry;
      } else {
        entries.add(entry);
      }
      return tileset.copyWith(paletteEntries: entries);
    }).toList(growable: false);

    final updated = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreateTilesetPaletteEntryResult {
  const CreateTilesetPaletteEntryResult(this.project, this.entry);

  final ProjectManifest project;
  final TilesetPaletteEntry entry;
}

class CreateTilesetPaletteEntryUseCase {
  CreateTilesetPaletteEntryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<CreateTilesetPaletteEntryResult> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException(
        'Palette entry name cannot be empty',
      );
    }
    if (source.width <= 0 || source.height <= 0) {
      throw const EditorValidationException(
        'Palette entry source size must be positive',
      );
    }
    if (source.x < 0 || source.y < 0) {
      throw const EditorValidationException(
        'Palette entry source coordinates must be >= 0',
      );
    }

    final tileset = project.tilesets.firstWhere(
      (tileset) => tileset.id == tilesetId,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tilesetId'),
    );
    final existingIds = tileset.paletteEntries.map((entry) => entry.id).toSet();
    final id = generateUniquePaletteEntryId(existingIds, trimmedName);
    final entry = TilesetPaletteEntry(
      id: id,
      name: trimmedName,
      category: category,
      source: source,
      recommendedLayerId: recommendedLayerId,
    );

    final updatedTilesets = project.tilesets.map((candidate) {
      if (candidate.id != tilesetId) return candidate;
      return candidate
          .copyWith(paletteEntries: [...candidate.paletteEntries, entry]);
    }).toList(growable: false);
    final updated = project.copyWith(tilesets: updatedTilesets);

    await _repo.saveProject(updated, workspace.projectManifestPath);
    return CreateTilesetPaletteEntryResult(updated, entry);
  }
}
