part of 'catalog_workshop_selection.dart';

const _guidedActions = {
  'event_v2.template.apply',
  'narrative.publish_document'
};

Future<CatalogWorkshopSelection> _readGuidedWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final fields = {
    'settings',
    'pokemon',
    'eventRegistry',
  };
  final selected = await reader.withMetadataFields(fields);
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final base = catalog.projectMetadata;
    final bytes = <String, List<int>>{};
    final paths = <String, String>{};
    final revisions = <String, String?>{};
    final ids = <String, Set<String>>{};
    void add(String field, Iterable<String> values) {
      final filtered = values.where((id) => id.isNotEmpty).toSet();
      if (filtered.isNotEmpty) {
        ids.putIfAbsent(field, () => {}).addAll(filtered);
      }
    }

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
    final rawSpec = parameters['spec'];
    final spec = rawSpec is Map
        ? StandardEventTemplateSpec.fromJson(Map<String, dynamic>.from(rawSpec))
        : null;
    final rawMap = parameters['map'];
    final mapId =
        spec?.mapId ?? (rawMap is Map ? rawMap['id'] as String? : null);
    if (mapId == null) {
      throw const FormatException('catalog.workshop: map identity required');
    }
    add('maps', [mapId]);
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    final ownerEntry =
        documents.project.maps.where((entry) => entry.id == mapId).firstOrNull;
    if (ownerEntry == null) {
      throw const ProjectSnapshotException(
          'project.map_missing', 'The map is not declared.');
    }
    await readFile('map:$mapId', ownerEntry.relativePath);
    MapData decodeMap(String id) {
      final value = bytes['map:$id'];
      if (value == null) {
        throw const ProjectSnapshotException('project.map_missing',
            'A map required by this mutation is missing.');
      }
      final map = MapData.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(value)) as Map));
      if (map.id != id) {
        throw const FormatException('catalog.workshop: map identity mismatch');
      }
      return map;
    }

    final owner = decodeMap(mapId);
    final maps = <String, MapData>{mapId: owner};
    final candidates = <Object?>[
      parameters,
      owner.toJson(),
    ];
    if (spec != null) {
      final entity = owner.entities
          .where((entity) => entity.id == spec.entityId)
          .firstOrNull;
      final previousRaw = entity?.properties['standardEventTemplate.v1'];
      final previous = previousRaw is String
          ? StandardEventTemplateSpec.fromJson(
              Map<String, dynamic>.from(jsonDecode(previousRaw) as Map))
          : null;
      final generation =
          entity?.properties['standardEventTemplate.sceneGeneration.v1'];
      if (previous != null) {
        candidates.add(previous.toJson());
        add('scenes',
            standardEventTemplateSceneIds(previous, generation: generation));
      }
      add(
          'scenes',
          standardEventTemplateSceneIds(spec,
              generation: standardEventTemplateNextSceneGeneration(spec,
                  previous: previous, previousGeneration: generation)));
      for (final value in [spec, if (previous != null) previous]) {
        final destination = value.parameters['destinationMapId'];
        if (destination is String) add('maps', [destination]);
      }
    }
    final writable = {
      'dialogues',
      'facts',
      'scenes',
      'cinematics',
      'storylines',
      'eventRegistry'
    };
    for (final field
        in writable.where(CatalogMetadataDocuments.fields.contains)) {
      ids.putIfAbsent(field, () => {});
      final incoming = parameters[field];
      if (incoming is List) {
        for (final value in incoming.whereType<Map>()) {
          final entry = field == 'dialogues' ? value['entry'] : value;
          if (entry is Map && entry['id'] is String) {
            add(field, [entry['id'] as String]);
          }
        }
      }
    }
    if (parameters['dialogues'] case final List sources) {
      for (final source in sources.whereType<Map>()) {
        if (source['entry'] case final Map entry) {
          if (entry['id'] case final String dialogueId) {
            add('scenes', await CatalogMetadataDocuments.readSceneIdsForDialogue(
                snapshot: catalog.snapshot, dialogueId: dialogueId));
          }
        }
      }
    }
    final changedSceneIds = <String>{
      if (parameters['scenes'] case final List scenes)
        for (final scene in scenes.whereType<Map>())
          if (scene['id'] case final String id) id,
      if (spec != null) ...?ids['scenes'],
    };
    final neededEvents = <String>{
      if (parameters['events'] case final List events)
        for (final event in events.whereType<Map>())
          if (event['id'] case final String id) id,
      if (spec != null) ...standardEventTemplateEventIds(spec),
    };
    final selectedEvents = <String>{};
    void includeEventDependencies() {
      neededEvents.addAll(CatalogWorkshopSelection._referenceIds(candidates,
          const {'eventId', 'eventIds', 'consumedEventId', 'consumedEventIds'}));
      var advanced = true;
      while (advanced) {
        advanced = false;
        for (final record in base.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
          if (selectedEvents.contains(record.id)) continue;
          final source = (record.definitionOrNull?.source ?? record.draftOrNull?.source)?.toJson();
          final wire = record.toJson();
          final sceneRefs = CatalogWorkshopSelection._referenceIds(wire, const {'sceneId'});
          if (!neededEvents.contains(record.id) && source?['mapId'] != mapId &&
              !sceneRefs.any(changedSceneIds.contains)) { continue; }
          selectedEvents.add(record.id);
          candidates.add(wire);
          neededEvents.addAll(CatalogWorkshopSelection._referenceIds(wire,
              const {'eventId', 'eventIds', 'consumedEventId', 'consumedEventIds'}));
          advanced = true;
        }
      }
    }
    final dependencyKeys = {
      'facts': {'factId', 'existingPartyFactId'},
      'maps': {'mapId', 'destinationMapId', 'targetMapId', 'sourceMapId'},
      'dialogues': {
        'dialogueId',
        'alternateDialogueId',
        'preBattleDialogueId',
        'victoryDialogueId',
        'defeatDialogueId'
      },
      'scenes': {'sceneId', 'preSessionSceneId'},
      'trainers': {'trainerId'},
      'shops': {'shopId'},
      'encounterTables': {'encounterTableId'},
      'cinematics': {'cinematicId'},
      'presentationCinematics': {'presentationCinematicId'},
      'storylines': {'storylineId'},
      'badges': {'badgeId', 'rewardBadgeId'},
      'worldRules': {'worldRuleId'},
      'scripts': {'scriptId'},
      'scenarios': {'scenarioId'},
    };
    var previous = -1;
    while (previous !=
        ids.values.fold<int>(0, (sum, values) => sum + values.length)) {
      previous = ids.values.fold<int>(0, (sum, values) => sum + values.length);
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: base, ids: ids);
      final definitionValues = documents.project.toJson()
        ..remove('eventRegistry')
        ..remove('settings')
        ..remove('newGame');
      candidates.add(definitionValues);
      includeEventDependencies();
      for (final entry in dependencyKeys.entries) {
        add(entry.key,
            CatalogWorkshopSelection._referenceIds(candidates, entry.value));
      }
    }
    final dependentMapIds = CatalogWorkshopSelection._referenceIds(candidates,
        const {'mapId', 'destinationMapId', 'targetMapId', 'sourceMapId'});
    for (final entry in documents.project.maps) {
      if (entry.id == mapId || !dependentMapIds.contains(entry.id)) continue;
      await readFile('map:${entry.id}', entry.relativePath);
      maps[entry.id] = decodeMap(entry.id);
    }
    final roots = <CatalogDefinitionKey>{};
    for (final entry in const {
      CatalogDefinitionKind.tileset: {'tilesetId', 'assetId', 'iconAssetId'},
      CatalogDefinitionKind.element: {
        'elementId',
        'portraitElementId',
        'illustrationElementId'
      },
      CatalogDefinitionKind.character: {
        'characterId',
        'alternateCharacterId',
        'avatarCharacterId',
        'defaultPlayerCharacterId',
        'playerAvatarCharacterIds'
      },
      CatalogDefinitionKind.model3d: {'modelId'},
    }.entries) {
      for (final id
          in CatalogWorkshopSelection._referenceIds(candidates, entry.value)) {
        final key = CatalogDefinitionKey(entry.key, id);
        if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
      }
    }
    final assets = await ProjectCatalogSelection(catalog).resolve(roots);
    var manifest = documents.project.copyWith(
        tilesets: assets.tilesets,
        elements: assets.elements,
        characters: assets.characters,
        models3d: assets.models3d);
    if (CatalogWorkshopSelection._referenceIds(candidates, const {'starterOptionId'}).isNotEmpty) {
      final context = await selected.readMetadata({'newGame'});
      manifest = manifest.copyWith(newGame: context.newGame);
      fields.add('newGame');
    }
    for (final entry in manifest.dialogues) {
      await readFile(
          dialogueSourceResourceIdentity(entry.id), entry.relativePath);
    }
    final suppliedDialogues = parameters['dialogues'];
    if (suppliedDialogues is List) {
      for (final value in suppliedDialogues.whereType<Map>()) {
        if (value['entry'] case final Map entry) {
          final dialogue =
              ProjectDialogueEntry.fromJson(Map<String, dynamic>.from(entry));
          await readFile(dialogueSourceResourceIdentity(dialogue.id),
              dialogue.relativePath);
        }
      }
    }
    if (manifest.pokemon.catalogFiles['items'] case final String path) {
      final needsItems = CatalogWorkshopSelection._referenceIds(
              candidates, const {'itemId', 'ballItemId'}).isNotEmpty ||
          manifest.trainers.any((trainer) => trainer.battleItems.isNotEmpty);
      if (needsItems) await readFile(itemCatalogResourceIdentity, path);
    }
    await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
    await readFile(
        projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey);
    final rawScenes = parameters['scenes'];
    if (rawScenes is List &&
        rawScenes
            .whereType<Map>()
            .map((raw) => SceneAsset.fromJson(Map<String, dynamic>.from(raw)))
            .any(sceneNeedsPartyMoveCatalog)) {
      if (manifest.pokemon.catalogFiles['moves'] case final String path) {
        await readFile('pokemonCatalog:moves', path);
      }
    }
    bytes['project'] = utf8.encode(jsonEncode(manifest.toJson()));
    paths['project'] = 'project.json';
    final snapshot = ProjectSnapshot(
        materializedCatalogProject: true,
        projectHandle: projectHandle,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: maps.values,
        availableProjectSections: {...fields, ...ids.keys},
        availableProjectDocuments: ids,
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes['project']!,
              logicalName: 'project.json'),
          for (final entry in paths.entries)
            if (entry.key != 'project') entry.key: revisions[entry.value]!
        },
        resourceBytes: bytes,
        resourceStorageKeys: paths,
        itemCatalog: bytes[itemCatalogResourceIdentity] == null
            ? null
            : decodeProjectItemCatalog(Map<String, dynamic>.from(
                jsonDecode(utf8.decode(bytes[itemCatalogResourceIdentity]!))
                    as Map)));
    final result = CatalogWorkshopSelection._(
        selected, snapshot, writable, revisions,
        metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}
