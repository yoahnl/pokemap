part of 'element_actions.dart';

AuthoringMutationDraft _buildElementDuplicate(
    AuthoringPlanningContext context, ElementActions actions) {
  final parameters = VisualLibraryParameters(context.request.parameters);
  parameters
      .allow(const {'sourceElementId', 'newElementId', 'name', 'categoryId'});
  final sourceId = parameters.string('sourceElementId');
  final newId = parameters.string('newElementId');
  final categoryId = parameters.string('categoryId');
  final name = resourceInformationName(context.request.parameters['name']);
  final original = context.snapshot.manifest;
  final source =
      original.elements.where((entry) => entry.id == sourceId).firstOrNull;
  if (source == null) {
    throw VisualLibraryException(
        'element.unknown', 'The source décor no longer exists.',
        details: {'elementId': sourceId});
  }
  if (original.elements.any((entry) => entry.id == newId)) {
    throw VisualLibraryException('element.identity_exists',
        'The new décor identity already exists. Nothing was replaced.',
        details: {'elementId': newId});
  }
  _requireElementDuplicateSources(context.snapshot, source);
  final independent = ProjectElementEntry.fromJson(
          jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>)
      .copyWith(id: newId, name: name, categoryId: categoryId);
  final next = actions.upsert(original,
      element: independent, atlases: readTilesetAtlases(original));
  final encoded = _encodeElementDuplicate(context.snapshot, next,
      sourceId: sourceId, newId: newId, name: name, categoryId: categoryId);
  return buildVisualManifestDraft(context.snapshot, next,
      operation: 'element.duplicate',
      path: '/elements/$newId',
      after: independent.toJson(),
      encodedManifest: encoded,
      referenceImpact: {
        'sourceElementId': sourceId,
        'createdElementId': newId,
        'sharedImages': true,
        'mapsUnchanged': true,
        'instancesUnchanged': true,
      });
}

void _requireElementDuplicateSources(
    ProjectSnapshot snapshot, ProjectElementEntry source) {
  final catalogBytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (catalogBytes == null) {
    throw VisualLibraryException('element.source_unsupported',
        'Import the source image as a managed atlas before duplicating this décor.');
  }
  final AssetCatalog catalog;
  try {
    catalog = AssetCatalog.fromJson(
        jsonDecode(utf8.decode(catalogBytes)) as Map<String, dynamic>);
  } on Object {
    throw VisualLibraryException('element.source_unsupported',
        'The source asset catalog cannot be read safely.');
  }
  final requiredIds = {
    source.tilesetId,
    for (final frame in source.frames)
      frame.tilesetId.isEmpty ? source.tilesetId : frame.tilesetId,
  };
  for (final id in requiredIds) {
    final tileset =
        snapshot.manifest.tilesets.where((entry) => entry.id == id).firstOrNull;
    final atlas = tileset?.source;
    if (tileset == null || atlas is! ProjectRegularAtlasTilesetSource) {
      throw VisualLibraryException('element.source_unsupported',
          'Duplication requires a registered regular atlas for every frame.',
          details: {'tilesetId': id});
    }
    final record =
        catalog.records.where((entry) => entry.id == atlas.assetId).firstOrNull;
    final bytes = record == null
        ? null
        : snapshot.findResourceBytes(
            record.logicalPath == assetBlobStorageKey(record.artifact)
                ? assetBlobResourceIdentity(record.artifact.digest)
                : 'assetLogical:${record.id}');
    if (record == null ||
        record.logicalPath != tileset.relativePath ||
        bytes == null ||
        ContentArtifactRef.fromBytes(bytes,
                mediaType: record.artifact.mediaType) !=
            record.artifact) {
      throw VisualLibraryException('element.source_unavailable',
          'A frame source is missing, changed or cannot be certified.',
          details: {'tilesetId': id, 'assetId': atlas.assetId});
    }
  }
}

List<int> _encodeElementDuplicate(
    ProjectSnapshot snapshot, ProjectManifest next,
    {required String sourceId,
    required String newId,
    required String name,
    required String categoryId}) {
  final raw = jsonDecode(utf8.decode(snapshot.resourceBytes('project')))
      as Map<String, dynamic>;
  final source = (raw['elements'] as List)
      .where((entry) => entry is Map && entry['id'] == sourceId)
      .firstOrNull;
  if (source is! Map) {
    throw VisualLibraryException('element.source_unavailable',
        'The persisted décor source is unavailable.');
  }
  final merged =
      jsonDecode(utf8.decode(encodeResourceInformationDocument(snapshot, next)))
          as Map<String, dynamic>;
  final entries = merged['elements'] as List;
  final position = entries.indexWhere((entry) => entry['id'] == newId);
  entries[position] = {
    ...Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map),
    'id': newId,
    'name': name,
    'categoryId': categoryId,
  };
  return utf8.encode(const JsonEncoder.withIndent('  ').convert(merged));
}

void _requireElementDeletionCoverage(
    ProjectSnapshot snapshot, String elementId) {
  if (!snapshot.manifest.elements.any((entry) => entry.id == elementId)) {
    throw VisualLibraryException(
        'element.unknown', 'The décor no longer exists.',
        details: {'elementId': elementId});
  }
  final report = const ResourceUsageProjection()
      .analyze(snapshot, ResourceUsageTarget(family: 'decors', id: elementId));
  final mapIds = snapshot.maps.map((map) => map.id).toSet();
  final requiredMapIds = snapshot.manifest.maps.map((map) => map.id).toSet();
  if (!report.complete ||
      !mapIds.containsAll(requiredMapIds) ||
      !requiredMapIds.containsAll(mapIds)) {
    throw VisualLibraryException('element.usage_inventory_incomplete',
        'The project reference inventory is incomplete. The décor was preserved.',
        details: {
          'elementId': elementId,
          'coverageIssues': report.coverageIssues
        });
  }
  if (report.entries.isNotEmpty) {
    throw VisualLibraryException('element.references_blocking',
        'The décor still has project references and cannot be removed.',
        details: {
          'elementId': elementId,
          'references': [
            for (final entry in report.entries)
              '${entry.ownerKind}:${entry.ownerId}:${entry.location}',
          ],
          'usages': [for (final entry in report.entries) entry.toJson()]
        });
  }
}
