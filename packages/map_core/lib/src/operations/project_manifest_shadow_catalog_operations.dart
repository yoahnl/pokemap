import '../models/project_manifest.dart';
import '../models/shadow_catalog.dart';

/// Returns the current project shadow profile catalog without copying it.
ProjectShadowCatalog shadowCatalogForProject(ProjectManifest manifest) {
  return manifest.shadowCatalog;
}

/// True when the project owns at least one shadow profile.
bool projectHasShadowProfiles(ProjectManifest manifest) {
  return manifest.shadowCatalog.isNotEmpty;
}

/// Returns a new manifest with only [shadowCatalog] replaced.
ProjectManifest replaceProjectShadowCatalog(
  ProjectManifest manifest,
  ProjectShadowCatalog shadowCatalog,
) {
  return manifest.copyWith(shadowCatalog: shadowCatalog);
}

/// Applies [update] once to the current shadow catalog and stores the result.
ProjectManifest updateProjectShadowCatalog(
  ProjectManifest manifest,
  ProjectShadowCatalog Function(ProjectShadowCatalog current) update,
) {
  return manifest.copyWith(shadowCatalog: update(manifest.shadowCatalog));
}

/// Replaces the project shadow catalog with an empty catalog.
ProjectManifest clearProjectShadowCatalog(ProjectManifest manifest) {
  return manifest.copyWith(shadowCatalog: const ProjectShadowCatalog.empty());
}
