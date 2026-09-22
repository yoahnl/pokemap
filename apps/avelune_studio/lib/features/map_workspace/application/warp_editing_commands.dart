import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

class WarpEditingCommands {
  WarpEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _sequence = 0;

  String _id() {
    String id;
    do {
      id = 'warp-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    } while (document.current.warps.any((warp) => warp.id == id));
    return id;
  }

  MapWarp? selected(String? id) =>
      document.current.warps.where((warp) => warp.id == id).firstOrNull;

  List<MapWarp> at(GridPos position) => document.current.warps.reversed
      .where((warp) => warp.pos.x == position.x && warp.pos.y == position.y)
      .toList(growable: false);

  List<ProjectMapEntry> destinations() =>
      project.maps.where((entry) => entry.id != document.current.id).toList();

  ProjectMapEntry? destinationOf(MapWarp warp) =>
      project.maps.where((entry) => entry.id == warp.targetMapId).firstOrNull;

  String? destinationProblem(MapWarp warp) => destinationOf(warp) == null
      ? 'La carte de destination n’existe plus dans le projet.'
      : null;

  MapWarp place(ProjectMapEntry destination, GridPos position) {
    if (!project.maps.any((entry) => entry.id == destination.id)) {
      throw StateError('Cette carte ne fait plus partie du projet.');
    }
    final warp = MapWarp(
      id: _id(),
      pos: position,
      targetMapId: destination.id,
      targetPos: const GridPos(x: 0, y: 0),
    );
    document.commit(addWarpToMap(document.current, warp: warp));
    return warp;
  }

  void move(String id, GridPos position) => document.commit(
    updateWarpOnMap(document.current, warpId: id, pos: position),
  );

  void retarget(
    String id, {
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
  }) {
    if (targetMapId != null &&
        !project.maps.any((entry) => entry.id == targetMapId)) {
      throw StateError('Cette carte ne fait plus partie du projet.');
    }
    document.commit(
      updateWarpOnMap(
        document.current,
        warpId: id,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
      ),
    );
  }

  void delete(String id) =>
      document.commit(removeWarpFromMap(document.current, warpId: id));
}
