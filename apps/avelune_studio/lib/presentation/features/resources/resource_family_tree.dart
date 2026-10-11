import 'package:map_core/map_core.dart';

import 'resource_catalog.dart';

class ResourceFamilyNode {
  const ResourceFamilyNode({
    required this.id,
    required this.name,
    required this.parentId,
    required this.depth,
    required this.count,
    required this.custom,
  });
  final String id, name;
  final String? parentId;
  final int depth, count;
  final bool custom;
}

class ResourceFamilyTree {
  ResourceFamilyTree(
    ProjectManifest project,
    Iterable<ResourceItem> items, {
    String? activeMapId,
    bool forMapPicker = false,
  }) {
    final available = filterResourceCatalog(
      project,
      items,
      ResourceCatalogFilterState(),
      activeMapId: activeMapId,
      forMapPicker: forMapPicker,
    );
    total = available.length;
    final catalog = project.resourceLibraryCatalog;
    final families = catalog.effectiveFamilies;
    final ids = families.map((family) => family.id).toSet();
    final customIds = catalog.families.map((family) => family.id).toSet();
    final direct = <String, int>{};
    for (final item in available) {
      final id = item.metadata(project)?.familyId;
      if (id == null) {
        unclassified++;
      } else {
        direct[id] = (direct[id] ?? 0) + 1;
      }
    }
    final visited = <String>{};
    void visit(String? parent, int depth) {
      for (final family in families.where(
        (family) => family.parentId == parent,
      )) {
        if (!visited.add(family.id)) continue;
        final descendants = catalog.descendantFamilyIds(family.id);
        nodes.add(
          ResourceFamilyNode(
            id: family.id,
            name: family.name,
            parentId: family.parentId,
            depth: depth,
            count: descendants.fold(
              0,
              (count, id) => count + (direct[id] ?? 0),
            ),
            custom: customIds.contains(family.id),
          ),
        );
        visit(family.id, depth + 1);
      }
    }

    visit(null, 0);
    for (final family in families) {
      if (!visited.contains(family.id) && !ids.contains(family.parentId)) {
        visit(family.parentId, 0);
      }
    }
  }
  final nodes = <ResourceFamilyNode>[];
  int total = 0;
  int unclassified = 0;
}
