import 'package:map_core/map_core.dart';

import 'narrative_authoring_exception.dart';

ProjectManifest placePublishedCinematic(
  ProjectManifest project,
  String cinematicId,
  Map<String, dynamic> placement,
) {
  if (project.version != ProjectVersion.v7) {
    throw NarrativeAuthoringException(
      'cinematic_library.project_v7_required',
      'Cinematic library actions require project version 7.',
      details: {'projectVersion': project.version.name},
    );
  }
  if (placement.keys.any(
        (key) => !const {'folderId', 'index'}.contains(key),
      ) ||
      !placement.containsKey('folderId') ||
      placement['index'] is! int ||
      (placement['folderId'] != null && placement['folderId'] is! String)) {
    throw ArgumentError.value(placement, 'libraryPlacement');
  }
  return project.copyWith(
    cinematicLibraryCatalog:
        const CinematicLibraryCatalogOperations().placeCinematic(
      project.cinematicLibraryCatalog,
      family: CinematicLibraryFamily.world,
      cinematicId: cinematicId,
      targetFolderId: placement['folderId'] as String?,
      targetIndex: placement['index'] as int,
    ),
  );
}
