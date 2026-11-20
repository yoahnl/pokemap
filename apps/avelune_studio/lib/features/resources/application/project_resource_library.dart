import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/studio_search_text.dart';
import 'resource_catalog.dart';

abstract interface class ProjectResourceLibraryPort {
  Future<ProjectResourceLibrary> readResourceLibrary(ProjectSession session);
}

abstract interface class ProjectResourceLibraryDimensionsPort
    implements ProjectResourceLibraryPort {
  Future<ProjectResourceLibrary> readResourceLibraryIndex(
    ProjectSession session,
  );

  Future<Map<String, Set<ProjectDimension>>?> readResourceLibraryDimensions(
    ProjectSession session, {
    required String revision,
  });
}

abstract interface class ProjectResourceLibraryMapUsagesPort {
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  });
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
    this.placementContext,
    this.role = ResourceLibraryRole.standard,
    Iterable<String> tags = const [],
    Set<ProjectDimension>? compatibleDimensions,
  }) : compatibleDimensions = compatibleDimensions == null
           ? resourceCompatibleDimensions(kind)
           : Set.unmodifiable(compatibleDimensions),
       searchText = studioSearchText([name, ...tags, ?description].join(' '));

  ProjectLibraryItem._withDimensions(
    ProjectLibraryItem item,
    Set<ProjectDimension> dimensions,
  ) : kind = item.kind,
      id = item.id,
      name = item.name,
      familyId = item.familyId,
      mapId = item.mapId,
      description = item.description,
      category = item.category,
      placementContext = item.placementContext,
      role = item.role,
      searchText = item.searchText,
      compatibleDimensions = Set.unmodifiable(dimensions);

  final String kind, id, name, searchText;
  final String? familyId, mapId, description;
  final ResourceUsageCategory? category;
  final ResourcePlacementContext? placementContext;
  final ResourceLibraryRole role;
  final Set<ProjectDimension> compatibleDimensions;

  String get identity => '$kind:$id';

  ProjectLibraryItem withDimensions(Set<ProjectDimension> dimensions) =>
      ProjectLibraryItem._withDimensions(this, dimensions);
}

class ProjectResourceLibrary {
  ProjectResourceLibrary(
    this.catalog,
    Iterable<ProjectLibraryItem> items, {
    this.revision,
  }) : items = List.unmodifiable(items);

  factory ProjectResourceLibrary.fromManifest(ProjectManifest project) {
    final catalog = project.resourceLibraryCatalog;
    return ProjectResourceLibrary(catalog, [
      for (final item in resourceCatalog(project))
        _manifestItem(item, item.metadata(project)),
    ]);
  }

  final ResourceLibraryCatalog catalog;
  final List<ProjectLibraryItem> items;
  final String? revision;

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
    placementContext: entry?.placementContext,
    role: entry?.role ?? ResourceLibraryRole.standard,
    tags: item.tags,
    compatibleDimensions: item.compatibleDimensions,
  );
}

ProjectManifest withoutLibraryResource(
  ProjectManifest manifest,
  ({String kind, String id}) resource,
) {
  final (:kind, :id) = resource;
  final library = manifest.resourceLibraryCatalog;
  final classification = library.entryFor(kind, id);
  final project = classification == null
      ? manifest
      : manifest.copyWith(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            families: library.families,
            entries: library.entries.where((entry) => entry != classification),
          ),
        );

  ProjectManifest remove<T>(
    List<T> entries,
    String Function(T) identity,
    ProjectManifest Function(List<T>) update,
  ) => entries.any((entry) => identity(entry) == id)
      ? update(entries.where((entry) => identity(entry) != id).toList())
      : project;

  final terrain = project.smartTileCatalog;
  final borders = project.borderCatalog;
  return switch (kind) {
    'model3d' => remove(
      project.models3d,
      (model) => model.id,
      (models) =>
          project.copyWith(models3d: ProjectModel3dEntries.prepare(models)),
    ),
    'tileset' => remove(
      project.tilesets,
      (tileset) => tileset.id,
      (tilesets) => project.copyWith(tilesets: tilesets),
    ),
    'element' => remove(
      project.elements,
      (element) => element.id,
      (elements) => project.copyWith(elements: elements),
    ),
    'character' => remove(
      project.characters,
      (character) => character.id,
      (characters) => project.copyWith(characters: characters),
    ),
    'environmentPreset' => remove(
      project.environmentPresets,
      (preset) => preset.id,
      (presets) => project.copyWith(environmentPresets: presets),
    ),
    'smartTilePreset' => remove(
      terrain.presets,
      (preset) => preset.id,
      (presets) => project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          formatVersion: terrain.formatVersion,
          categories: terrain.categories,
          atlases: terrain.atlases,
          materials: terrain.materials,
          animations: terrain.animations,
          patterns: terrain.patterns,
          drafts: terrain.drafts,
          presets: presets,
        ),
      ),
    ),
    'borderBlueprint' => remove(
      borders.records,
      (border) => border.id,
      (records) => project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: borders.formatVersion,
          visualSnapshots: borders.visualSnapshots,
          records: records,
        ),
      ),
    ),
    _ => project,
  };
}
