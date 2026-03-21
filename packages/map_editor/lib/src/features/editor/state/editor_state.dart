import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../tools/editor_tool.dart';

part 'editor_state.freezed.dart';

@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    // Context
    ProjectFileSystem? fileSystem,
    ProjectManifest? project,

    // Active Map
    MapData? activeMap,
    String? activeMapPath,

    // Active Tools & Selection
    @Default(EditorToolType.selection) EditorToolType activeTool,
    String? activeLayerId,
    GridPos? hoveredTile,
    int? selectedTileId,
    String? selectedPaletteEntryId,
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
