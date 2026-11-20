part of 'local_resource_adapter.dart';

const _libraryDeletionAction = 'catalog.definition.delete';

extension _LocalProjectLibraryLifecycle on LocalResourceAdapter {
  Future<ProjectLibraryEdit> _copyLibraryResource(
    ProjectLibraryItem item,
    String name,
    String expectedRevision,
  ) async {
    _requireLibraryEditing();
    final id = _identity('copy');
    final title = _libraryName(name);
    final ResourceMutationReceipt receipt;
    if (item.kind == 'model3d') {
      final selected = await mapAdapter.readResourcePreview(
        session,
        item.kind,
        item.id,
      );
      final source = selected.models3d.singleWhere(
        (model) => model.id == item.id,
      );
      receipt = await _run(
        'model3d.duplicate',
        (_) => {'modelId': id, 'sourceModelId': item.id, 'name': title},
        sourcePath: p.joinAll([
          session.directoryPath,
          ...source.relativePath.split('/'),
        ]),
        sourceMediaType: 'model/gltf-binary',
        expectedBeforeRevision: expectedRevision,
      );
    } else {
      receipt = await _publishLibraryDefinition(
        'catalog.definition.duplicate',
        {
          'resourceKind': item.kind,
          'id': item.id,
          'targetId': id,
          'name': title,
        },
        expectedRevision,
      );
    }
    return _readLibraryEdit(item.kind, id, receipt);
  }

  Future<ResourceMutationPreparation> _prepareLibraryDeletion(
    ProjectLibraryItem item,
    String expectedRevision,
  ) => mapAdapter.withResourceMutation(() async {
    _requireLibraryEditing();
    final before = await mapAdapter.resourceBaseline(session);
    if (before.revision != expectedRevision) {
      throw const ResourceFailure(
        'Le catalogue a changé. Actualisez la bibliothèque puis réessayez.',
      );
    }
    final context = await _LocalResourceMutationContext.create(session);
    try {
      await context.attach();
      final opened = context.opened;
      final catalog = await context.openService.catalogProject(
        opened.projectHandle,
      );
      if (catalog == null ||
          await mapAdapter.resourceRevision(session) != before.revision) {
        throw const ResourceFailure(
          'Le catalogue a changé depuis l’ouverture de la fiche.',
        );
      }
      final requestId = _identity('remove_resource');
      final parameters = {'resourceKind': item.kind, 'id': item.id};
      final planned = await context.api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: requestId,
          workspaceHandle: opened.workspaceHandle.value,
          actionId: _libraryDeletionAction,
          actionVersion: 1,
          idempotencyKey: requestId,
          expectedRevision: catalog.revision,
          parameters: parameters,
        ),
      );
      _requireAvailable();
      final preparation = ResourceMutationPreparation(
        sessionId: session.sessionId,
        actionId: _libraryDeletionAction,
        parameters: parameters,
        snapshotRevision: catalog.revision,
        manifestRevision: before.revision,
        changedPaths: planned.plan.changeSet.changes
            .map((change) => change.storageKey)
            .toList(),
        confirmationRequired: true,
        impact: {'usageCount': 0},
      );
      _prepared[preparation] = _ResourcePreparedContext(
        handles: context.handles,
        opened: opened,
        api: context.api,
        artifacts: context.artifacts,
        plan: planned.plan,
        manifest: before.manifest,
        projectedProject: withoutLibraryResource(before.manifest, (
          kind: item.kind,
          id: item.id,
        )),
        projectedRevision: await _projectedLibraryRevision(planned.plan),
      );
      return preparation;
    } on Object catch (error) {
      await context.close();
      throw _libraryLifecycleFailure(error, before.manifest.maps);
    }
  });
}

Object _libraryLifecycleFailure(
  Object error, [
  List<ProjectMapEntry> maps = const [],
]) => switch (error) {
  ResourceFailure() => error,
  CatalogStorageException(
    code: 'catalog.resource_usage.preparation_required',
  ) =>
    const ProjectLibraryNeedsPreparation(),
  FormatException(message: String message)
      when message.startsWith('catalog.resource_positions.') =>
    const ProjectLibraryNeedsPreparation(),
  MapAuthoringException(code: 'catalog.definition_in_use', :final details) =>
    ResourceFailure(_libraryUseMessage(details, maps)),
  MapAuthoringException(code: 'tileset.regrid_local_uses') =>
    const ResourceFailure(
      'La planche contient une palette, des tuiles configurées ou des réglages du monde liés à ce découpage.',
    ),
  MapAuthoringException(code: 'tileset.atlas_missing') => const ResourceFailure(
    'Cette planche n’a pas de grille régulière.',
  ),
  MapAuthoringException(code: 'tileset.grid_invalid') => const ResourceFailure(
    'La nouvelle grille doit tenir dans les dimensions de l’image.',
  ),
  MapAuthoringException(code: 'tileset.grid_unchanged') =>
    const ResourceFailure(
      'La largeur et la hauteur sont identiques au découpage enregistré.',
    ),
  MapAuthoringException(code: 'border.blueprint.delete_published_forbidden') =>
    const ResourceFailure(
      'Cette bordure est publiée. Elle peut être retirée des choix dans son atelier.',
    ),
  FormatException(message: String message)
      when message.startsWith('exterior.resource_in_use') =>
    const ResourceFailure(
      'Cette ressource est utilisée dans un décor extérieur.',
    ),
  FormatException(message: String message)
      when message.startsWith('exterior.reference_index_recovery_required') =>
    const ResourceFailure(
      'Les usages dans les décors extérieurs doivent être vérifiés avant le retrait.',
    ),
  _ => _resourceFailure(error),
};

String _libraryUseMessage(
  Map<String, Object?> details,
  List<ProjectMapEntry> maps,
) {
  final owners = (details['owners'] as List<Object?>? ?? const [])
      .whereType<String>();
  final mapIndex = ProjectMapEntries.prepare(maps);
  final names = [
    for (final owner in owners)
      if (owner.startsWith('map:'))
        if (mapIndex.lookup(owner.substring(4)) case final map?)
          '« ${map.name} »',
  ];
  if (names.isNotEmpty) {
    final listed = names.take(3).join(', ');
    return 'Cette ressource est utilisée sur ${names.length == 1 ? 'la carte' : 'les cartes'} $listed${names.length > 3 ? ' et ${names.length - 3} de plus' : ''}.';
  }
  return owners.isNotEmpty
      ? 'Cette ressource est encore utilisée dans le projet.'
      : 'Une autre ressource dépend encore de cette fiche.';
}

bool _draftUsesLibraryResource(
  ProjectLibraryItem item,
  Iterable<Map<String, Object?>> drafts,
) {
  final kinds = switch (item.kind) {
    'smartTilePreset' => const {'preset'},
    'environmentPreset' => const {'environmentPreset', 'preset'},
    'borderBlueprint' => const {'border'},
    final kind => {kind},
  };
  return drafts.any(
    (draft) => resourceReferences(draft).any(
      (reference) => reference.id == item.id && kinds.contains(reference.kind),
    ),
  );
}
