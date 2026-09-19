import 'package:map_core/map_core_domain.dart';

enum ResourceKind { decors, terrains, images }

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
}

class ResourceLibraryState {
  ResourceKind kind = ResourceKind.decors;
  String query = '';
  String category = '';
  String? selectedId;
  bool grid = true;
  double offset = 0;
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
