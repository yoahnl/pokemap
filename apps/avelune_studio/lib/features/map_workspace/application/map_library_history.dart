import '../domain/map_catalog_port.dart';

typedef MapHistoryPosition = ({int depth, Object? token});

final class MapLibraryStep {
  const MapLibraryStep({
    required this.receipt,
    required this.positions,
    required this.revisions,
    this.returnMapId,
  });

  final MapCatalogReceipt receipt;
  final Map<String, MapHistoryPosition> positions;
  final Map<String, String> revisions;
  final String? returnMapId;
}

final class MapLibraryHistory {
  final _done = <MapLibraryStep>[];
  final _undone = <MapLibraryStep>[];

  bool get isEmpty => _done.isEmpty && _undone.isEmpty;

  MapLibraryStep? next({required bool redo}) =>
      (redo ? _undone : _done).lastOrNull;

  void record(MapLibraryStep step) {
    _done.add(step);
    _undone.clear();
  }

  void land(MapLibraryStep step, {required bool redo}) {
    (redo ? _undone : _done).removeLast();
    (redo ? _done : _undone).add(step);
  }

  void discard({required bool redo}) {
    if (redo) {
      _undone.clear();
    } else if (_done.isNotEmpty) {
      _done.removeLast();
    }
  }

  void clear() {
    _done.clear();
    _undone.clear();
  }

  bool leads({
    required bool redo,
    String? mapId,
    int depth = 0,
    Object? token,
    bool mapCanStep = false,
  }) {
    final step = next(redo: redo);
    if (step == null) return false;
    if (mapId == null || !mapCanStep) return true;
    final at = step.positions[mapId] ?? (depth: 0, token: null);
    return redo
        ? depth == at.depth
        : depth == at.depth && identical(token, at.token);
  }
}
