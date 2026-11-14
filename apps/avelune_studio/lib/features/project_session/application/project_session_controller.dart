import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';

class ProjectSessionController {
  ProjectSessionController(this._port, {Duration Function()? clock})
    : _clock = clock;

  final ProjectSessionPort _port;
  final Duration Function()? _clock;
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
    final progress = ProjectOpeningProgress(clock: _clock)
      ..start(ProjectOpeningPhase.project);
    _publish(
      ProjectSessionState(
        status: ProjectSessionStatus.opening,
        project: previous,
        requestedPath: directoryPath,
        progress: progress,
      ),
    );

    ProjectSession session;
    try {
      session = await _port.open(
        directoryPath,
        onPhase: (phase) {
          if (_isCurrent(generation)) progress.advance(phase);
        },
      );
    } catch (error) {
      if (_isCurrent(generation)) {
        _publish(
          ProjectSessionState(
            status: ProjectSessionStatus.failed,
            project: previous,
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
    progress
      ..finish(ProjectOpeningPhase.project)
      ..finish(ProjectOpeningPhase.workshop);
    for (final phase in const [
      ProjectOpeningPhase.narrativeTitles,
      ProjectOpeningPhase.narrativeUsages,
      ProjectOpeningPhase.mapDirectory,
    ]) {
      progress[phase].status == ProjectOpeningStepStatus.running
          ? progress.finish(phase)
          : progress.skip(phase);
    }
    _publish(
      ProjectSessionState(
        status: ProjectSessionStatus.ready,
        project: session,
        requestedPath: directoryPath,
        progress: progress,
      ),
    );
    if (previous != null) await _port.close(previous);
  }

  void cancelOpening() {
    if (_disposed || _state.status != ProjectSessionStatus.opening) return;
    _generation++;
    final previous = _state.project;
    _publish(
      previous == null
          ? const ProjectSessionState()
          : ProjectSessionState(
              status: ProjectSessionStatus.ready,
              project: previous,
              requestedPath: previous.directoryPath,
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
