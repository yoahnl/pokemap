import 'package:map_core/map_core.dart';

final class ItemCatalogSnapshot {
  ItemCatalogSnapshot._({
    required this.catalog,
    required Map<String, ProjectItemDefinition> definitionsById,
  }) : _definitionsById = Map.unmodifiable(definitionsById);

  factory ItemCatalogSnapshot.fromCatalog(ProjectItemCatalog catalog) {
    final normalizedCatalog = catalog.normalized();
    final definitionsById = <String, ProjectItemDefinition>{};
    for (final definition in normalizedCatalog.entries) {
      if (definitionsById.containsKey(definition.id)) {
        throw StateError(
          'ItemCatalogSnapshot contains duplicate item id ${definition.id}',
        );
      }
      definitionsById[definition.id] = definition;
    }
    return ItemCatalogSnapshot._(
      catalog: normalizedCatalog,
      definitionsById: definitionsById,
    );
  }

  final ProjectItemCatalog catalog;
  final Map<String, ProjectItemDefinition> _definitionsById;

  Iterable<ProjectItemDefinition> get definitions =>
      _definitionsById.values;

  ProjectItemDefinition? definitionFor(String itemId) =>
      _definitionsById[itemId.trim()];
}
