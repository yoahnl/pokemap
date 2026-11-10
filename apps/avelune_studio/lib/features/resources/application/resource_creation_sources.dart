import 'package:map_core/map_core_domain.dart';

import '../../terrains/domain/terrain_draft_compatibility.dart';
import '../../decors/application/decor_source_support.dart';
import 'resource_catalog.dart';

List<ResourceItem> resourceCreationSources(
  ProjectManifest project, {
  bool decor = false,
}) => resourceCatalog(project)
    .where(
      (item) => (!decor && project.settings.dimension == ProjectDimension.threeD
          ? item.model3d != null && item.metadata(project)?.mapId == null
          : item.tileset != null &&
                (decor
                    ? canCreateDecor(item.tileset!, project)
                    : terrainSourceCompatibilityProblem(item.tileset!) ==
                          null)),
    )
    .toList();

bool nativeLedgeSourcesAvailable(
  BorderBlueprintRecord record,
  ProjectManifest project, {
  Iterable<String> unavailableResourceIds = const [],
}) {
  final unavailable = unavailableResourceIds.toSet();
  final primitives = record.draft.definition.primitives;
  if (primitives.isEmpty) return false;
  for (final primitive in primitives) {
    if (primitive.isSpatial ||
        primitive.role != BorderPrimitiveRole.structureLarge) {
      return false;
    }
    final element = project.elements
        .where((element) => element.id == primitive.sourceElementId)
        .firstOrNull;
    if (element == null || element.frames.isEmpty) return false;
    final resourceIds = <String>{element.id};
    for (final frame in element.frames) {
      final id = frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId;
      final tileset = project.tilesets
          .where((tile) => tile.id == id)
          .firstOrNull;
      if (tileset == null) return false;
      resourceIds.add(id);
      if (tileset.source case ProjectImageCollectionTilesetSource(
        :final pages,
      )) {
        resourceIds.addAll(pages.map((page) => page.assetId));
      }
    }
    if (resourceIds.any(unavailable.contains)) return false;
  }
  return true;
}

String? nativeLedgeJumpDimensionNotice(ProjectDimension dimension) =>
    dimension == ProjectDimension.threeD
    ? 'Ce saut s’applique aux cartes 2D : sur une carte 3D, le jeu ne fait pas sauter un rebord. Ajoutez-y un « Talus à sens unique » depuis les outils de la carte.'
    : null;

List<ResourceItem> borderCreationSources(
  ProjectManifest project, {
  String? activeMapId,
}) => resourceCatalog(project)
    .where(
      (item) => project.settings.dimension == ProjectDimension.threeD
          ? item.model3d != null
          : item.element != null,
    )
    .where(
      (item) => activeMapId != null || item.metadata(project)?.mapId == null,
    )
    .toList();

List<ResourceItem> environmentPaletteCandidates(
  ProjectManifest project, {
  Set<String> excluded = const {},
}) => resourceCatalog(project)
    .where(
      (item) =>
          !excluded.contains(item.identity) &&
          (item.element != null || item.model3d != null),
    )
    .toList();
