import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/map_atmosphere_port.dart';

final class MapAtmosphereController {
  MapAtmosphereController._(
    this.session,
    this.mapId,
    this.port,
    MapAtmosphereState state,
  ) : current = state.settings,
      _saved = state.settings,
      _revision = state.revision;
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
  final Set<void Function()> _listeners = {};
  bool _externalConflict = false;
  String? error;
  SpatialAtmosphereSettings get saved => _saved;
  String get revision => _revision;
  bool get dirty => current != _saved;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  static Future<MapAtmosphereController> open(
    ProjectSession session,
    String mapId,
    MapAtmospherePort port,
  ) async => MapAtmosphereController._(
    session,
    mapId,
    port,
    await port.loadAtmosphere(session, mapId),
  );

  void edit(SpatialAtmosphereSettings next) {
    if (_disposed || next == current) return;
    _undo.add(current);
    _redo.clear();
    current = next;
    error = null;
    _notify();
  }

  void undo() {
    if (_disposed || _undo.isEmpty) return;
    _redo.add(current);
    current = _undo.removeLast();
    error = null;
    _notify();
  }

  void redo() {
    if (_disposed || _redo.isEmpty) return;
    _undo.add(current);
    current = _redo.removeLast();
    error = null;
    _notify();
  }

  void reject(String message) {
    if (_disposed) return;
    error = message;
    _notify();
  }

  void rejectExternalChange() {
    if (_disposed) return;
    _externalConflict = true;
    error = 'Une modification externe concerne cette ambiance. Votre brouillon et son historique sont conservés. Rouvrez la carte avant de publier.';
    _notify();
  }

  Future<bool> save() async {
    if (_disposed || saving) return false;
    if (!dirty) return true;
    if (_externalConflict) {
      rejectExternalChange();
      return false;
    }
    final snapshot = current;
    saving = true;
    error = null;
    _notify();
    try {
      final result = await port.saveAtmosphere(
        session,
        mapId,
        snapshot,
        _revision,
      );
      if (_disposed) return false;
      _saved = result.settings;
      _revision = result.revision;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) _notify();
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
