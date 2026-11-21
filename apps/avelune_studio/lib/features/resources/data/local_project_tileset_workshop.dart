part of 'local_resource_adapter.dart';

mixin _LocalProjectTilesetWorkshop implements ProjectTilesetWorkshopPort {
  LocalResourceAdapter get _tilesetWorkshopAdapter;

  @override
  bool get tilesetGridEditingAvailable =>
      _tilesetWorkshopAdapter.session.storage ==
      ProjectSessionStorage.workingCatalog;

  @override
  Future<ResourceMutationReceipt> saveTilesetGrid(
    ProjectLibraryItem item, {
    required LibraryImageSize tileSize,
    required String expectedRevision,
    String? Function()? validateBeforeApply,
  }) async {
    if (item.kind != 'tileset') {
      throw const ResourceFailure('Cette fiche ne contient pas de planche.');
    }
    return _tilesetWorkshopAdapter._publishLibraryDefinition(
      'tileset.regrid',
      {
        'tilesetId': item.id,
        'tileWidth': tileSize.width,
        'tileHeight': tileSize.height,
      },
      expectedRevision,
      validateBeforeApply: validateBeforeApply,
    );
  }

  @override
  Future<void> reconcileTilesetGrid(ResourceMutationReceipt receipt) {
    final adapter = _tilesetWorkshopAdapter;
    return adapter.mapAdapter.withResourceMutation(() async {
      adapter._requireLibraryEditing();
      if (receipt.actionId != 'tileset.regrid' ||
          await adapter.mapAdapter.resourceRevision(adapter.session) !=
              receipt.revision) {
        throw const ResourceFailure(
          'Le catalogue a changé depuis l’enregistrement. Rouvrez le projet pour relire la planche.',
        );
      }
      await _verifyResourceReceiptPaths(adapter.session.directoryPath, receipt);
      adapter._requireAvailable();
      await adapter.mapAdapter.acceptResourceMutation(adapter.session, receipt);
    });
  }
}
