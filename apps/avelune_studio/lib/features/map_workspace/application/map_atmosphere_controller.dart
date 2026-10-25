import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/map_atmosphere_port.dart';

final class MapAtmosphereController extends ChangeNotifier {
  MapAtmosphereController._(this.session, this.mapId, this.port, MapAtmosphereState state)
      : current = state.settings, _saved = state.settings, _revision = state.revision;
  final ProjectSession session;
  final String mapId;
  final MapAtmospherePort port;
  SpatialAtmosphereSettings current;
  SpatialAtmosphereSettings _saved;
  String _revision;
  final _undo = <SpatialAtmosphereSettings>[];
  final _redo = <SpatialAtmosphereSettings>[];
  bool saving = false;
  bool _disposed = false;
  String? error;
  bool get dirty => current != _saved;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  static Future<MapAtmosphereController> open(ProjectSession session, String mapId, MapAtmospherePort port) async =>
      MapAtmosphereController._(session, mapId, port, await port.loadAtmosphere(session, mapId));

  void edit(SpatialAtmosphereSettings next) {
    if (_disposed || next == current) return;
    _undo.add(current);
    _redo.clear();
    current = next;
    error = null;
    notifyListeners();
  }

  void undo() {
    if (_disposed || _undo.isEmpty) return;
    _redo.add(current);
    current = _undo.removeLast();
    error = null;
    notifyListeners();
  }

  void redo() {
    if (_disposed || _redo.isEmpty) return;
    _undo.add(current);
    current = _redo.removeLast();
    error = null;
    notifyListeners();
  }

  void reject(String message) {
    if (_disposed) return;
    error = message;
    notifyListeners();
  }

  Future<bool> save() async {
    if (_disposed || saving) return false;
    if (!dirty) return true;
    final snapshot = current;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final result = await port.saveAtmosphere(session, mapId, snapshot, _revision);
      if (_disposed) return false;
      _saved = result.settings;
      _revision = result.revision;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
