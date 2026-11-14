part of 'local_resource_adapter.dart';

final _resourceMutationActions = {
  'project.actor_contact_shadows.configure',
  'model3d.import',
  'model3d.source.replace',
  'model3d.source.replace_batch',
  'model3d.configure',
  'model3d.delete',
  'asset.move',
  'asset.delete',
  'asset.replace',
  'element.delete',
  'element.duplicate',
  'tileset.source.replace',
  'tileset.remove',
  ...ResourceManagementActions.actionIds,
  'tileset.import_image',
  'element.upsert',
  'environment.preset.upsert',
  'environment.preset.delete',
  'smart_tile.preset.draft.upsert',
  'smart_tile.preset.publish',
  'smart_tile.preset.rename',
  'smart_tile.preset.duplicate',
  'smart_tile.preset.delete',
  'smart_tile.preset.draft.delete',
  'border.blueprint.draft.upsert',
  'border.blueprint.publish',
  'border.blueprint.delete',
  'border.blueprint.set_deprecated',
  'map.library.reorganize',
  'characterStudio.character.create',
  'characterStudio.character.update',
  'characterStudio.character.deletePlan',
  'characterStudio.character.delete',
  'characterStudio.animationClip.upsert',
  'characterStudio.animationClip.delete',
  'characterStudio.portraitState.create',
  'characterStudio.character.portrait.clear',
  'characterStudio.asset.import',
};

extension _LocalResourceMutationSteps on LocalResourceAdapter {
  Future<List<Object?>> _stagedBorderSources(
    LocalMapAuthoringMutationApi api,
    LocalArtifactStore artifacts,
    List<BorderResourcePrimitive> borderSources,
    Set<String> stagedHandles,
  ) async {
    final handlesByPath = <String, String>{};
    return <Object?>[
      for (final source in borderSources)
        if (!source.draft.isSpatial)
          <String, Object?>{
            'primitiveId': source.draft.id,
            'frames': <Object?>[
              for (final frame in source.frames)
                <String, Object?>{
                  'artifactHandle': await _stageBorderFrame(
                    api,
                    artifacts,
                    frame,
                    handlesByPath,
                    stagedHandles,
                  ),
                  'sourceProjectRelativePath': frame.relativePath,
                  'sourceRectPx': <String, int>{
                    'x': frame.rect.x,
                    'y': frame.rect.y,
                    'width': frame.rect.width,
                    'height': frame.rect.height,
                  },
                  if (frame.durationMs != null) 'durationMs': frame.durationMs,
                  if (frame.transparentColorArgb != null)
                    'transparentColorArgb': frame.transparentColorArgb,
                },
            ],
          },
    ];
  }

  Future<void> _applyPlanned({
    required LocalMapAuthoringMutationApi api,
    required OpenedProject opened,
    required AuthoringMutationPlanResult planned,
    required String operationId,
    required bool confirmDestructive,
    required String? Function()? validateBeforeApply,
  }) async {
    try {
      final confirmation = confirmDestructive
          ? await api.confirmMutation(
              opened.projectHandle,
              planId: planned.planId,
            )
          : null;
      await api.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: operationId,
        confirmationToken: confirmation?.confirmationToken,
        precondition: () async {
          await beforeTransactionPrecondition?.call();
          _requireAvailable();
          final problem = validateBeforeApply?.call();
          if (problem != null) throw ResourceFailure(problem);
        },
      );
    } on Object catch (failure, stack) {
      late final AuthoringMutationResult recovered;
      try {
        recovered = await api.recoverMutation(
          opened.projectHandle,
          operationId: operationId,
        );
      } on Object {
        Error.throwWithStackTrace(failure, stack);
      }
      if (recovered.receipt.status.name != 'applied' &&
          recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
        Error.throwWithStackTrace(failure, stack);
      }
    }
  }

  Future<void> _rereadApplied({
    required LocalMapAuthoringMutationApi api,
    required ProjectSnapshotLoader snapshots,
    required OpenedProject opened,
    required ProjectSnapshot snapshot,
    required AuthoringMutationPlanResult planned,
    required ResourceMutationReceipt receipt,
    required String actionId,
    required Map<String, Object?> fields,
    required bool scopedModelMutation,
    required void Function(String name) phase,
  }) async {
    try {
      phase('apply.end');
      await beforeReconciliation?.call();
      _requireAvailable();
      if (snapshot.materializedCatalogProject || scopedModelMutation) {
        final after = scopedModelMutation
            ? await api.readWorkshopSnapshot(
                opened.projectHandle,
                actionId: actionId,
                parameters: fields,
              )
            : await snapshots.load(
                opened.projectHandle,
                policy: ProjectSnapshotLoadPolicy.editorReadProjection,
              );
        if ((scopedModelMutation
                    ? _modelSourceDocumentRevision(after)
                    : studioProjectSnapshotRevision(after)) !=
                receipt.revision ||
            (scopedModelMutation
                ? !_modelSourcesMatch(
                    after.manifest,
                    planned.projectedProject ?? snapshot.manifest,
                  )
                : after.manifest != receipt.manifest)) {
          throw const ResourceFailure(
            'La publication a changé avant sa relecture. Relisez sans la rejouer.',
          );
        }
      }
      await mapAdapter.acceptResourceMutation(
        session,
        receipt,
        allowMapOrganization: actionId == 'map.library.reorganize',
      );
    } on Object catch (failure) {
      throw ResourceFailure(
        'La publication a réussi, mais la relecture a échoué. Ne relancez pas la mutation. $failure',
        partialReceipt: receipt,
      );
    }
  }
}
