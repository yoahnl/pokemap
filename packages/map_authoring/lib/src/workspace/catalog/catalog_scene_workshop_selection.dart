part of 'catalog_workshop_selection.dart';

const _sceneWorkshopActions = {
  'scene.upsert',
  'scene.graph.patch',
  'scene.interactive_command.set'
};

Future<CatalogWorkshopSelection> _readSceneWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final selected = await reader.withMetadataFields({'settings', 'pokemon'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final ids = <String, Set<String>>{};
    void add(String field, Iterable<String> values) {
      final filtered = values.where((value) => value.isNotEmpty).toSet();
      if (filtered.isNotEmpty) {
        ids.putIfAbsent(field, () => {}).addAll(filtered);
      }
    }

    final rawScene = parameters['scene'];
    add('scenes', [
      if (parameters['sceneId'] is String) parameters['sceneId'] as String,
      if (rawScene is Map && rawScene['id'] is String) rawScene['id'] as String
    ]);
    final base = catalog.projectMetadata;
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    final candidates = <Object?>[parameters];
    var previous = -1;
    while (previous !=
        ids.values.fold<int>(0, (total, values) => total + values.length)) {
      previous =
          ids.values.fold<int>(0, (total, values) => total + values.length);
      candidates.add(documents.project.toJson());
      for (final entry in const {
        'scenes': {'sceneId'},
        'maps': {'mapId', 'destinationMapId', 'targetMapId', 'sourceMapId'},
        'facts': {'factId', 'factIds', 'sourceId'},
        'storylines': {'storylineId'},
        'dialogues': {'dialogueId'},
        'trainers': {'trainerId'},
        'shops': {'shopId'},
        'badges': {'badgeId'},
        'cinematics': {'cinematicId'},
        'presentationCinematics': {'presentationCinematicId'},
        'worldRules': {'worldRuleId'},
      }.entries) {
        add(entry.key,
            CatalogWorkshopSelection._referenceIds(candidates, entry.value));
      }
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: base, ids: ids);
    }
    var manifest = documents.project;
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
        'illustrationElementId'
      },
      CatalogDefinitionKind.tileset: {'tilesetId', 'portraitTilesetId'},
      CatalogDefinitionKind.model3d: {'modelId'},
    }.entries) {
      for (final id
          in CatalogWorkshopSelection._referenceIds(candidates, entry.value)) {
        final key = CatalogDefinitionKey(entry.key, id);
        if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
      }
    }
    final resources = await ProjectCatalogSelection(catalog).resolve(roots);
    manifest = manifest.copyWith(
        tilesets: resources.tilesets,
        elements: resources.elements,
        characters: resources.characters,
        models3d: resources.models3d);
    final bytes = <String, List<int>>{};
    final paths = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> readFile(String identity, String path) async {
      validateProjectRelativePath(path);
      if (path == 'project.json' ||
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
        paths[identity] = path;
      } finally {
        await payload.release();
      }
    }

    for (final entry in readDependencies.entries) {
      await readFile(entry.key, entry.value);
    }
    final mediaIds = CatalogWorkshopSelection._referenceIds(
        candidates, {'imageResourceId', 'mediaAssetId'});
    if (mediaIds.isNotEmpty) {
      await readFile(
          projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey);
    }
    final assetIds = CatalogWorkshopSelection._referenceIds(
        candidates, {'assetId', 'modelId', 'elementId', 'characterId'});
    if (assetIds.isNotEmpty) {
      await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
    }
    final maps = <MapData>[];
    for (final map in manifest.maps) {
      await readFile('map:${map.id}', map.relativePath);
      final mapBytes = bytes['map:${map.id}'];
      if (mapBytes == null) {
        throw const ProjectSnapshotException(
            'project.map_missing', 'A map required by this scene is missing.');
      }
      final decoded = MapData.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(mapBytes)) as Map));
      if (decoded.id != map.id) {
        throw const FormatException('catalog.workshop: map identity mismatch');
      }
      maps.add(decoded);
    }
    for (final dialogue in manifest.dialogues) {
      await readFile(
          dialogueSourceResourceIdentity(dialogue.id), dialogue.relativePath);
    }
    final itemIds = CatalogWorkshopSelection._referenceIds(
        candidates, {'itemId', 'inputItemId', 'outputItemId', 'ballItemId'});
    final itemPath = manifest.pokemon.catalogFiles['items'];
    if (itemIds.isNotEmpty && manifest.pokemon.enabled && itemPath != null) {
      await readFile(itemCatalogResourceIdentity, itemPath);
    }
    final movePath = manifest.pokemon.catalogFiles['moves'];
    final needsMoves = manifest.scenes.any(sceneNeedsPartyMoveCatalog) ||
        rawScene is Map &&
            sceneNeedsPartyMoveCatalog(
                SceneAsset.fromJson(Map<String, dynamic>.from(rawScene))) ||
        parameters['upsertNodes'] is List &&
            sceneNodesNeedPartyMoveCatalog([
              for (final node in parameters['upsertNodes'] as List)
                SceneNode.fromJson(Map<String, dynamic>.from(node as Map))
            ]);
    if (needsMoves && manifest.pokemon.enabled && movePath != null) {
      await readFile('pokemonCatalog:moves', movePath);
    }
    bytes['project'] = utf8.encode(jsonEncode(manifest.toJson()));
    paths['project'] = 'project.json';
    final snapshot = ProjectSnapshot(
        materializedCatalogProject: true,
        projectHandle: projectHandle,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: maps,
        availableProjectSections: {
          'settings',
          'pokemon',
          'scenes',
          ...ids.keys
        },
        availableProjectDocuments: ids,
        resourceBytes: bytes,
        resourceStorageKeys: paths,
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes['project']!,
              logicalName: 'project.json'),
          for (final entry in paths.entries)
            if (entry.key != 'project') entry.key: revisions[entry.value]!
        },
        itemCatalog: bytes[itemCatalogResourceIdentity] == null
            ? null
            : decodeProjectItemCatalog(Map<String, dynamic>.from(
                jsonDecode(utf8.decode(bytes[itemCatalogResourceIdentity]!))
                    as Map)));
    final result = CatalogWorkshopSelection._(
        selected, snapshot, {'scenes'}, revisions,
        metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}
