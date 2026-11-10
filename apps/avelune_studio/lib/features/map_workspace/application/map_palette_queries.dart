import '../../resources/application/resource_catalog.dart';
import '../../resources/application/resource_family_tree.dart';

class MapPaletteQueries {
  MapPaletteQueries(this.filters);
  final ResourceCatalogFilterState filters;
  String intent = 'Décors';
  final queries = <String, String>{};
  final families = <String, String>{};

  void select(String value, {String? currentQuery}) {
    if (value == intent) return;
    queries[intent] = currentQuery ?? filters.query;
    families[intent] = filters.familyId;
    intent = value;
    filters
      ..query = queries[value] ?? ''
      ..familyId = families[value] ?? '';
  }
}

List<ResourceFamilyNode> mapPaletteQuickFamilies(
  ResourceFamilyTree tree,
  String selectedId,
) {
  final nodes = tree.nodes;
  final parentIds = nodes.map((node) => node.parentId).toSet();
  final quick =
      nodes
          .where((node) => node.count > 0 && !parentIds.contains(node.id))
          .toList()
        ..sort((left, right) {
          final nested = right.depth.compareTo(left.depth);
          if (nested != 0) return nested;
          final count = right.count.compareTo(left.count);
          return count == 0 ? left.name.compareTo(right.name) : count;
        });
  final choices = quick.take(6).toList();
  final selected = nodes.where((node) => node.id == selectedId).firstOrNull;
  if (selected != null) {
    choices.removeWhere((node) => node.id == selected.id);
    choices.insert(0, selected);
  }
  return choices;
}
