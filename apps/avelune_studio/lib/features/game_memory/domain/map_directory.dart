enum MapDirectoryElementKind { entity, trigger, mapEvent, modelInstance }

final class MapDirectoryElement {
  const MapDirectoryElement({
    required this.id,
    required this.kind,
    this.name,
    this.characterId,
    this.entityId,
  });

  final String id;
  final MapDirectoryElementKind kind;
  final String? name;
  final String? characterId;
  final String? entityId;
}

final class MapDirectoryPage {
  MapDirectoryPage({
    required this.mapId,
    required this.name,
    required List<MapDirectoryElement> elements,
  }) : elements = List.unmodifiable(elements);

  final String mapId;
  final String name;
  final List<MapDirectoryElement> elements;

  MapDirectoryElement? element(MapDirectoryElementKind kind, String id) =>
      elements
          .where((element) => element.kind == kind && element.id == id)
          .firstOrNull;
}
