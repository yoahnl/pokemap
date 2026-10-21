import 'package:map_core/map_core.dart';

import 'runtime_project_catalog.dart';

ProjectManifest runtimeRetainedWorldValidationProject({
  required ProjectManifest activeProject,
  required Iterable<ProjectManifest> retainedProjects,
}) {
  final owner = RuntimeProjectCatalog.ownerOf(activeProject);
  if (owner == null) return activeProject;
  return owner.mergeNarrativeVisualDefinitions(activeProject, retainedProjects);
}
