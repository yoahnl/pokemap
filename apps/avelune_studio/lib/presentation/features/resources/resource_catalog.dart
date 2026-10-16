import 'package:map_core/map_core.dart';

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

final _catalogIndexes = Expando<Map<String, ResourceLibraryEntry>>();

ResourceLibraryEntry? _catalogEntry(
  ResourceLibraryCatalog catalog,
  String identity,
) {
  final index = _catalogIndexes[catalog] ??= Map.unmodifiable({
    for (final entry in catalog.entries) entry.identity: entry,
  });
  return index[identity];
}

class ResourceCatalogFilterState {
  ResourceCatalogFilterState({
    this.familyId = '',
    this.scope = ResourceCatalogScope.all,
    this.usage = ResourceCatalogUsage.all,
    this.context = ResourceCatalogContext.all,
    this.query = '',
    this.showComponents = false,
  });
  String familyId;
  ResourceCatalogScope scope;
  ResourceCatalogUsage usage;
  ResourceCatalogContext context;
  String query;
  bool showComponents;

  ResourceCatalogFilterState copy() => ResourceCatalogFilterState(
    familyId: familyId,
    scope: scope,
    usage: usage,
    context: context,
    query: query,
    showComponents: showComponents,
  );

  void copyFrom(ResourceCatalogFilterState value) {
    familyId = value.familyId;
    scope = value.scope;
    usage = value.usage;
    context = value.context;
    query = value.query;
    showComponents = value.showComponents;
  }

  void reset() {
    familyId = '';
    scope = ResourceCatalogScope.all;
    usage = ResourceCatalogUsage.all;
    context = ResourceCatalogContext.all;
    query = '';
    showComponents = false;
  }
}

const uncategorizedResourceCategory = '__uncategorized__';

class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.name,
    required this.kind,
    this.element,
    this.model3d,
    this.terrain,
    this.tileset,
    this.border,
    this.environment,
    this.character,
    this.category = '',
    this.tags = const [],
  });
  final String id;
  final String name;
  final ResourceKind kind;
  final ProjectElementEntry? element;
  final ProjectModel3dEntry? model3d;
  final ProjectSmartTilePreset? terrain;
  final ProjectTilesetEntry? tileset;
  final BorderBlueprintRecord? border;
  final EnvironmentPreset? environment;
  final ProjectCharacterEntry? character;
  final String category;
  final List<String> tags;
  String get canonicalKind => switch (this) {
    ResourceItem(model3d: _?) => 'model3d',
    ResourceItem(element: _?) => 'element',
    ResourceItem(terrain: _?) => 'smartTilePreset',
    ResourceItem(tileset: _?) => 'tileset',
    ResourceItem(border: _?) => 'borderBlueprint',
    ResourceItem(environment: _?) => 'environmentPreset',
    ResourceItem(character: _?) => 'character',
    _ => kind.canonicalKind,
  };
  String get identity => '$canonicalKind:$id';
  Set<ResourceCatalogUsage> get usages => switch (canonicalKind) {
    'element' => {ResourceCatalogUsage.place, ResourceCatalogUsage.scatter},
    'model3d' => {
      ResourceCatalogUsage.place,
      ResourceCatalogUsage.paint,
      ResourceCatalogUsage.trace,
      ResourceCatalogUsage.scatter,
    },
    'character' => {ResourceCatalogUsage.place},
    'smartTilePreset' || 'tileset' => {ResourceCatalogUsage.paint},
    'borderBlueprint' => {ResourceCatalogUsage.trace},
    'environmentPreset' => {ResourceCatalogUsage.scatter},
    _ => {},
  };
  String get typeLabel => switch (canonicalKind) {
    'element' => 'Décor',
    'model3d' => 'Modèle 3D',
    'smartTilePreset' => 'Terrain automatique',
    'tileset' => 'Image et tuiles',
    'borderBlueprint' => 'Bordure',
    'environmentPreset' => 'Environnement',
    'character' => 'Personnage',
    _ => switch (kind) {
      ResourceKind.decors => 'Décor',
      ResourceKind.terrains => 'Terrain automatique',
      ResourceKind.images => 'Image et tuiles',
    },
  };

  bool compatibleWith(ProjectDimension dimension) => switch (canonicalKind) {
    'model3d' => dimension == ProjectDimension.threeD,
    'smartTilePreset' =>
      dimension == ProjectDimension.threeD ||
          terrain?.rules.every(
                (rule) => rule.candidates.every(
                  (candidate) => candidate.parts.every(
                    (part) => part.source is! SmartTileModel3dSource,
                  ),
                ),
              ) ==
              true,
    'environmentPreset' =>
      environment?.isSpatial == (dimension == ProjectDimension.threeD),
    'borderBlueprint' =>
      (border?.latestPublished?.definition.isSpatial ??
              border?.draft.definition.isSpatial) ==
          (dimension == ProjectDimension.threeD),
    'element' || 'tileset' => dimension == ProjectDimension.twoD,
    _ => true,
  };

  ResourceLibraryEntry? metadata(ProjectManifest project) =>
      _catalogEntry(project.resourceLibraryCatalog, identity);
}

class ResourceLibraryState {
  final filters = ResourceCatalogFilterState();
  bool atelierVisible = false;
  ResourceLibraryFamily family = ResourceLibraryFamily.decors;
  ResourceKind _kind = ResourceKind.decors;
  ResourceKind get kind => _kind;
  set kind(ResourceKind value) {
    _kind = value;
    family = switch (value) {
      ResourceKind.decors => ResourceLibraryFamily.decors,
      ResourceKind.terrains => ResourceLibraryFamily.terrains,
      ResourceKind.images => ResourceLibraryFamily.images,
    };
  }

  void selectFamily(ResourceLibraryFamily value) {
    atelierVisible = true;
    family = value;
    final resourceKind = switch (value) {
      ResourceLibraryFamily.decors => ResourceKind.decors,
      ResourceLibraryFamily.terrains => ResourceKind.terrains,
      ResourceLibraryFamily.images => ResourceKind.images,
      _ => null,
    };
    if (resourceKind != null) _kind = resourceKind;
    category = '';
    filters.familyId = '';
    filters.usage = ResourceCatalogUsage.all;
  }

  String get query => filters.query;
  set query(String value) => filters.query = value;
  String category = '';
  String? _selectedId;
  ResourceKind _selectedKind = ResourceKind.decors;
  String? _selectedCanonicalKind;
  String? get selectedId => _selectedId;
  set selectedId(String? value) {
    _selectedId = value;
    _selectedKind = kind;
    _selectedCanonicalKind = null;
  }

  String? get selectedIdentity => _selectedId == null
      ? null
      : '${_selectedCanonicalKind ?? _selectedKind.canonicalKind}:$_selectedId';
  ResourceSort sort = ResourceSort.nameAscending;
  bool grid = true;
  bool revealPending = false;
  double offset = 0;

  bool matchesQuery(ResourceItem item) => '${item.name} ${item.tags.join(' ')}'
      .toLowerCase()
      .contains(query.trim().toLowerCase());

  bool matchesCategory(ResourceItem item, {Set<String>? acceptedCategories}) =>
      category.isEmpty ||
      (category == uncategorizedResourceCategory
          ? item.category.isEmpty
          : acceptedCategories?.contains(item.category) ??
                item.category == category);

  List<ResourceItem> visibleItems(
    List<ResourceItem> items, {
    Set<String>? acceptedCategories,
  }) {
    final visible = items
        .where(
          (item) =>
              item.kind == kind &&
              matchesQuery(item) &&
              matchesCategory(item, acceptedCategories: acceptedCategories),
        )
        .toList();
    visible.sort((a, b) {
      final names = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (names == 0) return a.identity.compareTo(b.identity);
      return sort == ResourceSort.nameAscending ? names : -names;
    });
    return visible;
  }

  ResourceItem? reconcileSelection(List<ResourceItem> visible) {
    final selected = visible
        .where((item) => item.identity == selectedIdentity)
        .firstOrNull;
    final result = selected ?? visible.firstOrNull;
    select(result);
    return result;
  }

  void select(ResourceItem? item) {
    _selectedId = item?.id;
    _selectedKind = item?.kind ?? kind;
    _selectedCanonicalKind = item?.canonicalKind;
  }

  void reveal(ResourceItem item) {
    kind = item.kind;
    if (!matchesQuery(item)) query = '';
    if (!matchesCategory(item)) category = '';
    filters.familyId = '';
    filters.scope = ResourceCatalogScope.all;
    filters.context = ResourceCatalogContext.all;
    filters.usage = ResourceCatalogUsage.all;
    select(item);
    revealPending = true;
  }
}

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
        '${item.name} ${item.tags.join(' ')}'.toLowerCase().contains(query);
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
