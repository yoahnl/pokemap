part of 'local_resource_adapter.dart';

ResourceMutationReceipt _resourceReceipt(
  ProjectManifest before,
  String beforeRevision,
  AuthoringPlan plan,
  String? createdTilesetId,
  String operationId,
) {
  final changes = plan.changeSet.changes;
  final manifestChanges = changes.where((c) => c.storageKey == 'project.json');
  if (manifestChanges.length > 1) {
    throw const ResourceFailure(
      'Plusieurs écritures concurrentes du manifeste.',
    );
  }
  final bytes = manifestChanges.firstOrNull?.afterBytes;
  if (manifestChanges.isNotEmpty && bytes == null) {
    throw const ResourceFailure('Le manifeste ne peut pas être supprimé.');
  }
  final manifest = bytes == null
      ? before
      : ProjectManifest.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        );
  if (plan.request.actionId != 'map.library.reorganize' &&
      jsonEncode(before.maps) != jsonEncode(manifest.maps)) {
    throw const ResourceFailure(
      'Une ressource ne peut pas remplacer le catalogue de cartes.',
    );
  }
  return ResourceMutationReceipt(
    before: before,
    manifest: manifest,
    beforeRevision: beforeRevision,
    revision: bytes == null
        ? beforeRevision
        : narrativeEventBytesFingerprint(bytes),
    changedPaths: List.unmodifiable(changes.map((c) => c.storageKey)),
    createdTilesetId: createdTilesetId,
    operationId: operationId,
    actionId: plan.request.actionId,
    snapshotBeforeRevision: plan.baseRevision,
    resourceRevisions: Map.unmodifiable({
      for (final change in changes)
        '${change.resource.kind}:${change.resource.id}': change.afterRevision,
    }),
    pathRevisions: Map.unmodifiable({
      for (final change in changes) change.storageKey: change.afterRevision,
    }),
    changedMaps: Map.unmodifiable({
      if (plan.request.actionId == 'characterStudio.character.delete')
        for (final change in changes.where((c) => c.resource.kind == 'map'))
          change.resource.id: MapData.fromJson(
            jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
          ),
    }),
    mapRevisions: Map.unmodifiable({
      if (plan.request.actionId == 'characterStudio.character.delete')
        for (final change in changes.where((c) => c.resource.kind == 'map'))
          change.resource.id: narrativeEventBytesFingerprint(
            change.afterBytes!,
          ),
    }),
  );
}
