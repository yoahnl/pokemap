part of 'catalog_workshop_selection.dart';

const _gameplayActions = {
  'campaign.battle_savings.update',
  'pokemon.ruleset.set',
  'campaign.encounter_table.upsert',
  'campaign.trainer.upsert',
  'campaign.shop.upsert',
  'bag.capacity.set',
  'item.create',
  'item.update',
};

Future<CatalogWorkshopSelection> _readGameplayWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  final selected = await reader.withMetadataFields({
    'pokemon',
    if (actionId == 'campaign.battle_savings.update') 'battleSavings',
    if (actionId == 'bag.capacity.set') 'newGame',
    if (actionId == 'bag.capacity.set') 'bagCapacity'
  });
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final ids = <String, Set<String>>{};
    void add(String field, Iterable<String> values) {
      final filtered = values.where((id) => id.isNotEmpty).toSet();
      if (filtered.isNotEmpty) {
        ids.putIfAbsent(field, () => {}).addAll(filtered);
      }
    }

    final writable = <String>{};
    final value = parameters['value'];
    final documentField = switch (actionId) {
      'campaign.trainer.upsert' => 'trainers',
      'campaign.shop.upsert' => 'shops',
      'campaign.encounter_table.upsert' => 'encounterTables',
      _ => null,
    };
    if (documentField != null) {
      writable.add(documentField);
      add(documentField,
          [if (value is Map && value['id'] is String) value['id'] as String]);
    }
    if (actionId == 'pokemon.ruleset.set') {
      writable.add('pokemon');
      final raw = parameters['profile'];
      if (raw is Map) {
        final next =
            PokemonRulesetProfile.fromJson(Map<String, dynamic>.from(raw));
        if (next.mechanics.disabledFeatures
            .contains(PokemonDisabledFeature.doubleBattles)) {
          add(
              'trainers',
              await CatalogMetadataDocuments.readTrainerIds(
                  snapshot: catalog.snapshot, doublesOnly: true));
        }
      }
    }
    if (actionId == 'bag.capacity.set') writable.add('bagCapacity');
    if (actionId == 'campaign.battle_savings.update') writable.add('battleSavings');
    if (actionId == 'item.update' && parameters['itemId'] is String) {
      add(
          'trainers',
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: catalog.snapshot,
              itemId: parameters['itemId'] as String));
    }
    final original = catalog.projectMetadata;
    final base = original.copyWith(settings: ProjectSettings(dimension: original.settings.dimension, spatialCamera: original.settings.spatialCamera, tileWidth: original.settings.tileWidth, tileHeight: original.settings.tileHeight),
        newGame: actionId == 'bag.capacity.set'
            ? ProjectNewGameConfig(initialBag: original.newGame.initialBag)
            : const ProjectNewGameConfig());
    var documents = await CatalogMetadataDocuments.readDocuments(
        snapshot: catalog.snapshot, project: base, ids: ids);
    final candidates = <Object?>[
      parameters,
      base.settings.toJson()
    ];
    var previous = -1;
    while (
        previous != ids.values.fold<int>(0, (n, values) => n + values.length)) {
      previous = ids.values.fold<int>(0, (n, values) => n + values.length);
      candidates.add(documents.project.toJson());
      for (final entry in const {
        'facts': {'factId', 'existingPartyFactId', 'enabledFactId', 'balanceFactId'},
        'scenes': {'sceneId', 'preSessionSceneId'},
        'badges': {'badgeId', 'rewardBadgeId'},
        'dialogues': {
          'dialogueId',
          'preBattleDialogueId',
          'victoryDialogueId',
          'defeatDialogueId'
        }
      }.entries) {
        add(entry.key,
            CatalogWorkshopSelection._referenceIds(candidates, entry.value));
      }
      if (actionId == 'campaign.battle_savings.update') {
        final identities = <String>{
          ...?ids['facts'],
          for (final fact in documents.project.facts)
            if (fact.legacyFlagName case final String alias) alias,
        };
        for (final identity in identities) {
          add('facts', await CatalogMetadataDocuments.readFactIdsForRuntimeIdentity(
              snapshot: catalog.snapshot, runtimeIdentity: identity));
        }
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
        'portraitElementId',
        'illustrationElementId'
      },
      CatalogDefinitionKind.tileset: {'portraitTilesetId'},
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
    final needsItems = actionId.startsWith('item.') ||
        actionId == 'campaign.shop.upsert' ||
        manifest.trainers.any((trainer) =>
            trainer.battleItems.isNotEmpty ||
            trainer.team.any((member) => member.ballItemId != null)) ||
        (actionId == 'campaign.trainer.upsert' &&
            value is Map &&
            (ProjectTrainerEntry.fromJson(Map<String, dynamic>.from(value))
                    .battleItems
                    .isNotEmpty ||
                ProjectTrainerEntry.fromJson(Map<String, dynamic>.from(value))
                    .team
                    .any((member) => member.ballItemId != null))) ||
        (actionId == 'bag.capacity.set' &&
            manifest.newGame.initialBag.isNotEmpty &&
            !ProjectBagCapacity.fromJson(Map<String, dynamic>.from(parameters))
                .isUnlimited);
    if (manifest.pokemon.catalogFiles['items'] case final String path
        when needsItems) {
      await readFile(itemCatalogResourceIdentity, path);
    }
    bytes['project'] = utf8.encode(jsonEncode(manifest.toJson()));
    paths['project'] = 'project.json';
    final fingerprints = <String, String>{
      'project': computeAuthoringBytesFingerprint(bytes['project']!,
          logicalName: 'project.json'),
      for (final entry in paths.entries)
        if (entry.key != 'project') entry.key: revisions[entry.value]!
    };
    final snapshot = ProjectSnapshot(
        materializedCatalogProject: true,
        projectHandle: projectHandle,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: const [],
        availableProjectSections: {
          'pokemon',
          ...ids.keys,
          ...writable
        },
        availableProjectDocuments: ids,
        resourceFingerprints: fingerprints,
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
