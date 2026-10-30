import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/map_editor_port.dart';

final class MapEditorController extends ChangeNotifier {
  MapEditorController({
    required this.session,
    required this.mapId,
    required this.port,
    required MapEditorWorkspaceState state,
  }) : current = state.state,
       _saved = state.state,
       _revision = state.revision;

  final ProjectSession session;
  final String mapId;
  final MapEditorPort port;
  MapEditorState current;
  MapEditorState _saved;
  String _revision;
  final _undo = <MapEditorState>[];
  final _redo = <MapEditorState>[];
  Future<bool>? _pending;
  bool _disposed = false;
  bool _externalConflict = false;
  String? error;
  String get revision => _revision;
  bool get dirty => current != _saved;
  bool get saving => _pending != null;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get canWrite => session.storage != ProjectSessionStorage.portableCatalog;

  static Future<MapEditorController> open(
    ProjectSession session,
    String mapId,
    MapEditorPort port,
  ) async => MapEditorController(
    session: session,
    mapId: mapId,
    port: port,
    state: await port.loadEditorState(session, mapId),
  );

  Future<bool> setLocked(String kind, String id, bool locked) =>
      setGroupLocked([(kind, id)], locked);

  Future<bool> setGroupLocked(
    Iterable<(String, String)> elements,
    bool locked,
  ) {
    if (_disposed || !canWrite) return Future.value(false);
    final keys = current.lockedElements.toSet();
    for (final (kind, id) in elements) {
      if (!locked && current.lockedFamilies.contains(kind)) {
        throw StateError(
          'Cette famille est verrouillée globalement. Utilisez Tout déverrouiller pour lever ce verrou.',
        );
      }
      final key = '$kind:$id';
      if (locked) {
        keys.add(key);
      } else {
        keys.remove(key);
      }
    }
    final next = current.copyWith(lockedElements: keys);
    if (next != current) {
      _undo.add(current);
      _redo.clear();
      current = next;
      error = null;
      notifyListeners();
    }
    return save();
  }

  Future<bool> unlockAll() {
    if (_disposed || !canWrite) return Future.value(false);
    final next = current.copyWith(lockedElements: {}, lockedFamilies: {});
    if (current != next) {
      _undo.add(current);
      _redo.clear();
      current = next;
      error = null;
      notifyListeners();
    }
    return save();
  }

  Future<bool> setHidden(String kind, String id, bool hidden) =>
      setGroupHidden([(kind, id)], hidden);

  Future<bool> setGroupHidden(
    Iterable<(String, String)> elements,
    bool hidden,
  ) {
    if (_disposed || !canWrite) return Future.value(false);
    final keys = current.hiddenElements.toSet();
    for (final (kind, id) in elements) {
      if (!hidden && current.hiddenFamilies.contains(kind)) {
        throw StateError(
          'Cette famille est masquée globalement. Utilisez Tout afficher pour la réafficher.',
        );
      }
      final key = '$kind:$id';
      if (hidden) {
        keys.add(key);
      } else {
        keys.remove(key);
      }
    }
    final next = current.copyWith(hiddenElements: keys);
    if (next != current) {
      _undo.add(current);
      _redo.clear();
      current = next;
      error = null;
      notifyListeners();
    }
    return save();
  }

  Future<bool> showAll() {
    if (_disposed || !canWrite) return Future.value(false);
    final next = current.copyWith(hiddenElements: {}, hiddenFamilies: {});
    if (current != next) {
      _undo.add(current);
      _redo.clear();
      current = next;
      error = null;
      notifyListeners();
    }
    return save();
  }

  Future<bool> undo() {
    if (_disposed || !canWrite || _undo.isEmpty) return Future.value(false);
    _redo.add(current);
    current = _undo.removeLast();
    error = null;
    notifyListeners();
    return save();
  }

  Future<bool> redo() {
    if (_disposed || !canWrite || _redo.isEmpty) return Future.value(false);
    _undo.add(current);
    current = _redo.removeLast();
    error = null;
    notifyListeners();
    return save();
  }

  void rejectExternalChange() {
    if (_disposed) return;
    _externalConflict = true;
    error = 'Une modification externe concerne cet état de l’éditeur. Votre brouillon et son historique sont conservés. Rouvrez la carte avant de publier.';
    notifyListeners();
  }

  Future<bool> save() {
    if (_disposed || !canWrite) return Future.value(false);
    final pending = _pending;
    if (pending != null) return pending;
    if (!dirty) return Future.value(true);
    if (_externalConflict) {
      rejectExternalChange();
      return Future.value(false);
    }
    final operation = Future<bool>.microtask(_persist);
    _pending = operation;
    notifyListeners();
    return operation;
  }

  Future<bool> _persist() async {
    try {
      while (!_disposed && dirty) {
        final snapshot = current;
        final saved = await port.saveEditorState(
          session,
          mapId,
          snapshot,
          _revision,
        );
        if (_disposed) return false;
        _saved = saved.state;
        _revision = saved.revision;
        error = null;
      }
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      _pending = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
