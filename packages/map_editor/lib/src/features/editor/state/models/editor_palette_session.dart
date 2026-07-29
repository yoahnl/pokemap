import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import 'editor_ui_modes.dart';

part 'editor_palette_session.freezed.dart';

/// Session-only sentinel used by the asset browser for tilesets that have no
/// declared library folder. It is UI taxonomy, never a persisted folder ID.
const kEditorPaletteUnclassifiedFolderId = '__unclassified__';

enum EditorPaletteAssetCollection {
  all,
  recent,
  favorites,
}

@freezed
class EditorPaletteContextKey with _$EditorPaletteContextKey {
  const factory EditorPaletteContextKey({
    required String mapId,
    required String layerId,
  }) = _EditorPaletteContextKey;
}

@freezed
sealed class EditorPaletteBrushMemory with _$EditorPaletteBrushMemory {
  const factory EditorPaletteBrushMemory.none() = NoEditorPaletteBrushMemory;

  const factory EditorPaletteBrushMemory.tile({
    required int tileId,
    required String tilesetId,
  }) = TileEditorPaletteBrushMemory;

  const factory EditorPaletteBrushMemory.paletteEntry({
    required String entryId,
    required String tilesetId,
  }) = PaletteEntryEditorPaletteBrushMemory;

  const factory EditorPaletteBrushMemory.projectElement({
    required String elementId,
  }) = ProjectElementEditorPaletteBrushMemory;
}

@freezed
class EditorLayerPaletteContext with _$EditorLayerPaletteContext {
  const factory EditorLayerPaletteContext({
    String? selectedTilesetId,
    String? selectedElementGroupId,
    PaletteCategory? paletteCategoryFilter,
    @Default(EditorPaletteBrushMemory.none())
    EditorPaletteBrushMemory activeBrush,
    @Default(TilesElementsPanelMode.palette) TilesElementsPanelMode panelMode,
    @Default('') String browserQuery,
    String? browserFolderId,
    String? projectElementCategoryId,
    @Default(EditorPaletteAssetCollection.all)
    EditorPaletteAssetCollection browserCollection,
    @Default(false) bool showIncompatible,
  }) = _EditorLayerPaletteContext;
}

@freezed
class EditorPaletteSession with _$EditorPaletteSession {
  const factory EditorPaletteSession({
    EditorPaletteContextKey? activeKey,
    @Default(<EditorPaletteContextKey, EditorLayerPaletteContext>{})
    Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
    @Default(<String>[]) List<String> recentTilesetIds,
    @Default(<String>[]) List<String> favoriteTilesetIds,
  }) = _EditorPaletteSession;
}
