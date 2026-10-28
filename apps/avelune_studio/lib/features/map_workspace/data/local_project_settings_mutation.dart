part of 'local_map_workspace_adapter.dart';

extension _LocalProjectSettingsMutation on LocalMapWorkspaceAdapter {
  Future<({ProjectSettings settings, String revision})>
  _configureProjectSettings(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters,
    String expectedRevision,
    ProjectSettings Function(ProjectSettings current, ProjectSettings projected)
    projectSettings,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Créez une copie de travail pour enregistrer ces réglages.',
      );
    }
    return _withSurfAuthoring(session, (opener, opened, api, _) async {
      final before = _project(session);
      if (before.revision != expectedRevision ||
          await resourceRevision(session) != expectedRevision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet a changé. Vos réglages restent en brouillon.',
        );
      }
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: actionId,
        parameters: parameters,
      );
      final id =
          'studio_settings_${DateTime.now().microsecondsSinceEpoch}_${_settingsOperations++}';
      final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
        ),
      );
      await api.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: id,
        precondition: () async {
          if (await resourceRevision(session) != expectedRevision) {
            throw const MapWorkspaceFailure(
              MapWorkspaceProblem.conflict,
              'Le projet a changé pendant l’enregistrement.',
            );
          }
        },
      );
      final revision = await resourceRevision(session);
      final projected = plan.projectedProject!.settings;
      ProjectManifest update(ProjectManifest value) =>
          value.copyWith(settings: projectSettings(value.settings, projected));
      final current = _project(session);
      final next = update(current.manifest);
      _projects[session.sessionId] = _ProjectDocument(
        current.root,
        next,
        revision,
        complete: current.complete,
        metadataFields: current.metadataFields,
      );
      for (final cache in [
        _resourceSelections,
        _activeMapDefinitions,
        _workshopCharacterDefinitions,
      ]) {
        if (cache[session.sessionId] case final value?) {
          cache[session.sessionId] = update(value);
        }
      }
      return (settings: next.settings, revision: revision);
    });
  }
}
