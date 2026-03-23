import 'package:map_core/map_core.dart';

String generateUniqueTilesetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'tileset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existingIds = project.tilesets.map((tileset) => tileset.id).toSet();
  while (existingIds.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int nextTilesetSortOrder(
  ProjectManifest project,
  TilesetScope scope,
  String? groupId,
) {
  final filtered = project.tilesets.where((tileset) {
    if (tileset.scope != scope) return false;
    if (scope == TilesetScope.global) return true;
    return tileset.groupId == groupId;
  });
  if (filtered.isEmpty) return 0;
  return filtered
          .map((tileset) => tileset.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

int compareTilesets(ProjectTilesetEntry a, ProjectTilesetEntry b) {
  if (a.isWorldTileset != b.isWorldTileset) {
    return a.isWorldTileset ? -1 : 1;
  }
  final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrderCompare != 0) return sortOrderCompare;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

String? pickDefaultTilesetId(ProjectManifest project, String? groupId) {
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
        .where((tileset) =>
            tileset.scope == TilesetScope.group &&
            tileset.groupId != null &&
            ancestors.contains(tileset.groupId))
        .toList()
      ..sort(compareTilesets);
    if (grouped.isNotEmpty) return grouped.first.id;
  }

  final world = project.tilesets
      .where((tileset) => tileset.isWorldTileset)
      .toList()
    ..sort(compareTilesets);
  if (world.isNotEmpty) return world.first.id;

  final global = project.tilesets
      .where((tileset) => tileset.scope == TilesetScope.global)
      .toList()
    ..sort(compareTilesets);
  if (global.isNotEmpty) return global.first.id;

  return project.tilesets.first.id;
}

String generateUniquePaletteEntryId(Set<String> existingIds, String seed) {
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

String generateUniqueElementCategoryId(ProjectManifest project, String seed) {
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
      project.elementCategories.map((category) => category.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String generateUniqueTilesetElementGroupId(
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

String generateUniqueProjectElementId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'element' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.elements.map((element) => element.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String generateUniqueTerrainPresetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'terrain_preset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.terrainPresets.map((preset) => preset.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String generateUniquePathPresetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'path_preset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existing = project.pathPresets.map((preset) => preset.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int nextTerrainPresetSortOrder(ProjectManifest project) {
  if (project.terrainPresets.isEmpty) return 0;
  return project.terrainPresets
          .map((preset) => preset.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

int nextPathPresetSortOrder(ProjectManifest project) {
  if (project.pathPresets.isEmpty) return 0;
  return project.pathPresets
          .map((preset) => preset.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

int compareProjectElements(ProjectElementEntry a, ProjectElementEntry b) {
  final sortCompare = a.sortOrder.compareTo(b.sortOrder);
  if (sortCompare != 0) return sortCompare;
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (nameCompare != 0) return nameCompare;
  return a.id.compareTo(b.id);
}

Set<String> collectTilesetGroupScope({
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

List<ProjectElementCategory> defaultElementCategories() {
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
