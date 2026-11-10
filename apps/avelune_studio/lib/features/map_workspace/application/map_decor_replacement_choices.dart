import 'package:map_core/map_core_domain.dart';

import '../../resources/application/resource_catalog.dart';
import 'map_border_review.dart';

List<ResourceItem> mapDecorReplacementChoices(
  ProjectManifest project, {
  required String mapId,
  required bool spatial,
  String query = '',
}) {
  final kind = spatial ? 'model3d' : 'element';
  final borderPieces = mapBorderPieceIdentities(project);
  return filterResourceCatalog(
    project,
    resourceCatalog(project).where(
      (item) =>
          item.canonicalKind == kind &&
          !borderPieces.contains('$kind:${item.id}'),
    ),
    ResourceCatalogFilterState(query: query),
    activeMapId: mapId,
    forMapPicker: true,
  );
}
