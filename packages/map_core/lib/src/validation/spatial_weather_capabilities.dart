import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';
import '../models/spatial_visual_profile.dart';

abstract final class SpatialWeatherCapabilities {
  static const capabilityId = 'map3d.weather@1';
  static const extendedCapabilityId = 'map3d.weather-states@1';
  static const soundCapabilityId = 'map3d.weather-audio@1';

  static bool requiresProject(ProjectManifest project) =>
      _requiresProject(project, sound: false);
  static bool requiresSoundProject(ProjectManifest project) =>
      _requiresProject(project, sound: true);

  static bool requiresExtendedProject(ProjectManifest project) =>
      _requiresProject(project, sound: false, extended: true);

  static bool _requiresProject(ProjectManifest project, {required bool sound, bool extended = false}) {
    bool requires(SpatialVisualPatch? patch) => extended ? patch?.requiresExtendedWeather == true : sound
        ? patch?.requiresWeatherSound == true
        : patch?.requiresWeather == true;
    return project.worldRules.any(
          (rule) => requires(rule.effect.visualSettings),
        ) ||
        project.scenes.any(
          (scene) => scene.graph.nodes.any((node) {
            final payload = node.payload;
            if (payload is! SceneActionPayload) return false;
            final command = payload.interactiveCommand;
            return command is SceneWorldPresentationInteractiveCommand &&
                requires(command.visualSettings);
          }),
        ) ||
        project.cinematics.any(
          (cinematic) => cinematic.timeline.steps.any(
            (step) => requires(step.visualSettings),
          ),
        );
  }
}
