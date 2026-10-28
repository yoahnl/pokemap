import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';

final class ProjectCsState {
  const ProjectCsState({required this.configuration, required this.revision});
  final ProjectFieldAbilitiesSettings? configuration;
  final String revision;
}

abstract interface class ProjectCsPort {
  Future<ProjectCsState> loadFieldAbilities(ProjectSession session);
  Future<ProjectCsState> saveFieldAbility(
    ProjectSession session,
    FieldAbility ability,
    bool enabled,
    String expectedRevision,
  );
  Future<ProjectCsState> saveFieldAbilityId(
    ProjectSession session,
    String abilityId,
    bool enabled,
    String expectedRevision,
  );
}
