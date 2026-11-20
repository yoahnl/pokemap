part of 'authoring_mutation_adapter.dart';

extension EditorMapLifecycleMutations on AuthoringMutationAdapter {
  Future<EditorAuthoringMutationProjection> applyMapLifecycle(
    String projectRootPath,
    ProjectManifest expectedProject, {
    required String actionId,
    required Map<String, Object?> parameters,
    String? sourceMapId,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(() async {
        final before = await session.snapshot();
        if (before.manifest != expectedProject) {
          throw const EditorConflictException(
            'Le projet a changé depuis son chargement. Rechargez-le avant '
            'de modifier ses cartes.',
          );
        }
        if (actionId == 'map.rename' &&
            before.maps.length != before.manifest.maps.length) {
          throw const EditorAuthoringMutationFailure(
            code: 'map.inventory_incomplete',
            message: 'Certaines cartes du projet sont illisibles.',
          );
        }
        final source = sourceMapId == null ? null : before.mapById(sourceMapId);
        if (source != null) requireWritableMapVisualStackForLifecycle(source);
        final operationId = _identity('editor_map_lifecycle');
        final plan = await _planInSession(
          session,
          actionId: actionId,
          parameters: parameters,
          idempotencyKey: operationId,
          expectedRevision: before.revision,
        );
        final confirmation = actionId == 'map.delete_apply'
            ? await session.mutations.confirmMutation(
                session.projectHandle,
                planId: plan.planId,
              )
            : null;
        final applied = await _applyInSession(
          session,
          plan,
          operationId: operationId,
          confirmationToken: confirmation?.confirmationToken,
        );
        return applied.projection ??
            (throw const EditorConflictException(
              'La modification a été enregistrée. Rechargez le projet pour '
              'synchroniser la liste des cartes.',
            ));
      });
    } on EditorConflictException {
      rethrow;
    } on EditorInvalidOperationException {
      rethrow;
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      if (_isConflictCode(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      throw failure;
    }
  }
}
