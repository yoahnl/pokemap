part of 'local_resource_adapter.dart';

const _saveWorkshopBorderAction = 'border.blueprint.draft.upsert';
const _publishWorkshopBorderAction = 'border.blueprint.publish';

mixin _LocalProjectBorderWorkshop
    implements ProjectBorderWorkshopPort, ResourcePort {
  LocalResourceAdapter get _borderWorkshopAdapter;

  @override
  bool get canEditBorderWorkshop =>
      _borderWorkshopAdapter.session.storage ==
      ProjectSessionStorage.workingCatalog;

  @override
  Future<ResourceMutationReceipt> createBorder(BorderCreationRequest request) =>
      _createBorder(_borderWorkshopAdapter, request);

  @override
  Future<ProjectBorderWorkshopRead> readWorkshopBorder(String borderId) async {
    final adapter = _borderWorkshopAdapter;
    adapter._requireAvailable();
    final read = await adapter.mapAdapter.readResourcePreviewWithRevision(
      adapter.session,
      'borderBlueprint',
      borderId,
    );
    adapter._requireAvailable();
    return read;
  }

  @override
  Future<ResourceMutationReceipt> saveBorderDraft(
    String borderId, {
    required BorderBlueprintDraft draft,
    required String expectedRevision,
  }) {
    final definition = draft.definition;
    if (!definition.isSpatial ||
        definition.template != BorderBlueprintTemplate.connectedLine) {
      throw const ResourceFailure(
        'L’atelier permet de modifier les lignes connectées 3D.',
      );
    }
    return _borderWorkshopAdapter._run(
      _saveWorkshopBorderAction,
      (_) => {
        'record': encodeBorderBlueprintRecordJson(
          BorderBlueprintRecord(id: borderId, draft: draft),
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        ),
      },
      expectedBeforeRevision: expectedRevision,
      scopedBorderId: borderId,
    );
  }

  @override
  Future<ResourceMutationReceipt> publishBorderDraft(
    String borderId, {
    required String expectedRevision,
  }) => _borderWorkshopAdapter._run(
    _publishWorkshopBorderAction,
    (_) => {'blueprintId': borderId},
    expectedBeforeRevision: expectedRevision,
    scopedBorderId: borderId,
  );

  @override
  Future<void> reconcileBorderWorkshop(
    String borderId,
    ResourceMutationReceipt receipt,
  ) {
    final adapter = _borderWorkshopAdapter;
    return adapter.mapAdapter.withResourceMutation(() async {
      await _verifyWorkshopBorderReceipt(adapter, borderId, receipt);
      adapter._requireAvailable();
      await adapter.mapAdapter.acceptResourceMutation(
        adapter.session,
        receipt,
        changedBorder: _publishedWorkshopBorder(receipt, borderId),
      );
    });
  }
}

BorderBlueprintRecord? _publishedWorkshopBorder(
  ResourceMutationReceipt receipt,
  String? borderId,
) => borderId != null && receipt.actionId == _publishWorkshopBorderAction
    ? receipt.manifest.borderCatalog.recordById(borderId)
    : null;

ProjectManifest _mergeBorderWorkshopProjection(
  ProjectManifest before,
  ProjectManifest? projected,
  String borderId,
) {
  final after = projected?.borderCatalog;
  final record = after?.recordById(borderId);
  if (record == null) {
    throw const ResourceFailure('La bordure est absente du plan.');
  }
  final current = before.borderCatalog;
  final hasRecord = current.recordById(borderId) != null;
  return before.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: after!.formatVersion,
      records: [
        for (final previous in current.records)
          previous.id == borderId ? record : previous,
        if (!hasRecord) record,
      ],
      visualSnapshots: current.visualSnapshots,
    ),
  );
}

Future<void> _verifyWorkshopBorderReceipt(
  LocalResourceAdapter adapter,
  String borderId,
  ResourceMutationReceipt receipt,
) async {
  final expected = receipt.manifest.borderCatalog.recordById(borderId);
  final actual = await adapter.readWorkshopBorder(borderId);
  if (receipt.revision != actual.revision ||
      expected == null ||
      actual.project.borderCatalog.recordById(borderId) != expected) {
    throw const BorderWorkshopReopenRequired();
  }
}

ResourceFailure _borderWorkshopMutationFailure(Object error) => ResourceFailure(
  switch (error) {
    AuthoringPlanException(code: 'plan.stale') ||
    CatalogStorageException(
      code: 'catalog.revision_conflict',
    ) => 'Le catalogue a changé. Votre brouillon est conservé à l’écran.',
    CatalogStorageException(code: 'catalog.preparation_required') ||
    FormatException(
      message: 'catalog.resource_positions.preparation_required',
    ) => 'Rouvrez le projet pour préparer les ressources des bordures.',
    MapAuthoringException(code: 'border.blueprint.publication_invalid') => 'La configuration des pièces bloque la publication. Vérifiez les rôles et les orientations.',
    MapAuthoringException(code: 'border.blueprint.no_change') ||
    AuthoringPlanException(
      code: 'border.blueprint.no_change',
    ) => 'Ce brouillon correspond déjà à la version enregistrée.',
    _ => 'La bordure n’a pas pu être enregistrée. Votre saisie est conservée.',
  },
);
