import 'dart:io';
import 'dart:isolate';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

Future<RuntimePlayerOptionsAvailability> resolveHubGameOptionsAvailability({
  required String projectFilePath,
  required Set<String> capabilities,
}) => Isolate.run(() async {
  final catalog = await RuntimeProjectCatalog.open(
    projectFilePath,
    maximumCachedMaps: 0,
    maximumCachedMapBytes: 0,
  );
  try {
    return await hubGameOptionsAvailability(
      project: catalog.projectMetadata,
      capabilities: capabilities,
      loadMap: catalog.loadMapData,
      loadVisualProfile: (mapId) => loadSpatialVisualProfile(
        projectRoot: File(projectFilePath).parent.path,
        mapId: mapId,
      ),
    );
  } finally {
    catalog.dispose();
  }
});

Future<RuntimePlayerOptionsAvailability> hubGameOptionsAvailability({
  required ProjectManifest project,
  required Set<String> capabilities,
  required Future<MapData> Function(String) loadMap,
  required Future<SpatialVisualPatch> Function(String?) loadVisualProfile,
}) async {
  final spatial = project.settings.dimension == ProjectDimension.threeD;
  var weather =
      spatial &&
      (capabilities.contains(
            WorldEnvironmentCapabilities.realWeatherCapabilityId,
          ) ||
          WorldEnvironmentCapabilities.requiresRealProject(project));
  var worldTime =
      capabilities.contains(
        SpatialSceneLightingCapabilities.dayNightCapabilityId,
      ) ||
      project.encounterTables.any(
        (table) =>
            table.variants.any((variant) => variant.timeWindows.isNotEmpty),
      ) ||
      project.worldRules.any(
        (rule) => _usesClock(rule.effect.visualSettings),
      ) ||
      project.cinematics.any(
        (cinematic) => cinematic.timeline.steps.any(
          (step) => _usesClock(step.visualSettings),
        ),
      ) ||
      project.scenes.any(
        (scene) => scene.graph.nodes.any((node) {
          final payload = node.payload;
          if (payload is! SceneActionPayload) return false;
          final command = payload.interactiveCommand;
          return command is SceneWorldPresentationInteractiveCommand &&
              _usesClock(command.visualSettings);
        }),
      );
  try {
    if (spatial && (!weather || !worldTime)) {
      final profile = await loadVisualProfile(null);
      weather = weather || profile.requiresRealWeather;
      worldTime = worldTime || _usesClock(profile);
    }
    for (final entry in project.maps) {
      if (worldTime && (!spatial || weather)) break;
      if (!worldTime) {
        final map = await loadMap(entry.id);
        worldTime =
            map.spatialScene?.dayNightCycle != null ||
            map.entities.any((entity) {
              final npc = entity.npc;
              if (npc == null) return false;
              return _timePredicate(npc.trainerBattleWhen) ||
                  _timePredicate(npc.trainerBattleReadyWhen) ||
                  _timePredicate(npc.visibilityRule?.predicate) ||
                  npc.conditionalDialogues.any(
                    (dialogue) => _timePredicate(dialogue.when),
                  );
            });
      }
      if (spatial && (!weather || !worldTime)) {
        final profile = await loadVisualProfile(entry.id);
        weather = weather || profile.requiresRealWeather;
        worldTime = worldTime || _usesClock(profile);
      }
    }
  } on Object {
    return RuntimePlayerOptionsAvailability(
      graphics3d: spatial,
      weather: spatial,
      worldTime: true,
    );
  }
  return RuntimePlayerOptionsAvailability(
    graphics3d: spatial,
    weather: weather,
    worldTime: worldTime,
  );
}

bool _usesClock(SpatialVisualPatch? patch) =>
    patch?.values.keys.any((parameter) => parameter.isClock) ?? false;

bool _timePredicate(MapEntityRuntimePredicate? predicate) =>
    predicate?.kind == MapEntityRuntimePredicateKind.localTimeWindow;
