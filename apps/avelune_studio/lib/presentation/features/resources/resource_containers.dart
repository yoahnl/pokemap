import 'package:map_core/map_core_domain.dart';
import 'resource_catalog.dart';

class ResourceContainer {
  const ResourceContainer(this.id, this.name, this.parentId, this.sortOrder);
  final String id, name;
  final String? parentId;
  final int sortOrder;
}

List<ResourceContainer> resourceContainers(
  ProjectManifest project,
  ResourceKind family,
) => switch (family) {
  ResourceKind.images => [
    for (final folder in project.tilesetFolders)
      ResourceContainer(
        folder.id,
        folder.name,
        folder.parentFolderId,
        folder.sortOrder,
      ),
  ],
  ResourceKind.decors => [
    for (final category in project.elementCategories)
      ResourceContainer(
        category.id,
        category.name,
        category.parentCategoryId,
        category.sortOrder,
      ),
  ],
  ResourceKind.terrains => [
    for (final category in project.smartTileCatalog.categories)
      ResourceContainer(category.id, category.name, null, category.sortOrder),
  ],
};

String containerTitle(ResourceKind family) =>
    family == ResourceKind.images ? 'dossier' : 'catégorie';

String containerAction(ResourceKind family, String operation) =>
    '${switch (family) {
      ResourceKind.images => 'tileset_folder',
      ResourceKind.decors => 'element_category',
      ResourceKind.terrains => 'smart_tile.category',
    }}.$operation';

Map<String, Object?> containerParameters(
  ResourceKind family,
  ResourceContainer value,
) => {
  family == ResourceKind.images ? 'folder' : 'category': {
    'id': value.id,
    'name': value.name,
    'sortOrder': value.sortOrder,
    if (family != ResourceKind.terrains)
      family == ResourceKind.images ? 'parentFolderId' : 'parentCategoryId':
          value.parentId,
  },
};

(String, Map<String, Object?>) resourceMoveParameters(
  ResourceItem item,
  String? destination,
) => switch (item.kind) {
  ResourceKind.images => (
    'tileset.metadata.update',
    {'tilesetId': item.id, 'name': item.name, 'folderId': destination},
  ),
  ResourceKind.decors => (
    'element.category.assign',
    {'elementId': item.id, 'categoryId': destination},
  ),
  ResourceKind.terrains => (
    'smart_tile.preset.category.assign',
    {'presetId': item.id, 'categoryId': destination ?? ''},
  ),
};
