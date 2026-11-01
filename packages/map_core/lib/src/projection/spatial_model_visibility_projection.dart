import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/narrative_map_view.dart';
import '../models/project_manifest.dart';
import '../operations/periodic_reward_condition_evaluator.dart';
import '../operations/presentation_condition_context.dart';

final class SpatialModelVisibilityProjection {
  SpatialModelVisibilityProjection({
    required ProjectManifest project,
    required MapData map,
    List<NarrativeMapView> maps = const [],
    PeriodicRewardSceneLookup? lookupRewardScenes,
    PresentationMapLookup? lookupMaps,
  }) : _instances = {
         for (final instance
             in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
           instance.id: instance,
       },
       _conditions = PresentationConditionContext(
         project: project,
         map: map,
         maps: maps,
         lookupRewardScenes: lookupRewardScenes,
         lookupMaps: lookupMaps,
       );

  final Map<String, SpatialModelInstance> _instances;
  final PresentationConditionContext _conditions;

  bool isPresent(GameState gameState, String instanceId) {
    final instance = _instances[instanceId];
    if (instance == null) return false;
    final condition = instance.visibilityCondition;
    return condition == null ||
        _conditions.evaluate(condition, gameState).passed;
  }
}
