part of 'project_snapshot_loader.dart';

const _nativeWorkshopActions = {
  'pokemon.ruleset.set',
  'campaign.encounter_table.upsert',
  'campaign.trainer.upsert',
  'campaign.shop.upsert',
  'bag.capacity.set',
  'item.create',
  'item.update',
  'event_v2.template.apply',
  'narrative.publish_document',
};

const _nativeWorkshopReferences = {
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
  'tilesets': {'tilesetId', 'assetId', 'iconAssetId', 'portraitTilesetId'},
  'elements': {'elementId', 'portraitElementId', 'illustrationElementId'},
  'characters': {
    'characterId',
    'alternateCharacterId',
    'avatarCharacterId',
    'defaultPlayerCharacterId',
    'playerAvatarCharacterIds'
  },
  'models3d': {'modelId'},
};

Set<String> _nativeReferenceIds(Object? value, Set<String> keys) {
  final result = <String>{};
  void visit(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (keys.contains(entry.key)) {
          final referenced = entry.value;
          if (referenced is String && referenced.isNotEmpty) {
            result.add(referenced);
          } else if (referenced is List) {
            result.addAll(
                referenced.whereType<String>().where((id) => id.isNotEmpty));
          }
        }
        visit(entry.value);
      }
    } else if (node is List) {
      for (final child in node) {
        visit(child);
      }
    }
  }

  visit(value);
  return result;
}

String? _nativeEventId(Map record) {
  final body = record['definition'] ?? record['draft'];
  return body is Map && body['id'] is String ? body['id'] as String : null;
}

Future<ProjectSnapshot> _loadNativeWorkshop(
  ProjectSnapshotLoader loader,
  ProjectHandle projectHandle, {
  required String actionId,
  required Map<String, Object?> parameters,
  required Map<String, String> readDependencies,
}) async {
  if (!_nativeWorkshopActions.contains(actionId)) {
    throw const ProjectSnapshotException('project.workshop_scope_required',
        'This action does not have a native workshop dependency scope.');
  }
  final access = loader._handles.resolveProject(projectHandle);
  await access.requireReadableProject();
  final projectBytes = await access.readResourceBytes('project.json');
  final decoded = jsonDecode(utf8.decode(projectBytes.bytes));
  if (decoded is! Map || decoded['storage'] != null) {
    throw const ProjectSnapshotException('project.native_workshop_required',
        'This workshop loader requires a native project document.');
  }
  final raw = Map<String, dynamic>.from(decoded);
  final guided = actionId == 'event_v2.template.apply' ||
      actionId == 'narrative.publish_document';
  final sections = <String>{'pokemon', if (guided) 'settings'};
  final ids = <String, Set<String>>{};
  final indexes = <String, Map<String, List<Map<String, dynamic>>>>{};
  final selected = <String, Map<String, Map<String, dynamic>>>{};
  final candidates = <Object?>[parameters];
  void add(String field, Iterable<String> values) {
    final clean = values.where((id) => id.isNotEmpty).toSet();
    if (clean.isEmpty) return;
    ids.putIfAbsent(field, () => {}).addAll(clean);
    sections.add(field);
  }

  Map<String, List<Map<String, dynamic>>> index(String field) =>
      indexes.putIfAbsent(field, () {
        final result = <String, List<Map<String, dynamic>>>{};
        final values = raw[field];
        if (values is! List) return result;
        for (final value in values) {
          if (value is Map && value['id'] is String) {
            result.putIfAbsent(value['id'] as String, () => []).add(
                value is Map<String, dynamic>
                    ? value
                    : Map<String, dynamic>.from(value));
          }
        }
        return result;
      });
  void collect() {
    for (final entry in ids.entries) {
      final found = selected.putIfAbsent(entry.key, () => {});
      for (final id in entry.value) {
        if (found.containsKey(id)) continue;
        final rows = index(entry.key)[id];
        if (rows == null) continue;
        if (rows.length != 1) {
          throw const ProjectSnapshotException('project.definition_ambiguous',
              'A selected project definition has duplicate identities.');
        }
        found[id] = rows.single;
        candidates.add(rows.single);
      }
    }
  }

  final resources = <_LoadedProjectResource>[
    _LoadedProjectResource(
        relativePath: 'project.json', identity: 'project', bytes: projectBytes),
  ];
  final absent = <String>{};
  final paths = <String, String>{'project': 'project.json'};
  final maps = <String, MapData>{};
  Future<void> read(String identity, String path,
      {bool required = false}) async {
    validateProjectRelativePath(path);
    if (identity.trim().isEmpty ||
        identity == 'project' ||
        (paths.containsKey(identity) && paths[identity] != path) ||
        (paths.containsValue(path) && paths[identity] != path)) {
      throw const ProjectSnapshotException(
          'project.workshop_dependency_invalid',
          'Workshop dependency identities must be unique and stable.');
    }
    if (path == 'project.json' ||
        path.startsWith('catalog/') ||
        path.startsWith('.pokemap/')) {
      throw const ProjectSnapshotException(
          'project.workshop_dependency_invalid',
          'A workshop dependency must identify a project content file.');
    }
    if (paths.containsValue(path) || absent.contains(path)) return;
    final bytes = required
        ? await access.readResourceBytes(path)
        : await _readOptional(access, path);
    if (bytes == null) {
      absent.add(path);
      return;
    }
    resources.add(_LoadedProjectResource(
        relativePath: path, identity: identity, bytes: bytes));
    paths[identity] = path;
  }

  for (final entry in readDependencies.entries) {
    await read(entry.key, entry.value);
  }
  final field = switch (actionId) {
    'campaign.trainer.upsert' => 'trainers',
    'campaign.shop.upsert' => 'shops',
    'campaign.encounter_table.upsert' => 'encounterTables',
    _ => null,
  };
  if (field != null) {
    sections.add(field);
    ids.putIfAbsent(field, () => {});
    final value = parameters['value'];
    if (value is Map && value['id'] is String) {
      add(field, [value['id'] as String]);
    }
  }
  if (actionId == 'pokemon.ruleset.set') {
    final profile = parameters['profile'];
    if (profile is Map &&
        PokemonRulesetProfile.fromJson(Map<String, dynamic>.from(profile))
            .mechanics
            .disabledFeatures
            .contains(PokemonDisabledFeature.doubleBattles)) {
      for (final rows in index('trainers').values) {
        for (final trainer in rows) {
          if (trainer['battleFormat'] == 'doubles') {
            add('trainers', [trainer['id'] as String]);
          }
        }
      }
    }
  }
  if (actionId == 'item.update' && parameters['itemId'] is String) {
    for (final rows in index('trainers').values) {
      for (final trainer in rows) {
        if (_nativeReferenceIds(trainer['team'], const {'ballItemId'})
                .contains(parameters['itemId']) ||
            (trainer['battleItems'] is Map &&
                (trainer['battleItems'] as Map)
                    .containsKey(parameters['itemId']))) {
          add('trainers', [trainer['id'] as String]);
        }
      }
    }
  }
  final projected = <String, dynamic>{
    'name': raw['name'],
    'version': raw['version'],
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (raw.containsKey('pokemon')) 'pokemon': raw['pokemon'],
  };
  final rawSettings = raw['settings'];
  if (rawSettings is Map) {
    projected['settings'] = guided
        ? rawSettings
        : {
            for (final key in const {
              'dimension',
              'spatialCamera',
              'tileWidth',
              'tileHeight'
            })
              if (rawSettings.containsKey(key)) key: rawSettings[key],
          };
  }
  if (actionId == 'bag.capacity.set') {
    sections.add('bagCapacity');
    if (raw.containsKey('bagCapacity')) {
      projected['bagCapacity'] = raw['bagCapacity'];
    }
    final newGame = raw['newGame'];
    if (newGame is Map) {
      projected['newGame'] = {'initialBag': newGame['initialBag'] ?? []};
    }
  }
  StandardEventTemplateSpec? spec;
  String? ownerMapId;
  final changedSceneIds = <String>{};
  if (guided) {
    final rawSpec = parameters['spec'];
    if (rawSpec is Map) {
      spec = StandardEventTemplateSpec.fromJson(
          Map<String, dynamic>.from(rawSpec));
    }
    final rawMap = parameters['map'];
    ownerMapId =
        spec?.mapId ?? (rawMap is Map ? rawMap['id'] as String? : null);
    if (ownerMapId == null) {
      throw const ProjectSnapshotException(
          'project.map_missing', 'The workshop map identity is required.');
    }
    add('maps', [ownerMapId]);
    collect();
    final ownerEntry = selected['maps']?[ownerMapId];
    if (ownerEntry == null) {
      throw const ProjectSnapshotException(
          'project.map_missing', 'The workshop map is not declared.');
    }
    await read(
        'map:$ownerMapId', ProjectMapEntry.fromJson(ownerEntry).relativePath,
        required: true);
    final ownerBytes = resources
        .firstWhere((entry) => entry.identity == 'map:$ownerMapId')
        .bytes!;
    final owner = await loader._decodeExecutor.decodeMap(ownerBytes.bytes);
    if (owner.id != ownerMapId) {
      throw const ProjectSnapshotException('project.map_invalid',
          'The workshop map identity differs from its declaration.');
    }
    maps[owner.id] = owner;
    candidates.add(owner.toJson());
    if (spec != null) {
      final entity = owner.entities
          .where((entity) => entity.id == spec!.entityId)
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
      final nextGeneration = standardEventTemplateNextSceneGeneration(spec,
          previous: previous, previousGeneration: generation);
      final nextScenes =
          standardEventTemplateSceneIds(spec, generation: nextGeneration);
      add('scenes', nextScenes);
      if (previous == null || nextGeneration != generation) {
        changedSceneIds.addAll(nextScenes);
      }
    }
    for (final field in const {
      'dialogues',
      'facts',
      'scenes',
      'cinematics',
      'storylines'
    }) {
      sections.add(field);
      ids.putIfAbsent(field, () => {});
      final values = parameters[field];
      if (values is List) {
        for (final value in values.whereType<Map>()) {
          final document = field == 'dialogues' ? value['entry'] : value;
          if (document is Map && document['id'] is String) {
            add(field, [document['id'] as String]);
          }
        }
      }
    }
  }
  if (guided && parameters['scenes'] is List) {
    for (final scene in (parameters['scenes'] as List).whereType<Map>()) {
      final id = scene['id'];
      if (id is! String) continue;
      final before = index('scenes')[id];
      if (before == null ||
          before.length != 1 ||
          SceneAsset.fromJson(before.single) !=
              SceneAsset.fromJson(Map<String, dynamic>.from(scene))) {
        changedSceneIds.add(id);
      }
    }
  }
  if (guided && parameters['dialogues'] is List) {
    final changedDialogues = <String>{
      for (final value in (parameters['dialogues'] as List).whereType<Map>())
        if (value['entry'] is Map && (value['entry'] as Map)['id'] is String)
          (value['entry'] as Map)['id'] as String,
    };
    for (final rows in index('scenes').values) {
      for (final scene in rows) {
        if (_nativeReferenceIds(scene, const {'dialogueId'})
            .any(changedDialogues.contains)) {
          add('scenes', [scene['id'] as String]);
        }
      }
    }
  }
  final eventIds = <String>{
    if (spec != null) ...standardEventTemplateEventIds(spec),
    if (parameters['events'] case final List events)
      for (final event in events.whereType<Map>())
        if (_nativeEventId(event) case final String id) id,
  };
  final eventRecords = <String, Map<String, dynamic>>{};
  final storyStepOwners = <String, Set<String>>{};
  if (guided) {
    for (final rows in index('storylines').values) {
      for (final story in rows) {
        final chapters = story['chapters'];
        if (chapters is! List) continue;
        for (final chapter in chapters.whereType<Map>()) {
          final steps = chapter['steps'];
          if (steps is! List) continue;
          for (final step in steps.whereType<Map>()) {
            if (step['id'] case final String id) {
              storyStepOwners
                  .putIfAbsent(id, () => {})
                  .add(story['id'] as String);
            }
          }
        }
      }
    }
  }
  var previousCount = -1;
  while (previousCount !=
      ids.values
          .fold<int>(eventRecords.length, (n, values) => n + values.length)) {
    previousCount = ids.values
        .fold<int>(eventRecords.length, (n, values) => n + values.length);
    collect();
    if (guided) {
      for (final stepId in _nativeReferenceIds(candidates, const {'stepId'})) {
        add('storylines', storyStepOwners[stepId] ?? const {});
      }
    }
    for (final entry in _nativeWorkshopReferences.entries) {
      if (!guided &&
          const {
            'maps',
            'tilesets',
            'models3d',
            'trainers',
            'shops',
            'encounterTables',
            'cinematics',
            'presentationCinematics',
            'storylines',
            'worldRules',
            'scripts',
            'scenarios'
          }.contains(entry.key)) {
        continue;
      }
      add(entry.key, _nativeReferenceIds(candidates, entry.value));
    }
    if (raw['eventRegistry'] case final Map registry when guided) {
      eventIds.addAll(_nativeReferenceIds(candidates, const {
        'eventId',
        'eventIds',
        'consumedEventId',
        'consumedEventIds'
      }));
      final records = registry['records'];
      if (records is List) {
        for (final record in records.whereType<Map>()) {
          final id = _nativeEventId(record);
          if (id is! String || eventRecords.containsKey(id)) continue;
          final mapRefs = _nativeReferenceIds(record, const {'mapId'});
          final scenes = _nativeReferenceIds(record, const {'sceneId'});
          if (!eventIds.contains(id) &&
              !mapRefs.contains(ownerMapId) &&
              !scenes.any(changedSceneIds.contains)) {
            continue;
          }
          if (records
                  .whereType<Map>()
                  .where((record) => _nativeEventId(record) == id)
                  .length !=
              1) {
            throw const ProjectSnapshotException('project.definition_ambiguous',
                'A selected event has duplicate identities.');
          }
          final value = Map<String, dynamic>.from(record);
          eventRecords[id] = value;
          candidates.add(value);
        }
      }
    }
  }
  collect();
  for (final entry in selected.entries) {
    projected[entry.key] = entry.value.values.toList();
  }
  if (guided) {
    sections.add('eventRegistry');
    ids['eventRegistry'] = {...eventIds, ...eventRecords.keys};
    if (raw['eventRegistry'] case final Map registry) {
      projected['eventRegistry'] = {
        ...registry,
        'records': eventRecords.values.toList(),
        'legacyClaims': <Object?>[]
      };
    }
    if (_nativeReferenceIds(candidates, const {'starterOptionId'}).isNotEmpty) {
      sections.add('newGame');
      projected['newGame'] = raw['newGame'];
    }
    for (final entry in selected['maps']?.values ?? <Map<String, dynamic>>[]) {
      final declaration = ProjectMapEntry.fromJson(entry);
      if (maps.containsKey(declaration.id)) continue;
      await read('map:${declaration.id}', declaration.relativePath,
          required: true);
      final bytes = resources
          .firstWhere((entry) => entry.identity == 'map:${declaration.id}')
          .bytes!;
      final map = await loader._decodeExecutor.decodeMap(bytes.bytes);
      if (map.id != declaration.id) {
        throw const ProjectSnapshotException('project.map_invalid',
            'A dependency map identity differs from its declaration.');
      }
      maps[map.id] = map;
    }
  }
  final manifest = ProjectManifest.fromJson(projected);
  for (final dialogue in manifest.dialogues) {
    await read(
        dialogueSourceResourceIdentity(dialogue.id), dialogue.relativePath);
  }
  if (parameters['dialogues'] case final List incoming) {
    for (final value in incoming.whereType<Map>()) {
      if (value['entry'] case final Map entry) {
        final dialogue =
            ProjectDialogueEntry.fromJson(Map<String, dynamic>.from(entry));
        await read(
            dialogueSourceResourceIdentity(dialogue.id), dialogue.relativePath);
      }
    }
  }
  final needsItems = actionId.startsWith('item.') ||
      actionId == 'campaign.shop.upsert' ||
      _nativeReferenceIds(candidates, const {'itemId', 'ballItemId'})
          .isNotEmpty ||
      manifest.trainers.any((trainer) => trainer.battleItems.isNotEmpty) ||
      (actionId == 'campaign.trainer.upsert' &&
          parameters['value'] is Map &&
          ProjectTrainerEntry.fromJson(
                  Map<String, dynamic>.from(parameters['value'] as Map))
              .battleItems
              .isNotEmpty) ||
      (actionId == 'bag.capacity.set' &&
          manifest.newGame.initialBag.isNotEmpty);
  if (manifest.pokemon.catalogFiles['items'] case final String path
      when needsItems) {
    await read(itemCatalogResourceIdentity, path);
  }
  if (parameters['scenes'] case final List scenes when guided) {
    if (scenes
        .whereType<Map>()
        .map((scene) => SceneAsset.fromJson(Map<String, dynamic>.from(scene)))
        .any(sceneNeedsPartyMoveCatalog)) {
      if (manifest.pokemon.catalogFiles['moves'] case final String path) {
        await read('pokemonCatalog:moves', path);
      }
    }
  }
  final matches = await loader._matchSecondObservations(access, resources);
  if (matches.contains(false)) {
    throw const ProjectSnapshotException('project.changed_during_snapshot',
        'A workshop source changed while its snapshot was loading.');
  }
  for (final path in absent) {
    if (await _readOptional(access, path) != null) {
      throw const ProjectSnapshotException('project.changed_during_snapshot',
          'A workshop dependency appeared while its snapshot was loading.');
    }
  }
  final fingerprints = <String, String>{};
  final revision = NarrativeProjectFingerprintBuilder();
  resources.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  for (final resource in resources) {
    final fingerprint = await loader._decodeExecutor.fingerprintResource(
        resource.bytes!.bytes,
        relativePath: resource.relativePath);
    fingerprints[resource.identity] = fingerprint;
    final bytes = utf8.encode(fingerprint);
    revision
      ..startEntry(
          relativePath: resource.relativePath, byteLength: bytes.length)
      ..addBytes(bytes)
      ..endEntry();
  }
  await access.requireReadableProject();
  final itemBytes = resources
      .where((entry) => entry.identity == itemCatalogResourceIdentity)
      .firstOrNull
      ?.bytes;
  return ProjectSnapshot(
      projectHandle: projectHandle,
      revision: revision.close(),
      manifest: manifest,
      maps: maps.values,
      availableProjectSections: sections,
      availableProjectDocuments: ids,
      resourceFingerprints: fingerprints,
      scopedStorageRevisions: {
        for (final resource in resources)
          resource.relativePath: fingerprints[resource.identity],
        for (final path in absent) path: null,
      },
      ownedResourceBytes: {
        for (final resource in resources) resource.identity: resource.bytes!
      },
      resourceStorageKeys: paths,
      itemCatalog: itemBytes == null
          ? null
          : decodeProjectItemCatalog(Map<String, dynamic>.from(
              jsonDecode(utf8.decode(itemBytes.bytes)) as Map)));
}
