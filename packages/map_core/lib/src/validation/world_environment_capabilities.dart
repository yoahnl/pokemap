import '../models/project_manifest.dart';
import '../models/spatial_visual_profile.dart';
import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';

abstract final class WorldEnvironmentCapabilities {
  static const capabilityId = 'map3d.world-environment@1';

  static const weatherEpisodesCapabilityId = 'map3d.weather-episodes@1';
  static bool requiresEpisodesProject(ProjectManifest project) =>
      _requiresProject(project, (patch) => patch.requiresWeatherEpisodes);
  static const realWeatherCapabilityId = 'map3d.real-weather@1';
  static bool requiresProject(ProjectManifest project) =>
      _requiresProject(project, (patch) => patch.requiresWorldEnvironment);
  static bool requiresRealProject(ProjectManifest project) =>
      _requiresProject(project, (patch) => patch.requiresRealWeather);
  static bool _requiresProject(
    ProjectManifest project,
    bool Function(SpatialVisualPatch) requires,
  ) =>
      project.worldRules.any(
        (rule) =>
            rule.effect.visualSettings != null &&
            requires(rule.effect.visualSettings!),
      ) ||
      project.scenes.any(
        (scene) => scene.graph.nodes.any((node) {
          final payload = node.payload;
          if (payload is! SceneActionPayload) return false;
          final command = payload.interactiveCommand;
          return command is SceneWorldPresentationInteractiveCommand &&
              command.visualSettings != null &&
              requires(command.visualSettings!);
        }),
      ) ||
      project.cinematics.any(
        (cinematic) => cinematic.timeline.steps.any(
          (step) =>
              step.visualSettings != null && requires(step.visualSettings!),
        ),
      );
}
