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
  EditorEraserFootprint eraserFootprint,
  CollisionBrushSizeMode collisionBrushSizeMode,
  bool isSaving,
  bool isDirty,
  bool isProjectDirty,
  bool canSaveMap,
  bool canUndoMap,
  bool canRedoMap,
  String? statusMessage,
});

typedef EditorWorldMapToolbarSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  MapData? activeMap,
  MapLayer? activeLayer,
  EditorToolType activeTool,
  TerrainSelectionMode terrainSelectionMode,
  bool isSaving,
  bool canSaveMap,
  bool canUndoMap,
  bool canRedoMap,
});

typedef EditorWorldMapInspectorInputSnapshot = ({
  MapData? activeMap,
  ProjectManifest? project,
  EditorToolType activeTool,
  String? activeLayerId,
  String? activeLayerName,
  String? selectedEntityId,
  String? selectedMapEventId,
  String? selectedWarpId,
  String? selectedTriggerId,
  String? selectedGameplayZoneId,
  String? selectedPlacedElementInstanceId,
  String? assignedTilesetId,
});

enum EditorWorldMapBrushKind {
  none,
  tile,
  paletteEntry,
  projectElement,
}

/// Snapshot ciblé pour le Project Explorer.
typedef EditorProjectExplorerSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  EditorWorkspaceMode workspaceMode,
  PokemonCatalogSection pokemonCatalogSection,
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

typedef EditorMapPaletteAssetBrowserSnapshot = ({
  ProjectManifest? project,
  MapData? activeMap,
  String? activeLayerId,
  String? assignedTilesetId,
  EditorLayerPaletteContext context,
  List<String> recentTilesetIds,
  List<String> favoriteTilesetIds,
});

final editorWorkspaceModeProvider = Provider<EditorWorkspaceMode>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.workspaceMode));
});

final editorProjectManifestProvider = Provider<ProjectManifest?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.project));
});

final editorPokemonCatalogSectionProvider = Provider<PokemonCatalogSection>((
  ref,
) {
  return ref.watch(
    editorNotifierProvider.select((s) => s.pokemonCatalogSection),
  );
});

final editorProjectRootPathProvider = Provider<String?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
});

final editorSelectedTilesetEntryProvider =
    Provider<ProjectTilesetEntry?>((ref) {
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
  final hasActiveMapStroke = ref.watch(
    editorNotifierProvider.select((s) => s.mapStrokeStart != null),
  );

  final workspaceTitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap?.name ?? 'Espace carte',
    EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
    EditorWorkspaceMode.trainer => 'Trainer Studio',
    EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
    EditorWorkspaceMode.narrativeOverview => 'Narrative Studio / Aperçu',
    EditorWorkspaceMode.globalStory => 'Global Story Workspace',
    EditorWorkspaceMode.scenes => 'Scenes Workspace',
    EditorWorkspaceMode.events => 'Event Builder',
    EditorWorkspaceMode.step => 'Step Studio',
    EditorWorkspaceMode.cutscene => 'Cutscene Studio',
    EditorWorkspaceMode.dialogue => 'Dialogue Studio',
    EditorWorkspaceMode.facts => 'Facts Manager',
    EditorWorkspaceMode.shops => 'Boutique Builder',
    EditorWorkspaceMode.worldRules => 'World Rules Manager',
    EditorWorkspaceMode.narrativeValidator => 'Narrative Validator',
    EditorWorkspaceMode.pathStudio => 'Path Studio',
    EditorWorkspaceMode.environmentStudio => 'Environment Studio',
    EditorWorkspaceMode.personalizationStudio => 'Personalization Studio',
    EditorWorkspaceMode.borderStudio => 'Border Studio',
  };

  final workspaceSubtitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap == null
        ? 'Ouvrez une carte pour commencer à construire votre monde.'
        : '${activeMap.size.width} × ${activeMap.size.height} tuiles • ${activeMap.layers.length} couches',
    EditorWorkspaceMode.tileset => selectedTileset == null
        ? 'Sélectionnez un tileset pour parcourir et organiser votre bibliothèque.'
        : 'Bibliothèque visuelle pour éditer les tuiles, éléments et groupes.',
    EditorWorkspaceMode.trainer =>
      'Créez des dresseurs, des équipes et des listes prêtes au combat sans éditer de JSON brut.',
    EditorWorkspaceMode.pokedex =>
      'Pokédex, Moves et Items réunis dans un même pôle de catalogues Pokémon.',
    EditorWorkspaceMode.narrativeOverview =>
      'Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.',
    EditorWorkspaceMode.globalStory =>
      'Progression narrative macro : arcs, jalons et branches de haut niveau.',
    EditorWorkspaceMode.scenes =>
      'Shell read-only des Scenes V1 depuis ProjectManifest.scenes.',
    EditorWorkspaceMode.events =>
      'Liste read-only des événements de la map active, issue du read model Event Builder.',
    EditorWorkspaceMode.step =>
      'Espace logique des étapes : règles de progression, résultats attendus, cinématiques liées.',
    EditorWorkspaceMode.cutscene =>
      'Espace d’exécution de scène : dialogues, mouvements, attentes, embranchements locaux.',
    EditorWorkspaceMode.dialogue =>
      'Création de conversations : blocs visuels, prévisualisation, export Yarn — pas un IDE de script brut.',
    EditorWorkspaceMode.facts =>
      'Registre no-code des faits persistants lisibles par les scènes et règles du monde.',
    EditorWorkspaceMode.shops =>
      'Catalogues, prix et disponibilité pilotés par la progression du jeu.',
    EditorWorkspaceMode.worldRules =>
      'Règles visibles du monde basées sur des sources authorées et des cibles de carte.',
    EditorWorkspaceMode.narrativeValidator =>
      'Verdict de jouabilité, solvabilité et raccordements Event par map.',
    EditorWorkspaceMode.pathStudio =>
      'Créer des motifs de chemin à partir des presets PathPattern du projet.',
    EditorWorkspaceMode.environmentStudio =>
      'Presets d’environnements réutilisables',
    EditorWorkspaceMode.personalizationStudio =>
      'Personnalisez la présentation visuelle et l’introduction de votre jeu.',
    EditorWorkspaceMode.borderStudio =>
      'Créez des blueprints de côtes, murets et clôtures à partir de vos assets.',
  };

  final exposesMapActions = workspaceMode == EditorWorkspaceMode.map;

  return (
    workspaceMode: workspaceMode,
    workspaceTitle: workspaceTitle,
    workspaceSubtitle: workspaceSubtitle,
    canUndoMap: exposesMapActions && !hasActiveMapStroke && canUndoMap,
    canRedoMap: exposesMapActions && !hasActiveMapStroke && canRedoMap,
    isSaving: isSaving,
    canSaveMap: exposesMapActions &&
        activeMap != null &&
        !isSaving &&
        !hasActiveMapStroke,
  );
});

final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      final exposesMapActions = state.workspaceMode == EditorWorkspaceMode.map;
      final hasActiveMapStroke = state.mapStrokeStart != null;
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
        eraserFootprint: state.eraserFootprint,
        collisionBrushSizeMode: state.collisionBrushSizeMode,
        isSaving: state.isSaving,
        isDirty: state.isDirty,
        isProjectDirty: state.isProjectDirty,
        canSaveMap:
            exposesMapActions && state.activeMap != null && !hasActiveMapStroke,
        canUndoMap:
            exposesMapActions && !hasActiveMapStroke && state.canUndoMap,
        canRedoMap:
            exposesMapActions && !hasActiveMapStroke && state.canRedoMap,
        statusMessage: state.statusMessage,
      );
    }),
  );
});

final editorWorldMapToolbarSnapshotProvider =
    Provider<EditorWorldMapToolbarSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      final exposesMapActions = state.workspaceMode == EditorWorkspaceMode.map;
      final hasActiveMapStroke = state.mapStrokeStart != null;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        activeLayer: _resolveActiveLayerFromState(state),
        activeTool: state.activeTool,
        terrainSelectionMode: state.terrainSelectionMode,
        isSaving: state.isSaving,
        canSaveMap: exposesMapActions &&
            state.activeMap != null &&
            !state.isSaving &&
            !hasActiveMapStroke,
        canUndoMap:
            exposesMapActions && !hasActiveMapStroke && state.canUndoMap,
        canRedoMap:
            exposesMapActions && !hasActiveMapStroke && state.canRedoMap,
      );
    }),
  );
});

final editorWorldMapInspectorInputSnapshotProvider =
    Provider<EditorWorldMapInspectorInputSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final activeLayer = _resolveActiveLayerFromState(state);
      return (
        activeMap: state.activeMap,
        project: state.project,
        activeTool: state.activeTool,
        activeLayerId: state.activeLayerId,
        activeLayerName: activeLayer?.name,
        selectedEntityId: state.selectedEntityId,
        selectedMapEventId: state.selectedMapEventId,
        selectedWarpId: state.selectedWarpId,
        selectedTriggerId: state.selectedTriggerId,
        selectedGameplayZoneId: state.selectedGameplayZoneId,
        selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
        assignedTilesetId: _resolveAssignedTilesetId(
          state.activeMap,
          state.activeLayerId,
        ),
      );
    }),
  );
});

final editorWorldMapBrushKindProvider =
    Provider<EditorWorldMapBrushKind>((ref) {
  return ref.watch(
    editorNotifierProvider.select(
      (state) => switch (state.activeBrush) {
        NoEditorBrush() => EditorWorldMapBrushKind.none,
        TileEditorBrush() => EditorWorldMapBrushKind.tile,
        PaletteEntryEditorBrush() => EditorWorldMapBrushKind.paletteEntry,
        ProjectElementEditorBrush() => EditorWorldMapBrushKind.projectElement,
      },
    ),
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
        pokemonCatalogSection: state.pokemonCatalogSection,
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

final editorMapPaletteAssetBrowserSnapshotProvider =
    Provider<EditorMapPaletteAssetBrowserSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final map = state.activeMap;
      final layerId = state.activeLayerId;
      final key = map == null || layerId == null
          ? null
          : EditorPaletteContextKey(mapId: map.id, layerId: layerId);
      final assignedTilesetId = _resolveAssignedTilesetId(
        map,
        layerId,
      );
      return (
        project: state.project,
        activeMap: map,
        activeLayerId: layerId,
        assignedTilesetId: assignedTilesetId,
        context: key == null
            ? const EditorLayerPaletteContext()
            : state.paletteSession.contexts[key] ??
                EditorLayerPaletteContext(
                  selectedTilesetId: assignedTilesetId,
                ),
        recentTilesetIds: state.paletteSession.recentTilesetIds,
        favoriteTilesetIds: state.paletteSession.favoriteTilesetIds,
      );
    }),
  );
});

String? _resolveAssignedTilesetId(MapData? map, String? activeLayerId) {
  if (map == null || activeLayerId == null) return null;
  for (final layer in map.layers) {
    if (layer.id != activeLayerId || layer is! TileLayer) continue;
    final layerTilesetId = layer.tilesetId?.trim();
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      return layerTilesetId;
    }
    final mapTilesetId = map.tilesetId.trim();
    return mapTilesetId.isEmpty ? null : mapTilesetId;
  }
  return null;
}

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

  final studioSelectedId = state.selectedTilesetEditorId;
  if (state.workspaceMode == EditorWorkspaceMode.tileset &&
      studioSelectedId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == studioSelectedId) {
        return tileset;
      }
    }
  }

  final activeMap = state.activeMap;
  final activeLayerId = state.activeLayerId;
  if (activeMap != null && activeLayerId != null) {
    final key = EditorPaletteContextKey(
      mapId: activeMap.id,
      layerId: activeLayerId,
    );
    final contextSelectedId =
        state.paletteSession.contexts[key]?.selectedTilesetId;
    if (contextSelectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == contextSelectedId) {
          return tileset;
        }
      }
    }
  }

  final activeLayer = _resolveActiveLayerFromState(state);
  if (activeLayer is TileLayer) {
    final explicitLayerTilesetId = activeLayer.tilesetId?.trim();
    final mapTilesetId = activeMap?.tilesetId.trim();
    final layerTilesetId =
        explicitLayerTilesetId != null && explicitLayerTilesetId.isNotEmpty
            ? explicitLayerTilesetId
            : mapTilesetId;
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      for (final tileset in project.tilesets) {
        if (tileset.id == layerTilesetId) {
          return tileset;
        }
      }
    }
  }

  if (state.workspaceMode == EditorWorkspaceMode.map &&
      activeMap != null &&
      activeLayerId != null) {
    return null;
  }

  final brushTilesetId = _resolveActiveBrushTilesetId(state, project);
  if (brushTilesetId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == brushTilesetId) {
        return tileset;
      }
    }
  }

  if (studioSelectedId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == studioSelectedId) {
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
