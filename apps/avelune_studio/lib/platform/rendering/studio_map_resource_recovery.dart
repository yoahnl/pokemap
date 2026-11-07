part of 'studio_map_resources.dart';

extension StudioMapResourceRecovery on StudioMapResources {
  Future<void> _retryResources(Iterable<String> resourceIds) async {
    if (_disposed) return;
    final ids = resourceIds
        .where((id) => _diagnostics[id]?.canRetry ?? false)
        .toSet();
    final borderId = 'border:${_activeMap?.id}';
    if (resourceIds.contains(borderId) && borderPreview.issue != null) {
      borderPreview.invalidate(manifest, _activeMap!);
      await borderPreview.settled;
    }
    for (final id in ids) {
      final old = _diagnostics[id];
      if (old == null) continue;
      _diagnostics[id] = WorkspaceResourceDiagnostic(
        resourceId: id,
        name: old.name,
        cause: old.cause,
        detail: old.detail,
        status: WorkspaceResourceStatus.retrying,
        ownerKind: old.ownerKind,
        ownerId: old.ownerId,
        ownerName: old.ownerName,
        role: old.role,
      );
    }
    _notify();
    await Future.wait(
      ids.map(
        (id) => store.request(id, retry: true, retainUntilComplete: true),
      ),
    );
  }

  void _failed(String id, StudioResourceFailure? failure) {
    if (_disposed) return;
    if (failure == null) {
      _diagnostics.remove(id);
    } else {
      final owner = _index.owners[id];
      _diagnostics[id] = WorkspaceResourceDiagnostic(
        resourceId: id,
        name: owner == null
            ? _index.names[id] ?? id
            : '${owner.name} · ${owner.role}',
        cause: failure.cause,
        detail: failure.detail,
        retryable: failure.retryable,
        ownerKind: owner?.kind,
        ownerId: owner?.id,
        ownerName: owner?.name,
        role: owner?.role,
      );
    }
  }

  void _notify() => _changes.emitLater();
}
