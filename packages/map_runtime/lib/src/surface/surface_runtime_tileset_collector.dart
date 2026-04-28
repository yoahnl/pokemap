import 'package:map_core/map_core.dart';

/// Collects Surface atlas tilesets required by placed Surface presets.
///
/// The collector scans every frame referenced by each placed preset. That is a
/// little broader than the Lot 89 resolver, but it keeps runtime loading ready
/// for animations that hop across multiple atlases or tilesets.
Set<String> collectSurfaceRuntimeTilesetIds({
  required MapData map,
  required ProjectSurfaceCatalog catalog,
}) {
  final presetIds = <String>{};
  for (final layer in map.layers.whereType<SurfaceLayer>()) {
    for (final placement in layer.placements) {
      final presetId = placement.surfacePresetId.trim();
      if (presetId.isNotEmpty) {
        presetIds.add(presetId);
      }
    }
  }
  if (presetIds.isEmpty) {
    return const <String>{};
  }

  final tilesetIds = <String>{};
  for (final presetId in presetIds) {
    final preset = catalog.presetById(presetId);
    if (preset == null) {
      continue;
    }
    for (final ref in preset.variantAnimations.refs) {
      final animation = catalog.animationById(ref.animationId.trim());
      if (animation == null) {
        continue;
      }
      for (final frame in animation.timeline.frames) {
        final atlas = catalog.atlasById(frame.tileRef.atlasId.trim());
        final tilesetId = atlas?.tilesetId.trim();
        if (tilesetId != null && tilesetId.isNotEmpty) {
          tilesetIds.add(tilesetId);
        }
      }
    }
  }

  return Set<String>.unmodifiable(tilesetIds);
}
