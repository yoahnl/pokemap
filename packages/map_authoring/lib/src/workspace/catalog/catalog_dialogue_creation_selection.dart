part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readDialogueCreationWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final ids = <String, Set<String>>{
      'dialogues': {},
      'dialogueFolders': {},
      'facts': {},
    };
    final incoming = actionId == 'dialogue.create'
        ? [parameters]
        : parameters['dialogues'] is List
            ? parameters['dialogues'] as List
            : const [];
    final candidates = <Object?>[catalog.projectMetadata.settings.toJson()];
    final paths = <String>{};
    final incomingOwnership = <(ProjectDialogueEntry, bool)>[];
    for (final value in incoming) {
      if (value is! Map || value['entry'] is! Map) continue;
      final entry = ProjectDialogueEntry.fromJson(
          Map<String, dynamic>.from(value['entry'] as Map));
      validateProjectRelativePath(entry.relativePath);
      ids['dialogues']!.add(entry.id);
      final dialogueOwners = <String>{};
      try {
        dialogueOwners.addAll(
            await CatalogMetadataDocuments.readDialoguePathOwnerIds(
                snapshot: catalog.snapshot, relativePath: entry.relativePath));
        ids['dialogues']!.addAll(dialogueOwners);
      } on FormatException catch (error) {
        if (error.message !=
            'catalog.metadata_documents.dialogue_ownership_preparation_required') {
          rethrow;
        }
        throw AuthoringPlanException(
            code: 'catalog.dialogue_ownership_preparation_required',
            message:
                'Prepare the dialogue source path ownership index before creating dialogues in this catalog.',
            remediation: const [
              'Run explicit workshop preparation with scope dialogueCreation. It reads only dialogue metadata and ownership rows.'
            ]);
      }
      final mapOwners = await CatalogMetadataDocuments.readMapOwnerIds(
          snapshot: catalog.snapshot,
          mapId: null,
          relativePath: entry.relativePath);
      incomingOwnership
          .add((entry, dialogueOwners.isNotEmpty || mapOwners.isNotEmpty));
      if (entry.folderId case final String folderId) {
        ids['dialogueFolders']!.add(folderId);
      }
      paths.add(entry.relativePath);
      if (value['source'] case final String source) {
        final compiled = const DialogueAuthoringCompiler()
            .compile(entry: entry, source: source);
        if (compiled.document case final document?) {
          candidates.add(document.toJson());
          try {
            ids['facts']!.addAll(dialogueDocumentFactIds(document));
          } on FormatException {
            continue;
          }
        }
      }
    }
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: catalog.projectMetadata, ids: ids);
    final existingIds =
        documents.project.dialogues.map((entry) => entry.id).toSet();
    final incomingIds = <String>{};
    for (final (entry, pathOwned) in incomingOwnership) {
      if (existingIds.contains(entry.id) || !incomingIds.add(entry.id)) {
        break;
      }
      if (pathOwned) {
        throw NarrativeAuthoringException('dialogue.path_conflict',
            'The requested dialogue source path is already owned.',
            details: {'relativePath': entry.relativePath});
      }
    }
    while (true) {
      final folders = <String>{
        for (final entry in documents.project.dialogues)
          if (entry.folderId case final String id) id,
        for (final folder in documents.project.dialogueFolders)
          if (folder.parentFolderId case final String id) id,
      }.difference(ids['dialogueFolders']!);
      if (folders.isEmpty) break;
      ids['dialogueFolders']!.addAll(folders);
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot,
          project: catalog.projectMetadata,
          ids: ids);
    }
    final roots = <CatalogDefinitionKey>{};
    for (final id in CatalogWorkshopSelection._referenceIds(
        candidates, {'characterId', 'defaultPlayerCharacterId'})) {
      final key = CatalogDefinitionKey(CatalogDefinitionKind.character, id);
      if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
    }
    final resources = await ProjectCatalogSelection(catalog).resolve(roots);
    final manifest = documents.project.copyWith(
        characters: resources.characters,
        elements: resources.elements,
        models3d: resources.models3d,
        tilesets: resources.tilesets);
    final bytes = <String, List<int>>{};
    final storageKeys = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> readFile(String identity, String path) async {
      validateProjectRelativePath(path);
      if (identity == 'project' ||
          path == 'project.json' ||
          path.startsWith('catalog/') ||
          path.startsWith('.pokemap/')) {
        throw const FormatException(
            'catalog.workshop: invalid read dependency');
      }
      if (revisions.containsKey(path)) return;
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        bytes[identity] = await payload.readBytes();
        storageKeys[identity] = path;
      } finally {
        await payload.release();
      }
    }

    for (final entry in readDependencies.entries) {
      await readFile(entry.key, entry.value);
    }
    for (final path in paths) {
      revisions.putIfAbsent(path, () => null);
      revisions[path] = await reader.store.gateway.readResourceRevision(path);
    }
    bytes['project'] = utf8.encode(jsonEncode(manifest.toJson()));
    storageKeys['project'] = 'project.json';
    final snapshot = ProjectSnapshot(
        materializedCatalogProject: true,
        projectHandle: projectHandle,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: const [],
        availableProjectSections: {'settings', ...ids.keys},
        availableProjectDocuments: ids,
        resourceBytes: bytes,
        resourceStorageKeys: storageKeys,
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes['project']!,
              logicalName: 'project.json'),
          for (final entry in storageKeys.entries)
            if (entry.key != 'project') entry.key: revisions[entry.value]!,
        });
    final result = CatalogWorkshopSelection._(
        selected, snapshot, {'dialogues'}, revisions,
        metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}
