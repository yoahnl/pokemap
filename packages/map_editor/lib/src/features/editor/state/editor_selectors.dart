import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/terrain_selection_mode.dart';
import '../tools/editor_tool.dart';
import 'editor_notifier.dart';
import 'editor_state.dart';

/// Snapshot léger du shell.
///
/// On évite ainsi de faire rebuild le shell entier sur chaque champ de
/// `EditorState`, tout en gardant un contrat lisible côté UI.
typedef EditorShellSnapshot = ({
  EditorWorkspaceMode workspaceMode,
  String workspaceTitle,
  String workspaceSubtitle,
  bool canUndoMap,
  bool canRedoMap,
  bool isSaving,
  bool canSaveMap,
});

/// Snapshot ciblé pour la toolbar.
///
/// Il contient uniquement les champs réellement lus par `TopToolbar`.
typedef EditorToolbarSnapshot = ({
  ProjectManifest? project,
  String? projectRootPath,
  ProjectSettings settings,
  MapData? activeMap,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  MapLayer? activeLayer,
  EditorToolType activeTool,
  TerrainSelectionMode terrainSelectionMode,
  TerrainType selectedTerrainType,
  MapEntityKind selectedEntityKind,
  CollisionBrushSizeMode collisionBrushSizeMode,
  bool isSaving,
  bool isDirty,
  bool canUndoMap,
  bool canRedoMap,
  String? statusMessage,
});

/// Snapshot ciblé pour le Project Explorer.
typedef EditorProjectExplorerSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? activeMapId,
});

/// Snapshot léger pour les racines des panneaux terrain/path.
typedef EditorTerrainLibrarySnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  List<ProjectTilesetEntry> tilesets,
  TerrainType selectedTerrainType,
  Map<TerrainType, String> selectedTerrainPresetByType,
  String? selectedTerrainPresetId,
  String? selectedPathPresetId,
});

/// Snapshot léger pour la racine du panneau palette tileset.
typedef EditorTilesetPaletteSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  MapData? activeMap,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? projectRootPath,
  String? activeLayerId,
  EditorBrush activeBrush,
  PaletteCategory? paletteCategoryFilter,
  String? selectedTilesetElementGroupId,
  TilesElementsPanelMode tilesElementsPanelMode,
  String? selectedPlacedElementInstanceId,
});

final editorWorkspaceModeProvider = Provider<EditorWorkspaceMode>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.workspaceMode));
});

final editorProjectManifestProvider = Provider<ProjectManifest?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.project));
});

final editorProjectRootPathProvider = Provider<String?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
});

final editorSelectedTilesetEntryProvider = Provider<ProjectTilesetEntry?>((ref) {
  return ref.watch(
    editorNotifierProvider.select(_resolveSelectedTilesetEntryFromState),
  );
});

final editorActiveLayerProvider = Provider<MapLayer?>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final map = state.activeMap;
      final activeLayerId = state.activeLayerId;
      if (map == null || activeLayerId == null) {
        return null;
      }
      for (final layer in map.layers) {
        if (layer.id == activeLayerId) {
          return layer;
        }
      }
      return null;
    }),
  );
});

final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
  final workspaceMode = ref.watch(editorWorkspaceModeProvider);
  final activeMap = ref.watch(
    editorNotifierProvider.select((s) => s.activeMap),
  );
  final selectedTileset = ref.watch(editorSelectedTilesetEntryProvider);
  final canUndoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canUndoMap),
  );
  final canRedoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canRedoMap),
  );
  final isSaving = ref.watch(
    editorNotifierProvider.select((s) => s.isSaving),
  );

  final workspaceTitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap?.name ?? 'Map Workspace',
    EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
    EditorWorkspaceMode.pokedex => 'Pokédex',
    EditorWorkspaceMode.globalStory => 'Global Story Workspace',
    EditorWorkspaceMode.step => 'Step Studio',
    EditorWorkspaceMode.cutscene => 'Cutscene Studio',
    EditorWorkspaceMode.dialogue => 'Dialogue Studio',
  };

  final workspaceSubtitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap == null
        ? 'Open a map to start building your world.'
        : '${activeMap.size.width} x ${activeMap.size.height} tiles  •  ${activeMap.layers.length} layers',
    EditorWorkspaceMode.tileset => selectedTileset == null
        ? 'Select a tileset to browse and curate your library.'
        : 'Visual library editing for tiles, elements and groups.',
    EditorWorkspaceMode.pokedex =>
      'Simple species list from local project data: number, name, id and types.',
    EditorWorkspaceMode.globalStory =>
      'Macro narrative progression: arcs, milestones and high-level branches.',
    EditorWorkspaceMode.step =>
      'Step logic workspace: progression rules, expected outcomes, linked cutscenes.',
    EditorWorkspaceMode.cutscene =>
      'Scene execution workspace: dialogue, movement, waits, local branching.',
    EditorWorkspaceMode.dialogue =>
      'Conversation authoring: visual blocks, preview, Yarn export — not a raw script IDE.',
  };

  return (
    workspaceMode: workspaceMode,
    workspaceTitle: workspaceTitle,
    workspaceSubtitle: workspaceSubtitle,
    canUndoMap: canUndoMap,
    canRedoMap: canRedoMap,
    isSaving: isSaving,
    canSaveMap: activeMap != null && !isSaving,
  );
});

final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        projectRootPath: state.projectRootPath,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeLayer: _resolveActiveLayerFromState(state),
        activeTool: state.activeTool,
        terrainSelectionMode: state.terrainSelectionMode,
        selectedTerrainType: state.selectedTerrainType,
        selectedEntityKind: state.selectedEntityKind,
        collisionBrushSizeMode: state.collisionBrushSizeMode,
        isSaving: state.isSaving,
        isDirty: state.isDirty,
        canUndoMap: state.canUndoMap,
        canRedoMap: state.canRedoMap,
        statusMessage: state.statusMessage,
      );
    }),
  );
});

final editorProjectExplorerSnapshotProvider =
    Provider<EditorProjectExplorerSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeMapId: state.activeMap?.id,
      );
    }),
  );
});

final editorTerrainLibrarySnapshotProvider =
    Provider<EditorTerrainLibrarySnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        tilesets: project?.tilesets ?? const <ProjectTilesetEntry>[],
        selectedTerrainType: state.selectedTerrainType,
        selectedTerrainPresetByType: state.selectedTerrainPresetByType,
        selectedTerrainPresetId: state.selectedTerrainPresetId,
        selectedPathPresetId: state.selectedPathPresetId,
      );
    }),
  );
});

final editorTilesetPaletteSnapshotProvider =
    Provider<EditorTilesetPaletteSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        projectRootPath: state.projectRootPath,
        activeLayerId: state.activeLayerId,
        activeBrush: state.activeBrush,
        paletteCategoryFilter: state.paletteCategoryFilter,
        selectedTilesetElementGroupId: state.selectedTilesetElementGroupId,
        tilesElementsPanelMode: state.tilesElementsPanelMode,
        selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      );
    }),
  );
});

MapLayer? _resolveActiveLayerFromState(EditorState state) {
  final map = state.activeMap;
  final activeLayerId = state.activeLayerId;
  if (map == null || activeLayerId == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == activeLayerId) {
      return layer;
    }
  }
  return null;
}

ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  final project = state.project;
  if (project == null) {
    return null;
  }

  final selectedId = state.selectedTilesetEditorId;
  if (selectedId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == selectedId) {
        return tileset;
      }
    }
  }

  final activeLayer = _resolveActiveLayerFromState(state);
  if (activeLayer is TileLayer) {
    final layerTilesetId = activeLayer.tilesetId?.trim();
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      for (final tileset in project.tilesets) {
        if (tileset.id == layerTilesetId) {
          return tileset;
        }
      }
    }
  }

  final brushTilesetId = _resolveActiveBrushTilesetId(state, project);
  if (brushTilesetId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == brushTilesetId) {
        return tileset;
      }
    }
  }

  if (project.tilesets.isEmpty) {
    return null;
  }
  return project.tilesets.first;
}

String? _resolveActiveBrushTilesetId(
  EditorState state,
  ProjectManifest project,
) {
  final brush = state.activeBrush;
  if (brush is TileEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is PaletteEntryEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is ProjectElementEditorBrush) {
    for (final element in project.elements) {
      if (element.id == brush.elementId) {
        return element.tilesetId;
      }
    }
  }
  return null;
}
