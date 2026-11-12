part of 'catalog_workshop_selection.dart';

const _nativeResourceActions = <String, (CatalogDefinitionKind, String)>{
  'characterStudio.animationClip.upsert': (CatalogDefinitionKind.character, 'characterId'),
  'tileset.upsert': (CatalogDefinitionKind.tileset, 'tileset'),
  'campaign.character.upsert': (CatalogDefinitionKind.character, 'value'),
  'resource.classify': (CatalogDefinitionKind.resourceLibraryEntry, ''),
  'resource.classify_batch': (CatalogDefinitionKind.resourceLibraryEntry, 'entries'),
  'resource.family.create': (CatalogDefinitionKind.resourceFamily, ''),
  'resource.family.update': (CatalogDefinitionKind.resourceFamily, ''),
  'resource.family.delete': (CatalogDefinitionKind.resourceFamily, ''),
  'smart_tile.atlas.upsert': (CatalogDefinitionKind.smartTileAtlas, 'atlas'),
  'smart_tile.animation.upsert': (CatalogDefinitionKind.smartTileAnimation, 'animation'),
  'smart_tile.material.upsert_batch': (
    CatalogDefinitionKind.smartTileMaterial,
    'materials'
  ),
  'smart_tile.pattern.upsert': (
    CatalogDefinitionKind.smartTilePattern,
    'pattern'
  ),
  'smart_tile.pattern.upsert_batch': (
    CatalogDefinitionKind.smartTilePattern,
    'patterns'
  ),
  'smart_tile.preset.publish': (
    CatalogDefinitionKind.smartTilePreset,
    'preset'
  ),
  'border.blueprint.draft.upsert': (
    CatalogDefinitionKind.borderRecord,
    'record'
  ),
  'border.blueprint.publish': (
    CatalogDefinitionKind.borderRecord,
    'blueprintId'
  ),
  'border.blueprint.set_deprecated': (
    CatalogDefinitionKind.borderRecord,
    'blueprintId'
  ),
  'environment.preset.upsert': (
    CatalogDefinitionKind.environmentPreset,
    'preset'
  ),
};

Future<CatalogWorkshopSelection> _readNativeResourceWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
}) async {
  final (kind, parameter) = _nativeResourceActions[actionId]!;
  final publishingBorder = actionId == 'border.blueprint.publish';
  final deprecatingBorder = actionId == 'border.blueprint.set_deprecated';
  if (parameters.containsKey('layer') || parameters.containsKey('draftId')) {
    CatalogWorkshopSelection.unsupported(
        actionId, 'standalone new resource publication');
  }
  final clip = actionId == 'characterStudio.animationClip.upsert';
  if (clip && parameters['kind'] != 'system') {
    CatalogWorkshopSelection.unsupported(actionId, 'a system animation slot');
  }
  final family = kind == CatalogDefinitionKind.resourceFamily;
  final value = clip
      ? {'id': parameters[parameter]}
      : actionId == 'resource.classify' || family
          ? parameters
          : parameters[parameter];
  final inputs = value is List ? value : [value];
  final ids = <String>{};
  for (final input in inputs) {
    final id = kind == CatalogDefinitionKind.resourceLibraryEntry && input is Map
        ? '${input['resourceKind']}:${input['resourceId']}' : publishingBorder || deprecatingBorder
        ? input
        : family && input is Map
        ? input['familyId']
        : input is Map
            ? input['id']
            : null;
    if (id is! String || id.isEmpty || id.trim() != id || !ids.add(id)) {
      throw const FormatException(
          'catalog.native_resource: unique target identities required');
    }
  }
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final roots = <CatalogDefinitionKey>{};
    final replacements = <CatalogDefinitionKey>{};
    final removals = <CatalogDefinitionKey, int>{};
    final moves = <CatalogDefinitionKey, int>{};
    final drafts = <BorderBlueprintRecord>[];
    final candidates = <Object?>[parameters];
    final usageMaps = <String, Set<String>>{};
    final scopedMapIds = <String>{};
    var count = 0;
    if (family) {
      count = await CatalogResourcePositions.read(catalog.snapshot, kind);
      final key = CatalogDefinitionKey(kind, ids.single);
      final existing = await catalog.lookup(key);
      if (existing != null) {
        roots.add(key);
        replacements.add(key);
      }
      final parent = parameters['parentId'];
      if (parent is String && !ResourceLibraryCatalog.predefinedFamilies.any((family) => family.id == parent)) {
        roots.add(CatalogDefinitionKey(kind, parent));
      }
      if (actionId == 'resource.family.delete' && existing != null) {
        if (!await CatalogReverseReferences.prepared(catalog.snapshot)) {
          throw const CatalogStorageException('catalog.resource_usage.preparation_required',
              'Explicitly prepare resource indexes before deleting a family.');
        }
        if (await CatalogResourceUsageIndex.familyHasMembers(catalog.snapshot, key.id) ||
            (await CatalogReverseReferences.consumers(catalog.snapshot, key)).isNotEmpty) {
          throw VisualLibraryException('resource_library.family_not_empty',
              'Move the classified resources and child families before deleting this family.');
        }
        final position = existing.payload['position'];
        if (position is! int || position < 0 || position >= count) {
          throw const FormatException('catalog.native_resource: family position');
        }
        removals[key] = position;
        if (position != count - 1) {
          final lastId = await CatalogResourcePositions.readSlot(catalog.snapshot, kind, count - 1);
          final mover = CatalogDefinitionKey(kind, lastId);
          roots.add(mover);
          moves[mover] = position;
        }
        count--;
      }
    } else {
      count = await CatalogResourcePositions.read(catalog.snapshot, kind);
    }
    if (kind == CatalogDefinitionKind.resourceLibraryEntry) {
      for (final input in inputs.cast<Map>()) {
        if (input['resourceKind'] is! String || input['resourceId'] is! String) {
          CatalogWorkshopSelection.unsupported(actionId, 'typed classifications');
        }
        final resourceKind = catalogResourceKinds[input['resourceKind']];
        if (resourceKind == null) throw const FormatException('Unknown classification resource kind.');
        roots.add(CatalogDefinitionKey(resourceKind, input['resourceId'] as String));
        final family = input['familyId'];
        if (family is String && !ResourceLibraryCatalog.predefinedFamilies.any((x) => x.id == family)) {
          roots.add(CatalogDefinitionKey(CatalogDefinitionKind.resourceFamily, family));
        }
        final key = CatalogDefinitionKey(kind,
            '${input['resourceKind']}:${input['resourceId']}');
        final existing = await catalog.lookup(key);
        final previous = existing == null ? const <String, Object?>{} : Map<String, Object?>.from(
            existing.payload['value'] as Map);
        Object? field(String name) =>
            input.containsKey(name) ? input[name] : previous[name];
        final mapId = field('mapId');
        if (mapId is String) {
          scopedMapIds.add(mapId);
          usageMaps[key.id] = await CatalogResourceUsageIndex.mapUsages(
              catalog.snapshot, input['resourceKind'] as String, input['resourceId'] as String,
              const [], readMapIds: () async => (await reader.readMetadata({'maps'})).maps.map((map) => map.id));
        }
        if (existing == null) continue;
        if (mapId == null && field('familyId') == null &&
            field('description') == null &&
            field('placementContext') == null &&
            field('category') == null &&
            (field('role') ?? 'standard') == 'standard') {
          final position = existing.payload['position'];
          if (position is! int || position < 0 || position >= count) {
            throw const FormatException(
                'catalog.native_resource: classification position');
          }
          removals[key] = position;
        } else {
          replacements.add(key);
        }
      }
      if (removals.isNotEmpty) {
        final remaining = count - removals.length;
        final holes = removals.values.where((p) => p < remaining).toList()
          ..sort();
        final movers = <int>[
          for (var position = remaining; position < count; position++)
            if (!removals.containsValue(position)) position
        ];
        for (var index = 0; index < holes.length; index++) {
          final String identity;
          try {
            identity = await CatalogResourcePositions.readSlot(
                catalog.snapshot, kind, movers[index]);
          } on FormatException {
            CatalogWorkshopSelection.unsupported(
                actionId, 'a prepared classification position index');
          }
          final mover = CatalogDefinitionKey(kind, identity);
          if ((await catalog.lookup(mover))?.payload['position'] !=
              movers[index]) {
            CatalogWorkshopSelection.unsupported(
                actionId, 'a current classification position index');
          }
          moves[mover] = holes[index];
        }
        count = remaining;
      }
    }
    for (final id in ids) {
      final key = CatalogDefinitionKey(kind, id);
      final existing = await catalog.lookup(key);
      if (publishingBorder || deprecatingBorder) {
        if (existing == null) {
          throw const FormatException(
              'catalog.native_resource: Border draft missing');
        }
        final record = decodeBorderBlueprintRecordJson(
            existing.payload['value'],
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
        if (publishingBorder && !record.draft.definition.isSpatial) {
          CatalogWorkshopSelection.unsupported(
              actionId, 'a spatial Border draft');
        }
        if (publishingBorder && record.latestPublished != null) {
          final encoded = encodeBorderBlueprintRecordJson(record,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
          if (canonicalAuthoringJson((encoded['draft'] as Map)['definition']) ==
              canonicalAuthoringJson(
                  (encoded['latestPublished'] as Map)['definition'])) {
            throw AuthoringPlanException(
                code: 'border.blueprint.no_change',
                message: 'The draft already matches the published spatial Border.');
          }
        }
        drafts.add(record);
        candidates.add(existing.payload['value']);
        replacements.add(key);
      } else if (clip && existing != null) {
        roots.add(key);
        replacements.add(key);
        candidates.add(existing.payload['value']);
      } else if (existing != null && kind == CatalogDefinitionKind.character) {
        final before = ProjectCharacterEntry.fromJson(
            Map<String, dynamic>.from(existing.payload['value'] as Map));
        final after = ProjectCharacterEntry.fromJson(
            Map<String, dynamic>.from(value as Map));
        if (after.copyWith(animations: before.animations) != before ||
            before.animations.any((clip) => !after.animations.contains(clip)) ||
            after.animations
                    .map((clip) => (clip.state, clip.direction))
                    .toSet()
                    .length !=
                after.animations.length) {
          CatalogWorkshopSelection.unsupported(actionId,
              'preserving the character and every existing animation slot');
        }
        roots.add(key);
        replacements.add(key);
      } else if (actionId == 'border.blueprint.draft.upsert' && existing != null) {
        final before = decodeBorderBlueprintRecordJson(
            existing.payload['value'],
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
        if (!before.draft.definition.isSpatial) {
          CatalogWorkshopSelection.unsupported(
              actionId, 'a spatial Border draft');
        }
        drafts.add(before);
        replacements.add(key);
        candidates.add(existing.payload['value']);
      } else if (clip) {
        throw const FormatException('catalog.character_clip: character missing');
      } else if (existing != null &&
          kind != CatalogDefinitionKind.resourceLibraryEntry &&
          !family) {
        CatalogWorkshopSelection.unsupported(
            actionId, 'a new resource identity');
      }
    }
    for (final (dependencyKind, keys) in const [
      (CatalogDefinitionKind.tileset, {'tilesetId'}),
      (CatalogDefinitionKind.model3d, {'modelId', 'sourceModelId'}),
      (CatalogDefinitionKind.element, {'elementId', 'sourceElementId'}),
      (CatalogDefinitionKind.smartTileAtlas, {'atlasId'}),
      (
        CatalogDefinitionKind.smartTileMaterial,
        {'materialId', 'defaultMaterialId', 'allowedMaterialIds'}
      ),
      (CatalogDefinitionKind.smartTileAnimation, {'animationId'}),
      (CatalogDefinitionKind.smartTilePattern, {'patternId'}),
      (
        CatalogDefinitionKind.smartTilePreset,
        {'presetId', 'sourceSmartTilePresetId'}
      ),
    ]) {
      for (final id
          in CatalogWorkshopSelection._referenceIds(candidates, keys)) {
        final key = CatalogDefinitionKey(dependencyKind, id);
        if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
      }
    }
    final categoryKind = kind == CatalogDefinitionKind.environmentPreset ||
            kind == CatalogDefinitionKind.borderRecord
        ? CatalogDefinitionKind.elementCategory
        : CatalogDefinitionKind.smartTileCategory;
    for (final id
        in CatalogWorkshopSelection._referenceIds(candidates, {'categoryId'})) {
      roots.add(CatalogDefinitionKey(categoryKind, id));
    }
    final familyRoots = roots.where((key) => key.kind == CatalogDefinitionKind.resourceFamily).toList();
    for (var i = 0; i < familyRoots.length; i++) {
      final unit = await catalog.lookup(familyRoots[i]);
      final parent = (unit?.payload['value'] as Map?)?['parentId'];
      if (parent is! String || ResourceLibraryCatalog.predefinedFamilies.any((family) => family.id == parent)) continue;
      final key = CatalogDefinitionKey(CatalogDefinitionKind.resourceFamily, parent);
      if (roots.add(key)) familyRoots.add(key);
      if (familyRoots.length > catalog.snapshot.limits.maxClosureNodes) {
        throw const FormatException('catalog.native_resource: family depth');
      }
    }
    var manifest = await ProjectCatalogSelection(catalog).resolve(roots);
    for (final entry in manifest.resourceLibraryCatalog.entries) {
      if (entry.mapId == null) continue;
      scopedMapIds.add(entry.mapId!);
      usageMaps[entry.identity] ??= await CatalogResourceUsageIndex.mapUsages(
          catalog.snapshot, entry.resourceKind, entry.resourceId, const [],
          readMapIds: () async => (await reader.readMetadata({'maps'})).maps.map((map) => map.id));
    }
    if (scopedMapIds.isNotEmpty) {
      final documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: manifest, ids: {'maps': scopedMapIds});
      manifest = manifest.copyWith(maps: [
        for (final entry in documents.project.maps)
          ProjectMapEntry(id: entry.id, name: entry.name, relativePath: entry.relativePath),
      ]);
    }
    if (drafts.isNotEmpty) {
      manifest = manifest.copyWith(
          borderCatalog: ProjectBorderCatalog(
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
              records: [...manifest.borderCatalog.records, ...drafts],
              visualSnapshots: manifest.borderCatalog.visualSnapshots));
    }
    final settings = manifest.settings;
    manifest = manifest.copyWith(
        settings: ProjectSettings(
            dimension: settings.dimension,
            spatialCamera: settings.spatialCamera,
            tileWidth: settings.tileWidth,
            tileHeight: settings.tileHeight));
    final values = <String, List<int>>{};
    final paths = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> readFile(String identity, String path) async {
      if (revisions.containsKey(path)) return;
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        values[identity] = await payload.readBytes();
        paths[identity] = path;
      } finally {
        await payload.release();
      }
    }

    if (actionId == 'smart_tile.atlas.upsert' || actionId == 'tileset.upsert') {
      await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
      final bytes = values[assetCatalogResourceIdentity];
      if (bytes != null) {
        final assets = AssetCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        for (final tileset in manifest.tilesets) {
          final asset = assets.records
              .where((asset) => asset.logicalPath == tileset.relativePath)
              .firstOrNull;
          if (asset != null) {
            await readFile(assetBlobResourceIdentity(asset.artifact.digest),
                assetBlobStorageKey(asset.artifact));
          }
        }
      }
    }
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final section =
        CatalogResourcePositions.sectionOf(kind)!.split('.').first;
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        materializedCatalogProject: true,
        resourceLibraryMapUsageOverrides: usageMaps,
        revision:
            CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
        manifest: manifest,
        maps: const [],
        availableProjectSections: {
          'settings',
          section
        },
        resourceBytes: {
          ...values,
          'project': bytes
        },
        resourceStorageKeys: {
          ...paths,
          'project': 'project.json'
        },
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json'),
          for (final entry in paths.entries) entry.key: revisions[entry.value]!,
        });
    final result = CatalogWorkshopSelection._(
        selected, snapshot, {section}, revisions,
        resourceCounts: {kind: count}, resourceReplacements: replacements,
        resourceRemovals: removals.keys.toSet(), resourceMoves: moves);
    await result.requireCurrent();
    return result;
  });
}
