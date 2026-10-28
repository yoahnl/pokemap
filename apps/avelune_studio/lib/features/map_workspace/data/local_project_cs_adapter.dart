part of 'local_map_workspace_adapter.dart';

extension _LocalProjectCsAdapter on LocalMapWorkspaceAdapter {
  Future<ProjectCsState> _loadFieldAbilities(ProjectSession session) =>
      LocalWorkshopReader(session, reader: _reader).read(
        metadataFields: {'settings'},
        operation: (project, _, revision) async => ProjectCsState(
          configuration: project.settings.fieldAbilities,
          revision: revision,
        ),
      );
  Future<ProjectCsState> _saveFieldAbilityId(
    ProjectSession session,
    String abilityId,
    bool enabled,
    String expectedRevision,
  ) async {
    final result = await _configureProjectSettings(
      session,
      'field_ability.configure',
      {'abilityId': abilityId, 'enabled': enabled},
      expectedRevision,
      (current, projected) =>
          current.copyWith(fieldAbilities: projected.fieldAbilities),
    );
    return ProjectCsState(
      configuration: result.settings.fieldAbilities,
      revision: result.revision,
    );
  }
}
