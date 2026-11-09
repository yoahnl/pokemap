part of 'catalog_resource_usage_index.dart';

abstract final class _CatalogResourceUsageMutation {
  static Future<List<CatalogDefinitionUnit>> maintain({
    required CatalogSnapshot snapshot,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
    required Iterable<AuthoringResourceChange> additionalChanges,
    Iterable<CatalogDefinitionUnit> restoredExternalSources = const [],
  }) async {
    if (!await CatalogResourceUsageIndex.prepared(snapshot)) return [];
    final pending = {for (final unit in upserts) unit.key: unit};
    final removed = removals.toSet();
    Future<CatalogDefinitionUnit?> lookup(CatalogDefinitionKey key) async =>
        removed.contains(key)
            ? null
            : pending[key] ?? await snapshot.lookup(key);
    final updated = <String, _UsageSource?>{};
    for (final key in {...pending.keys, ...removed}) {
      if (key.kind == CatalogDefinitionKind.workspaceState) continue;
      final unit = pending[key];
      updated[CatalogResourceUsageIndex._source(key)] =
          unit == null ? null : await _catalogUsageSource(unit, lookup);
    }
    for (final change in additionalChanges) {
      var kind = change.resource.kind;
      var id = change.resource.id;
      if (kind == 'pokemonDocument' && id.startsWith('media:')) {
        kind = 'pokemonMedia';
        id = id.substring('media:'.length);
      }
      if (change.storageKey == projectMediaCatalogStorageKey) {
        kind = 'projectMediaCatalog';
      }
      if (!const {'map', 'dialogue', 'projectMediaCatalog', 'pokemonMedia'}
          .contains(kind)) {
        continue;
      }
      final payload = change.afterPayload;
      final documentKind = kind == 'dialogue' ? 'dialogueSource' : kind;
      if (kind == 'projectMediaCatalog') {
        final previous = change.beforePayload == null
            ? const <ProjectMediaAsset>[]
            : decodeProjectMediaCatalogBytes(
                    await change.beforePayload!.readBytes())
                .entries;
        final next = payload == null
            ? const <ProjectMediaAsset>[]
            : decodeProjectMediaCatalogBytes(await payload.readBytes()).entries;
        final entries = {for (final entry in next) entry.id: entry};
        for (final mediaId in {
          ...previous.map((entry) => entry.id),
          ...entries.keys
        }) {
          final entry = entries[mediaId];
          updated['external:media:$mediaId'] = entry == null
              ? null
              : (
                  owner: 'media:$mediaId',
                  targets: _usageSource(ResourceUsageDocument(
                          'media',
                          mediaId,
                          mediaId,
                          change.storageKey,
                          Map<String, dynamic>.from(entry.toJson())))
                      .targets,
                  revision: change.afterRevision
                );
        }
        continue;
      }
      final source = 'external:$documentKind:$id';
      if (payload == null) {
        updated[source] = null;
        continue;
      }
      final bytes = await payload.readBytes();
      final Map<String, dynamic> value;
      if (kind == 'dialogue') {
        final entryUnit =
            await lookup(CatalogMetadataDocuments.documentKey('dialogues', id));
        final position = entryUnit?.payload['position'];
        if (position is! int) {
          throw const FormatException(
              'catalog.resource_usage.dialogue_missing');
        }
        final definition = await lookup(
            CatalogMetadataDocuments.definitionKey('dialogues', position));
        final entry = ProjectDialogueEntry.fromJson(Map<String, dynamic>.from(
            (definition!.payload['value'] as Map)['definition'] as Map));
        final compiled = const DialogueAuthoringCompiler()
            .compile(entry: entry, source: utf8.decode(bytes));
        if (!compiled.canPublish || compiled.document == null) {
          throw const FormatException(
              'catalog.resource_usage.dialogue_invalid');
        }
        value = compiled.document!.toJson();
      } else {
        value =
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
      }
      final document = _usageSource(ResourceUsageDocument(
          documentKind, id, id, change.storageKey, value));
      updated[source] = (
        owner: document.owner,
        targets: document.targets,
        revision: change.afterRevision
      );
    }
    for (final unit in restoredExternalSources) {
      final identity = unit.payload['identity'] as String;
      if (!identity.startsWith('external:') ||
          CatalogResourceUsageIndex._key('resourceUsageSource', identity) !=
              unit.key) {
        throw const FormatException('catalog.resource_usage.source_identity');
      }
      updated[identity] = (
        owner: unit.payload['owner'] as String,
        targets: CatalogResourceUsageIndex._strings(unit, identity, 'targets'),
        revision: unit.payload['resourceRevision'] as String?
      );
    }
    return _maintainSources(snapshot, updated);
  }

  static Future<List<CatalogDefinitionUnit>> _maintainSources(
      CatalogSnapshot snapshot, Map<String, _UsageSource?> updated) async {
    final result = <CatalogDefinitionUnit>[];
    final facets = <String, Set<String>>{};
    Future<Set<String>> facet(String identity) async =>
        facets[identity] ??= CatalogResourceUsageIndex._strings(
            await snapshot.lookup(CatalogResourceUsageIndex._key(
                'resourceUsageConsumers', identity)),
            identity,
            'sources');
    for (final entry in updated.entries) {
      final source = entry.key;
      final old = await snapshot.lookup(
          CatalogResourceUsageIndex._key('resourceUsageSource', source));
      final previous =
          CatalogResourceUsageIndex._strings(old, source, 'targets');
      final next = entry.value?.targets ?? const <String>{};
      if (old == null &&
          (entry.value == null ||
              next.isEmpty && !source.startsWith('external:'))) {
        continue;
      }
      for (final target in previous.difference(next)) {
        (await facet(target)).remove(source);
      }
      for (final target in next.difference(previous)) {
        (await facet(target)).add(source);
      }
      final row = CatalogResourceUsageIndex._document(
          source, entry.value?.owner ?? old!.payload['owner'] as String, next,
          revision: entry.value?.revision);
      if (old == null ||
          old.payload['owner'] != row.payload['owner'] ||
          old.payload['resourceRevision'] != row.payload['resourceRevision'] ||
          previous.length != next.length ||
          !previous.containsAll(next)) {
        result.add(row);
      }
    }
    for (final entry in facets.entries) {
      result.add(CatalogResourceUsageIndex._consumers(entry.key, entry.value));
    }
    return result;
  }
}
