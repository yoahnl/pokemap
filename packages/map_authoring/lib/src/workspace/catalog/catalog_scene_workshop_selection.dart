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
    final incomingNodes = <SceneNode>[
      if (rawScene is Map)
        ...SceneAsset.fromJson(Map<String, dynamic>.from(rawScene)).graph.nodes,
      if (parameters['upsertNodes'] case final List nodes)
        for (final node in nodes)
          SceneNode.fromJson(Map<String, dynamic>.from(node as Map)),
      if (parameters['command'] case final Map command)
        SceneNode(
            id: 'incoming-command',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.fromJson(
                    Map<String, dynamic>.from(command)))),
    ];
    final itemIds = <String>{};
    final stepIds = <String>{};
    final resolvedStepIds = <String>{};
    final starterIds = <String>{};
    final journeyIds = <String>{};
    final imageIds = <String>{};
    final eventIds = <String>{};
    final ownerScenes = <String>{};
    void includeDependencies(ProjectManifest project) {
      final index = buildNarrativeDependencyIndex(
          project: project, additionalSceneNodes: incomingNodes);
      for (final usage in index.usages) {
        final target = usage.target;
        switch (target.kind) {
          case NarrativeDependencyTargetKind.fact:
            add('facts', [target.id]);
          case NarrativeDependencyTargetKind.badge:
            add('badges', [target.id]);
          case NarrativeDependencyTargetKind.item:
            itemIds.add(target.id);
          case NarrativeDependencyTargetKind.scene:
            add('scenes', [target.id]);
          case NarrativeDependencyTargetKind.dialogue:
            add('dialogues', [target.id]);
          case NarrativeDependencyTargetKind.cinematic:
            add('cinematics', [target.id]);
          case NarrativeDependencyTargetKind.media:
            add('cinematicMediaAssets', [target.id]);
          case NarrativeDependencyTargetKind.storyline:
            add('storylines', [target.id]);
          case NarrativeDependencyTargetKind.step:
            stepIds.add(target.id);
          case NarrativeDependencyTargetKind.worldRule:
            add('worldRules', [target.id]);
          case NarrativeDependencyTargetKind.railJourney:
            journeyIds.add(target.id);
          case NarrativeDependencyTargetKind.sourceMap:
            if (target.physicalMapId case final String mapId) {
              add('maps', [mapId]);
            }
            switch (target.sourceKind) {
              case 'encounterTable':
                add('encounterTables', [target.id]);
              case 'presentationCinematic':
                add('presentationCinematics', [target.id]);
              case 'starterOption':
                starterIds.add(target.id);
              case 'projectMedia':
                imageIds.add(target.id);
              case 'shop':
                add('shops', [target.id]);
              case 'battle':
                for (final prefix in ['trainer:', 'static:']) {
                  if (target.id.startsWith(prefix)) {
                    add('trainers', [target.id.substring(prefix.length)]);
                  }
                }
            }
          case NarrativeDependencyTargetKind.eventV2:
            eventIds.add(target.id);
          case NarrativeDependencyTargetKind.chapter:
            break;
        }
      }
    }

    add('scenes', [
      if (parameters['sceneId'] is String) parameters['sceneId'] as String,
      if (rawScene is Map && rawScene['id'] is String) rawScene['id'] as String
    ]);
    var base = catalog.projectMetadata;
    ProjectNewGameConfig? starterCatalog;
    RailJourneyCatalog? journeyCatalog;
    var journeyCatalogLoaded = false;
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    final candidates = <Object?>[];
    var previous = -1;
    int dependencyCount() =>
        ids.values.fold<int>(0, (total, values) => total + values.length) +
        stepIds.length +
        starterIds.length +
        journeyIds.length +
        eventIds.length;
    while (previous != dependencyCount()) {
      previous = dependencyCount();
      final pendingOwners =
          (ids['scenes'] ?? const <String>{}).difference(ownerScenes);
      if (pendingOwners.isNotEmpty) {
        ownerScenes.addAll(pendingOwners);
        eventIds.addAll(await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            catalog.snapshot, reader.store.projectRoot, pendingOwners));
      }
      if (eventIds.isNotEmpty) {
        base = base.copyWith(
            eventRegistry: await CatalogNarrativeEventDocuments.read(
                catalog.snapshot, eventIds));
        documents = await CatalogMetadataDocuments.readDocuments(
            snapshot: catalog.snapshot, project: base, ids: ids);
      }
      includeDependencies(documents.project);
      final sharedFields = {
        if (starterIds.isNotEmpty && starterCatalog == null) 'newGame',
        if (journeyIds.isNotEmpty && !journeyCatalogLoaded)
          'railJourneyCatalog',
      };
      if (sharedFields.isNotEmpty) {
        final shared = await selected.readMetadata(sharedFields);
        if (sharedFields.contains('newGame')) starterCatalog = shared.newGame;
        if (sharedFields.contains('railJourneyCatalog')) {
          journeyCatalog = shared.railJourneyCatalog;
          journeyCatalogLoaded = true;
        }
      }
      if (starterCatalog != null) {
        base = base.copyWith(
            newGame: ProjectNewGameConfig(
                enabled: starterCatalog.enabled,
                starterOptions: [
              for (final option in starterCatalog.starterOptions)
                if (starterIds.contains(option.id)) option
            ]));
        candidates.add(base.newGame.toJson());
      }
      if (journeyCatalog != null) {
        base = base.copyWith(
            railJourneyCatalog: RailJourneyCatalog(journeys: [
          for (final journey in journeyCatalog.journeys)
            if (journeyIds.contains(journey.id)) journey
        ]));
        candidates.add(base.railJourneyCatalog!.toJson());
      }
      final selectedDefinitions = documents.project.toJson()..remove('scenes');
      candidates.add(selectedDefinitions);
      for (final entry in const {
        'scenes': {'sceneId', 'preSessionSceneId'},
        'maps': {
          'mapId',
          'destinationMapId',
          'targetMapId',
          'sourceMapId',
          'stationMapId',
          'vehicleMapId'
        },
        'facts': {'factId', 'factIds'},
        'storylines': {'storylineId'},
        'dialogues': {
          'dialogueId',
          'alternateDialogueId',
          'preBattleDialogueId',
          'victoryDialogueId',
          'defeatDialogueId'
        },
        'trainers': {'trainerId'},
        'shops': {'shopId'},
        'badges': {'badgeId', 'rewardBadgeId'},
        'cinematics': {'cinematicId'},
        'presentationCinematics': {'presentationCinematicId'},
        'worldRules': {'worldRuleId'},
      }.entries) {
        add(entry.key,
            CatalogWorkshopSelection._referenceIds(candidates, entry.value));
      }
      stepIds.addAll(
          CatalogWorkshopSelection._referenceIds(candidates, {'stepId'}));
      for (final stepId in stepIds.difference(resolvedStepIds)) {
        resolvedStepIds.add(stepId);
        add(
            'storylines',
            await CatalogMetadataDocuments.readStorylineIdsForStep(
                snapshot: catalog.snapshot, stepId: stepId));
      }
      documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: base, ids: ids);
    }
    var manifest = documents.project;
    final visualCandidates = [
      parameters,
      for (final scene in manifest.scenes) scene.toJson(),
      ...candidates
    ];
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
      for (final id in CatalogWorkshopSelection._referenceIds(
          visualCandidates, entry.value)) {
        final key = CatalogDefinitionKey(entry.key, id);
        if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
      }
    }
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
    if (imageIds.isNotEmpty) {
      await readFile(
          projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey);
    }
    final assetIds = CatalogWorkshopSelection._referenceIds(
        visualCandidates, {'assetId', 'modelId', 'elementId', 'characterId'});
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
    final resources = await ProjectCatalogSelection(catalog)
        .forMaps(maps, additionalRoots: roots);
    manifest = manifest.copyWith(
        tilesets: resources.tilesets,
        elements: resources.elements,
        characters: resources.characters,
        models3d: resources.models3d);
    for (final dialogue in manifest.dialogues) {
      await readFile(
          dialogueSourceResourceIdentity(dialogue.id), dialogue.relativePath);
    }
    itemIds.addAll(CatalogWorkshopSelection._referenceIds(
        candidates, {'itemId', 'inputItemId', 'outputItemId', 'ballItemId'}));
    final itemPath = manifest.pokemon.catalogFiles['items'];
    if (itemIds.isNotEmpty && manifest.pokemon.enabled && itemPath != null) {
      await readFile(itemCatalogResourceIdentity, itemPath);
    }
    final movePath = manifest.pokemon.catalogFiles['moves'];
    final needsMoves = manifest.scenes.any(sceneNeedsPartyMoveCatalog) ||
        sceneNodesNeedPartyMoveCatalog(incomingNodes);
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
