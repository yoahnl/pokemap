part of 'local_resource_adapter.dart';

extension _LocalResourceDefinitionPublication on LocalResourceAdapter {
  Future<ResourceMutationReceipt> _publishLibraryDefinition(
    String action,
    Map<String, Object?> parameters,
    String expectedRevision, {
    String? Function()? validateBeforeApply,
    String? terrainId,
    String? environmentId,
    String? decorId,
  }) => mapAdapter.withResourceMutation(() async {
    _requireLibraryEditing();
    _resourceMutationActive = true;
    try {
      final problem = validateBeforeApply?.call();
      if (problem != null) throw ResourceFailure(problem);
      final before = await mapAdapter.resourceBaseline(session);
      if (before.revision != expectedRevision) {
        throw const ResourceFailure(
          'Le catalogue a changé. Actualisez la bibliothèque puis réessayez.',
        );
      }
      final context = await _requireMutationContext();
      await context.attach();
      final opened = context.opened;
      final scoped =
          terrainId != null || environmentId != null || decorId != null;
      final copyingBorder =
          action == 'catalog.definition.duplicate' &&
          parameters['resourceKind'] == 'borderBlueprint';
      final catalog = await context.openService.catalogProject(
        opened.projectHandle,
        metadataFields: scoped || copyingBorder ? const {} : null,
      );
      final revision = catalog?.revision;
      if (revision == null ||
          await mapAdapter.resourceRevision(session) != before.revision) {
        throw const ResourceFailure(
          'Le catalogue a changé. Actualisez la bibliothèque puis réessayez.',
        );
      }
      final operationId = _identity('resource');
      final planned = await context.api
          .planMutation(
            opened.projectHandle,
            AuthoringRequest(
              requestId: operationId,
              workspaceHandle: opened.workspaceHandle.value,
              actionId: action,
              actionVersion: 1,
              idempotencyKey: operationId,
              expectedRevision: revision,
              parameters: parameters,
              extensions: scoped ? const {'workshopScope': true} : const {},
            ),
          )
          .onError<MapAuthoringException>((error, stackTrace) async {
            if (error.code == 'catalog.definition.border_copy_unsupported') {
              throw const ResourceFailure(
                'Seules les lignes connectées 3D sans dépendances déclarées peuvent être dupliquées.',
              );
            }
            if (action != 'tileset.regrid' ||
                error.code != 'catalog.definition_in_use') {
              Error.throwWithStackTrace(error, stackTrace);
            }
            final maps = before.manifest.maps;
            final message = await catalog!
                .read(
                  (project) => _namedLibraryUseMessage(
                    project.snapshot,
                    error.details,
                    maps,
                    subject: 'Cette planche',
                  ),
                )
                .onError<Object>(
                  (_, _) => _libraryUseMessage(error.details, maps),
                );
            throw ResourceFailure(message);
          });
      try {
        final plan = planned.plan;
        if (plan.changeSet.changes.isEmpty) {
          return ResourceMutationReceipt(
            before: before.manifest,
            manifest: before.manifest,
            beforeRevision: before.revision,
            revision: before.revision,
            changedPaths: const [],
          );
        }
        final terrain = terrainId == null
            ? null
            : planned.projectedProject!.smartTileCatalog.presets.singleWhere(
                (value) => value.id == terrainId,
              );
        final environment = environmentId == null
            ? null
            : planned.projectedProject!.environmentPresets.singleWhere(
                (value) => value.id == environmentId,
              );
        final decor = decorId == null
            ? null
            : planned.projectedProject!.elements.singleWhere(
                (value) => value.id == decorId,
              );
        final edited = _resourceReceipt(
          before.manifest,
          before.revision,
          plan,
          null,
          operationId,
          projectedProject: switch ((terrain, environment, decor)) {
            (final terrain?, _, _) => replaceLoadedTerrainProjection(
              before.manifest,
              terrain,
            ),
            (_, final environment?, _) => upsertProjectEnvironmentPreset(
              before.manifest,
              environment,
            ),
            (_, _, final decor?) => upsertDecorProjection(
              before.manifest,
              decor,
            ),
            _ => before.manifest,
          },
          projectedRevision: await _projectedLibraryRevision(plan),
          changedTerrain: terrain,
          changedElement: decor,
        );
        await _applyPlanned(
          api: context.api,
          opened: opened,
          planned: planned,
          operationId: operationId,
          confirmDestructive: false,
          validateBeforeApply: validateBeforeApply,
        );
        try {
          await beforeReconciliation?.call();
          _requireAvailable();
          if (terrain != null) {
            await _verifyWorkshopTerrain(this, terrain, edited.revision);
          }
          if (environment != null) {
            await _verifyWorkshopEnvironment(
              this,
              environment,
              edited.revision,
            );
          }
          if (decor != null) {
            await _verifyWorkshopDecor(this, decor, edited.revision);
          }
          await mapAdapter.acceptResourceMutation(
            session,
            edited,
            changedTerrain: terrain,
            changedEnvironment: environment,
          );
        } on Object {
          throw ResourceFailure(
            terrain == null
                ? 'La modification est enregistrée. Actualisez la bibliothèque pour relire la fiche.'
                : 'Les raccords sont enregistrés. Relisez la publication pour les afficher.',
            partialReceipt: edited,
          );
        }
        return edited;
      } finally {
        await planned.plan.releaseAppliedPayload();
      }
    } on ResourceFailure {
      rethrow;
    } on Object catch (error) {
      throw terrainId == null
          ? _libraryLifecycleFailure(error)
          : _terrainWorkshopMutationFailure(error);
    } finally {
      _resourceMutationActive = false;
      if (_disposed) await _closeMutationContext();
    }
  });
}
