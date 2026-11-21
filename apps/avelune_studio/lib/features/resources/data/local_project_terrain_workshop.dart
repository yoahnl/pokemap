part of 'local_resource_adapter.dart';

const _publishTerrainAction = 'smart_tile.preset.publish';

mixin _LocalProjectTerrainWorkshop implements ProjectTerrainWorkshopPort {
  LocalResourceAdapter get _terrainWorkshopAdapter;

  @override
  bool get terrainConnectionEditingAvailable =>
      _terrainWorkshopAdapter.session.storage ==
      ProjectSessionStorage.workingCatalog;

  @override
  Future<ResourceMutationReceipt> publishTerrainConnections(
    ProjectSmartTilePreset preset, {
    required String expectedRevision,
  }) => _terrainWorkshopAdapter._publishLibraryDefinition(
    _publishTerrainAction,
    {'preset': preset.toJson()},
    expectedRevision,
    terrainId: preset.id,
  );

  @override
  Future<void> reconcileTerrainConnections(ResourceMutationReceipt receipt) {
    final adapter = _terrainWorkshopAdapter;
    return adapter.mapAdapter.withResourceMutation(() async {
      adapter._requireLibraryEditing();
      final terrain = receipt.changedTerrain;
      if (receipt.actionId != _publishTerrainAction || terrain == null) {
        throw const ResourceFailure(
          'Cette publication de terrain est indisponible.',
        );
      }
      await _verifyWorkshopTerrain(adapter, terrain, receipt.revision);
      adapter._requireAvailable();
      await adapter.mapAdapter.acceptResourceMutation(
        adapter.session,
        receipt,
        changedTerrain: terrain,
      );
    });
  }
}

ResourceFailure _terrainWorkshopMutationFailure(
  Object error,
) => ResourceFailure(switch (error) {
  AuthoringPlanException(code: 'plan.stale') ||
  CatalogStorageException(code: 'catalog.revision_conflict') ||
  MapWorkspaceFailure(
    problem: MapWorkspaceProblem.conflict,
  ) => 'Le catalogue a changé. Votre raccord est conservé à l’écran.',
  AuthoringPlanException(code: 'catalog.mutation_scope_required') =>
    'Seule la tuile du raccord peut changer dans sa planche d’origine.',
  FormatException(message: 'catalog.resource_positions.preparation_required') ||
  CatalogStorageException(
    code: 'catalog.preparation_required',
  ) => 'Le catalogue doit être préparé avant la publication des raccords.',
  _ => 'Les raccords n’ont pas pu être publiés. Votre saisie est conservée.',
});

Future<void> _verifyWorkshopTerrain(
  LocalResourceAdapter adapter,
  ProjectSmartTilePreset terrain,
  String revision,
) async {
  final actual = await adapter.mapAdapter.readResourcePreviewWithRevision(
    adapter.session,
    'smartTilePreset',
    terrain.id,
  );
  if (actual.revision != revision ||
      actual.project.smartTileCatalog.presets.singleOrNull != terrain) {
    throw const ResourceFailure(
      'Le catalogue a changé après la publication. Rouvrez le projet pour relire le terrain.',
    );
  }
}
