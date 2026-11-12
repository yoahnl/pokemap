import 'package:map_core/map_core.dart';

import 'resource_catalog.dart';

extension ResourceUsageCategoryLibrary on ResourceUsageCategory {
  String get label => switch (this) {
    ResourceUsageCategory.vegetation => 'Végétation',
    ResourceUsageCategory.ground => 'Sols',
    ResourceUsageCategory.path => 'Chemins',
    ResourceUsageCategory.water => 'Eau',
    ResourceUsageCategory.relief => 'Reliefs et parois',
    ResourceUsageCategory.building => 'Bâtiments',
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
) =>
    item.metadata(project)?.category ??
    derivedResourceUsageCategory(item, project) ??
    switch (item.canonicalKind) {
      'model3d' || 'element' => ResourceUsageCategory.object,
      _ => null,
    };

bool resourceAwaitsUsageCategory(ResourceItem item, ProjectManifest project) =>
    item.metadata(project)?.category == null &&
    derivedResourceUsageCategory(item, project) == null &&
    resourceUsageCategory(item, project) != null;
