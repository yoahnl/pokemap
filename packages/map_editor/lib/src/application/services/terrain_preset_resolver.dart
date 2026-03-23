import 'package:map_core/map_core.dart';

class TerrainPresetResolver {
  const TerrainPresetResolver();

  List<ProjectTerrainPreset> listTerrainPresets(
    ProjectManifest project, {
    TerrainType? terrainType,
  }) {
    final presets = project.terrainPresets.where((preset) {
      if (terrainType == null) {
        return true;
      }
      return preset.terrainType == terrainType;
    }).toList(growable: false)
      ..sort(_compareBySortThenName);
    return presets;
  }

  List<ProjectPathPreset> listPathPresets(ProjectManifest project) {
    final presets =
        List<ProjectPathPreset>.from(project.pathPresets, growable: false)
          ..sort(_compareBySortThenName);
    return presets;
  }

  List<ProjectPresetCategory> listPresetCategories(
    ProjectManifest project, {
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final normalizedParentId = parentCategoryId?.trim();
    final categories = _categoriesFor(project, kind).where((category) {
      if (normalizedParentId == null) {
        return category.parentCategoryId == null;
      }
      return category.parentCategoryId == normalizedParentId;
    }).toList(growable: false)
      ..sort(_compareBySortThenName);
    return categories;
  }

  ProjectPresetCategory? findPresetCategoryById(
    ProjectManifest project, {
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final id = categoryId?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final category in _categoriesFor(project, kind)) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  String? resolvePresetCategoryPath(
    ProjectManifest project, {
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final id = categoryId?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }

    final categories = _categoriesFor(project, kind);
    final byId = <String, ProjectPresetCategory>{
      for (final category in categories) category.id: category,
    };
    final category = byId[id];
    if (category == null) {
      return null;
    }

    final segments = <String>[category.name];
    var cursor = category.parentCategoryId;
    final visited = <String>{category.id};
    while (cursor != null && visited.add(cursor)) {
      final parent = byId[cursor];
      if (parent == null) {
        break;
      }
      segments.insert(0, parent.name);
      cursor = parent.parentCategoryId;
    }
    return segments.join(' / ');
  }

  ProjectTerrainPreset? findTerrainPresetById(
    ProjectManifest project,
    String? presetId,
  ) {
    final id = presetId?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final preset in project.terrainPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  ProjectPathPreset? findPathPresetById(
    ProjectManifest project,
    String? presetId,
  ) {
    final id = presetId?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final preset in project.pathPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  ProjectTerrainPreset? resolveSelectedTerrainPreset(
    ProjectManifest project, {
    required TerrainType terrainType,
    required String? selectedTerrainPresetId,
    required Map<TerrainType, String> selectedTerrainPresetByType,
  }) {
    if (!terrainType.isBackgroundPaintable) {
      return null;
    }
    final selectedByTypeId = selectedTerrainPresetByType[terrainType];
    if (selectedByTypeId != null) {
      final selectedByType = findTerrainPresetById(project, selectedByTypeId);
      if (selectedByType != null && selectedByType.terrainType == terrainType) {
        return selectedByType;
      }
    }
    if (selectedTerrainPresetId != null) {
      final selected = findTerrainPresetById(project, selectedTerrainPresetId);
      if (selected != null && selected.terrainType == terrainType) {
        return selected;
      }
    }
    final presets = listTerrainPresets(project, terrainType: terrainType);
    if (presets.isEmpty) {
      return null;
    }
    return presets.first;
  }

  ProjectPathPreset? resolveSelectedPathPreset(
    ProjectManifest project, {
    required String? selectedPathPresetId,
  }) {
    final selected = findPathPresetById(project, selectedPathPresetId);
    if (selected != null) {
      return selected;
    }
    final presets = listPathPresets(project);
    if (presets.isEmpty) {
      return null;
    }
    return presets.first;
  }

  String? resolveInitialTerrainPresetId(ProjectManifest project) {
    final presets = listTerrainPresets(project, terrainType: TerrainType.grass);
    if (presets.isNotEmpty) {
      return presets.first.id;
    }
    final all = listTerrainPresets(project);
    if (all.isEmpty) {
      return null;
    }
    return all.first.id;
  }

  String? resolveInitialPathPresetId(ProjectManifest project) {
    final all = listPathPresets(project);
    if (all.isEmpty) {
      return null;
    }
    return all.first.id;
  }

  Map<TerrainType, String> resolveInitialTerrainPresetByType(
    ProjectManifest project,
  ) {
    final result = <TerrainType, String>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) {
        continue;
      }
      final presets = listTerrainPresets(project, terrainType: type);
      if (presets.isNotEmpty) {
        result[type] = presets.first.id;
      }
    }
    return result;
  }

  String? resolveSelectedTerrainPresetId({
    required ProjectManifest? project,
    required TerrainType terrainType,
    required String? preferredPresetId,
    required Map<TerrainType, String> selectedTerrainPresetByType,
  }) {
    if (project == null || !terrainType.isBackgroundPaintable) {
      return preferredPresetId;
    }
    final preferred = findTerrainPresetById(project, preferredPresetId);
    if (preferred != null && preferred.terrainType == terrainType) {
      return preferred.id;
    }
    final byType = selectedTerrainPresetByType[terrainType];
    final preferredByType = findTerrainPresetById(project, byType);
    if (preferredByType != null && preferredByType.terrainType == terrainType) {
      return preferredByType.id;
    }
    final candidates = listTerrainPresets(project, terrainType: terrainType);
    if (candidates.isNotEmpty) {
      return candidates.first.id;
    }
    return preferredPresetId;
  }

  String? resolveSelectedPathPresetId({
    required ProjectManifest? project,
    required String? preferredPresetId,
  }) {
    if (project == null) {
      return preferredPresetId;
    }
    final preferred = findPathPresetById(project, preferredPresetId);
    if (preferred != null) {
      return preferred.id;
    }
    final presets = listPathPresets(project);
    if (presets.isEmpty) {
      return null;
    }
    return presets.first.id;
  }

  Map<TerrainType, String> sanitizeTerrainPresetSelectionByType({
    required ProjectManifest project,
    required Map<TerrainType, String> current,
  }) {
    final sanitized = <TerrainType, String>{};
    for (final entry in current.entries) {
      if (!entry.key.isBackgroundPaintable) {
        continue;
      }
      final preset = findTerrainPresetById(project, entry.value);
      if (preset == null || preset.terrainType != entry.key) {
        continue;
      }
      sanitized[entry.key] = preset.id;
    }
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable || sanitized.containsKey(type)) {
        continue;
      }
      final presets = listTerrainPresets(project, terrainType: type);
      if (presets.isNotEmpty) {
        sanitized[type] = presets.first.id;
      }
    }
    return sanitized;
  }

  ProjectTerrainPreset? findLastCreatedTerrainPreset(
    ProjectManifest previous,
    ProjectManifest updated,
  ) {
    final previousIds =
        previous.terrainPresets.map((preset) => preset.id).toSet();
    for (final preset in updated.terrainPresets) {
      if (!previousIds.contains(preset.id)) {
        return preset;
      }
    }
    return null;
  }

  ProjectPathPreset? findLastCreatedPathPreset(
    ProjectManifest previous,
    ProjectManifest updated,
  ) {
    final previousIds = previous.pathPresets.map((preset) => preset.id).toSet();
    for (final preset in updated.pathPresets) {
      if (!previousIds.contains(preset.id)) {
        return preset;
      }
    }
    return null;
  }

  Map<TerrainType, ProjectTerrainPreset> mapTerrainPresetsByType(
    ProjectManifest project,
  ) {
    final presets = <TerrainType, ProjectTerrainPreset>{};
    for (final preset in listTerrainPresets(project)) {
      presets.putIfAbsent(preset.terrainType, () => preset);
    }
    return presets;
  }

  List<ProjectPresetCategory> _categoriesFor(
    ProjectManifest project,
    PresetLibraryKind kind,
  ) {
    return kind == PresetLibraryKind.terrain
        ? project.terrainCategories
        : project.pathCategories;
  }

  int _compareBySortThenName(dynamic a, dynamic b) {
    final sortCompare = (a.sortOrder as int).compareTo(b.sortOrder as int);
    if (sortCompare != 0) {
      return sortCompare;
    }
    return (a.name as String).toLowerCase().compareTo(
          (b.name as String).toLowerCase(),
        );
  }
}
