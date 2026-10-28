part of 'catalog_workshop_selection.dart';

const _nativeResourceActions = <String, (CatalogDefinitionKind, String)>{
  'characterStudio.animationClip.upsert': (CatalogDefinitionKind.character, 'characterId'),
  'tileset.upsert': (CatalogDefinitionKind.tileset, 'tileset'),
  'campaign.character.upsert': (CatalogDefinitionKind.character, 'value'),
  'resource.classify_batch': (CatalogDefinitionKind.resourceLibraryEntry, 'entries'),
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
  if (parameters.containsKey('layer') || parameters.containsKey('draftId')) {
    CatalogWorkshopSelection.unsupported(
        actionId, 'standalone new resource publication');
  }
  final clip = actionId == 'characterStudio.animationClip.upsert';
  if (clip && parameters['kind'] != 'system') {
    CatalogWorkshopSelection.unsupported(actionId, 'a system animation slot');
  }
  final value = clip ? {'id': parameters[parameter]} : parameters[parameter];
  final inputs = value is List ? value : [value];
  final ids = <String>{};
  for (final input in inputs) {
    final id = kind == CatalogDefinitionKind.resourceLibraryEntry && input is Map
        ? '${input['resourceKind']}:${input['resourceId']}' : publishingBorder
        ? input
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
    final count = await CatalogResourcePositions.read(catalog.snapshot, kind);
    final roots = <CatalogDefinitionKey>{};
    final replacements = <CatalogDefinitionKey>{};
    final drafts = <BorderBlueprintRecord>[];
    final candidates = <Object?>[parameters];
    if (kind == CatalogDefinitionKind.resourceLibraryEntry) {
      for (final input in inputs.cast<Map>()) {
        if (input['mapId'] != null || input['resourceKind'] is! String || input['resourceId'] is! String) {
          CatalogWorkshopSelection.unsupported(actionId, 'new global classifications only');
        }
        final resourceKind = catalogResourceKinds[input['resourceKind']];
        if (resourceKind == null) throw const FormatException('Unknown classification resource kind.');
        roots.add(CatalogDefinitionKey(resourceKind, input['resourceId'] as String));
        final family = input['familyId'];
        if (family is String && !ResourceLibraryCatalog.predefinedFamilies.any((x) => x.id == family)) {
          roots.add(CatalogDefinitionKey(CatalogDefinitionKind.resourceFamily, family));
        }
      }
    }
    for (final id in ids) {
      final key = CatalogDefinitionKey(kind, id);
      final existing = await catalog.lookup(key);
      if (publishingBorder) {
        if (existing == null) {
          throw const FormatException(
              'catalog.native_resource: Border draft missing');
        }
        final record = decodeBorderBlueprintRecordJson(
            existing.payload['value'],
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
        if (record.latestPublished != null ||
            !record.draft.definition.isSpatial) {
          CatalogWorkshopSelection.unsupported(
              actionId, 'first publication of a spatial Border draft');
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
      } else if (clip) {
        throw const FormatException('catalog.character_clip: character missing');
      } else if (existing != null) {
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
    var manifest = await ProjectCatalogSelection(catalog).resolve(roots);
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
    final section = CatalogResourcePositions.sections[kind]!.split('.').first;
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        materializedCatalogProject: true,
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
        resourceCounts: {kind: count}, resourceReplacements: replacements);
    await result.requireCurrent();
    return result;
  });
}
