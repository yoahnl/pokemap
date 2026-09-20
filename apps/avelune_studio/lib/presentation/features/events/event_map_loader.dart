import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';

class EventMapLoader {
  EventMapLoader(this.workspace);
  final MapWorkspaceController workspace;
  final _maps = <String, MapData>{};
  final _pending = <String, Future<MapData>>{};

  Future<MapData> load(String id) async {
    final open = workspace.documents[id]?.current;
    if (open != null) return open;
    final cached = _maps[id];
    if (cached != null) return cached;
    return _pending.putIfAbsent(id, () async {
      try {
        final entries = workspace.project!.maps.where(
          (entry) => entry.id == id,
        );
        if (entries.length != 1) {
          throw StateError('Cette carte est absente ou ambiguë.');
        }
        final document = await workspace.port.loadMap(
          workspace.session,
          entries.single,
        );
        if (!workspace.isDisposed) {
          if (_maps.length >= 3) _maps.remove(_maps.keys.first);
          _maps[id] = document.map;
        }
        return document.map;
      } finally {
        _pending.remove(id);
      }
    });
  }
}
