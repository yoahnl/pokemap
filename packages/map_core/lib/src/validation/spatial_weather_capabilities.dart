import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';

abstract final class SpatialWeatherCapabilities {
  static const capabilityId = 'map3d.weather@1';

  static bool requiresProject(ProjectManifest project) =>
      project.worldRules.any(
        (rule) => rule.effect.visualSettings?.requiresWeather == true,
      ) ||
      project.scenes.any(
        (scene) => scene.graph.nodes.any((node) {
          final payload = node.payload;
          if (payload is! SceneActionPayload) return false;
          final command = payload.interactiveCommand;
          return command is SceneWorldPresentationInteractiveCommand &&
              command.visualSettings?.requiresWeather == true;
        }),
      ) ||
      project.cinematics.any(
        (cinematic) => cinematic.timeline.steps.any(
          (step) => step.visualSettings?.requiresWeather == true,
        ),
      );
}
