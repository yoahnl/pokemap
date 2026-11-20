part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readDialogueUpdateWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final raw = parameters['entry'];
  final incoming = raw is Map
      ? ProjectDialogueEntry.fromJson(Map<String, dynamic>.from(raw))
      : null;
  final id = incoming?.id ?? parameters['dialogueId'] as String;
  final sourceIdentity = dialogueSourceResourceIdentity(id);
  final bytes = <String, List<int>>{};
  final paths = <String, String>{};
  final revisions = <String, String?>{};
  Future<void> readFile(String identity, String path) async {
    validateProjectRelativePath(path);
    if (identity == 'project' ||
        path == 'project.json' ||
        path.startsWith('catalog/') ||
        path.startsWith('.pokemap/')) {
      throw const FormatException('catalog.workshop: invalid read dependency');
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

  if (incoming != null &&
      incoming.localization != null &&
      readDependencies.isEmpty &&
      parameters.length == 1) {
    final variant = await reader.read((catalog) async {
      await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
      final base = catalog.projectMetadata.copyWith(
        settings: catalog.projectMetadata.settings.copyWith(
          defaultPlayerCharacterId: null,
        ),
        newGame: const ProjectNewGameConfig(),
      );
      final ids = <String, Set<String>>{
        'dialogues': {id},
        if (incoming.folderId case final folder?) 'dialogueFolders': {folder},
      };
      var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot,
        project: base,
        ids: ids,
      );
      final before = documents.project.dialogues.firstOrNull;
      if (before == null ||
          before.localization == null ||
          before.copyWith(localization: incoming.localization) != incoming) {
        return null;
      }
      await readFile(sourceIdentity, before.relativePath);
      if (!bytes.containsKey(sourceIdentity)) return null;
      documents = await _readDialogueFolderAncestors(
        snapshot: catalog.snapshot,
        base: base,
        ids: ids,
        documents: documents,
      );
      return _dialogueUpdateSelection(
        selected: reader,
        projectHandle: projectHandle,
        manifest: documents.project,
        documents: documents,
        ids: ids,
        bytes: bytes,
        paths: paths,
        revisions: revisions,
      );
    });
    if (variant != null) return variant;
  }

  final selected = await reader.withMetadataFields({'settings', 'newGame'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    var base =
        catalog.projectMetadata.copyWith(newGame: const ProjectNewGameConfig());
    final ids = <String, Set<String>>{
      'dialogues': {id},
      'scenes': await CatalogMetadataDocuments.readSceneIdsForDialogue(
          snapshot: catalog.snapshot, dialogueId: id),
      'dialogueFolders': {if (incoming?.folderId case final String id) id},
      'facts': {},
      'cinematicMediaAssets': {},
    };
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    var loadedCounts = {
      for (final entry in ids.entries) entry.key: entry.value.length
    };
    final before = documents.project.dialogues
        .where((entry) => entry.id == id)
        .firstOrNull;
    if (before != null) {
      await readFile(sourceIdentity, before.relativePath);
    }
    for (final dependency in readDependencies.entries) {
      await readFile(dependency.key, dependency.value);
    }
    final candidates = <Object?>[
      parameters,
      catalog.projectMetadata.settings.toJson(),
      catalog.projectMetadata.newGame.toJson(),
    ];
    final feedback = <DialogueLineFeedback>[];
    for (final scene in documents.project.scenes) {
      for (final node in scene.graph.nodes) {
        final payload = node.payload;
        if (payload is SceneYarnDialoguePayload && payload.dialogueId == id) {
          feedback
              .addAll(payload.linePolicies.map((policy) => policy.feedback));
        }
      }
    }
    for (final (entry, source) in [
      if (before != null && bytes[sourceIdentity] != null)
        (before, utf8.decode(bytes[sourceIdentity]!)),
      if (parameters['source'] case final String source)
        if (incoming ?? before case final ProjectDialogueEntry entry)
          (entry, source),
    ]) {
      final compiled = const DialogueAuthoringCompiler()
          .compile(entry: entry, source: source);
      final document = compiled.document;
      if (document == null) continue;
      candidates.add(document.toJson());
      try {
        ids['facts']!.addAll(dialogueDocumentFactIds(document));
      } on FormatException {
        continue;
      }
      feedback.addAll(sceneDialogueLineScopes(document)
          .map((scope) => scope.feedback)
          .whereType<DialogueLineFeedback>());
    }
    for (final line in feedback) {
      if (line.audioCue case final cue?) {
        ids['cinematicMediaAssets']!.add(cue.mediaAssetId);
      }
    }
    final withAncestors = await _readDialogueFolderAncestors(
      snapshot: catalog.snapshot,
      base: base,
      ids: ids,
      documents: documents,
    );
    if (!identical(withAncestors, documents)) {
      documents = withAncestors;
      loadedCounts = {
        for (final entry in ids.entries) entry.key: entry.value.length
      };
    }
    final journeys = CatalogWorkshopSelection._referenceIds(
        [for (final scene in documents.project.scenes) scene.toJson()],
        {'journeyId'});
    if (journeys.isNotEmpty) {
      final metadata = await selected.readMetadata({'railJourneyCatalog'});
      final railCatalog = metadata.railJourneyCatalog;
      if (railCatalog != null) {
        final scoped = RailJourneyCatalog(journeys: [
          for (final journey in railCatalog.journeys)
            if (journeys.contains(journey.id)) journey,
        ]);
        base = base.copyWith(railJourneyCatalog: scoped);
        ids['maps'] = CatalogWorkshopSelection._referenceIds(
            scoped.toJson(), {'stationMapId', 'vehicleMapId', 'mapId'});
        candidates.add(scoped.toJson());
        ids['facts']!.addAll({
          for (final journey in scoped.journeys) ...{
            ...journey.requirements.requiredFactIds,
            ...journey.requirements.requiredAnyFactIds,
          },
        });
        ids['storylines'] = {};
        for (final step in {
          for (final journey in scoped.journeys)
            ...journey.requirements.completedStoryStepIds,
        }) {
          ids['storylines']!.addAll(
              await CatalogMetadataDocuments.readStorylineIdsForStep(
                  snapshot: catalog.snapshot, stepId: step));
        }
      }
    }
    if (ids.entries
        .any((entry) => loadedCounts[entry.key] != entry.value.length)) {
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: base, ids: ids);
    }
    final roots = <CatalogDefinitionKey>{};
    for (final entry in const {
      CatalogDefinitionKind.character: {
        'characterId',
        'avatarCharacterId',
        'defaultPlayerCharacterId',
        'playerAvatarCharacterIds'
      },
      CatalogDefinitionKind.element: {
        'elementId',
        'portraitElementId',
        'illustrationElementId',
        'stationElementId',
        'vehicleElementId'
      },
      CatalogDefinitionKind.tileset: {'tilesetId', 'assetId', 'iconAssetId'},
      CatalogDefinitionKind.model3d: {'modelId'},
    }.entries) {
      for (final id
          in CatalogWorkshopSelection._referenceIds(candidates, entry.value)) {
        final key = CatalogDefinitionKey(entry.key, id);
        if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
      }
    }
    for (final line in feedback) {
      for (final segment in line.segments.whereType<DialogueIconSegment>()) {
        final id = segment.assetId;
        if (id.startsWith('character-animation:')) {
          final owners = await CatalogResourceUsageIndex.consumerOwners(
              catalog.snapshot,
              'asset:${id.substring('character-animation:'.length)}');
          for (final owner
              in owners.where((id) => id.startsWith('character:'))) {
            roots.add(CatalogDefinitionKey(CatalogDefinitionKind.character,
                owner.substring('character:'.length)));
          }
        } else {
          final key = CatalogDefinitionKey(CatalogDefinitionKind.tileset, id);
          if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
        }
      }
    }
    final resources = await ProjectCatalogSelection(catalog).resolve(roots);
    documents = await _dialogueResourceGroups(
        catalog.snapshot, documents, ids, resources);
    final manifest = documents.project.copyWith(
        characterStudioCatalog: resources.characterStudioCatalog,
        tilesetFolders: resources.tilesetFolders,
        elementCategories: resources.elementCategories,
        characters: resources.characters,
        tilesets: resources.tilesets,
        elements: resources.elements,
        models3d: resources.models3d);
    return _dialogueUpdateSelection(
      selected: selected,
      projectHandle: projectHandle,
      manifest: manifest,
      documents: documents,
      ids: ids,
      bytes: bytes,
      paths: paths,
      revisions: revisions,
    );
  });
}

Future<CatalogMetadataDocumentSelection> _readDialogueFolderAncestors({
  required CatalogSnapshot snapshot,
  required ProjectManifest base,
  required Map<String, Set<String>> ids,
  required CatalogMetadataDocumentSelection documents,
}) async {
  final included = ids['dialogueFolders'];
  if (included == null) return documents;
  var current = documents;
  while (true) {
    final missing = <String>{
      for (final entry in current.project.dialogues)
        if (entry.folderId case final String id) id,
      for (final folder in current.project.dialogueFolders)
        if (folder.parentFolderId case final String id) id,
    }.difference(included);
    if (missing.isEmpty) return current;
    included.addAll(missing);
    current = await CatalogMetadataDocuments.readDocuments(
        snapshot: snapshot, project: base, ids: ids);
  }
}

Future<CatalogWorkshopSelection> _dialogueUpdateSelection({
  required CatalogProjectReader selected,
  required ProjectHandle projectHandle,
  required ProjectManifest manifest,
  required CatalogMetadataDocumentSelection documents,
  required Map<String, Set<String>> ids,
  required Map<String, List<int>> bytes,
  required Map<String, String> paths,
  required Map<String, String?> revisions,
}) async {
  final includesScenes = ids.containsKey('scenes');
  bytes['project'] = utf8.encode(jsonEncode(manifest.toJson()));
  paths['project'] = 'project.json';
  final snapshot = ProjectSnapshot(
      materializedCatalogProject: true,
      projectHandle: projectHandle,
      revision:
          CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
      manifest: manifest,
      maps: const [],
      availableProjectSections: {if (includesScenes) 'settings', ...ids.keys},
      availableProjectDocuments: ids,
      resourceBytes: bytes,
      resourceStorageKeys: paths,
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(bytes['project']!,
            logicalName: 'project.json'),
        for (final entry in paths.entries)
          if (entry.key != 'project') entry.key: revisions[entry.value]!,
      });
  final result = CatalogWorkshopSelection._(selected, snapshot,
      {'dialogues', if (includesScenes) 'scenes'}, revisions,
      metadataDocuments: documents);
  await result.requireCurrent();
  return result;
}
