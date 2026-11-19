import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/studio_search_text.dart';
import 'resource_catalog.dart';

abstract interface class ProjectResourceLibraryPort {
  Future<ProjectResourceLibrary> readResourceLibrary(ProjectSession session);
}

class ProjectLibraryItem {
  ProjectLibraryItem({
    required this.kind,
    required this.id,
    required this.name,
    this.familyId,
    this.mapId,
    this.description,
    this.category,
    this.role = ResourceLibraryRole.standard,
    Iterable<String> tags = const [],
  }) : searchText = studioSearchText([name, ...tags, ?description].join(' '));

  final String kind, id, name, searchText;
  final String? familyId, mapId, description;
  final ResourceUsageCategory? category;
  final ResourceLibraryRole role;

  String get identity => '$kind:$id';
}

class ProjectResourceLibrary {
  ProjectResourceLibrary(this.catalog, Iterable<ProjectLibraryItem> items)
    : items = List.unmodifiable(items);

  factory ProjectResourceLibrary.fromManifest(ProjectManifest project) {
    final catalog = project.resourceLibraryCatalog;
    return ProjectResourceLibrary(catalog, [
      for (final item in resourceCatalog(project))
        _manifestItem(item, item.metadata(project)),
    ]);
  }

  final ResourceLibraryCatalog catalog;
  final List<ProjectLibraryItem> items;

  static ProjectLibraryItem _manifestItem(
    ResourceItem item,
    ResourceLibraryEntry? entry,
  ) => ProjectLibraryItem(
    kind: item.canonicalKind,
    id: item.id,
    name: item.name,
    familyId: entry?.familyId,
    mapId: entry?.mapId,
    description: entry?.description,
    category: entry?.category,
    role: entry?.role ?? ResourceLibraryRole.standard,
    tags: item.tags,
  );
}
