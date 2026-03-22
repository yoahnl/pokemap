import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../tools/editor_tool.dart';

part 'editor_state.freezed.dart';

enum EditorWorkspaceMode {
  map,
  tileset,
}

@freezed
sealed class EditorBrush with _$EditorBrush {
  const factory EditorBrush.none() = NoEditorBrush;
  const factory EditorBrush.tile({
    required int tileId,
    required String tilesetId,
  }) = TileEditorBrush;
  const factory EditorBrush.paletteEntry({
    required String entryId,
    required String tilesetId,
  }) = PaletteEntryEditorBrush;
  const factory EditorBrush.projectElement({
    required String elementId,
  }) = ProjectElementEditorBrush;
}

@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    // Context
    ProjectFileSystem? fileSystem,
    ProjectManifest? project,
    @Default(EditorWorkspaceMode.map) EditorWorkspaceMode workspaceMode,

    // Active Map
    MapData? activeMap,
    String? activeMapPath,

    // Active Tools & Selection
    @Default(EditorToolType.selection) EditorToolType activeTool,
    String? activeLayerId,
    GridPos? hoveredTile,
    @Default(EditorBrush.none()) EditorBrush activeBrush,
    String? selectedTilesetEditorId,
    String? selectedTilesetElementGroupId,
    PaletteCategory? paletteCategoryFilter,

    // Viewport
    @Default(1.0) double zoom,
    @Default(Offset.zero) Offset panOffset,

    // Status
    @Default(false) bool isDirty,
    @Default(false) bool isSaving,
    String? statusMessage,
    String? errorMessage,
  }) = _EditorState;
}
