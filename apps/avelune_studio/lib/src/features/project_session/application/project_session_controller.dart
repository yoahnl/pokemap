import 'project_session.dart';
import 'project_session_state.dart';

class ProjectSessionController {
  ProjectSessionController(this._port);

  final ProjectSessionPort _port;
  final Set<void Function()> _listeners = {};
  ProjectSessionState _state = const ProjectSessionState();
  int _generation = 0;
  bool _disposed = false;

  ProjectSessionState get state => _state;
  bool get disposed => _disposed;

  void addListener(void Function() listener) {
    if (_disposed) throw StateError('Project session scope is disposed');
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  Future<void> open(String directoryPath) async {
    if (_disposed) throw StateError('Project session scope is disposed');
    final generation = ++_generation;
    final previous = _state.project;
    _publish(
      ProjectSessionState(
        status: ProjectSessionStatus.opening,
        requestedPath: directoryPath,
      ),
    );

    ProjectSession session;
    try {
      if (previous != null) await _port.close(previous);
      if (!_isCurrent(generation)) return;
      session = await _port.open(directoryPath);
    } catch (error) {
      if (_isCurrent(generation)) {
        _publish(
          ProjectSessionState(
            status: ProjectSessionStatus.failed,
            requestedPath: directoryPath,
            problem: error is ProjectOpenFailure
                ? error.problem
                : ProjectOpenProblem.readFailed,
          ),
        );
      }
      return;
    }

    if (!_isCurrent(generation)) {
      await _port.close(session);
      return;
    }
    _publish(
      ProjectSessionState(
        status: ProjectSessionStatus.ready,
        project: session,
        requestedPath: directoryPath,
      ),
    );
  }

  Future<void> close() async {
    if (_disposed) return;
    _generation++;
    final previous = _state.project;
    _publish(const ProjectSessionState());
    if (previous != null) await _port.close(previous);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _listeners.clear();
    final previous = _state.project;
    _state = const ProjectSessionState();
    if (previous != null) await _port.close(previous);
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _publish(ProjectSessionState state) {
    _state = state;
    for (final listener in List<void Function()>.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }
}
