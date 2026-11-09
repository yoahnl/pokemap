part of 'project_snapshot_loader.dart';

const _nativeWorkshopActions = {
  'characterStudio.animationClip.upsert',
  'scene.condition.set',
  'scene.graph.patch',
  'world_rule.create',
  'world_rule.update',
  'world_rule.upsert_batch',
  'event_v2.record_upsert',
  'event_v2.record_upsert_batch',
  'entity.set_presentation',
  'map3d.instance.visibility.set',
  'map3d.instance.configure_field_obstacle',
  ...TriggerZoneActions.fieldTraversalActions,
  'surf.configure',
  'field_ability.configure',
  'project.audio.cue.configure',
  'presentationMedia.import',
  'project.audio.media.adopt_asset',
  'campaign.battle_savings.update',
  'pokemon.ruleset.set',
  'pokemon.media.write',
  'campaign.encounter_table.upsert',
  'campaign.trainer.upsert',
  'campaign.shop.upsert',
  'bag.capacity.set',
  'item.create',
  'item.update', 'item.set_capture_effect',
  'event_v2.template.apply',
  'narrative.publish_document',
};

const _nativeWorkshopReferences = {
  'facts': {'factId', 'existingPartyFactId', 'enabledFactId', 'balanceFactId'},
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
  'encounterTables': {'encounterTableId', 'battleTemplateId'},
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

Set<String> _nativeReferenceIds(Object? value, Set<String> keys, {bool ignorePeriodicRewardReferences = false}) {
  final result = <String>{};
  void visit(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (ignorePeriodicRewardReferences && entry.key == 'rewardReference') continue;
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
  final characterClip = actionId == 'characterStudio.animationClip.upsert';
  if (characterClip && parameters['kind'] != 'system') {
    throw const ProjectSnapshotException('project.workshop_scope_required',
        'Only system animation slots have a native workshop scope.');
  }
  final mapEdit = actionId == 'map3d.edit_batch' ||
      Map3dEditProjection.admittedActions.contains(actionId);
  final modelShadows = actionId == 'model3d.configure' && parameters.length == 2 &&
      parameters.containsKey('modelId') && parameters.containsKey('castsShadowsByDefault');
  if (!mapEdit && !modelShadows && !_nativeWorkshopActions.contains(actionId)) {
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
  if (modelShadows) {
    final id = parameters['modelId'];
    if (id is! String || parameters['castsShadowsByDefault'] is! bool) {
      throw const FormatException('Invalid model shadow configuration.');
    }
    final selected = [for (final entry in raw['models3d'] as List? ?? const [])
      if (entry is Map && entry['id'] == id) Map<String, dynamic>.from(entry)];
    if (selected.length != 1) throw const FormatException('Unknown or ambiguous model identity.');
    final settings = raw['settings'] as Map? ?? const {};
    final manifest = ProjectManifest.fromJson({
      'name': raw['name'], 'version': raw['version'], 'maps': const [], 'tilesets': const [],
      'models3d': selected,
      'pokemon': {'ruleset': (raw['pokemon'] as Map?)?['ruleset']},
      'settings': {for (final key in ['dimension', 'spatialCamera', 'tileWidth', 'tileHeight'])
        if (settings.containsKey(key)) key: settings[key]},
    });
    final revision = await loader._decodeExecutor.fingerprintResource(projectBytes.bytes, relativePath: 'project.json');
    if (!await access.matchesResourceBytes('project.json', projectBytes.bytes)) {
      throw const ProjectSnapshotException('project.changed_during_snapshot', 'The project changed while reading the selected model.');
    }
    return ProjectSnapshot(projectHandle: projectHandle, revision: revision,
      manifest: manifest, maps: const [], availableProjectSections: const {'settings', 'models3d'},
      availableProjectDocuments: {'models3d': {id}}, scopedStorageRevisions: {'project.json': revision},
      resourceFingerprints: {'project': revision}, resourceStorageKeys: const {'project': 'project.json'},
      ownedResourceBytes: {'project': projectBytes});
  }
  if (mapEdit) {
    return _loadNativeMapEdit(
        loader, projectHandle, raw, projectBytes, parameters);
  }
  if (actionId == 'map3d.instance.configure_field_obstacle' ||
      actionId == 'map3d.instance.visibility.set' ||
      actionId == 'entity.set_presentation' ||
      TriggerZoneActions.fieldTraversalActions.contains(actionId)) {
    return _loadNativeMapProperties(
        loader, projectHandle, raw, projectBytes, parameters,
        actionId: actionId);
  }
  final adoptingAudio = actionId == 'project.audio.media.adopt_asset';
  final conditionRule = actionId.startsWith('world_rule.');
  final conditionEvent = actionId == 'event_v2.record_upsert' ||
      actionId == 'event_v2.record_upsert_batch';
  final sceneCondition = actionId == 'scene.condition.set' || actionId == 'scene.graph.patch' || conditionRule || conditionEvent;
  final presentationImport =
      actionId == 'presentationMedia.import' || adoptingAudio;
  final guided = actionId == 'event_v2.template.apply' ||
      actionId == 'narrative.publish_document';
  final sections = <String>{
    if (!presentationImport) 'pokemon',
    if (guided ||
        const {
          'surf.configure',
          'field_ability.configure',
          'project.audio.cue.configure'
        }.contains(actionId))
      'settings'
  };
  final ids = <String, Set<String>>{};
  final indexes = <String, Map<String, List<Map<String, dynamic>>>>{};
  final selected = <String, Map<String, Map<String, dynamic>>>{};
  final surfConfiguration = parameters['configuration'];
  final candidates = <Object?>[
    if (actionId != 'surf.configure')
      parameters
    else if (surfConfiguration is Map &&
        surfConfiguration['accessMode'] == 'condition')
      surfConfiguration['condition'],
  ];
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
    for (final entry in ids.entries.toList()) {
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
        if (entry.key == 'scenes') {
          final graph = rows.single['graph'];
          if (graph is Map && graph['nodes'] is List) {
            for (final node in (graph['nodes'] as List).whereType<Map>()) {
              final payload = node['payload'];
              final source = payload is Map ? payload['conditionSource'] : null;
              if (source is! Map || source['sourceId'] is! String) continue;
              final field = switch (source['sourceKind']) { 'fact' => 'facts', 'badge' => 'badges', 'trainerDefeated' => 'trainers', _ => null };
              if (field != null) add(field, [source['sourceId'] as String]);
            }
          }
        }

      }
    }
  }

  if (parameters['conditionSource'] case final Map source) {
    final field = switch (source['sourceKind']) {
      'badge' => 'badges', 'fact' => 'facts', 'trainerDefeated' => 'trainers', _ => null,
    };
    if (field != null && source['sourceId'] is String) add(field, [source['sourceId'] as String]);
  }
  if (conditionRule) {
    sections.add('worldRules');
    for (final rule in [
      if (parameters['rule'] case final Map rule) rule,
      if (parameters['rules'] case final List rules) ...rules.whereType<Map>()
    ]) {
      if (rule['id'] case final String id) add('worldRules', [id]);
      if (rule['source'] case final Map source) {
        if (source['kind'] == 'fact' && source['sourceId'] is String)
          add('facts', [source['sourceId'] as String]);
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
  if (presentationImport) {
    await read(assetCatalogResourceIdentity, assetCatalogStorageKey);
    await read(
        projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey);
    if (adoptingAudio) {
      final assetId = parameters['assetId'];
      if (assetId is! String) {
        throw const FormatException('Choose a source asset identity.');
      }
      List<int>? loaded(String identity) => resources
          .where((r) => r.identity == identity)
          .firstOrNull
          ?.bytes
          ?.bytes;
      final source = readAssetRecordFromCatalogBytes(
          loaded(assetCatalogResourceIdentity), assetId);
      final attached = findProjectAudioMediaForSource(
          readProjectMediaCatalogDocumentBytes(
              loaded(projectMediaCatalogResourceIdentity)),
          assetId);
      if (source != null &&
          (source.artifact.mediaType.startsWith('audio/') ||
              source.artifact.mediaType == 'application/octet-stream') &&
          attached == null) {
        await read(assetBlobResourceIdentity(source.artifact.digest),
            assetBlobStorageKey(source.artifact));
      }
    }
    final handle = parameters['artifactHandle'];
    if (handle is String) {
      final match =
          RegExp(r'^artifact://sha256/([0-9a-f]{64})$').firstMatch(handle);
      if (match != null) {
        final digest = match.group(1)!;
        await read(assetBlobResourceIdentity('sha256:$digest'),
            'assets/.pokemap-store/$digest.blob');
      }
    }
  }
  if (actionId == 'project.audio.cue.configure') {
    if (parameters['binding'] case final Map binding
        when binding['source'] == 'custom') {
      await read(
          projectMediaCatalogResourceIdentity, projectMediaCatalogStorageKey,
          required: true);
      await read(assetCatalogResourceIdentity, assetCatalogStorageKey);
    }
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
    if (profile is Map && profile['disabledFeatures'] is List &&
        (profile['disabledFeatures'] as List).contains('double-battles')) {
      for (final rows in index('trainers').values) {
        for (final trainer in rows) {
          if (trainer['battleFormat'] == 'doubles') {
            add('trainers', [trainer['id'] as String]);
          }
        }
      }
    }
  }
  if ((actionId == 'item.update' || actionId == 'item.set_capture_effect') && parameters['itemId'] is String) {
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
    'pokemon': presentationImport
        ? {'ruleset': (raw['pokemon'] as Map?)?['ruleset']}
        : raw['pokemon'],
  };
  final rawSettings = raw['settings'];
  if (rawSettings is Map) {
    projected['settings'] = guided || sceneCondition ||
            const {
              'surf.configure',
              'field_ability.configure',
              'project.audio.cue.configure'
            }.contains(actionId)
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
  if (actionId == 'campaign.battle_savings.update') {
    sections.add('battleSavings');
    if (raw.containsKey('battleSavings')) {
      projected['battleSavings'] = raw['battleSavings'];
    }
    candidates.add(raw['battleSavings']);
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
    if (actionId == 'campaign.battle_savings.update') {
      final identities = <String>{
        ...?ids['facts'],
        for (final fact
            in selected['facts']?.values ?? <Map<String, dynamic>>[])
          if (fact['legacyFlagName'] case final String alias) alias,
      };
      for (final rows in index('facts').values) {
        for (final fact in rows) {
          if (identities.contains(fact['id']) ||
              identities.contains(fact['legacyFlagName'])) {
            add('facts', [fact['id'] as String]);
          }
        }
      }
    }
    if (guided) {
      for (final stepId in _nativeReferenceIds(candidates, const {'stepId'})) {
        add('storylines', storyStepOwners[stepId] ?? const {});
      }
    }
    for (final entry in _nativeWorkshopReferences.entries) {
      if (!guided && !sceneCondition &&
          {
            if (!const {
              'surf.configure',
              'field_ability.configure',
              'project.audio.cue.configure'
            }.contains(actionId))
              'maps',
            if (!characterClip) 'tilesets',
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
      add(entry.key, _nativeReferenceIds(candidates, entry.value,
        ignorePeriodicRewardReferences: sceneCondition));
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
  if (conditionEvent) {
    final expandedScenes = <String>{};
    while (true) {
      final scenes = [
        for (final scene in (selected['scenes'] ?? const {}).entries)
          if (expandedScenes.add(scene.key)) scene.value,
      ];
      if (scenes.isEmpty) break;
      for (final entry in _nativeWorkshopReferences.entries) {
        add(entry.key, _nativeReferenceIds(scenes, entry.value,
            ignorePeriodicRewardReferences: true));
      }
      final stepIds = _nativeReferenceIds(scenes, const {'stepId'});
      if (stepIds.isNotEmpty) {
        for (final rows in index('storylines').values) {
          for (final story in rows) {
            final chapters = story['chapters'];
            if (chapters is! List) continue;
            final owns = chapters.whereType<Map>().any((chapter) =>
                chapter['steps'] is List &&
                (chapter['steps'] as List).whereType<Map>().any(
                    (step) => stepIds.contains(step['id'])));
            if (owns) add('storylines', [story['id'] as String]);
          }
        }
      }
      collect();
    }
  }
  for (final entry in selected.entries) {
    projected[entry.key] = entry.value.values.toList();
  }
  final studioCatalog = characterClip ? raw['characterStudioCatalog'] : null;
  if (studioCatalog case final Map catalog) {
    final characters = selected['characters']?.values ?? const <Map<String, dynamic>>[];
    final portraitIds = _nativeReferenceIds(
        [for (final character in characters) character['portraits']],
        const {'portraitStateId'});
    final customIds = _nativeReferenceIds(
        [for (final character in characters) character['customAnimations']],
        const {'definitionId'});
    List<Map<String, dynamic>> definitions(String field, Set<String> referenced) {
      final rows = catalog[field];
      if (rows is! List) return const [];
      final found = <String>{};
      return [
        for (final row in rows)
          if (row is Map && row['id'] is String && referenced.contains(row['id']))
            if (found.add(row['id'] as String))
              Map<String, dynamic>.from(row)
            else
              throw const ProjectSnapshotException('project.definition_ambiguous',
                  'A selected character definition has duplicate identities.'),
      ];
    }
    projected['characterStudioCatalog'] = {
      'portraitStates': definitions('portraitStates', portraitIds),
      'customAnimationDefinitions': definitions('customAnimationDefinitions', customIds),
    };
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
  if (sceneCondition) {
    for (final entry in selected['maps']?.values ?? <Map<String, dynamic>>[]) {
      final declaration = ProjectMapEntry.fromJson(entry);
      if (maps.containsKey(declaration.id)) continue;
      await read('map:${declaration.id}', declaration.relativePath, required: true);
      final bytes = resources.singleWhere((entry) => entry.identity == 'map:${declaration.id}').bytes!;
      final map = await loader._decodeExecutor.decodeMap(bytes.bytes);
      if (map.id != declaration.id) {
        throw const ProjectSnapshotException('project.map_invalid', 'A dependency map identity differs from its declaration.');
      }
      maps[map.id] = map;
    }
  }
  final rewardSceneIds = <String>{};
  void collectRewardReferences(Object? value) {
    if (value is Map) {
      if (value['rewardReference'] case final Map reference) {
        rewardSceneIds.add(PeriodicRewardReference.fromJson(Map<String, dynamic>.from(reference)).sceneId);
      }
      for (final child in value.values) {
        collectRewardReferences(child);
      }
    } else if (value is List) {
      for (final child in value) {
        collectRewardReferences(child);
      }
    }
  }
  if (sceneCondition) collectRewardReferences(candidates);
  final referenceScenes = <SceneAsset>[];
  for (final id in rewardSceneIds.difference(selected['scenes']?.keys.toSet() ?? {})) {
    final rows = index('scenes')[id] ?? const <Map<String, dynamic>>[];
    if (rows.length > 1) {
      throw const ProjectSnapshotException('project.definition_ambiguous', 'A selected reward source Scene has duplicate identities.');
    }
    for (final row in rows) {
      referenceScenes.add(SceneAsset.fromJson(row));
    }
  }
  if (conditionEvent ||
      conditionRule &&
          _nativeReferenceIds(candidates, const {'eventId'}).isNotEmpty) {
    sections.add('eventRegistry');
    if (raw.containsKey('eventRegistry'))
      projected['eventRegistry'] = raw['eventRegistry'];
  }
  final manifest = ProjectManifest.fromJson(projected);
  if (actionId == 'pokemon.media.write') {
    final path = parameters['relativePath'];
    final document = parameters['document'];
    final speciesId = document is Map ? document['speciesId'] : null;
    if (path is! String ||
        speciesId is! String ||
        speciesId.trim().isEmpty ||
        speciesId != speciesId.trim() ||
        !isCanonicalPokemonMediaStoragePath(
            manifest.pokemon.mediaDir, path, speciesId)) {
      throw const ProjectSnapshotException(
          'project.workshop_dependency_invalid',
          'A Pokemon media edit requires its configured media path and identity.');
    }
    await read(pokemonMediaResourceIdentity(speciesId), path);
  }
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
      (actionId == 'pokemon.ruleset.set' &&
          (parameters['profile'] as Map?)?['profileId'] != PokemonRulesetProfile.contextualProfileId) ||
      actionId == 'campaign.shop.upsert' ||
      _nativeReferenceIds(candidates, const {'itemId', 'ballItemId'})
          .isNotEmpty ||
      manifest.trainers.any((trainer) => trainer.battleItems.isNotEmpty) ||
      (actionId == 'campaign.trainer.upsert' &&
          parameters['value'] is Map &&
          ((parameters['value'] as Map)['battleItems'] is Map &&
           ((parameters['value'] as Map)['battleItems'] as Map).isNotEmpty)) ||
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
  if (actionId == 'scene.graph.patch') {
    final incoming = (parameters['upsertNodes'] as List? ?? const [])
        .whereType<Map>()
        .map((node) => SceneNode.fromJson(Map<String, dynamic>.from(node)))
        .toList();
    final replaced = incoming.map((node) => node.id).toSet();
    final removed = (parameters['removeNodeIds'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final resultingNodes = [
      for (final scene in manifest.scenes.where(
        (scene) => scene.id == parameters['sceneId'],
      ))
        for (final node in scene.graph.nodes)
          if (!replaced.contains(node.id) && !removed.contains(node.id)) node,
      ...incoming,
    ];
    if (sceneNodesNeedPartyMoveCatalog(resultingNodes)) {
      if (manifest.pokemon.catalogFiles['moves'] case final String path) {
        await read('pokemonCatalog:moves', path);
      }
    }
  }
  if (actionId == 'scene.condition.set' &&
      _conditionNeedsPartyMoveCatalog(parameters['conditionSource'])) {
    if (manifest.pokemon.catalogFiles['moves'] case final String path) {
      await read('pokemonCatalog:moves', path);
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
      rewardReferenceScenes: referenceScenes,
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

Future<ProjectSnapshot> _loadNativeMapProperties(
    ProjectSnapshotLoader loader,
    ProjectHandle handle,
    Map<String, dynamic> raw,
    ProjectResourceBytes projectBytes,
    Map<String, Object?> parameters,
    {required String actionId}) async {
  final route = TriggerZoneActions.fieldTraversalActions.contains(actionId);
  final mapId = parameters['mapId'];
  if (mapId is! String || mapId.isEmpty || mapId.trim() != mapId) {
    throw const ProjectSnapshotException(
        'project.map_invalid', 'A map identity is required.');
  }
  final entries = (raw['maps'] as List? ?? const [])
      .whereType<Map>()
      .where((entry) => entry['id'] == mapId)
      .toList();
  if (entries.length != 1) {
    throw const ProjectSnapshotException('project.map_missing',
        'The selected map is not declared exactly once.');
  }
  final declaration =
      ProjectMapEntry.fromJson(Map<String, dynamic>.from(entries.single));
  final access = loader._handles.resolveProject(handle);
  final mapBytes = await access.readResourceBytes(declaration.relativePath);
  final map = await loader._decodeExecutor.decodeMap(mapBytes.bytes);
  if (map.id != mapId ||
      (!route &&
          actionId != 'entity.set_presentation' &&
          map.spatialScene == null)) {
    throw const ProjectSnapshotException(
        'project.map_invalid', 'The selected spatial map identity differs.');
  }
  if (route &&
      !TriggerZoneActions.isFieldTraversalMutation(map, actionId, parameters)) {
    throw const ProjectSnapshotException(
        'project.field_traversal_scope_required',
        'This zone mutation needs its existing reference scope.');
  }
  final visibility = const {
    'map3d.instance.visibility.set',
    'entity.set_presentation'
  }.contains(actionId);
  if (!visibility) MapValidator.validate(map);
  final instance = route || visibility
      ? null
      : map.spatialScene!.instances
          .where((item) => item.id == parameters['instanceId'])
          .firstOrNull;
  final models = route || visibility
      ? const <Map>[]
      : (raw['models3d'] as List? ?? const [])
          .whereType<Map>()
          .where((entry) => entry['id'] == instance?.modelId)
          .toList();
  if (models.length > 1) {
    throw const ProjectSnapshotException(
        'project.model_invalid', 'The selected model identity is duplicated.');
  }
  final version = raw['version'] == null
      ? ProjectVersion.v8
      : ProjectVersion.values
          .where((value) => value.name == raw['version'])
          .firstOrNull;
  if (version == null) {
    throw const ProjectSnapshotException(
        'project.version_unsupported', 'The project version is unknown.');
  }
  var manifest = ProjectManifest(
      name: raw['name'] as String,
      version: version,
      settings: !route && raw['settings'] is Map
          ? ProjectSettings.fromJson(
              Map<String, dynamic>.from(raw['settings'] as Map))
          : const ProjectSettings(),
      tilesets: const [],
      maps: [
        declaration
      ],
      models3d: [
        for (final model in models)
          ProjectModel3dEntry.fromJson(Map<String, dynamic>.from(model))
      ]);
  final referenceScenes = <SceneAsset>[];
  final conditionMaps = <MapData>[];
  final dependencyBytes = <String, ProjectResourceBytes>{};
  final dependencyRevisions = <String, String>{};
  final dependencyPaths = <String, String>{};
  if (visibility) {
    final rawPresentation = parameters['presentation'];
    final presentation = rawPresentation == null
        ? null
        : MapEntityPresentation.fromJson(
            Map<String, dynamic>.from(rawPresentation as Map));
    final dependencies = actionId == 'entity.set_presentation'
        ? ModelVisibilityDependencies.expressions(
            presentation?.variants.map((value) => value.condition) ?? const [])
        : ModelVisibilityDependencies(parameters['visibilityCondition']);
    List<Map<String, dynamic>> select(String field, Set<String> ids) => [
          for (final value in raw[field] as List? ?? const [])
            if (value is Map && ids.contains(value['id']))
              Map<String, dynamic>.from(value),
        ];
    referenceScenes.addAll(
        select('scenes', dependencies.rewardSceneIds).map(SceneAsset.fromJson));
    final registry = raw['eventRegistry'];
    manifest = manifest.copyWith(
      characters: select(
              'characters',
              presentation?.variants
                      .map((value) => value.characterId)
                      .whereType<String>()
                      .toSet() ??
                  const {})
          .map(ProjectCharacterEntry.fromJson)
          .toList(),
      facts: select('facts', dependencies.factIds)
          .map(NarrativeFactDefinition.fromJson)
          .toList(),
      maps: [
        declaration,
        ...select('maps', dependencies.mapIds.difference({mapId}))
            .map(ProjectMapEntry.fromJson)
      ],
      eventRegistry: registry is Map
          ? NarrativeEventRegistry.fromJson({
              ...Map<String, dynamic>.from(registry),
              'records': [
                for (final record in registry['records'] as List? ?? const [])
                  if (record is Map &&
                      dependencies.eventIds.contains(_nativeEventId(record)))
                    record
              ],
              'legacyClaims': const [],
            })
          : null,
    );
    for (final entry in manifest.maps.where((value) => value.id != mapId)) {
      final content = await access.readResourceBytes(entry.relativePath);
      final value = await loader._decodeExecutor.decodeMap(content.bytes);
      if (value.id != entry.id)
        throw const FormatException('native.visibility: map identity mismatch');
      conditionMaps.add(value);
      dependencyBytes['map:${entry.id}'] = content;
      dependencyPaths['map:${entry.id}'] = entry.relativePath;
      dependencyRevisions['map:${entry.id}'] = await loader._decodeExecutor
          .fingerprintResource(content.bytes, relativePath: entry.relativePath);
    }
  }
  if (!await access.matchesResourceBytes('project.json', projectBytes.bytes) ||
      !await access.matchesResourceBytes(
          declaration.relativePath, mapBytes.bytes)) {
    throw const ProjectSnapshotException('project.changed_during_snapshot',
        'The selected map or project changed while reading.');
  }
  final projectRevision = await loader._decodeExecutor
      .fingerprintResource(projectBytes.bytes, relativePath: 'project.json');
  final mapRevision = await loader._decodeExecutor.fingerprintResource(
      mapBytes.bytes,
      relativePath: declaration.relativePath);
  await access.requireReadableProject();
  return ProjectSnapshot(
      projectHandle: handle,
      revision: computeAuthoringJsonFingerprint(
          {'project': projectRevision, 'map:$mapId': mapRevision,
        ...dependencyRevisions
      },
          logicalName: 'native-field-obstacle-selection.json'),
      manifest: manifest,
      maps: [map, ...conditionMaps],
      rewardReferenceScenes: referenceScenes,
      availableProjectSections: route ? const {} : const {'settings'},
      availableProjectDocuments: {
        'maps': {mapId},
        'models3d': {if (instance != null) instance.modelId}
      },
      resourceFingerprints: {
        'project': projectRevision,
        'map:$mapId': mapRevision,
        ...dependencyRevisions
      },
      scopedStorageRevisions: {
        'project.json': projectRevision,
        for (final entry in dependencyPaths.entries)
          entry.value: dependencyRevisions[entry.key]!,
        declaration.relativePath: mapRevision
      },
      ownedResourceBytes: {'project': projectBytes, 'map:$mapId': mapBytes,
        ...dependencyBytes
      },
      resourceStorageKeys: {
        'project': 'project.json',
        'map:$mapId': declaration.relativePath,
        ...dependencyPaths
      });
}

Future<ProjectSnapshot> _loadNativeMapEdit(
    ProjectSnapshotLoader loader,
    ProjectHandle handle,
    Map<String, dynamic> raw,
    ProjectResourceBytes projectBytes,
    Map<String, Object?> parameters) async {
  final mapId = parameters['mapId'];
  if (mapId is! String || mapId.isEmpty || mapId.trim() != mapId) {
    throw const ProjectSnapshotException(
        'project.map_invalid', 'A map identity is required.');
  }
  final rows = (raw['maps'] as List? ?? const [])
      .whereType<Map>()
      .where((entry) => entry['id'] == mapId)
      .toList();
  if (rows.length != 1) {
    throw const ProjectSnapshotException('project.map_missing',
        'The selected map must be declared exactly once.');
  }
  final declaration =
      ProjectMapEntry.fromJson(Map<String, dynamic>.from(rows.single));
  final access = loader._handles.resolveProject(handle);
  final mapBytes = await access.readResourceBytes(declaration.relativePath);
  final map = await loader._decodeExecutor.decodeMap(mapBytes.bytes);
  if (map.id != mapId) {
    throw const ProjectSnapshotException(
        'project.map_invalid', 'The selected map identity differs.');
  }
  final candidates = <Object?>[map.toJson(), parameters];
  final requestedNames = requestedMapEditMaterialNames(parameters);
  if (requestedNames.isNotEmpty) {
    final catalog = raw['smartTileCatalog'];
    if (catalog is Map) {
      for (final field in ['materials', 'presets']) {
        for (final row
            in (catalog[field] as List? ?? const []).whereType<Map>()) {
          if (requestedNames.contains(
                  normalizeMapEditMaterialName(row['id'] as String? ?? '')) ||
              requestedNames.contains(
                  normalizeMapEditMaterialName(row['name'] as String? ?? ''))) {
            candidates.add(
                {field == 'materials' ? 'materialId' : 'presetId': row['id']});
          }
        }
      }
    }
  }

  final selected = <String, dynamic>{
    'name': raw['name'],
    'version': raw['version'],
    'settings': raw['settings'],
    'pokemon': raw['pokemon'],
    'maps': [rows.single],
    'tilesets': <Object?>[],
  };
  final indexes = <String, Map<String, List<Map>>>{};
  final admitted = <String, Set<String>>{};
  final definitions = <String, ({Object? source, Set<String> keys})>{
    for (final field in _nativeWorkshopReferences.entries)
      if (field.key != 'maps')
        field.key: (
          source: raw[field.key],
          keys: {
            ...field.value,
            if (field.key == 'models3d') 'sourceModelId',
            if (field.key == 'elements') 'sourceElementId',
          }
        ),
    'environmentPresets': (
      source: raw['environmentPresets'],
      keys: {'presetId'}
    ),
    'smartTileCatalog.materials': (
      source: (raw['smartTileCatalog'] as Map?)?['materials'],
      keys: {
        'materialId',
        'materialPalette',
        'allowedMaterialIds',
        'defaultMaterialId'
      }
    ),
    'smartTileCatalog.presets': (
      source: (raw['smartTileCatalog'] as Map?)?['presets'],
      keys: {'presetId', 'targetPresetId'}
    ),
    'smartTileCatalog.atlases': (
      source: (raw['smartTileCatalog'] as Map?)?['atlases'],
      keys: {'atlasId'}
    ),
    'smartTileCatalog.patterns': (
      source: (raw['smartTileCatalog'] as Map?)?['patterns'],
      keys: {'patternId'}
    ),
    'borderCatalog.records': (
      source: (raw['borderCatalog'] as Map?)?['records'],
      keys: {'blueprintId', 'targetBlueprintId'}
    ),
    'borderCatalog.visualSnapshots': (
      source: (raw['borderCatalog'] as Map?)?['visualSnapshots'],
      keys: {'snapshotId', 'visualSnapshotId'}
    ),
  };
  final chosen = <String, List<Map>>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final definition in definitions.entries) {
      final wanted = _nativeReferenceIds(candidates, definition.value.keys);
      if (wanted.isEmpty) continue;
      final index = indexes.putIfAbsent(definition.key, () {
        final result = <String, List<Map>>{};
        final source = definition.value.source;
        if (source is List) {
          for (final value in source.whereType<Map>()) {
            if (value['id'] is String) {
              result.putIfAbsent(value['id'] as String, () => []).add(value);
            }
          }
        }
        return result;
      });
      final seen = admitted.putIfAbsent(definition.key, () => {});
      for (final id in wanted) {
        if (!seen.add(id)) continue;
        final found = index[id];
        if (found == null) continue;
        if (found.length != 1) {
          throw const ProjectSnapshotException('project.definition_ambiguous',
              'A selected map dependency has duplicate identities.');
        }
        chosen.putIfAbsent(definition.key, () => []).add(found.single);
        candidates.add(found.single);
        changed = true;
      }
    }
  }
  for (final definition in chosen.entries) {
    final path = definition.key.split('.');
    if (path.length == 1) {
      selected[path.single] = definition.value;
    } else {
      final original = raw[path.first] as Map;
      final catalog = selected.putIfAbsent(
          path.first,
          () => <String, dynamic>{
                if (original.containsKey('formatVersion'))
                  'formatVersion': original['formatVersion'],
                for (final field in original.entries)
                  if (field.value is List) field.key as String: <Object?>[],
              }) as Map;
      catalog[path.last] = definition.value;
    }
  }
  final library = raw['resourceLibraryCatalog'];
  if (library is Map) {
    final resourceIds = admitted.values.expand((ids) => ids).toSet();
    final entries = (library['entries'] as List? ?? const [])
        .whereType<Map>()
        .where((entry) => resourceIds.contains(entry['resourceId']))
        .toList();
    final familyIds = _nativeReferenceIds(entries, {'familyId'});
    var grew = true;
    final families = <Map>[];
    while (grew) {
      grew = false;
      for (final family
          in (library['families'] as List? ?? const []).whereType<Map>()) {
        if (!familyIds.contains(family['id']) || families.contains(family)) {
          continue;
        }
        families.add(family);
        if (family['parentId'] is String &&
            familyIds.add(family['parentId'] as String)) {
          grew = true;
        }
      }
    }
    selected['resourceLibraryCatalog'] = {
      'formatVersion': library['formatVersion'],
      'entries': entries,
      'families': families
    };
  }
  final deletedIds = <String>{};
  void deleted(Object? operation) {
    if (operation is! Map ||
        operation['actionId'] != 'map3d.instance.delete_batch') {
      return;
    }
    final values = operation['parameters'];
    if (values is Map && values['instanceIds'] is List) {
      deletedIds.addAll((values['instanceIds'] as List).whereType<String>());
    }
  }

  if (parameters['operations'] is List) {
    for (final operation in parameters['operations'] as List) {
      deleted(operation);
    }
  } else if (parameters['instanceIds'] is List) {
    deletedIds.addAll((parameters['instanceIds'] as List).whereType<String>());
  }
  if (deletedIds.isNotEmpty) {
    for (final field in [
      'scenes',
      'cinematics',
      'presentationCinematics',
      'worldRules',
      'eventRegistry'
    ]) {
      final referenced = _nativeReferenceIds(
              raw[field], {'instanceId', 'sourceId', 'modelInstanceId'})
          .intersection(deletedIds);
      if (referenced.isNotEmpty) {
        throw ProjectSnapshotException('map3d.instance_referenced',
            'A model instance is referenced by a narrative document and cannot be deleted.');
      }
    }
  }
  final manifest = ProjectManifest.fromJson(selected);
  MapValidator.validate(map, projectDialogueContext: manifest);
  if (!await access.matchesResourceBytes('project.json', projectBytes.bytes) ||
      !await access.matchesResourceBytes(
          declaration.relativePath, mapBytes.bytes)) {
    throw const ProjectSnapshotException('project.changed_during_snapshot',
        'Map dependencies changed while reading.');
  }
  final projectRevision = await loader._decodeExecutor
      .fingerprintResource(projectBytes.bytes, relativePath: 'project.json');
  final mapRevision = await loader._decodeExecutor.fingerprintResource(
      mapBytes.bytes,
      relativePath: declaration.relativePath);
  await access.requireReadableProject();
  return ProjectSnapshot(
      projectHandle: handle,
      revision: computeAuthoringJsonFingerprint(
          {'project': projectRevision, 'map:$mapId': mapRevision},
          logicalName: 'native-map-edit-selection.json'),
      manifest: manifest,
      maps: [
        map
      ],
      availableProjectSections: const {},
      availableProjectDocuments: {
        'maps': {mapId}
      },
      resourceFingerprints: {
        'project': projectRevision,
        'map:$mapId': mapRevision
      },
      scopedStorageRevisions: {
        'project.json': projectRevision,
        declaration.relativePath: mapRevision
      },
      ownedResourceBytes: {
        'project': projectBytes,
        'map:$mapId': mapBytes
      },
      resourceStorageKeys: {
        'project': 'project.json',
        'map:$mapId': declaration.relativePath
      });
}

bool _conditionNeedsPartyMoveCatalog(Object? source) {
  if (source is! Map) return false;
  try {
    return SceneConditionSource.fromJson(Map<String, dynamic>.from(source))
            .partyMoveId !=
        null;
  } on Object {
    return false;
  }
}
