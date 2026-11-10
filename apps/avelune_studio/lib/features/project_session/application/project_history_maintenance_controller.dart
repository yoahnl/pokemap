import '../domain/project_history_maintenance.dart';
import '../domain/project_session.dart';
import 'project_session_controller.dart';

class ProjectHistoryMaintenanceController {
  ProjectHistoryMaintenanceController({
    required this.session,
    required this.port,
    this.allowSwitch,
    this.onBusyChanged,
  });

  final ProjectSessionController session;
  final ProjectHistoryMaintenancePort? port;
  final Future<bool> Function()? allowSwitch;
  final void Function(bool)? onBusyChanged;
  final _listeners = <void Function()>{};
  bool _disposed = false;
  bool _busy = false;
  bool _applying = false;
  bool _failed = false;
  String? _message;

  bool get busy => _busy;
  bool get applying => _applying;
  bool get failed => _failed;
  String? get message => _message;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  Future<void> run({
    required Future<bool?> Function(ProjectHistoryMaintenancePreview) confirm,
  }) async {
    final port = this.port;
    final project = session.state.project;
    if (_disposed ||
        _busy ||
        port == null ||
        project == null ||
        project.storage != ProjectSessionStorage.workingCatalog) {
      return;
    }
    if (allowSwitch != null && !await allowSwitch!()) return;
    if (!_current(project)) return;
    _busy = true;
    _failed = false;
    _message = 'Analyse de l’historique…';
    _notify();
    onBusyChanged?.call(true);
    try {
      final preview = await port.preview(project);
      if (!_current(project)) return;
      final approved = await confirm(preview);
      if (approved != true || preview.blocked || !_current(project)) {
        if (!_disposed) {
          _message = null;
          _notify();
        }
        return;
      }
      _applying = true;
      _message = 'Suppression des données expirées…';
      _notify();
      final result = await port.apply(project, preview);
      if (_current(project)) {
        _message =
            'Entretien terminé : ${result.deletedObjects} fichiers supprimés (${_mib(result.deletedBytes)} Mio de contenu). Les données utilisées par d’autres sessions sont conservées.';
        _notify();
      }
    } catch (failure) {
      if (_current(project)) {
        _failed = true;
        _message = failure is ProjectHistoryMaintenanceFailure
            ? failure.message
            : 'L’entretien n’a pas pu aboutir. Les données du projet restent conservées ; relancez l’analyse.';
        _notify();
      }
    } finally {
      _busy = false;
      _applying = false;
      _notify();
      onBusyChanged?.call(false);
    }
  }

  void clearMessage() {
    if (_disposed) return;
    _message = null;
    _failed = false;
    _notify();
  }

  bool _current(ProjectSession project) =>
      !_disposed && session.state.project?.sessionId == project.sessionId;

  String _mib(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');

  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
