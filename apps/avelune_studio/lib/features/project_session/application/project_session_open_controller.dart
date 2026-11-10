import 'dart:async';

import '../../home/application/recent_projects_controller.dart';
import 'project_session_controller.dart';
import 'project_session_state.dart';

class ProjectSessionOpenController {
  ProjectSessionOpenController({
    required this.session,
    required this.chooseDirectory,
    this.recentProjects,
    this.allowSwitch,
    this.isBlocked,
  });

  final ProjectSessionController session;
  final Future<String?> Function() chooseDirectory;
  final RecentProjectsController? recentProjects;
  final Future<bool> Function()? allowSwitch;
  final bool Function()? isBlocked;
  final _listeners = <void Function()>{};
  int _generation = 0;
  bool _disposed = false;
  bool _picking = false;
  bool _creating = false;
  String path = '';
  String? _error;

  bool get picking => _picking;
  bool get creating => _creating;
  String? get error => _error;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  Future<bool> open({String? directoryPath, bool browse = false}) async {
    if (_disposed ||
        isBlocked?.call() == true ||
        _picking ||
        session.state.status == ProjectSessionStatus.opening) {
      return false;
    }
    final generation = ++_generation;
    _error = null;
    _picking = true;
    _notify();
    var directory = directoryPath ?? path;
    path = directory;
    try {
      if (browse || directory.isEmpty) {
        final selected = await chooseDirectory();
        if (!_current(generation) || selected == null) return false;
        directory = selected;
        path = selected;
      }
      if (allowSwitch != null && !await allowSwitch!()) return false;
      if (!_current(generation)) return false;
      final previous = session.state.project;
      await session.open(directory);
      if (!_current(generation)) return false;
      final project = session.state.project;
      if (project == null || identical(project, previous)) return false;
      if (recentProjects case final recents?) {
        unawaited(recents.remember(project));
      }
      return true;
    } catch (_) {
      if (_current(generation)) {
        _error = 'Le sélecteur de dossier est indisponible. Saisissez le chemin puis réessayez.';
      }
      return false;
    } finally {
      if (_current(generation)) {
        _picking = false;
        _notify();
      }
    }
  }

  void cancel() {
    if (_disposed) return;
    _generation++;
    _picking = false;
    session.cancelOpening();
    _notify();
  }

  Future<void> runCreation({
    required Future<void> Function(Future<bool> Function(String)) present,
    Future<void> Function()? releaseParent,
    void Function(bool)? onVisibilityChanged,
  }) async {
    if (_disposed || _creating || _picking || isBlocked?.call() == true) return;
    final ownerProject = session.state.project?.sessionId;
    _creating = true;
    _notify();
    onVisibilityChanged?.call(true);
    try {
      await present((projectPath) async {
        if (_disposed || session.state.project?.sessionId != ownerProject) {
          return false;
        }
        path = projectPath;
        await open(directoryPath: projectPath);
        return !_disposed &&
            session.state.project?.directoryPath == projectPath;
      });
    } finally {
      try {
        await releaseParent?.call();
      } finally {
        onVisibilityChanged?.call(false);
        _creating = false;
        _notify();
      }
    }
  }

  Future<bool> close({bool guard = true}) async {
    if (_disposed || isBlocked?.call() == true) return false;
    if (guard && allowSwitch != null && !await allowSwitch!()) return false;
    if (_disposed) return false;
    _generation++;
    _picking = false;
    _error = null;
    await session.close();
    _notify();
    return true;
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _listeners.clear();
  }
}
