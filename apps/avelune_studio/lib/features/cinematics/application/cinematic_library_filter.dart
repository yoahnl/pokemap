import 'package:map_core/map_core_domain.dart';

import 'cinematic_workspace_controller.dart';

const cinematicLibraryNoMapLabel = 'Sans carte';

List<CinematicAsset> cinematicLibraryEntries(
  CinematicWorkspaceController controller, {
  required String search,
  required String folderId,
  required bool archived,
}) {
  final catalog = controller.project.cinematicLibraryCatalog;
  final query = search.trim().toLowerCase();
  return controller.entries.where((asset) {
    final entry = catalog.entries
        .where(
          (e) =>
              e.family == CinematicLibraryFamily.world &&
              e.cinematicId == asset.id,
        )
        .firstOrNull;
    final context =
        controller.project.maps
            .where((map) => map.id == asset.mapId)
            .firstOrNull
            ?.name ??
        cinematicLibraryNoMapLabel;
    return '${asset.title} $context ${asset.id}'.toLowerCase().contains(
          query,
        ) &&
        (folderId.isEmpty ||
            (controller.session(asset.id)?.folderId ?? entry?.folderId) ==
                folderId) &&
        (archived || entry?.isArchived != true);
  }).toList();
}
