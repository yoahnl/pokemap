part of 'local_resource_adapter.dart';

mixin _LocalProjectLibraryOrganization implements ProjectLibraryOrganization {
  LocalResourceAdapter get _libraryOrganizationAdapter;

  @override
  Future<ProjectLibraryBatchEdit> classifyLibraryResources(
    Iterable<ProjectLibraryItem> items, {
    required ({String? id})? family,
    required ResourceLibraryRole? role,
    required String expectedRevision,
  }) async {
    final selection = List<ProjectLibraryItem>.unmodifiable(items);
    const maximum = ResourceLibraryActions.maximumClassificationsPerBatch;
    if (selection.isEmpty || selection.length > maximum) {
      throw const ResourceFailure(
        'Sélectionnez entre 1 et $maximum ressources pour un classement groupé.',
      );
    }
    if (family == null && role == null) {
      throw const ResourceFailure('Choisissez une modification à appliquer.');
    }
    final receipt = await _publishLibraryOrganization(
      'resource.classify_batch',
      {
        'entries': [
          for (final item in selection)
            {
              'resourceKind': item.kind,
              'resourceId': item.id,
              if (family != null) 'familyId': family.id,
              if (role != null) 'role': role.name,
            },
        ],
      },
      expectedRevision,
    );
    if (receipt.noChange) return (items: selection, receipt: receipt);
    final adapter = _libraryOrganizationAdapter;
    try {
      final updated = await adapter.mapAdapter.readResourceLibraryItems(
        adapter.session,
        selection.map((item) => (kind: item.kind, id: item.id)),
        expectedRevision: receipt.revision,
      );
      return (items: updated, receipt: receipt);
    } on Object {
      throw ResourceFailure(
        'Le classement est enregistré. Actualisez la bibliothèque pour relire les fiches.',
        partialReceipt: receipt,
      );
    }
  }

  @override
  Future<ProjectLibraryFamilyEdit> saveLibraryFamily({
    required ResourceFamily? existing,
    required String name,
    required String? parentId,
    required String expectedRevision,
  }) async {
    final id = existing?.id ?? _libraryOrganizationAdapter._identity('family');
    final receipt = await _publishLibraryOrganization(
      existing == null ? 'resource.family.create' : 'resource.family.update',
      {'familyId': id, 'name': _libraryName(name), 'parentId': parentId},
      expectedRevision,
    );
    final saved = receipt.manifest.resourceLibraryCatalog.families
        .where((family) => family.id == id)
        .firstOrNull;
    if (saved == null && !receipt.noChange) {
      throw ResourceFailure(
        'La famille est enregistrée. Actualisez la bibliothèque pour la relire.',
        partialReceipt: receipt,
      );
    }
    return (id: id, family: saved ?? existing, receipt: receipt);
  }

  @override
  Future<ProjectLibraryFamilyEdit> deleteLibraryFamily(
    ResourceFamily family, {
    required String expectedRevision,
  }) async => (
    id: family.id,
    family: null,
    receipt: await _publishLibraryOrganization('resource.family.delete', {
      'familyId': family.id,
    }, expectedRevision),
  );

  Future<ResourceMutationReceipt> _publishLibraryOrganization(
    String action,
    Map<String, Object?> parameters,
    String expectedRevision,
  ) async {
    final adapter = _libraryOrganizationAdapter;
    adapter._requireLibraryEditing();
    final preparation = await _prepareCatalogClassification(
      adapter,
      action,
      parameters,
      expectedRevision,
    );
    return await _applyScopedClassification(
          adapter,
          preparation,
          explicitIndexPreparation: true,
        ) ??
        (throw const ProjectLibraryNeedsPreparation());
  }
}
