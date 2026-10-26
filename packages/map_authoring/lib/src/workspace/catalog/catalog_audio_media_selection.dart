part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readAudioMediaWorkshop({
  required String actionId,
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final configuring = actionId == 'project.battle_audio.update';
  final sections = configuring ? const {'battleAudio'} : const {'cinematicMediaAssets'};
  final mediaId = parameters['mediaId'];
  if (!configuring && (mediaId is! String || mediaId.isEmpty || mediaId.trim() != mediaId)) {
    throw const FormatException('catalog.audio: mediaId required');
  }
  final selected = await reader.withMetadataFields(configuring ? {'battleAudio'} : {});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final ids = {
      if (!configuring) 'cinematicMediaAssets': {mediaId as String},
    };
    final documents = await CatalogMetadataDocuments.readDocuments(
      snapshot: catalog.snapshot,
      project: catalog.projectMetadata,
      ids: ids,
    );
    final bytes = <String, List<int>>{};
    final paths = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> readFile(String identity, String path) async {
      validateProjectRelativePath(path);
      if (path == 'project.json' ||
          path.startsWith('catalog/') ||
          path.startsWith('.pokemap/')) {
        throw const FormatException('catalog.audio: invalid read dependency');
      }
      if (revisions.containsKey(path)) return;
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        bytes[identity] = await payload.readBytes();
        paths[identity] = path;
      } finally {
        await payload.release();
      }
    }

    await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
    if (parameters['artifactHandle'] case final String handle) {
      final match =
          RegExp(r'^artifact://sha256/([0-9a-f]{64})$').firstMatch(handle);
      if (match != null) {
        final digest = match.group(1)!;
        await readFile(assetBlobResourceIdentity('sha256:$digest'),
            'assets/.pokemap-store/$digest.blob');
      }
    }
    if (parameters['logicalPath'] case final String path) {
      await readFile('audioTarget', path);
    }
    for (final entry in readDependencies.entries) {
      await readFile(entry.key, entry.value);
    }
    final projectBytes = utf8.encode(jsonEncode(documents.project.toJson()));
    final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      materializedCatalogProject: true,
      revision:
          CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
      manifest: documents.project,
      maps: const [],
      availableProjectSections: sections,
      availableProjectDocuments: ids,
      resourceBytes: {...bytes, 'project': projectBytes},
      resourceStorageKeys: {...paths, 'project': 'project.json'},
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(projectBytes,
            logicalName: 'project.json'),
        for (final entry in paths.entries) entry.key: revisions[entry.value]!,
      },
    );
    final result = CatalogWorkshopSelection._(
      selected,
      snapshot,
      sections,
      revisions,
      metadataDocuments: documents,
    );
    await result.requireCurrent();
    return result;
  });
}
