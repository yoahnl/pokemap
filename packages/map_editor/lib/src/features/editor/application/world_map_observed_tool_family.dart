import '../presentation/world_map/world_map_workspace_session.dart';
import '../state/editor_selectors.dart';
import '../tools/editor_tool.dart';
import 'world_map_tool_family.dart';

/// Resolves the family represented by the editor's observable tool and brush.
///
/// Session state is consulted only for engine-level ambiguities: Selection can
/// represent Layers, while tilePaint can represent Paint/elements or
/// Place/object.
WorldMapToolFamily resolveWorldMapObservedToolFamily({
  required EditorToolType activeTool,
  required WorldMapWorkspaceSession session,
  required EditorWorldMapBrushKind brushKind,
}) {
  final tilePaintIsPlace = switch (brushKind) {
    EditorWorldMapBrushKind.projectElement =>
      session.activeFamily != WorldMapToolFamily.paint,
    EditorWorldMapBrushKind.tile ||
    EditorWorldMapBrushKind.paletteEntry =>
      false,
    EditorWorldMapBrushKind.none =>
      session.activeFamily == WorldMapToolFamily.place &&
          session.lastPlacementSubtool == WorldMapPlacementSubtool.object,
  };
  return switch (activeTool) {
    EditorToolType.selection =>
      session.activeFamily == WorldMapToolFamily.layers
          ? WorldMapToolFamily.layers
          : WorldMapToolFamily.selection,
    EditorToolType.tilePaint =>
      tilePaintIsPlace ? WorldMapToolFamily.place : WorldMapToolFamily.paint,
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
