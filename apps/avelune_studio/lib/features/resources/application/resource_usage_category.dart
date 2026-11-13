import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';

extension ResourceUsageCategoryLibrary on ResourceUsageCategory {
  String get label => switch (this) {
    ResourceUsageCategory.vegetation => 'Végétation',
    ResourceUsageCategory.ground => 'Sols',
    ResourceUsageCategory.path => 'Chemins',
    ResourceUsageCategory.water => 'Eau',
    ResourceUsageCategory.relief => 'Reliefs et parois',
    ResourceUsageCategory.building => 'Bâtiments',
    ResourceUsageCategory.structure => 'Structures',
    ResourceUsageCategory.furniture => 'Mobilier',
    ResourceUsageCategory.object => 'Objets',
  };

  String loadedKind(ProjectDimension dimension) => switch (this) {
    ResourceUsageCategory.ground ||
    ResourceUsageCategory.path ||
    ResourceUsageCategory.water => 'smartTilePreset',
    ResourceUsageCategory.relief => 'borderBlueprint',
    _ => dimension == ProjectDimension.twoD ? 'element' : 'model3d',
  };
}

ResourceUsageCategory? derivedResourceUsageCategory(
  ResourceItem item,
  ProjectManifest project,
) => switch (item.canonicalKind) {
  'environmentPreset' => ResourceUsageCategory.vegetation,
  'borderBlueprint' => ResourceUsageCategory.relief,
  'smartTilePreset' => _terrainCategory(item.terrain!, project),
  _ => null,
};

ResourceUsageCategory _terrainCategory(
  ProjectSmartTilePreset preset,
  ProjectManifest project,
) => switch (preset.usage) {
  SmartTileUsage.terrain ||
  SmartTileUsage.forestSurface => ResourceUsageCategory.ground,
  SmartTileUsage.path =>
    project.smartTileCatalog.materials
                .where((material) => material.id == preset.defaultMaterialId)
                .firstOrNull
                ?.pathSurfaceKind ==
            PathSurfaceKind.water
        ? ResourceUsageCategory.water
        : ResourceUsageCategory.path,
};

ResourceUsageCategory? resourceUsageCategory(
  ResourceItem item,
  ProjectManifest project,
) => switch (item.canonicalKind) {
  'model3d' || 'element' =>
    _classifiedCategory(item, project) ?? ResourceUsageCategory.object,
  _ =>
    item.metadata(project)?.category ??
        derivedResourceUsageCategory(item, project),
};

ResourceUsageCategory? _classifiedCategory(
  ResourceItem item,
  ProjectManifest project,
) {
  final entry = item.metadata(project);
  return project.resourceLibraryCatalog.familyCategory(entry?.familyId) ??
      entry?.category;
}

bool resourceAwaitsUsageCategory(ResourceItem item, ProjectManifest project) =>
    switch (item.canonicalKind) {
      'model3d' || 'element' => _classifiedCategory(item, project) == null,
      _ => false,
    };
