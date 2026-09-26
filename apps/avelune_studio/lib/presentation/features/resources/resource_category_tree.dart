import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';

class ResourceCategoryNode {
  const ResourceCategoryNode({
    required this.id,
    required this.name,
    required this.parentId,
    required this.depth,
    required this.count,
  });

  final String id;
  final String name;
  final String? parentId;
  final int depth;
  final int count;
}

class ResourceCategoryTree {
  ResourceCategoryTree(
    ProjectManifest manifest,
    ResourceKind kind,
    List<ResourceItem> items,
  ) {
    final definitions = switch (kind) {
      ResourceKind.decors => [
        for (final category in manifest.elementCategories)
          (category.id, category.name, category.parentCategoryId),
      ],
      ResourceKind.terrains => [
        for (final category in manifest.smartTileCatalog.categories)
          (category.id, category.name, null),
      ],
      ResourceKind.images => [
        for (final folder in manifest.tilesetFolders)
          (folder.id, folder.name, folder.parentFolderId),
      ],
    };
    final matching = items.where((item) => item.kind == kind).toList();
    total = matching.length;
    uncategorized = matching.where((item) => item.category.isEmpty).length;
    final direct = <String, int>{};
    for (final item in matching.where((item) => item.category.isNotEmpty)) {
      direct.update(item.category, (count) => count + 1, ifAbsent: () => 1);
    }
    _parents = {
      for (final definition in definitions) definition.$1: definition.$3,
    };
    final names = {
      for (final definition in definitions) definition.$1: definition.$2,
    };
    final counts = <String, int>{};
    for (final entry in direct.entries) {
      var id = entry.key;
      final visited = <String>{};
      while (visited.add(id)) {
        counts.update(
          id,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
        final parent = _parents[id];
        if (parent == null || !_parents.containsKey(parent)) break;
        id = parent;
      }
    }
    final children = <String?, List<String>>{};
    for (final id in counts.keys) {
      final parent = _parents[id];
      children
          .putIfAbsent(
            parent != null && counts.containsKey(parent) ? parent : null,
            () => [],
          )
          .add(id);
    }
    for (final siblings in children.values) {
      siblings.sort((a, b) {
        final left = names[a] ?? a;
        final right = names[b] ?? b;
        final order = left.toLowerCase().compareTo(right.toLowerCase());
        return order == 0 ? a.compareTo(b) : order;
      });
    }
    final flattened = <ResourceCategoryNode>[];
    void visit(String? parent, int depth) {
      for (final id in children[parent] ?? const <String>[]) {
        flattened.add(
          ResourceCategoryNode(
            id: id,
            name: names[id] ?? id,
            parentId: _parents[id],
            depth: depth,
            count: counts[id]!,
          ),
        );
        visit(id, depth + 1);
      }
    }

    visit(null, 0);
    nodes = List.unmodifiable(flattened);
  }

  late final Map<String, String?> _parents;
  late final List<ResourceCategoryNode> nodes;
  late final int total;
  late final int uncategorized;

  Set<String> idsFor(String id) {
    if (id.isEmpty || id == uncategorizedResourceCategory) return {id};
    return {
      for (final node in nodes)
        if (_isDescendant(node.id, id)) node.id,
    };
  }

  bool _isDescendant(String candidate, String ancestor) {
    var current = candidate;
    final visited = <String>{};
    while (visited.add(current)) {
      if (current == ancestor) return true;
      final parent = _parents[current];
      if (parent == null) return false;
      current = parent;
    }
    return false;
  }
}
