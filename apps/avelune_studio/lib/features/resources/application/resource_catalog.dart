import 'package:map_core/map_core_domain.dart';

import 'resource_catalog_filter_state.dart';
import 'resource_item.dart';

export 'resource_catalog_filter_state.dart';
export 'resource_item.dart';
export 'resource_library_state.dart';

enum ResourceKind { decors, terrains, images }

extension ResourceKindCanonicalKind on ResourceKind {
  String get canonicalKind => switch (this) {
    ResourceKind.decors => 'element',
    ResourceKind.terrains => 'smartTilePreset',
    ResourceKind.images => 'tileset',
  };
}

enum ResourceLibraryFamily {
  decors,
  terrains,
  borders,
  environments,
  images,
  models3d,
}

extension ResourceLibraryFamilyCanonicalKind on ResourceLibraryFamily {
  String get canonicalKind => switch (this) {
    ResourceLibraryFamily.decors => 'element',
    ResourceLibraryFamily.terrains => 'smartTilePreset',
    ResourceLibraryFamily.borders => 'borderBlueprint',
    ResourceLibraryFamily.environments => 'environmentPreset',
    ResourceLibraryFamily.images => 'tileset',
    ResourceLibraryFamily.models3d => 'model3d',
  };
}

enum ResourceSort { nameAscending, nameDescending }

enum ResourceCatalogScope { all, project, map }

enum ResourceCatalogContext { all, interior, exterior, unspecified }

extension ResourceCatalogContextLabels on ResourceCatalogContext {
  String get label => switch (this) {
    ResourceCatalogContext.all => 'Tous',
    ResourceCatalogContext.interior => 'Intérieur',
    ResourceCatalogContext.exterior => 'Extérieur',
    ResourceCatalogContext.unspecified => 'Non renseigné',
  };
}

String resourcePlacementContextLabel(ResourcePlacementContext? value) =>
    switch (value) {
      ResourcePlacementContext.interior => 'Intérieur',
      ResourcePlacementContext.exterior => 'Extérieur',
      ResourcePlacementContext.both => 'Les deux',
      null => 'Non renseigné',
    };

enum ResourceCatalogUsage { all, place, paint, trace, scatter }

const unclassifiedResourceFamily = '__unclassified__';

List<ResourceItem> resourceCatalog(ProjectManifest manifest) => [
  for (final model in manifest.models3d)
    ResourceItem(
      id: model.id,
      name: model.name,
      kind: ResourceKind.decors,
      model3d: model,
    ),
  for (final e in manifest.elements)
    ResourceItem(
      id: e.id,
      name: e.name,
      kind: ResourceKind.decors,
      element: e,
      category: e.categoryId,
      tags: e.tags,
    ),
  for (final t in manifest.smartTileCatalog.presets)
    ResourceItem(
      id: t.id,
      name: t.name,
      kind: ResourceKind.terrains,
      terrain: t,
      category: t.categoryId,
      tags: t.tags,
    ),
  for (final t in manifest.tilesets)
    ResourceItem(
      id: t.id,
      name: t.name,
      kind: ResourceKind.images,
      tileset: t,
      category: t.folderId ?? '',
    ),
  for (final border in manifest.borderCatalog.records)
    ResourceItem(
      id: border.id,
      name: border.draft.definition.name,
      kind: ResourceKind.decors,
      border: border,
    ),
  for (final environment in manifest.environmentPresets)
    ResourceItem(
      id: environment.id,
      name: environment.name,
      kind: ResourceKind.decors,
      environment: environment,
      category: environment.categoryId ?? '',
    ),
  for (final character in manifest.characters)
    ResourceItem(
      id: character.id,
      name: character.name,
      kind: ResourceKind.decors,
      character: character,
      tags: character.tags,
    ),
];

List<ResourceItem> filterResourceCatalog(
  ProjectManifest manifest,
  Iterable<ResourceItem> items,
  ResourceCatalogFilterState filters, {
  String? activeMapId,
  bool forMapPicker = false,
}) {
  final catalog = manifest.resourceLibraryCatalog;
  final descendants =
      filters.familyId.isEmpty ||
          filters.familyId == unclassifiedResourceFamily ||
          !catalog.effectiveFamilies.any(
            (family) => family.id == filters.familyId,
          )
      ? const <String>{}
      : catalog.descendantFamilyIds(filters.familyId);
  final query = filters.query.trim().toLowerCase();
  return items.where((item) {
    final entry = item.metadata(manifest);
    final placementContext = entry?.placementContext;
    final matchesContext = switch (filters.context) {
      ResourceCatalogContext.all => true,
      ResourceCatalogContext.interior =>
        placementContext == ResourcePlacementContext.interior ||
            placementContext == ResourcePlacementContext.both,
      ResourceCatalogContext.exterior =>
        placementContext == ResourcePlacementContext.exterior ||
            placementContext == ResourcePlacementContext.both,
      ResourceCatalogContext.unspecified => placementContext == null,
    };
    if (!matchesContext) return false;
    if (!filters.showComponents &&
        entry?.role == ResourceLibraryRole.component) {
      return false;
    }
    if (filters.typeKind.isNotEmpty && item.canonicalKind != filters.typeKind) {
      return false;
    }
    if (filters.usableOnly &&
        !item.usableIn(manifest, activeMapId: activeMapId)) {
      return false;
    }
    final mapId = entry?.mapId;
    if (forMapPicker &&
        (!item.compatibleWith(manifest.settings.dimension) ||
            (mapId != null && mapId != activeMapId))) {
      return false;
    }
    if (filters.scope == ResourceCatalogScope.project && mapId != null) {
      return false;
    }
    if (filters.scope == ResourceCatalogScope.map &&
        (mapId == null || (forMapPicker && mapId != activeMapId))) {
      return false;
    }
    if (filters.familyId == unclassifiedResourceFamily) {
      if (entry?.familyId != null) return false;
    } else if (filters.familyId.isNotEmpty &&
        !descendants.contains(entry?.familyId)) {
      return false;
    }
    if (!forMapPicker &&
        filters.usage != ResourceCatalogUsage.all &&
        !item.usages.contains(filters.usage)) {
      return false;
    }
    return query.isEmpty ||
        '${item.name} ${item.tags.join(' ')} ${entry?.description ?? ''}'
            .toLowerCase()
            .contains(query);
  }).toList();
}

String resourceCatalogContextLabel(
  ProjectManifest project,
  ResourceItem item,
) => resourcePlacementContextLabel(item.metadata(project)?.placementContext);

String resourceCatalogFamilyLabel(ProjectManifest project, ResourceItem item) {
  final id = item.metadata(project)?.familyId;
  if (id == null) return 'Sans famille';
  return project.resourceLibraryCatalog.effectiveFamilies
          .where((family) => family.id == id)
          .firstOrNull
          ?.name ??
      'Famille introuvable';
}

String resourceCatalogScopeLabel(ProjectManifest project, ResourceItem item) {
  final mapId = item.metadata(project)?.mapId;
  if (mapId == null) return 'Projet';
  final name = project.maps.where((map) => map.id == mapId).firstOrNull?.name;
  return name == null ? 'Carte introuvable' : 'Carte : $name';
}

Map<String, String> resourceCategories(
  ProjectManifest manifest,
  ResourceKind kind, {
  List<ResourceItem>? items,
}) {
  final family = (items ?? resourceCatalog(manifest)).where(
    (item) => item.kind == kind,
  );
  final present = family.map((item) => item.category).toSet();
  final labels = switch (kind) {
    ResourceKind.decors => {
      for (final category in manifest.elementCategories)
        category.id: category.name,
    },
    ResourceKind.terrains => {
      for (final category in manifest.smartTileCatalog.categories)
        category.id: category.name,
    },
    ResourceKind.images => {
      for (final folder in manifest.tilesetFolders) folder.id: folder.name,
    },
  };
  if (labels.isEmpty && present.every((id) => id.isEmpty)) return {};
  final ids = {...labels.keys, ...present.where((id) => id.isNotEmpty)}.toList()
    ..sort((a, b) {
      final result = (labels[a] ?? a).toLowerCase().compareTo(
        (labels[b] ?? b).toLowerCase(),
      );
      return result == 0 ? a.compareTo(b) : result;
    });
  return {
    '': 'Toutes',
    for (final id in ids) id: labels[id] ?? id,
    if (present.contains('')) uncategorizedResourceCategory: 'Sans catégorie',
  };
}

Set<String> borderPieceIdentities(BorderBlueprintRecord border) => {
  for (final primitive in border.draft.definition.primitives)
    ?(primitive.sourceModelId == null
        ? primitive.sourceElementId == null
              ? null
              : 'element:${primitive.sourceElementId}'
        : 'model3d:${primitive.sourceModelId}'),
  for (final primitive
      in border.latestPublished?.definition.primitives ??
          const <BorderPublishedPrimitive>[])
    ?(primitive.sourceModelId == null
        ? primitive.sourceElementId == null
              ? null
              : 'element:${primitive.sourceElementId}'
        : 'model3d:${primitive.sourceModelId}'),
};

List<String> owningBorderNames(ProjectManifest project, ResourceItem item) {
  final identity = item.model3d != null
      ? 'model3d:${item.id}'
      : item.element != null
      ? 'element:${item.id}'
      : null;
  if (identity == null) return const [];
  return [
    for (final border in project.borderCatalog.records)
      if (!border.isDeprecated &&
          borderPieceIdentities(border).contains(identity))
        border.draft.definition.name,
  ];
}
