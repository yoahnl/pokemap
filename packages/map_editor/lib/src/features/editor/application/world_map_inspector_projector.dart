import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../presentation/world_map/world_map_workspace_session.dart';
import '../state/editor_selectors.dart';
import '../tools/editor_tool.dart';
import 'map_canvas_object_hit_test.dart';
import 'world_map_tool_family.dart';

typedef WorldMapInspectorSnapshot = ({
  WorldMapInspectorKind kind,
  String? activeLayerId,
  MapCanvasObjectTarget? objectTarget,
  GridPos? cell,
  bool pinned,
});

final worldMapInspectorSnapshotProvider =
    Provider<WorldMapInspectorSnapshot>((ref) {
  return const WorldMapInspectorProjector().project(
    editor: ref.watch(editorWorldMapInspectorInputSnapshotProvider),
    session: ref.watch(worldMapWorkspaceSessionProvider),
  );
});

final class WorldMapInspectorProjector {
  const WorldMapInspectorProjector();

  WorldMapInspectorSnapshot project({
    required EditorWorldMapInspectorInputSnapshot editor,
    required WorldMapWorkspaceSession session,
  }) {
    final map = editor.activeMap;
    final activeLayerId = _resolveActiveLayerId(
      map: map,
      requestedId: editor.activeLayerId,
    );
    final objectTarget = map == null
        ? null
        : resolveSelectedCanvasObjectTarget(
            map: map,
            project: editor.project,
            selectedPlacedElementInstanceId:
                editor.selectedPlacedElementInstanceId,
            selectedEntityId: editor.selectedEntityId,
            selectedMapEventId: editor.selectedMapEventId,
            selectedWarpId: editor.selectedWarpId,
            selectedTriggerId: editor.selectedTriggerId,
            selectedGameplayZoneId: editor.selectedGameplayZoneId,
          );
    final cell = _resolveSelectedCell(map: map, session: session);
    final pinnedKind = session.pinnedInspectorKind;

    if (pinnedKind != null &&
        _isValidPin(
          kind: pinnedKind,
          map: map,
          activeLayerId: activeLayerId,
          objectTarget: objectTarget,
          cell: cell,
        )) {
      return _snapshot(
        kind: pinnedKind,
        activeLayerId: activeLayerId,
        objectTarget: objectTarget,
        cell: cell,
        pinned: true,
      );
    }

    final family = _resolveObservedFamily(
      activeTool: editor.activeTool,
      session: session,
    );
    final kind = switch (family) {
      WorldMapToolFamily.layers => WorldMapInspectorKind.layers,
      _ when objectTarget != null => WorldMapInspectorKind.objectSelection,
      _ when cell != null => WorldMapInspectorKind.cellSelection,
      WorldMapToolFamily.paint => WorldMapInspectorKind.paint,
      WorldMapToolFamily.erase => WorldMapInspectorKind.erase,
      WorldMapToolFamily.place => WorldMapInspectorKind.place,
      WorldMapToolFamily.selection => WorldMapInspectorKind.empty,
    };
    return _snapshot(
      kind: kind,
      activeLayerId: activeLayerId,
      objectTarget: objectTarget,
      cell: cell,
      pinned: false,
    );
  }
}

WorldMapInspectorSnapshot _snapshot({
  required WorldMapInspectorKind kind,
  required String? activeLayerId,
  required MapCanvasObjectTarget? objectTarget,
  required GridPos? cell,
  required bool pinned,
}) {
  return (
    kind: kind,
    activeLayerId: activeLayerId,
    objectTarget:
        kind == WorldMapInspectorKind.objectSelection ? objectTarget : null,
    cell: kind == WorldMapInspectorKind.cellSelection ? cell : null,
    pinned: pinned,
  );
}

String? _resolveActiveLayerId({
  required MapData? map,
  required String? requestedId,
}) {
  if (map == null || requestedId == null) return null;
  for (final layer in map.layers) {
    if (layer.id == requestedId) return requestedId;
  }
  return null;
}

GridPos? _resolveSelectedCell({
  required MapData? map,
  required WorldMapWorkspaceSession session,
}) {
  final cell = session.selectedCell;
  if (map == null ||
      cell == null ||
      session.selectedCellMapId != map.id ||
      cell.x < 0 ||
      cell.y < 0 ||
      cell.x >= map.size.width ||
      cell.y >= map.size.height) {
    return null;
  }
  return cell;
}

bool _isValidPin({
  required WorldMapInspectorKind kind,
  required MapData? map,
  required String? activeLayerId,
  required MapCanvasObjectTarget? objectTarget,
  required GridPos? cell,
}) {
  return switch (kind) {
    WorldMapInspectorKind.objectSelection => objectTarget != null,
    WorldMapInspectorKind.cellSelection => cell != null,
    WorldMapInspectorKind.paint ||
    WorldMapInspectorKind.erase ||
    WorldMapInspectorKind.place =>
      map != null && activeLayerId != null,
    WorldMapInspectorKind.layers => map != null,
    WorldMapInspectorKind.empty => false,
  };
}

WorldMapToolFamily _resolveObservedFamily({
  required EditorToolType activeTool,
  required WorldMapWorkspaceSession session,
}) {
  return switch (activeTool) {
    EditorToolType.selection =>
      session.activeFamily == WorldMapToolFamily.layers
          ? WorldMapToolFamily.layers
          : WorldMapToolFamily.selection,
    EditorToolType.tilePaint =>
      session.activeFamily == WorldMapToolFamily.place &&
              session.lastPlacementSubtool == WorldMapPlacementSubtool.object
          ? WorldMapToolFamily.place
          : WorldMapToolFamily.paint,
    EditorToolType.terrainPaint ||
    EditorToolType.surfacePaint ||
    EditorToolType.collisionPaint ||
    EditorToolType.borderPaint =>
      WorldMapToolFamily.paint,
    EditorToolType.eraser ||
    EditorToolType.borderErase =>
      WorldMapToolFamily.erase,
    EditorToolType.entityPlacement ||
    EditorToolType.eventPlacement ||
    EditorToolType.triggerPlacement ||
    EditorToolType.warpPlacement ||
    EditorToolType.gameplayZonePlacement =>
      WorldMapToolFamily.place,
  };
}
