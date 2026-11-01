part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readGen5BattleSourceWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final raw = parameters['binding'];
  final speciesPath = parameters['speciesPath'];
  if (raw is! Map ||
      speciesPath is! String ||
      raw['projectSpeciesId'] is! String ||
      raw['nationalDex'] is! int) {
    throw const FormatException('Invalid Gen 5 source import scope');
  }
  final id = raw['projectSpeciesId'] as String;
  final dex = raw['nationalDex'] as int;
  final bindingBytes = utf8.encode(jsonEncode(raw));
  final binding = Gen5BattleSourceBinding.decode(
    Uint8List.fromList(bindingBytes),
    expectedSha256: sha256.convert(bindingBytes).toString(),
    expectedProjectSpeciesId: id,
    expectedProjectNationalDex: dex,
  );
  final selected = await reader.withMetadataFields({'pokemon'});
  return selected.read((catalog) async {
    final manifest = catalog.projectMetadata;
    final directory = manifest.pokemon.speciesDir;
    if (!manifest.pokemon.enabled ||
        validateProjectRelativePath(directory).join('/') != directory ||
        validateProjectRelativePath(speciesPath).join('/') != speciesPath ||
        !speciesPath.startsWith('$directory/') ||
        !speciesPath.toLowerCase().endsWith('.json')) {
      throw const FormatException('Invalid project species path');
    }
    final values = <String, List<int>>{};
    final keys = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> capture(String identity, String path, int maximumBytes) async {
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        if (payload.byteLength > maximumBytes) {
          throw const FormatException(
              'Gen 5 source dependency exceeds its limit');
        }
        values[identity] = await payload.readBytes();
        keys[identity] = path;
      } finally {
        await payload.release();
      }
    }

    await capture(pokemonSpeciesResourceIdentity(id), speciesPath, 1024 * 1024);
    await capture('gen5BattleSource:${binding.bindingPath}', binding.bindingPath,
        gen5BattleSourceBindingMaxBytes);
    await capture('gen5BattleSource:${binding.bundlePath}', binding.bundlePath,
        gen5BattleSourceBundleMaxBytes);
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
