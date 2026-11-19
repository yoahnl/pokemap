import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/project_resource_library.dart';
import 'library/resource_library_view_data.dart';

class ProjectLibraryCatalogView {
  ProjectLibraryCatalogView(ProjectResourceLibrary library) {
    final families = {
      for (final family in library.catalog.effectiveFamilies) family.id: family,
    };
    List<String> ancestors(String? id) {
      final path = <String>[];
      while (id != null && families.containsKey(id)) {
        final family = families[id]!;
        path.add(id);
        id = family.parentId;
      }
      return path.reversed.toList(growable: false);
    }

    final labels = [
      for (final id in families.keys)
        MapEntry(
          id,
          ancestors(id).map((part) => families[part]!.name).join(' › '),
        ),
    ]..sort((a, b) => a.value.compareTo(b.value));
    familyLabels = Map.unmodifiable(Map.fromEntries(labels));
    entries = Map.unmodifiable({
      for (final item in library.items) item.identity: item,
    });
    items = List.unmodifiable([
      for (final item in library.items)
        ResourceLibraryItemView(
          id: item.identity,
          name: item.name,
          category: _category(item, library.catalog),
          type: _type(item),
          dimension: _dimension(item.kind),
          usedOn: null,
          role: item.role,
          familyIds: ancestors(item.familyId),
          familyPath: familyLabels[item.familyId],
          mapId: item.mapId,
          description: item.description,
          searchText: item.searchText,
        ),
    ]);
  }

  late final Map<String, String> familyLabels;
  late final Map<String, ProjectLibraryItem> entries;
  late final List<ResourceLibraryItemView> items;
}

ResourceLibraryCategory _category(
  ProjectLibraryItem item,
  ResourceLibraryCatalog catalog,
) {
  if (item.kind == 'tileset') return ResourceLibraryCategory.images;
  if (item.kind == 'character') return ResourceLibraryCategory.characters;
  if (item.kind == 'model3d' && item.role == ResourceLibraryRole.component) {
    return ResourceLibraryCategory.models;
  }
  return switch (item.category ?? catalog.familyCategory(item.familyId)) {
    ResourceUsageCategory.vegetation => ResourceLibraryCategory.vegetation,
    ResourceUsageCategory.ground => ResourceLibraryCategory.ground,
    ResourceUsageCategory.path => ResourceLibraryCategory.paths,
    ResourceUsageCategory.water => ResourceLibraryCategory.water,
    ResourceUsageCategory.relief => ResourceLibraryCategory.relief,
    ResourceUsageCategory.building => ResourceLibraryCategory.buildings,
    ResourceUsageCategory.structure => ResourceLibraryCategory.structures,
    ResourceUsageCategory.furniture => ResourceLibraryCategory.furniture,
    ResourceUsageCategory.object => ResourceLibraryCategory.objects,
    null => switch (item.kind) {
      'smartTilePreset' => ResourceLibraryCategory.ground,
      'borderBlueprint' => ResourceLibraryCategory.relief,
      'environmentPreset' => ResourceLibraryCategory.environments,
      _ => ResourceLibraryCategory.objects,
    },
  };
}

ResourceLibraryDimension? _dimension(String kind) => switch (kind) {
  'model3d' => ResourceLibraryDimension.threeDimensional,
  'tileset' || 'element' => ResourceLibraryDimension.twoDimensional,
  _ => null,
};

String _type(ProjectLibraryItem item) => switch (item.kind) {
  'model3d' =>
    item.role == ResourceLibraryRole.component
        ? 'Modèle 3D source'
        : 'Modèle 3D',
  'element' => 'Décor 2D',
  'tileset' => 'Image et tuiles',
  'character' => 'Personnage',
  'borderBlueprint' => 'Bordure',
  'environmentPreset' => 'Ensemble de décors',
  'smartTilePreset' => 'Terrain à peindre',
  _ => 'Ressource',
};
