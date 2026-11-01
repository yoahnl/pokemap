part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readBattleRecipeWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final raw = parameters['projectBinding'];
  final resources = parameters['resources'];
  if (raw is! Map || resources is! List || resources.length > 256) {
    throw const FormatException('Invalid battle recipe import scope');
  }
  final binding =
      BattleRecipeProjectBinding.fromJson(Map<String, dynamic>.from(raw))
          .binding;
  final paths = <String, int>{
    battleRecipeBindingPath(binding.projectMoveId): 65536,
    battleRecipeBlobPath(
        binding.recipeSha256, 'application/vnd.avelune.battle-recipe+json',
        projectMoveId: binding.projectMoveId): 1048576,
  };
  for (final resource in resources) {
    if (resource is! Map ||
        resource['sha256'] is! String ||
        resource['mediaType'] is! String) {
      throw const FormatException('Invalid battle recipe resource scope');
    }
    final type = resource['mediaType'] as String;
    final path = battleRecipeBlobPath(resource['sha256'] as String, type,
        projectMoveId: binding.projectMoveId);
    final limit = type == 'image/png' ? 8 * 1024 * 1024 : 262144;
    if (!paths.containsKey(path) || limit < paths[path]!) paths[path] = limit;
  }
  final selected = await reader.withMetadataFields({'pokemon'});
  return selected.read((catalog) async {
    final manifest = catalog.projectMetadata;
    final movesPath = manifest.pokemon.catalogFiles['moves'];
    if (!manifest.pokemon.enabled || movesPath == null) {
      throw const FormatException('Move catalog is unavailable');
    }
    final values = <String, List<int>>{};
    final keys = <String, String>{};
    final revisions = <String, String?>{};
    var bundleBytes = 0;
    Future<void> capture(String id, String path, int maximumBytes,
        {bool bundle = false}) async {
      validateProjectRelativePath(path);
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        if (payload.byteLength > maximumBytes) {
          throw const FormatException(
              'Battle recipe dependency exceeds its limit');
        }
        if (bundle) {
          bundleBytes += payload.byteLength;
          if (bundleBytes > 64 * 1024 * 1024 + 65536) {
            throw const FormatException(
                'Battle recipe bundle exceeds its limit');
          }
        }
        values[id] = await payload.readBytes();
        keys[id] = path;
      } finally {
        await payload.release();
      }
    }

    await capture('pokemonCatalog:moves', movesPath, 16 * 1024 * 1024);
    for (final entry in paths.entries) {
      await capture('battleRecipe:${entry.key}', entry.key, entry.value,
          bundle: true);
    }
    final project = utf8.encode(jsonEncode(manifest.toJson()));
    final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      materializedCatalogProject: true,
      revision:
          CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
      manifest: manifest,
      maps: const [],
      availableProjectSections: const {'pokemon'},
      scopedStorageRevisions: revisions,
      resourceBytes: {...values, 'project': project},
      resourceStorageKeys: {...keys, 'project': 'project.json'},
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(project,
            logicalName: 'project.json'),
        for (final entry in keys.entries) entry.key: revisions[entry.value]!,
      },
    );
    final result =
        CatalogWorkshopSelection._(selected, snapshot, const {}, revisions);
    await result.requireCurrent();
    return result;
  });
}
