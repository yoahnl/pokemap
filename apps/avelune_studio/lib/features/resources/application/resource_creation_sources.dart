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
