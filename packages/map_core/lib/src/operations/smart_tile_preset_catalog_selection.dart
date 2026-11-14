import '../models/smart_tile.dart';
import 'resource_pack_dependency_graph.dart';

ProjectSmartTileCatalog selectSmartTilePresetCatalog(
  ProjectSmartTileCatalog catalog,
  ProjectSmartTilePreset preset,
) {
  final materialIds = smartTilePresetMaterialIds(preset).toSet();
  final materials = catalog.materials
      .where((material) => materialIds.contains(material.id))
      .toList(growable: false);
  final animationIds = <String>{};
  final atlasIds = <String>{};
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        switch (part.source) {
          case SmartTileFrameSource(:final frame):
            atlasIds.add(frame.atlasId);
          case SmartTileAnimationSource(:final animationId):
            animationIds.add(animationId);
          case SmartTileModel3dSource():
            break;
        }
      }
    }
  }
  final animations = catalog.animations
      .where((animation) => animationIds.contains(animation.id))
      .toList(growable: false);
  for (final animation in animations) {
    for (final frame in animation.frames) {
      atlasIds.add(frame.frame.atlasId);
    }
  }
  final categoryIds = {
    preset.categoryId,
    for (final material in materials) material.categoryId,
  };
  return ProjectSmartTileCatalog(
    formatVersion: catalog.formatVersion,
    categories: catalog.categories
        .where((category) => categoryIds.contains(category.id))
        .toList(growable: false),
    atlases: catalog.atlases
        .where((atlas) => atlasIds.contains(atlas.id))
        .toList(growable: false),
    materials: materials,
    animations: animations,
    presets: catalog.presets
        .where((candidate) => candidate.id == preset.id)
        .toList(growable: false),
  );
}
