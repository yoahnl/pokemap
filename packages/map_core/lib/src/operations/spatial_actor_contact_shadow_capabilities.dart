import '../models/project_manifest.dart';
import '../models/map_spatial_scene.dart';

abstract final class SpatialActorContactShadowCapabilities {
  static const capabilityId = 'map3d.actor-contact-shadows@1';

  static bool requiresCapability(ProjectManifest project) =>
      project.settings.dimension == ProjectDimension.threeD &&
      project.characters.any(
        (character) =>
            character.contactShadow ??
            project.settings.actorContactShadowsByDefault,
      );
}
