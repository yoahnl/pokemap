import 'dart:async';
import 'package:map_authoring/map_authoring_project_creation.dart';

class ProjectCreationController {
  ProjectCreationController(this.port);
  final ProjectCreationPort port;
  final Set<void Function()> _listeners = {};
  String name = '', folderName = '', parentPath = '';
  String width = '20', height = '15';
  int step = 0, tileSize = 16;
  ProjectCreationTemplate template = ProjectCreationTemplate.playable;
  ProjectCreationPhase? phase;
  final completed = <ProjectCreationPhase>{};
  String? error, destination;
  String? errorField;
  ProjectCreationReceipt? receipt;
  bool running = false, checking = false, cancelled = false;
  bool _customFolder = false, _disposed = false;
  int _generation = 0;
  int _previewGeneration = 0;
  List<int>? previewBytes;
  String? previewError;
  bool previewLoading = false;

  Future<void> loadPreview() async {
    final generation = ++_previewGeneration;
    previewLoading = true;
    previewError = null;
    _notify();
    try {
      final bytes = await port.preview(request);
      if (!_disposed && generation == _previewGeneration) previewBytes = bytes;
    } catch (_) {
      if (!_disposed && generation == _previewGeneration) {
        previewBytes = null;
        previewError = 'Aperçu indisponible pour ces dimensions.';
      }
    } finally {
      if (!_disposed && generation == _previewGeneration) {
        previewLoading = false;
        _notify();
      }
    }
  }

  void changePreview(void Function() edit) {
    change(edit);
    unawaited(loadPreview());
  }

  bool get canCancel =>
      running &&
      phase != ProjectCreationPhase.writing &&
      phase != ProjectCreationPhase.verifying &&
      phase != ProjectCreationPhase.completed;
  bool get canClose => !running && !checking;

  ProjectCreationRequest get request => ProjectCreationRequest(
    name: name.trim(),
    folderName: folderName,
    parentPath: parentPath,
    template: template,
    tileSize: tileSize,
    mapWidth: int.tryParse(width) ?? 0,
    mapHeight: int.tryParse(height) ?? 0,
  );

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void change(void Function() edit) {
    if (running || checking || receipt != null) return;
    edit();
    destination = null;
    error = null;
    _notify();
  }

  void setName(String value) => change(() {
    name = value;
    if (!_customFolder) {
      folderName = value
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '-')
          .replaceAll(RegExp(r'[\\/<>:"|?*\x00-\x1f]'), '');
    }
  });
  void setFolder(String value) => change(() {
    folderName = value;
    _customFolder = true;
  });

  bool next() {
    try {
      request.validate(requireDestination: false);
      step++;
      error = null;
      errorField = null;
      _notify();
      unawaited(loadPreview());
      return true;
    } catch (problem) {
      error = _message(problem);
      errorField = problem is FormatException
          ? problem.source as String?
          : null;
      _notify();
      return false;
    }
  }

  void previous() => change(() {
    if (step > 0) step--;
  });

  Future<void> checkDestination() async {
    if (running || checking || _disposed) return;
    final generation = ++_generation;
    final captured = request;
    checking = true;
    error = null;
    destination = null;
    _notify();
    try {
      final path = await port.validateDestination(captured);
      if (!_disposed && generation == _generation) destination = path;
    } catch (problem) {
      if (!_disposed && generation == _generation) error = _message(problem);
    } finally {
      if (!_disposed && generation == _generation) {
        checking = false;
        _notify();
      }
    }
  }

  Future<ProjectCreationReceipt?> create() async {
    if (running || checking || _disposed || receipt != null) return null;
    final captured = request;
    running = true;
    cancelled = false;
    error = null;
    completed.clear();
    step = 4;
    _notify();
    try {
      final result = await port.create(
        captured,
        expectedDestination: destination,
        isCancelled: () => cancelled || _disposed,
        onPhase: (value) {
          if (phase != null) completed.add(phase!);
          phase = value;
          _notify();
        },
      );
      if (_disposed || cancelled) return null;
      receipt = result;
      return result;
    } catch (problem) {
      error = _message(problem);
      return null;
    } finally {
      running = false;
      _notify();
    }
  }

  void cancel() {
    if (!canCancel) return;
    cancelled = true;
    _notify();
  }

  void retry() => change(() {
    step = 3;
    phase = null;
  });
  void dispose() {
    _disposed = true;
    _generation++;
    _listeners.clear();
  }

  String _message(Object problem) =>
      problem is FormatException ? problem.message : problem.toString();
}
