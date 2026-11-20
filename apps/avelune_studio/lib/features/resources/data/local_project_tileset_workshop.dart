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

Future<String> _tilesetGridUseMessage(
  CatalogSnapshot snapshot,
  Map<String, Object?> details,
  List<ProjectMapEntry> maps,
) async {
  const labelLimit = 3;
  final owners = (details['owners'] as List<Object?>? ?? const [])
      .whereType<String>();
  final mapOwners = owners.where((owner) => owner.startsWith('map:'));
  final mapIndex = ProjectMapEntries.prepare(maps);
  final labels = [
    for (final owner in mapOwners.take(labelLimit))
      if (mapIndex.lookup(owner.substring(4)) case final map?)
        'la carte « ${map.name} »',
  ];
  final definitions = {
    for (final value
        in (details['definitions'] as List<Object?>? ?? const [])
            .whereType<Map<String, Object?>>())
      CatalogDefinitionKey.fromJson(value),
  };
  final ownerKinds = {
    ...CatalogDefinitionKind.values.asNameMap(),
    'preset': CatalogDefinitionKind.smartTilePreset,
    'border': CatalogDefinitionKind.borderRecord,
  };
  for (final owner in owners) {
    final separator = owner.indexOf(':');
    if (separator < 0) continue;
    final kind = ownerKinds[owner.substring(0, separator)];
    if (kind != null) {
      definitions.add(
        CatalogDefinitionKey(kind, owner.substring(separator + 1)),
      );
    }
  }
  for (final key in definitions.take(labelLimit - labels.length)) {
    final name = (await snapshot.indexEntry(key))?.summary.name;
    final isTerrainAtlas = key.kind == CatalogDefinitionKind.smartTileAtlas;
    if (name == null || (!isTerrainAtlas && name == key.id)) continue;
    final kind = isTerrainAtlas ? 'l’atlas de terrain' : 'la ressource';
    labels.add('$kind « $name »');
  }
  if (labels.isEmpty) return _libraryUseMessage(details, maps);
  final namedUses = labels.length == 1
      ? labels.single
      : '${labels.take(labels.length - 1).join(', ')} et ${labels.last}';
  final hasMore = mapOwners.length + definitions.length > labels.length;
  return 'Cette planche est utilisée par $namedUses${hasMore ? ', entre autres' : ''}.';
}
