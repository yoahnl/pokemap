import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'warp_editing_commands.dart';

class MapWarpTargetSession {
  MapWarpTargetSession(this.document, this.project, MapWarp warp)
    : warpId = warp.id,
      _seenMode = warp.triggerMode;
  final EditableMapDocument document;
  ProjectManifest project;
  String warpId;
  MapWarpTriggerMode _seenMode;
  MapWarpTriggerMode? pendingActiveMode;
  String? pendingDestination;
  int? pendingX, pendingY;
  int _generation = 0;
  bool _disposed = false;

  WarpEditingCommands get commands => WarpEditingCommands(document, project);
  MapWarp? get warp => commands.selected(warpId);
  bool get pending => pendingActiveMode != null;
  MapWarpTriggerMode get mode => pendingActiveMode ?? warp!.triggerMode;
  String? get targetMapId => pending ? pendingDestination : warp?.targetMapId;
  List<ProjectMapEntry> get destinations => commands
      .destinations()
      .where(
        (entry) =>
            !pending ||
            project.maps
                    .where((candidate) => candidate.id == entry.id)
                    .length ==
                1,
      )
      .toList();
  bool get known => destinations.any((entry) => entry.id == targetMapId);
  bool get canApply =>
      !_disposed && pending && known && pendingX != null && pendingY != null;

  void update(ProjectManifest project, MapWarp warp) {
    if (_disposed) return;
    if (warpId != warp.id || _seenMode != warp.triggerMode) clear();
    this.project = project;
    warpId = warp.id;
    _seenMode = warp.triggerMode;
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    pendingActiveMode = null;
    pendingDestination = null;
    pendingX = null;
    pendingY = null;
  }

  bool selectMode(String raw) {
    if (_disposed || warp == null) return false;
    final next = MapWarpTriggerMode.values.byName(raw);
    if (warp!.triggerMode == MapWarpTriggerMode.sceneOnly &&
        next != MapWarpTriggerMode.sceneOnly) {
      _generation++;
      pendingActiveMode = next;
      return true;
    }
    clear();
    return next == warp!.triggerMode ||
        _change(() => commands.retarget(warpId, triggerMode: next));
  }

  bool selectDestination(String id) {
    if (_disposed || warp == null) return false;
    _generation++;
    if (pending) {
      pendingDestination = id;
      pendingX = null;
      pendingY = null;
      return true;
    }
    return _change(() => commands.retarget(warpId, targetMapId: id));
  }

  bool commitTarget(String raw, {required bool horizontal}) {
    if (_disposed || warp == null) return false;
    _generation++;
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 0) {
      if (pending) {
        if (horizontal) {
          pendingX = null;
        } else {
          pendingY = null;
        }
      }
      document.error =
          'La case d’arrivée doit être exprimée en nombres positifs.';
      return false;
    }
    if (pending) {
      if (horizontal) {
        pendingX = parsed;
      } else {
        pendingY = parsed;
      }
      return true;
    }
    final current = warp!.targetPos;
    if (horizontal ? parsed == current.x : parsed == current.y) return true;
    return _change(
      () => commands.retarget(
        warpId,
        targetPos: horizontal
            ? GridPos(x: parsed, y: current.y)
            : GridPos(x: current.x, y: parsed),
      ),
    );
  }

  Future<bool> pickArrival(Future<GridPos?> Function(GridPos) choose) async {
    if (_disposed || warp == null) return false;
    final generation = ++_generation;
    final source = document.current;
    final currentId = warpId;
    final position = await choose(
      pending ? GridPos(x: pendingX ?? 0, y: pendingY ?? 0) : warp!.targetPos,
    );
    if (_disposed ||
        generation != _generation ||
        currentId != warpId ||
        !identical(source, document.current) ||
        position == null) {
      return false;
    }
    if (pending) {
      pendingX = position.x;
      pendingY = position.y;
      return true;
    }
    return _change(() => commands.retarget(warpId, targetPos: position));
  }

  bool apply() {
    if (!canApply) return false;
    return _change(
      () => commands.retarget(
        warpId,
        triggerMode: pendingActiveMode,
        targetMapId: pendingDestination,
        targetPos: GridPos(x: pendingX!, y: pendingY!),
      ),
    );
  }

  bool _change(void Function() change) {
    try {
      change();
      return true;
    } on Object catch (error) {
      document.error = error.toString();
      return false;
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }
}
