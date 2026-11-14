part of 'studio_mcp_service.dart';

extension _StudioMcpRoots on StudioMcpService {
  Future<void> _synchronizeRoots() async {
    if (_rootsSynchronized && _authorizedRoot == _desiredRoot) return;
    final process = _process;
    if (process == null) return;
    final generation = _generation;
    while (!_disposed && generation == _generation) {
      final root = _desiredRoot;
      final bookmark = root == null
          ? null
          : await projectBookmark?.call(root).timeout(commandTimeout);
      if (root != null && projectBookmark != null && bookmark == null) {
        throw const FormatException('permission.bookmark_unavailable');
      }
      if (_disposed || generation != _generation) return;
      if (root != _desiredRoot) continue;
      final id = 'studio-${++_requestNumber}';
      final acknowledged = Completer<void>();
      _requests[id] = acknowledged;
      try {
        await Future.wait([
          acknowledged.future.timeout(commandTimeout),
          process.send({
            'id': id,
            'command': 'set_roots',
            'roots': [?root],
            if (bookmark != null)
              'grants': [
                {'root': root, 'bookmark': bookmark},
              ],
          }),
        ], eagerError: true);
      } finally {
        _requests.remove(id);
      }
      if (_disposed || generation != _generation) return;
      if (root == _desiredRoot) {
        _authorizedRoot = root;
        _rootsSynchronized = true;
        return;
      }
    }
  }
}
