import 'package:map_core/map_core_domain.dart';

enum ResourceKind { decors, terrains, images }

enum ResourceSort { nameAscending, nameDescending }

const uncategorizedResourceCategory = '__uncategorized__';

class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.name,
    required this.kind,
    this.element,
    this.terrain,
    this.tileset,
    this.category = '',
    this.tags = const [],
  });
  final String id;
  final String name;
  final ResourceKind kind;
  final ProjectElementEntry? element;
  final ProjectSmartTilePreset? terrain;
  final ProjectTilesetEntry? tileset;
  final String category;
  final List<String> tags;
  String get identity => '${kind.name}:$id';
}

class ResourceLibraryState {
  ResourceKind kind = ResourceKind.decors;
  String query = '';
  String category = '';
  String? _selectedId;
  ResourceKind _selectedKind = ResourceKind.decors;
  String? get selectedId => _selectedId;
  set selectedId(String? value) {
    _selectedId = value;
    _selectedKind = kind;
  }

  String? get selectedIdentity =>
      _selectedId == null ? null : '${_selectedKind.name}:$_selectedId';
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
        .where((item) => item.identity == selectedIdentity && item.kind == kind)
        .firstOrNull;
    final result =
        selected ?? visible.where((item) => item.kind == kind).firstOrNull;
    selectedId = result?.id;
    return result;
  }

  void reveal(ResourceItem item) {
    kind = item.kind;
    if (!matchesQuery(item)) query = '';
    if (!matchesCategory(item)) category = '';
    selectedId = item.id;
    revealPending = true;
  }
}

List<ResourceItem> resourceCatalog(ProjectManifest manifest) => [
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
];

Map<String, String> resourceCategories(
  ProjectManifest manifest,
  ResourceKind kind, {
  List<ResourceItem>? items,
}) {
  final family = (items ?? resourceCatalog(manifest)).where(
    (item) => item.kind == kind,
  );
  final present = family.map((item) => item.category).toSet();
  if (present.every((id) => id.isEmpty)) return {};
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
  final ids = present.where((id) => id.isNotEmpty).toList()
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
