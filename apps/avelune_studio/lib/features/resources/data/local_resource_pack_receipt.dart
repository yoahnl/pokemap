part of 'local_resource_pack_adapter.dart';

extension _LocalResourcePackReceipt on LocalResourcePackAdapter {
  Future<ResourceMutationReceipt> _acceptApplied(
    _PackSession active,
    Map<String, Object?> projection,
  ) async {
    final json = Map<String, Object?>.from(projection['receipt']! as Map);
    if (!const {'applied', 'recovered'}.contains(json['status']) ||
        json['actionId'] != 'resource_pack.import') {
      throw const ResourceFailure(
        'Le reçu ne confirme pas un import appliqué.',
      );
    }
    final snapshot = await active.loader.load(
      active.opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.editorReadProjection,
    );
    final paths = <String, String?>{}, revisions = <String, String?>{};
    Future<void> consume(List<dynamic> entries) async {
      for (final value in entries) {
        final row = Map<String, Object?>.from(value as Map);
        if (row['resource'] is! Map || row['after'] is! Map) {
          throw const ResourceFailure(
            'Le reçu de l’import ne peut pas être relu.',
          );
        }
        final ref = Map<String, Object?>.from(row['resource']! as Map);
        final kind = ref['kind']! as String, id = ref['id']! as String;
        final identity = switch (kind) {
          'project' => 'project',
          'assetCatalog' => 'assetCatalog',
          'catalogHead' => 'catalogHead',
          'asset'
              when snapshot.resourceStorageKeys.containsKey(
                'assetLogical:$id',
              ) =>
            'assetLogical:$id',
          'assetBlob' => 'assetBlob:$id',
          _ => '$kind:$id',
        };
        final revision = (row['after']! as Map)['revision'] as String?;
        final path = snapshot.resourceStorageKeys[identity];
        if (path == null ||
            revision == null ||
            snapshot.resourceFingerprints[identity] != revision) {
          throw const ResourceFailure(
            'Une ressource importée a changé avant la relecture.',
          );
        }
        paths[path] = revision;
        revisions['$kind:$id'] = revision;
      }
    }

    final diff = Map<String, Object?>.from(json['diff']! as Map);
    if (diff['entries'] is List) {
      await consume(diff['entries']! as List);
    } else {
      var cursor = null as String?;
      do {
        final page = await active.mutations.readMutationDiffPage(
          active.opened.projectHandle,
          diffRef: diff['diffRef']! as String,
          cursor: cursor,
          limit: 100,
        );
        await consume(page['entries']! as List);
        final next = page['nextCursor'] as String?;
        if (next != null && next == cursor) {
          throw const ResourceFailure('Le reçu de l’import ne progresse plus.');
        }
        cursor = next;
      } while (cursor != null);
    }
    _requireActive();
    final before = _before!;
    final receipt = ResourceMutationReceipt(
      before: before.manifest,
      manifest: snapshot.manifest,
      beforeRevision: before.revision,
      revision: studioProjectSnapshotRevision(snapshot),
      changedPaths: List.unmodifiable(paths.keys),
      pathRevisions: Map.unmodifiable(paths),
      resourceRevisions: Map.unmodifiable(revisions),
      operationId: _operationId,
      actionId: 'resource_pack.import',
      snapshotBeforeRevision: json['beforeRevision'] as String?,
    );
    try {
      await resources.beforeReconciliation?.call();
      _requireActive();
      await mapAdapter.acceptResourceMutation(session, receipt);
    } on Object catch (failure) {
      throw ResourceFailure(
        'Import terminé — relire la bibliothèque. $failure',
        partialReceipt: receipt,
      );
    }
    return receipt;
  }
}
