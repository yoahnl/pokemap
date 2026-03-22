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
    int? selectedTileId,
    String? selectedPaletteEntryId,
    String? selectedProjectElementId,
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
