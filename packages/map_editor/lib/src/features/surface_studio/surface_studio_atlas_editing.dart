import 'package:map_core/map_core.dart';

int countAnimationsReferencingAtlasId(
  ProjectSurfaceCatalog catalog,
  String atlasId,
) {
  var n = 0;
  for (final anim in catalog.animations) {
    for (final frame in anim.timeline.frames) {
      if (frame.tileRef.atlasId == atlasId) {
        n += 1;
        break;
      }
    }
  }
  return n;
}

ProjectSurfaceCatalog replaceAtlasInCatalogInPlace(
  ProjectSurfaceCatalog catalog,
  ProjectSurfaceAtlas updated,
) {
  final i = catalog.atlases.indexWhere((a) => a.id == updated.id);
  if (i < 0) {
    throw StateError('Atlas id absent du catalogue: ${updated.id}');
  }
  final nextAtlases = List<ProjectSurfaceAtlas>.from(catalog.atlases);
  nextAtlases[i] = updated;
  return ProjectSurfaceCatalog(
    atlases: nextAtlases,
    animations: List<ProjectSurfaceAnimation>.from(catalog.animations),
    presets: List<ProjectSurfacePreset>.from(catalog.presets),
  );
}

ProjectSurfaceCatalog removeAtlasIdFromWorkCatalog(
  ProjectSurfaceCatalog catalog,
  String atlasId,
) {
  final nextAtlases = catalog.atlases.where((a) => a.id != atlasId).toList();
  if (nextAtlases.length == catalog.atlases.length) {
    throw StateError('Atlas id introuvable: $atlasId');
  }
  return ProjectSurfaceCatalog(
    atlases: nextAtlases,
    animations: List<ProjectSurfaceAnimation>.from(catalog.animations),
    presets: List<ProjectSurfacePreset>.from(catalog.presets),
  );
}
