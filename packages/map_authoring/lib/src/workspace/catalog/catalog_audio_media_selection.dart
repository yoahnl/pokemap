part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readAudioMediaWorkshop({
  required String actionId,
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final configuring = actionId == 'project.battle_audio.update';
  final presentation = actionId == 'presentationMedia.import';
  final importingBytes =
      actionId == 'asset.import' || actionId == 'asset.import_batch';
  final sections = importingBytes || presentation
      ? const <String>{}
      : configuring
          ? const {'battleAudio'}
          : const {'cinematicMediaAssets'};
  final mediaId = parameters['mediaId'];
  if (!configuring &&
      !importingBytes &&
      (mediaId is! String || mediaId.isEmpty || mediaId.trim() != mediaId)) {
    throw const FormatException('catalog.audio: mediaId required');
  }
  final selected =
      await reader.withMetadataFields(configuring ? {'battleAudio'} : {});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final ids = {
      if (!configuring && !importingBytes && !presentation)
        'cinematicMediaAssets': {mediaId as String},
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
    if (presentation) {
      await readFile(
          projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey);
    }
    final inputs =
        actionId == 'asset.import_batch' ? parameters['entries'] : [parameters];
    if (inputs is! List ||
        inputs.isEmpty ||
        inputs.length > 200 ||
        inputs.any((entry) => entry is! Map)) {
      throw const FormatException('catalog.media: expected one to 200 imports');
    }
    for (final input in inputs.cast<Map>()) {
      if (input['artifactHandle'] case final String handle) {
        final match =
            RegExp(r'^artifact://sha256/([0-9a-f]{64})$').firstMatch(handle);
        if (match != null) {
          final digest = match.group(1)!;
          await readFile(assetBlobResourceIdentity('sha256:$digest'),
              'assets/.pokemap-store/$digest.blob');
        }
      }
      if (input['logicalPath'] case final String path when !presentation) {
        await readFile(
            importingBytes ? 'mediaTarget:$path' : 'audioTarget', path);
        if (importingBytes && revisions[path] != null) {
          throw const FormatException(
              'catalog.media: destination already exists');
        }
      }
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
