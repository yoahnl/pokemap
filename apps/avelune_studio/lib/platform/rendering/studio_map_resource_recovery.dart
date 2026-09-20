part of 'studio_map_resources.dart';

extension StudioMapResourceRecovery on StudioMapResources {
  Future<void> _retryResources(Iterable<String> resourceIds) async {
    if (_disposed) return;
    final ids = resourceIds
        .where((id) => _diagnostics[id]?.canRetry ?? false)
        .toSet();
    for (final id in ids) {
      final old = _diagnostics[id];
      if (old == null) continue;
      _diagnostics[id] = WorkspaceResourceDiagnostic(
        resourceId: id,
        name: old.name,
        cause: old.cause,
        detail: old.detail,
        status: WorkspaceResourceStatus.retrying,
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
      _diagnostics[id] = WorkspaceResourceDiagnostic(
        resourceId: id,
        name: _index.names[id] ?? id,
        cause: failure.cause,
        detail: failure.detail,
        retryable: failure.retryable,
      );
    }
  }

  void _notify() => _changes.emitLater();
}
