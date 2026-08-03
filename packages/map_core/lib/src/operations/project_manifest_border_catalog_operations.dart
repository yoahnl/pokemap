import '../models/border_catalog.dart';
import '../models/enums.dart';
import '../models/project_manifest.dart';

/// Returns the current project-owned Border catalog without copying it.
ProjectBorderCatalog borderCatalogForProject(ProjectManifest manifest) {
  return manifest.borderCatalog;
}

/// Replaces only the Border catalog and promotes the manifest when needed.
///
/// Persisting any non-empty Border catalog is a V2 feature. Newer manifest
/// versions keep their version: adding Border data must never downgrade a
/// Smart Tile project.
ProjectManifest replaceProjectBorderCatalog(
  ProjectManifest manifest,
  ProjectBorderCatalog borderCatalog,
) {
  return manifest.copyWith(
    version: borderCatalog.isNotEmpty && manifest.version == ProjectVersion.v1
        ? ProjectVersion.v2
        : manifest.version,
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
