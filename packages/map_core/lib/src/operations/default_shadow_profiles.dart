import '../models/project_manifest.dart';
import '../models/shadow.dart';
import '../models/shadow_catalog.dart';

List<ProjectShadowProfile> createDefaultGroundStaticShadowProfiles() {
  return [
    ProjectShadowProfile(
      id: 'default-ground-soft-ellipse',
      name: 'Ombre douce au sol',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      opacity: 0.35,
    ),
    ProjectShadowProfile(
      id: 'default-ground-wide-ellipse',
      name: 'Ombre large au sol',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      scaleX: 1.35,
      scaleY: 0.85,
      opacity: 0.28,
    ),
    ProjectShadowProfile(
      id: 'default-ground-contact-blob',
      name: 'Ombre compacte au sol',
      mode: ShadowCasterMode.contactBlob,
      renderPass: ShadowRenderPass.groundStatic,
      opacity: 0.35,
    ),
  ];
}

bool isGroundStaticElementShadowProfile(ProjectShadowProfile profile) {
  return profile.renderPass == ShadowRenderPass.groundStatic &&
      profile.mode != ShadowCasterMode.none;
}

bool hasGroundStaticElementShadowProfiles(ProjectShadowCatalog catalog) {
  return catalog.profiles.any(isGroundStaticElementShadowProfile);
}

ProjectShadowCatalog ensureDefaultGroundStaticShadowProfiles(
  ProjectShadowCatalog catalog,
) {
  if (hasGroundStaticElementShadowProfiles(catalog)) {
    return catalog;
  }
  final existingIds = catalog.profiles.map((profile) => profile.id).toSet();
  final defaultsToAdd = createDefaultGroundStaticShadowProfiles().where(
    (profile) => !existingIds.contains(profile.id),
  );
  return ProjectShadowCatalog(
    profiles: [
      ...catalog.profiles,
      ...defaultsToAdd,
    ],
  );
}

ProjectManifest ensureDefaultGroundStaticShadowProfilesForProject(
  ProjectManifest manifest,
) {
  final nextCatalog = ensureDefaultGroundStaticShadowProfiles(
    manifest.shadowCatalog,
  );
  if (nextCatalog == manifest.shadowCatalog) {
    return manifest;
  }
  return manifest.copyWith(shadowCatalog: nextCatalog);
}
