import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';

final class ProjectSurfState {
  const ProjectSurfState({required this.configuration, required this.revision});
  final ProjectSurfSettings? configuration;
  final String revision;
}

final class ProjectSurfReferences {
  const ProjectSurfReferences({this.facts = const {}, this.badges = const {}});
  final Map<String, String> facts;
  final Map<String, String> badges;
}

abstract interface class ProjectSurfPort {
  Future<ProjectSurfState> loadSurf(ProjectSession session);
  Future<ProjectSurfState> saveSurf(
    ProjectSession session,
    ProjectSurfSettings? configuration,
    String expectedRevision,
  );
  Future<ProjectSurfReferences> loadSurfReferences(ProjectSession session);
  Future<NarrativeFactDefinition> loadSurfFact(
    ProjectSession session,
    String id,
  );
}
