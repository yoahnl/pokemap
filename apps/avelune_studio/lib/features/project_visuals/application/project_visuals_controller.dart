import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/project_visuals_port.dart';

final class ProjectVisualsController extends ChangeNotifier {
  ProjectVisualsController({required this.session, required this.port});
  final ProjectSession session;
  final ProjectVisualsPort port;
  final preview = ValueNotifier(SpatialVisualPatch());
  ProjectVisualsState? saved;
  ProjectMapEntry? scope;
  bool loading = false, saving = false;
  String? error;
  int? lastSaveMicroseconds;
  final _undo = <SpatialVisualPatch>[];
  final _redo = <SpatialVisualPatch>[];
  int _generation = 0;
  bool _disposed = false;
  SpatialVisualPatch? _gestureStart;
  void beginGesture() {
    _gestureStart ??= preview.value;
  }

  void endGesture() {
    final start = _gestureStart;
    _gestureStart = null;
    if (start != null && start != preview.value) {
      _undo.add(start);
      if (_undo.length > 100) _undo.removeAt(0);
      notifyListeners();
    }
  }

  bool get dirty => saved != null && saved!.profile != preview.value;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  Future<void> open({ProjectMapEntry? map}) async {
    final generation = ++_generation;
    _gestureStart = null;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final value = await port.loadVisuals(session, map: map);
      if (_disposed || generation != _generation) return;
      scope = map;
      saved = value;
      preview.value = value.profile;
      _undo.clear();
      _redo.clear();
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void edit(SpatialVisualPatch profile) {
    if (loading || saving || saved == null || profile == preview.value) return;
    if (_gestureStart == null) {
      _undo.add(preview.value);
      if (_undo.length > 100) _undo.removeAt(0);
    }
    _redo.clear();
    preview.value = profile;
    error = null;
    notifyListeners();
  }

  void undo() {
    if (!canUndo || saving) return;
    _redo.add(preview.value);
    preview.value = _undo.removeLast();
    notifyListeners();
  }

  void redo() {
    if (!canRedo || saving) return;
    _undo.add(preview.value);
    preview.value = _redo.removeLast();
    notifyListeners();
  }

  void discard() {
    if (saved == null || saving) return;
    preview.value = saved!.profile;
    _undo.clear();
    _redo.clear();
    error = null;
    notifyListeners();
  }

  Future<bool> save() async {
    if (saved == null || saving || loading) return false;
    if (!dirty) return true;
    saving = true;
    error = null;
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      final value = await port.saveVisuals(
        session,
        preview.value,
        saved!.revision,
        map: scope,
      );
      if (_disposed) return false;
      saved = value;
      lastSaveMicroseconds = watch.elapsedMicroseconds;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    preview.dispose();
    super.dispose();
  }
}
