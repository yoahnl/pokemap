import 'package:map_core/map_core.dart';

import '../../features/editor/state/models/editor_palette_session.dart';

typedef EditorPaletteActivation = ({
  EditorPaletteSession session,
  EditorLayerPaletteContext context,
});

class EditorPaletteSessionService {
  const EditorPaletteSessionService({
    this.maxRecentTilesets = 8,
    this.maxFavoriteTilesets = 32,
  })  : assert(maxRecentTilesets > 0),
        assert(maxFavoriteTilesets > 0);

  final int maxRecentTilesets;
  final int maxFavoriteTilesets;

  EditorPaletteSession remember(
    EditorPaletteSession session, {
    required EditorPaletteContextKey key,
    required EditorLayerPaletteContext context,
  }) {
    return session.copyWith(
      activeKey: key,
      contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
        ...session.contexts,
        key: context,
      },
    );
  }

  EditorPaletteActivation activate(
    EditorPaletteSession session, {
    required EditorPaletteContextKey key,
    required ProjectManifest project,
    required String? assignedTilesetId,
    MapData? activeMap,
  }) {
    final validTilesetIds =
        project.tilesets.map((tileset) => tileset.id).toSet();
    final sanitizedSession = sanitize(
      session,
      project: project,
      activeMap: activeMap,
    );
    final existing = sanitizedSession.contexts[key];
    final context = _sanitizeContext(
      existing ??
          EditorLayerPaletteContext(
            selectedTilesetId: _validId(assignedTilesetId, validTilesetIds),
          ),
      project: project,
      assignedTilesetId: assignedTilesetId,
    );
    return (
      session: remember(
        sanitizedSession,
        key: key,
        context: context,
      ),
      context: context,
    );
  }

  EditorPaletteSession sanitize(
    EditorPaletteSession session, {
    required ProjectManifest project,
    MapData? activeMap,
  }) {
    final validTilesetIds =
        project.tilesets.map((tileset) => tileset.id).toSet();
    final validMapIds = project.maps.map((entry) => entry.id).toSet();
    if (activeMap != null) {
      validMapIds.add(activeMap.id);
    }
    final activeLayerIds =
        activeMap?.layers.map((layer) => layer.id).toSet() ?? const <String>{};
    final contexts = <EditorPaletteContextKey, EditorLayerPaletteContext>{
      for (final entry in session.contexts.entries)
        if (validMapIds.contains(entry.key.mapId) &&
            (activeMap == null ||
                entry.key.mapId != activeMap.id ||
                activeLayerIds.contains(entry.key.layerId)))
          entry.key: entry.value,
    };
    final activeKey = session.activeKey;
    return _sanitizePreferences(
      session.copyWith(
        activeKey: activeKey != null && contexts.containsKey(activeKey)
            ? activeKey
            : null,
        contexts: contexts,
      ),
      validTilesetIds: validTilesetIds,
    );
  }

  EditorPaletteSession recordRecent(
    EditorPaletteSession session, {
    required String tilesetId,
    required Set<String> validTilesetIds,
  }) {
    final current = session.recentTilesetIds
        .where(validTilesetIds.contains)
        .where((id) => id != tilesetId)
        .toList(growable: true);
    if (validTilesetIds.contains(tilesetId)) {
      current.insert(0, tilesetId);
    }
    return session.copyWith(
      recentTilesetIds: current.take(maxRecentTilesets).toList(growable: false),
      favoriteTilesetIds: session.favoriteTilesetIds
          .where(validTilesetIds.contains)
          .toList(growable: false),
    );
  }

  EditorPaletteSession toggleFavorite(
    EditorPaletteSession session, {
    required String tilesetId,
    required Set<String> validTilesetIds,
  }) {
    final favorites = session.favoriteTilesetIds
        .where(validTilesetIds.contains)
        .toList(growable: true);
    if (favorites.remove(tilesetId)) {
      return session.copyWith(favoriteTilesetIds: favorites);
    }
    if (!validTilesetIds.contains(tilesetId)) {
      return session.copyWith(favoriteTilesetIds: favorites);
    }
    favorites.add(tilesetId);
    if (favorites.length > maxFavoriteTilesets) {
      favorites.removeRange(0, favorites.length - maxFavoriteTilesets);
    }
    return session.copyWith(favoriteTilesetIds: favorites);
  }

  EditorPaletteSession reset(EditorPaletteSession _) {
    return const EditorPaletteSession();
  }

  EditorPaletteSession _sanitizePreferences(
    EditorPaletteSession session, {
    required Set<String> validTilesetIds,
  }) {
    return session.copyWith(
      recentTilesetIds: session.recentTilesetIds
          .where(validTilesetIds.contains)
          .take(maxRecentTilesets)
          .toList(growable: false),
      favoriteTilesetIds: session.favoriteTilesetIds
          .where(validTilesetIds.contains)
          .take(maxFavoriteTilesets)
          .toList(growable: false),
    );
  }

  EditorLayerPaletteContext _sanitizeContext(
    EditorLayerPaletteContext context, {
    required ProjectManifest project,
    required String? assignedTilesetId,
  }) {
    final validTilesetIds =
        project.tilesets.map((tileset) => tileset.id).toSet();
    final validAssignedId = _validId(assignedTilesetId, validTilesetIds);
    final selectedTilesetId =
        _validId(context.selectedTilesetId, validTilesetIds) ?? validAssignedId;
    ProjectTilesetEntry? selectedTileset;
    for (final tileset in project.tilesets) {
      if (tileset.id == selectedTilesetId) {
        selectedTileset = tileset;
        break;
      }
    }
    final selectedGroupId = selectedTileset?.elementGroups
                .any((group) => group.id == context.selectedElementGroupId) ==
            true
        ? context.selectedElementGroupId
        : null;
    final validFolderIds = project.tilesetFolders
        .map((folder) => folder.id)
        .toSet()
      ..add(kEditorPaletteUnclassifiedFolderId);
    final validElementCategoryIds =
        project.elementCategories.map((category) => category.id).toSet();

    return context.copyWith(
      selectedTilesetId: selectedTilesetId,
      selectedElementGroupId: selectedGroupId,
      activeBrush: _sanitizeBrush(
        context.activeBrush,
        project: project,
        assignedTilesetId: validAssignedId,
      ),
      browserFolderId: _validId(context.browserFolderId, validFolderIds),
      projectElementCategoryId: _validId(
        context.projectElementCategoryId,
        validElementCategoryIds,
      ),
    );
  }

  EditorPaletteBrushMemory _sanitizeBrush(
    EditorPaletteBrushMemory brush, {
    required ProjectManifest project,
    required String? assignedTilesetId,
  }) {
    return brush.map(
      none: (_) => brush,
      tile: (tile) => tile.tilesetId == assignedTilesetId
          ? brush
          : const EditorPaletteBrushMemory.none(),
      paletteEntry: (entry) {
        if (entry.tilesetId != assignedTilesetId) {
          return const EditorPaletteBrushMemory.none();
        }
        for (final tileset in project.tilesets) {
          if (tileset.id == entry.tilesetId &&
              tileset.paletteEntries
                  .any((candidate) => candidate.id == entry.entryId)) {
            return brush;
          }
        }
        return const EditorPaletteBrushMemory.none();
      },
      projectElement: (element) {
        for (final candidate in project.elements) {
          if (candidate.id == element.elementId &&
              candidate.tilesetId == assignedTilesetId) {
            return brush;
          }
        }
        return const EditorPaletteBrushMemory.none();
      },
    );
  }

  String? _validId(String? id, Set<String> validIds) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return validIds.contains(normalized) ? normalized : null;
  }
}
