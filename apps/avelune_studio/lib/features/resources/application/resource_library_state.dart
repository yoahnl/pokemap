import 'resource_catalog.dart';

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

  bool includesFamily(ResourceItem item) => switch (family) {
    ResourceLibraryFamily.decors =>
      item.element != null || item.model3d != null,
    ResourceLibraryFamily.terrains => item.terrain != null,
    ResourceLibraryFamily.images => item.tileset != null,
    ResourceLibraryFamily.borders => item.border != null,
    ResourceLibraryFamily.environments => item.environment != null,
    ResourceLibraryFamily.models3d => item.model3d != null,
  };

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
  bool marking = false;
  final marked = <String>{};

  void toggleMark(ResourceItem item) {
    marking = true;
    if (!marked.remove(item.identity)) marked.add(item.identity);
  }

  void markAll(Iterable<ResourceItem> items) {
    marking = true;
    marked.addAll(items.map((item) => item.identity));
  }

  void clearMarks({bool stopMarking = false}) {
    marked.clear();
    if (stopMarking) marking = false;
  }

  List<ResourceItem> markedItems(Iterable<ResourceItem> catalog) {
    final present = {
      for (final item in catalog)
        if (marked.contains(item.identity)) item.identity: item,
    };
    marked.retainAll(present.keys);
    return present.values.toList()..sort((a, b) {
      final names = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return names == 0 ? a.identity.compareTo(b.identity) : names;
    });
  }

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

  bool selectionRemoved = false;

  void reconcileRemoval(
    Iterable<ResourceItem> before,
    Iterable<ResourceItem> after,
  ) {
    final identity = selectedIdentity;
    if (identity == null ||
        !before.any((item) => item.identity == identity) ||
        after.any((item) => item.identity == identity)) {
      return;
    }
    select(null);
    selectionRemoved = true;
  }

  ResourceItem? reconcileSelection(List<ResourceItem> visible) {
    if (selectionRemoved) return null;
    final selected = visible
        .where((item) => item.identity == selectedIdentity)
        .firstOrNull;
    final result = selected ?? visible.firstOrNull;
    select(result);
    return result;
  }

  void select(ResourceItem? item) {
    selectionRemoved = false;
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
