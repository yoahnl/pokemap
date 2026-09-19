import '../../project_session/domain/project_session.dart';
import '../domain/recent_studio_project.dart';

class RecentProjectsController {
  RecentProjectsController(this._port, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final RecentProjectsPort _port;
  final DateTime Function() _clock;
  final Set<void Function()> _listeners = {};
  List<RecentStudioProject> _entries = const [];
  Future<void> _pending = Future.value();
  bool _disposed = false;
  String? _error;

  List<RecentStudioProject> get entries => _entries;
  String? get error => _error;

  void addListener(void Function() listener) {
    if (_disposed) throw StateError('Recent projects scope is disposed');
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) => _listeners.remove(listener);

  Future<void> load() => _enqueue(() async {
    _entries = _normalize(await _port.load());
  });

  Future<void> remember(ProjectSession session) {
    final entry = RecentStudioProject(
      name: session.name,
      directoryPath: session.directoryPath,
      lastOpenedAt: _clock(),
    );
    return _enqueue(() async {
      final updated = _normalize([
        entry,
        ..._entries.where((item) => item.directoryPath != entry.directoryPath),
      ]);
      await _port.save(updated);
      _entries = updated;
    });
  }

  Future<void> remove(String path) => _enqueue(() async {
    final updated = List<RecentStudioProject>.unmodifiable(
      _entries.where((entry) => entry.directoryPath != path),
    );
    await _port.save(updated);
    _entries = updated;
  });

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    if (_disposed) return Future.value();
    _pending = _pending.then((_) async {
      if (_disposed) return;
      try {
        await operation();
        _error = null;
      } catch (_) {
        _error = 'Impossible de mettre à jour les projets récents.';
      }
      if (_disposed) return;
      for (final listener in List.of(_listeners)) {
        if (_listeners.contains(listener)) listener();
      }
    });
    return _pending;
  }

  List<RecentStudioProject> _normalize(List<RecentStudioProject> entries) {
    final sorted = List.of(entries)
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    final paths = <String>{};
    return List.unmodifiable(
      sorted.where((entry) => paths.add(entry.directoryPath)).take(5),
    );
  }
}
