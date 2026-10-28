import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';

abstract final class SpatialLightWorkshopCapabilities {
  static const capabilityId = 'map3d.light-workshop@1';
  static const flameCapabilityId = 'map3d.light-flame@1';
  static const crackleCapabilityId = 'map3d.light-crackle@1';
  static bool requiresCrackle(ProjectManifest project) => project.models3d.any(
    (model) => (model.light?.flame?.crackleVolume ?? 0) > 0,
  );
  static bool requiresFlames(ProjectManifest project) =>
      project.models3d.any((model) => model.light?.flame != null);
  static bool requiresProject(ProjectManifest project) =>
      project.models3d.any(
        (model) =>
            model.light?.colorCycle != null || model.light?.proximity != null,
      ) ||
      project.worldRules.any(
        (rule) => rule.effect.visualSettings?.requiresLightWorkshop == true,
      ) ||
      project.scenes.any(
        (scene) => scene.graph.nodes.any((node) {
          final payload = node.payload;
          if (payload is! SceneActionPayload) return false;
          final command = payload.interactiveCommand;
          return command is SceneWorldPresentationInteractiveCommand &&
              command.visualSettings?.requiresLightWorkshop == true;
        }),
      ) ||
      project.cinematics.any(
        (cinematic) => cinematic.timeline.steps.any(
          (step) => step.visualSettings?.requiresLightWorkshop == true,
        ),
      );
}
