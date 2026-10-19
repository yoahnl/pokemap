import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/smart_tile.dart';

abstract final class SpatialModelClipCapabilities {
  static const capabilityId = 'map3d.model-clip@1';
  static const resourcePackCapabilityId = 'models.static-clip';

  static Set<String> catalogModelIds(ProjectSmartTileCatalog catalog) => {
    for (final part in [
      for (final preset in catalog.presets)
        for (final rule in preset.rules)
          for (final candidate in rule.candidates) ...candidate.parts,
      for (final draft in catalog.drafts)
        for (final rule in draft.rules)
          for (final candidate in rule.candidates) ...candidate.parts,
      for (final pattern in catalog.patterns)
        for (final cell in pattern.cells) ...cell.parts,
    ])
      if (part.spatialClip != null && part.source is SmartTileModel3dSource)
        (part.source as SmartTileModel3dSource).modelId,
  };

  static Set<String> modelIds(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) => {
    ...catalogModelIds(project.smartTileCatalog),
    for (final map in maps)
      for (final instance in map.spatialScene?.instances ?? const [])
        if (instance.clip != null) instance.modelId,
  };

  static bool requiresCapability(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) => modelIds(project, maps: maps).isNotEmpty;

  static void validateSources(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) {
    final models = {for (final model in project.models3d) model.id: model};
    for (final id in modelIds(project, maps: maps)) {
      final model = models[id];
      if (model == null) {
        throw ValidationException(
          'A clipped source references a missing model.',
          code: 'model3d.clip_model_missing',
          details: {'modelId': id},
        );
      }
      if (model.inspection.animations.isNotEmpty) {
        throw ValidationException(
          'Clipped model sources require a static GLB without node or material animations.',
          code: 'model3d.clip_animated_source',
          details: {'modelId': id},
        );
      }
      if (model.rampProfile != null) {
        throw ValidationException(
          'A clipped model source cannot carry an attached ramp profile.',
          code: 'model3d.clip_ramp_source',
          details: {'modelId': id},
        );
      }
    }
  }
}
