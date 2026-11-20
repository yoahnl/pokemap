part of 'catalog_resource_usage_index.dart';

Future<({Set<String> sources, Set<String>? consumers})?>
    readCatalogResourceLibraryRelations(
  CatalogSnapshot snapshot,
  CatalogDefinitionKey key,
) async {
  final definition = await snapshot.lookup(key);
  if (definition == null) return null;
  final identity = _libraryRelationIdentity('${key.kind.name}:${key.id}');
  Set<String> libraryIdentities(Set<String> identities) => Set.unmodifiable({
        for (final value in identities)
          if (_libraryRelationIdentity(value) case final related?
              when related != identity)
            related,
      });

  final sources = libraryIdentities(
      await CatalogResourceUsageIndex.directDependencies(snapshot, definition));
  final consumers = await CatalogResourceUsageIndex.prepared(snapshot)
      ? libraryIdentities(await CatalogResourceUsageIndex.libraryConsumerOwners(
          snapshot, key.kind.name, key.id,
          includeExternal: false))
      : null;
  return (sources: sources, consumers: consumers);
}

String? _libraryRelationIdentity(String value) {
  final split = value.indexOf(':');
  if (split < 1) return null;
  final kind = switch (value.substring(0, split)) {
    'border' || 'borderRecord' => 'borderBlueprint',
    'preset' => 'smartTilePreset',
    final kind => kind,
  };
  return ResourceLibraryCatalog.resourceKinds.contains(kind)
      ? '$kind${value.substring(split)}'
      : null;
}
