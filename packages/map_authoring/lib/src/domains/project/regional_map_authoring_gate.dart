import 'package:map_core/map_core.dart';

import '../assets/asset_store.dart';

final class RegionalMapAuthoringGate {
  const RegionalMapAuthoringGate();

  List<ProjectRegionalMapDiagnostic> inspect(
      {required ProjectManifest project,
      required AssetCatalog assets,
      Iterable<MapData>? maps}) {
    final diagnostics = [
      ...validateProjectRegionalMap(
          catalog: project.regionalMap,
          projectMapIds: project.maps.map((map) => map.id),
          maps: maps)
    ];
    final catalog = project.regionalMap;
    if (catalog == null) return diagnostics;
    final references = <String, String>{
      for (final region in catalog.regions)
        if (region.imagePath != null)
          '\$.regionalMap.regions[${region.id}].imagePath': region.imagePath!,
      for (final point in catalog.pointsOfInterest)
        if (point.thumbnailPath != null)
          '\$.regionalMap.pointsOfInterest[${point.id}].thumbnailPath':
              point.thumbnailPath!,
    };
    for (final entry in references.entries) {
      final asset = assets.findByLogicalPath(entry.value);
      if (asset == null) {
        diagnostics.add(ProjectRegionalMapDiagnostic(
            code: 'regional_map.image_missing',
            path: entry.key,
            message: 'Import the selected image into the project library.'));
      } else if (!const {'image/png', 'image/jpeg', 'image/webp', 'image/gif'}
          .contains(asset.artifact.mediaType)) {
        diagnostics.add(ProjectRegionalMapDiagnostic(
            code: 'regional_map.image_type_invalid',
            path: entry.key,
            message: 'Choose a PNG, JPEG, WebP or GIF image.'));
      }
    }
    return List.unmodifiable(diagnostics);
  }
}
