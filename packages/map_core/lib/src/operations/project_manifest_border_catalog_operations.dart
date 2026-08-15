import '../models/border_catalog.dart';
import '../models/project_manifest.dart';

/// Returns the current project-owned Border catalog without copying it.
ProjectBorderCatalog borderCatalogForProject(ProjectManifest manifest) {
  return manifest.borderCatalog;
}

/// Replaces only the Border catalog on the canonical project version.
ProjectManifest replaceProjectBorderCatalog(
  ProjectManifest manifest,
  ProjectBorderCatalog borderCatalog,
) {
  return manifest.copyWith(
    borderCatalog: borderCatalog,
  );
}

/// Applies [update] once and stores its result through the versioned replace
/// boundary.
ProjectManifest updateProjectBorderCatalog(
  ProjectManifest manifest,
  ProjectBorderCatalog Function(ProjectBorderCatalog current) update,
) {
  final updatedCatalog = update(manifest.borderCatalog);
  return replaceProjectBorderCatalog(manifest, updatedCatalog);
}
