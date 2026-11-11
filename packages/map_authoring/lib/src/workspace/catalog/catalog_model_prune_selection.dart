part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readModelPruneWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  final ids = Model3dActions.pruneModelIds(parameters);
  return reader.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    if (!await CatalogReverseReferences.prepared(catalog.snapshot)) {
      throw const CatalogStorageException(
          'catalog.resource_usage.preparation_required',
          'Explicitly prepare resource indexes before library maintenance.');
    }
    final project = await catalog.exportProject();
    final selected =
        project.models3d.where((model) => ids.contains(model.id)).toList();
    if (selected.length != ids.length) {
      throw const FormatException(
          'model3d.prune_unused: unknown model identity');
    }
    final assetPayload = await reader.store.gateway
        .captureResourcePayload(assetCatalogStorageKey);
    if (assetPayload == null) {
      throw const FormatException(
          'model3d.prune_unused: missing asset catalog');
    }
    late final AssetCatalog assets;
    late final String assetRevision;
    try {
      assets = AssetCatalog.fromJson(Map<String, dynamic>.from(
          jsonDecode(utf8.decode(await assetPayload.readBytes())) as Map));
      assetRevision = assetPayload.resourceRevision;
    } finally {
      await assetPayload.release();
    }
    final sources = {
      for (final model in selected)
        model.sourceAssetId: assets.require(model.sourceAssetId)
    };
    if (sources.values.fold<int>(
            0, (total, source) => total + source.artifact.byteLength) >
        Model3dActions.maximumTotalByteLength) {
      throw const FormatException(
          'model3d.prune_unused: selected sources exceed 64 MiB');
    }
    for (final model in selected) {
      if (sources[model.sourceAssetId]!.logicalPath != model.relativePath) {
        throw const FormatException(
            'model3d.prune_unused: inconsistent model source path');
      }
    }
    final resources = <String, String>{
      assetCatalogResourceIdentity: assetCatalogStorageKey,
      for (final source in sources.values)
        'pruneSource:${source.id}': source.logicalPath,
      for (final source in sources.values)
        assetBlobResourceIdentity(source.artifact.digest):
            assetBlobStorageKey(source.artifact),
    };
    final audit = await CatalogResourceIndexSnapshot.read(
        catalog: catalog.snapshot,
        store: reader.store,
        projectHandle: projectHandle,
        completeProject: project,
        additionalResources: resources,
        includeExteriorDecoration: true);
    if (audit.snapshot.resourceFingerprints[assetCatalogResourceIdentity] !=
        assetRevision) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The asset catalog changed during library maintenance.');
    }
    for (final source in sources.values) {
      for (final identity in [
        'pruneSource:${source.id}',
        assetBlobResourceIdentity(source.artifact.digest)
      ]) {
        final bytes = audit.snapshot.resourceBytes(identity);
        if (bytes.length != source.artifact.byteLength ||
            computeAuthoringBytesFingerprint(bytes,
                    logicalName: 'artifact-content') !=
                source.artifact.digest) {
          throw AuthoringPlanException(
              code: 'model3d.prune_source_mismatch',
              message:
                  'Source ${source.id} ($identity) differs from its registered artifact.');
        }
      }
    }
    final units = await catalog.snapshot.readAllUnits();
    final removals = <CatalogDefinitionKey>{};
    final moves = <CatalogDefinitionKey, int>{};
    final counts = <CatalogDefinitionKind, int>{};
    for (final kind in [
      CatalogDefinitionKind.model3d,
      CatalogDefinitionKind.resourceLibraryEntry
    ]) {
      final rows = units.where((unit) => unit.key.kind == kind).toList();
      final count = CatalogResourcePositions.contiguousCount(rows);
      final deleted = rows
          .where((unit) => kind == CatalogDefinitionKind.model3d
              ? ids.contains(unit.key.id)
              : ids.any((id) => unit.key.id == 'model3d:$id'))
          .toList();
      removals.addAll(deleted.map((unit) => unit.key));
      final positions =
          deleted.map((unit) => unit.payload['position'] as int).toSet();
      final remaining = count - deleted.length;
      final holes = positions.where((position) => position < remaining).toList()
        ..sort();
      final tail = rows
          .where((unit) =>
              (unit.payload['position'] as int) >= remaining &&
              !removals.contains(unit.key))
          .toList()
        ..sort((a, b) => (a.payload['position'] as int)
            .compareTo(b.payload['position'] as int));
      for (var index = 0; index < holes.length; index++) {
        moves[tail[index].key] = holes[index];
      }
      counts[kind] = remaining;
    }
    final result = CatalogWorkshopSelection._(
        reader,
        audit.snapshot,
        {'models3d', 'resourceLibraryCatalog'},
        {
          for (final path in resources.values)
            path: audit.snapshot.scopedStorageRevisions![path]
        },
        resourceCounts: counts,
        resourceRemovals: removals,
        resourceMoves: moves,
        maintenanceRevision: audit.currentRevision);
    await result.requireCurrent();
    return result;
  });
}
