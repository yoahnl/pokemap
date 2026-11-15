part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readMapGroupAdditionsWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final rawAssignments = parameters['assignments'];
  final rawGroups = parameters['groups'];
  if (parameters.keys.any((key) => key != 'groups' && key != 'assignments') ||
      (parameters.containsKey('groups') && rawGroups is! List) ||
      rawAssignments is! List) {
    CatalogWorkshopSelection.unsupported('map.library.reorganize', 'groups and map assignments');
  }
  final mapIds = {
    for (final assignment in rawAssignments)
      if (assignment is Map && assignment['mapId'] is String) assignment['mapId'] as String,
  };
  final selected = await reader.withMetadataFields({'groups'});
  return selected.read((catalog) async {
    final original = catalog.projectMetadata.groups;
    final proposed = rawGroups is List
        ? [for (final value in rawGroups) ProjectMapGroup.fromJson(Map<String, dynamic>.from(value as Map))]
        : original;
    final proposedIds = {for (final group in proposed) group.id};
    if (original.any((group) => !proposedIds.contains(group.id))) {
      CatalogWorkshopSelection.unsupported('map.library.reorganize', 'map folders kept in the targeted organization');
    }
    final ids = <String, Set<String>>{
      'groups': {for (final group in original) group.id, ...proposedIds},
      if (mapIds.isNotEmpty) 'maps': mapIds,
    };
    final documents = await CatalogMetadataDocuments.readDocuments(snapshot: catalog.snapshot,
      project: catalog.projectMetadata.copyWith(maps: const []), ids: ids);
    final bytes = utf8.encode(jsonEncode(documents.project.toJson()));
    final sections = {'groups', if (mapIds.isNotEmpty) 'maps'};
    final snapshot = ProjectSnapshot(projectHandle: projectHandle, materializedCatalogProject: true,
      revision: selected.revision, manifest: documents.project, maps: const [], availableProjectSections: sections,
      availableProjectDocuments: ids, scopedStorageRevisions: const {},
      resourceBytes: {'project': bytes}, resourceStorageKeys: const {'project': 'project.json'},
      resourceFingerprints: {'project': computeAuthoringBytesFingerprint(bytes, logicalName: 'project.json')});
    final result = CatalogWorkshopSelection._(selected, snapshot, sections, const {}, metadataDocuments: documents);
    await result.requireCurrent();
    return result;
  });
}

Future<CatalogWorkshopSelection> _readMapMetadataWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final spatial = await CatalogSpatialMapSelection.read(
      reader: reader,
      projectHandle: projectHandle,
      actionId: 'map.update_metadata',
      parameters: parameters);
  final source = spatial.snapshot;
  final rawRules = parameters['contextualItemUses'];
  if (parameters.containsKey('contextualItemUses') && (rawRules is! List || rawRules.length > 128)) {
    throw const FormatException('A map supports at most 128 contextual item uses.');
  }
  final rules = rawRules == null ? const <ContextualItemUseRule>[] : [for (final raw in rawRules as List)
    ContextualItemUseRule.fromJson(Map<String, dynamic>.from(raw as Map))];
  final dependencies = ModelVisibilityDependencies.expressions(rules.map((rule) => rule.conditionExpression).whereType<NarrativeEventConditionExpression>());
  final selected = await spatial.reader.withMetadataFields({'settings', if (rules.isNotEmpty) 'pokemon'});
  final ids = <String, Set<String>>{
    'maps': {source.maps.single.id, ...dependencies.mapIds},
    if (parameters['escapeRopeDungeonId'] case final String id) 'groups': {id},
    if (rules.isNotEmpty) 'scenes': {for (final rule in rules) rule.sceneId, ...dependencies.rewardSceneIds},
    if (dependencies.factIds.isNotEmpty) 'facts': dependencies.factIds,
  };
  final documents = await selected.read((catalog) => CatalogMetadataDocuments.readDocuments(snapshot: catalog.snapshot,
    project: source.manifest.copyWith(pokemon: rules.isEmpty ? source.manifest.pokemon : catalog.projectMetadata.pokemon), ids: ids));
  final events = dependencies.eventIds.isEmpty ? null : await selected.read((catalog) =>
    CatalogNarrativeEventDocuments.read(catalog.snapshot, dependencies.eventIds));
  final manifest = documents.project.copyWith(eventRegistry: events);
  final revisions = <String, String?>{spatial.storageKey: spatial.mapRevision};
  if (rules.isNotEmpty) await _requireContextualSceneScopes(reader: selected, project: manifest,
    mapId: source.maps.single.id, sceneIds: {for (final rule in rules) rule.sceneId}, revisions: revisions);
  final extraBytes = <String, List<int>>{};
  final extraKeys = <String, String>{};
  final extraFingerprints = <String, String>{};
  final maps = [...source.maps];
  for (final entry in manifest.maps.where((entry) => entry.id != source.maps.single.id)) {
    final payload = await reader.store.gateway.captureResourcePayload(entry.relativePath);
    if (payload == null) throw const FormatException('A contextual condition owner map is missing.');
    try {
      final bytes = await payload.readBytes();
      final map = MapData.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
      if (map.id != entry.id) throw const FormatException('A contextual condition map identity is invalid.');
      maps.add(map);
      extraBytes['map:${entry.id}'] = bytes;
      extraKeys['map:${entry.id}'] = entry.relativePath;
      extraFingerprints['map:${entry.id}'] = payload.resourceRevision;
      revisions[entry.relativePath] = payload.resourceRevision;
    } finally { await payload.release(); }
  }
  ProjectItemCatalog? itemCatalog;
  final itemPath = rules.isEmpty ? null : manifest.pokemon.catalogFiles['items'];
  if (itemPath != null) {
    final payload = await reader.store.gateway.captureResourcePayload(itemPath);
    revisions[itemPath] = payload?.resourceRevision;
    if (payload != null) {
      try {
        final bytes = await payload.readBytes();
        itemCatalog = decodeProjectItemCatalog(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        extraBytes[itemCatalogResourceIdentity] = bytes;
        extraKeys[itemCatalogResourceIdentity] = itemPath;
        extraFingerprints[itemCatalogResourceIdentity] = payload.resourceRevision;
      } finally { await payload.release(); }
    }
  }
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      materializedCatalogProject: true,
      revision: CatalogWorkshopSelection.fingerprint(
          selected.revision, revisions),
      manifest: manifest,
      maps: maps,
      itemCatalog: itemCatalog,
      rewardReferenceScenes: manifest.scenes,
      availableProjectDocuments: ids,
      availableProjectSections: const {'maps'},
      scopedStorageRevisions: revisions,
      resourceBytes: {
        for (final key in source.resourceStorageKeys.keys)
          key: source.resourceBytes(key),
        ...extraBytes, 'project': projectBytes,
      },
      resourceStorageKeys: {...source.resourceStorageKeys, ...extraKeys},
      resourceFingerprints: {...source.resourceFingerprints, ...extraFingerprints,
        'project': computeAuthoringBytesFingerprint(projectBytes, logicalName: 'project.json')});
  final selection = CatalogWorkshopSelection._(
      selected, snapshot, {'maps'}, revisions,
      metadataDocuments: documents);
  await selection.requireCurrent();
  return selection;
}
