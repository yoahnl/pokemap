import 'package:freezed_annotation/freezed_annotation.dart' show immutable;
import 'package:map_core/map_core.dart';

import '../../../application/models/terrain_selection_mode.dart';
import '../../../application/services/narrative_event_legacy_authoring_guard.dart';
import '../../border_map_editing/application/border_tool_availability.dart';
import '../state/editor_state.dart';
import '../tools/editor_tool.dart';
import 'world_map_tool_family.dart';

sealed class WorldMapToolActivationRequest {
  const WorldMapToolActivationRequest();
}

sealed class WorldMapSubtoolActivationRequest
    extends WorldMapToolActivationRequest {
  const WorldMapSubtoolActivationRequest();
}

final class ActivateWorldMapSelection extends WorldMapToolActivationRequest {
  const ActivateWorldMapSelection();
}

final class ActivateWorldMapPaint extends WorldMapSubtoolActivationRequest {
  const ActivateWorldMapPaint(this.subtool);

  final WorldMapPaintSubtool subtool;
}

final class ActivateWorldMapErase extends WorldMapToolActivationRequest {
  const ActivateWorldMapErase();
}

final class ActivateWorldMapPlacement extends WorldMapSubtoolActivationRequest {
  const ActivateWorldMapPlacement(this.subtool);

  final WorldMapPlacementSubtool subtool;
}

@immutable
final class WorldMapToolActivationResult {
  const WorldMapToolActivationResult({
    required this.accepted,
    this.resultingTool,
    this.rejectionReason,
  });

  final bool accepted;
  final EditorToolType? resultingTool;
  final String? rejectionReason;
}

typedef WorldMapToolActivationSource = ({
  ProjectManifest? project,
  MapData? activeMap,
  String? activeLayerId,
  EditorBrush activeBrush,
  String? selectedSurfacePresetId,
});

typedef WorldMapToolActivationAssessment = ({
  EditorToolType? resultingTool,
  TerrainSelectionMode? terrainSelectionMode,
  EditorBrush? resultingBrush,
  TilesElementsPanelMode? tilesElementsPanelMode,
  String? rejectionReason,
});

typedef WorldMapToolActivationSessionSnapshot = ({
  String? activeMapId,
  String? activeLayerId,
  EditorToolType activeTool,
});

abstract interface class WorldMapToolActivationHost {
  WorldMapToolActivationSessionSnapshot
      get worldMapToolActivationSessionSnapshot;

  WorldMapToolActivationResult activateWorldMapTool(
    WorldMapToolActivationRequest request,
  );

  WorldMapToolActivationResult setActiveWorldMapLayer({
    required String layerId,
    required WorldMapToolActivationRequest toolRequest,
  });

  void setActiveLayer(String layerId);
}

WorldMapToolActivationSource worldMapToolActivationSourceFromState(
  EditorState state,
) {
  return (
    project: state.project,
    activeMap: state.activeMap,
    activeLayerId: state.activeLayerId,
    activeBrush: state.activeBrush,
    selectedSurfacePresetId: state.selectedSurfacePresetId,
  );
}

WorldMapToolActivationAssessment assessWorldMapToolActivation({
  required WorldMapToolActivationSource source,
  required WorldMapToolActivationRequest request,
  String? activeBorderFeatureId,
}) {
  if (request is ActivateWorldMapSelection) {
    return (
      resultingTool: EditorToolType.selection,
      terrainSelectionMode: null,
      resultingBrush: null,
      tilesElementsPanelMode: null,
      rejectionReason: null,
    );
  }

  final map = source.activeMap;
  if (map == null) {
    return _rejectedWorldMapActivation(
      'Select an active map before choosing an editing tool.',
    );
  }
  final layerId = source.activeLayerId;
  final layer = layerId == null ? null : _findLayerById(map, layerId);

  if (request case ActivateWorldMapPlacement(:final subtool)) {
    if (subtool == WorldMapPlacementSubtool.event) {
      final reason = narrativeEventLegacyAuthoringBlockReason(
        source.project,
        kind: NarrativeEventLegacyAuthoringKind.mapEvent,
      );
      if (reason != null) {
        return _rejectedWorldMapActivation(reason);
      }
    }
    if (subtool != WorldMapPlacementSubtool.object) {
      return (
        resultingTool: switch (subtool) {
          WorldMapPlacementSubtool.entity => EditorToolType.entityPlacement,
          WorldMapPlacementSubtool.event => EditorToolType.eventPlacement,
          WorldMapPlacementSubtool.trigger => EditorToolType.triggerPlacement,
          WorldMapPlacementSubtool.warp => EditorToolType.warpPlacement,
          WorldMapPlacementSubtool.gameplayZone =>
            EditorToolType.gameplayZonePlacement,
          WorldMapPlacementSubtool.object => throw StateError('unreachable'),
        },
        terrainSelectionMode: null,
        resultingBrush: const EditorBrush.none(),
        tilesElementsPanelMode: null,
        rejectionReason: null,
      );
    }
    if (layer is! TileLayer) {
      return (
        resultingTool: null,
        terrainSelectionMode: null,
        resultingBrush: null,
        tilesElementsPanelMode: null,
        rejectionReason: 'Place/object requires an active editable tile layer.',
      );
    }
    return (
      resultingTool: EditorToolType.tilePaint,
      terrainSelectionMode: null,
      resultingBrush: _compatibleProjectElementBrushForLayer(
        source,
        map,
        layer,
      ),
      tilesElementsPanelMode: TilesElementsPanelMode.palette,
      rejectionReason: null,
    );
  }

  if (request is ActivateWorldMapErase) {
    if (layer is BorderLayer) {
      final availability = assessBorderToolAvailability(
        manifest: source.project,
        map: map,
        activeLayerId: layerId,
        activeFeatureId: activeBorderFeatureId,
      );
      return (
        resultingTool:
            availability.isEnabled ? EditorToolType.borderErase : null,
        terrainSelectionMode: null,
        resultingBrush:
            availability.isEnabled ? const EditorBrush.none() : null,
        tilesElementsPanelMode: null,
        rejectionReason:
            availability.isEnabled ? null : availability.disabledReason,
      );
    }
    final canErase = layer is TileLayer ||
        layer is CollisionLayer ||
        layer is TerrainLayer ||
        layer is PathLayer ||
        layer is SurfaceLayer;
    return (
      resultingTool: canErase ? EditorToolType.eraser : null,
      terrainSelectionMode: null,
      resultingBrush: canErase ? const EditorBrush.none() : null,
      tilesElementsPanelMode: null,
      rejectionReason: canErase ? null : 'The active layer cannot be erased.',
    );
  }

  final paint = switch (request) {
    ActivateWorldMapPaint() => request,
    ActivateWorldMapSelection() ||
    ActivateWorldMapErase() ||
    ActivateWorldMapPlacement() =>
      throw StateError('Activation request was already handled.'),
  };
  switch (paint.subtool) {
    case WorldMapPaintSubtool.tile:
      if (layer is! TileLayer) {
        return _rejectedWorldMapActivation(
          'Paint/tile requires an active editable tile layer.',
        );
      }
      return (
        resultingTool: EditorToolType.tilePaint,
        terrainSelectionMode: null,
        resultingBrush: _compatibleTilePaintBrushForLayer(source, map, layer),
        tilesElementsPanelMode: TilesElementsPanelMode.palette,
        rejectionReason: null,
      );
    case WorldMapPaintSubtool.terrain:
      if (layer is! TerrainLayer) {
        return _rejectedWorldMapActivation(
          'Paint/terrain requires an active terrain layer.',
        );
      }
      return (
        resultingTool: EditorToolType.terrainPaint,
        terrainSelectionMode: TerrainSelectionMode.terrain,
        resultingBrush: const EditorBrush.none(),
        tilesElementsPanelMode: null,
        rejectionReason: null,
      );
    case WorldMapPaintSubtool.path:
      if (layer is! PathLayer) {
        return _rejectedWorldMapActivation(
          'Paint/path requires an active path layer.',
        );
      }
      return (
        resultingTool: EditorToolType.terrainPaint,
        terrainSelectionMode: TerrainSelectionMode.path,
        resultingBrush: const EditorBrush.none(),
        tilesElementsPanelMode: null,
        rejectionReason: null,
      );
    case WorldMapPaintSubtool.surface:
      if (layer is! SurfaceLayer) {
        return _rejectedWorldMapActivation(
          'Paint/surface requires an active surface layer.',
        );
      }
      if (!_surfacePresetExists(
        source.project,
        source.selectedSurfacePresetId,
      )) {
        return _rejectedWorldMapActivation(
          'Select an available surface before painting.',
        );
      }
      return (
        resultingTool: EditorToolType.surfacePaint,
        terrainSelectionMode: null,
        resultingBrush: const EditorBrush.none(),
        tilesElementsPanelMode: null,
        rejectionReason: null,
      );
    case WorldMapPaintSubtool.border:
      final availability = assessBorderToolAvailability(
        manifest: source.project,
        map: map,
        activeLayerId: layerId,
        activeFeatureId: activeBorderFeatureId,
      );
      return (
        resultingTool:
            availability.isEnabled ? EditorToolType.borderPaint : null,
        terrainSelectionMode: null,
        resultingBrush:
            availability.isEnabled ? const EditorBrush.none() : null,
        tilesElementsPanelMode: null,
        rejectionReason:
            availability.isEnabled ? null : availability.disabledReason,
      );
    case WorldMapPaintSubtool.collision:
      if (layer is! CollisionLayer) {
        return _rejectedWorldMapActivation(
          'Paint/collision requires an active collision layer.',
        );
      }
      return (
        resultingTool: EditorToolType.collisionPaint,
        terrainSelectionMode: null,
        resultingBrush: const EditorBrush.none(),
        tilesElementsPanelMode: null,
        rejectionReason: null,
      );
  }
}

WorldMapToolActivationAssessment _rejectedWorldMapActivation(String reason) {
  return (
    resultingTool: null,
    terrainSelectionMode: null,
    resultingBrush: null,
    tilesElementsPanelMode: null,
    rejectionReason: reason,
  );
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

bool _surfacePresetExists(ProjectManifest? project, String? presetId) {
  final normalizedPresetId = presetId?.trim();
  if (project == null ||
      normalizedPresetId == null ||
      normalizedPresetId.isEmpty) {
    return false;
  }
  return project.surfaceCatalog.presetById(normalizedPresetId) != null;
}

EditorBrush _compatibleTilePaintBrushForLayer(
  WorldMapToolActivationSource source,
  MapData map,
  TileLayer layer,
) {
  final assignedTilesetId = _assignedTilesetIdForLayer(map, layer);
  return switch (source.activeBrush) {
    TileEditorBrush(:final tileId, :final tilesetId)
        when tileId > 0 && tilesetId == assignedTilesetId =>
      source.activeBrush,
    PaletteEntryEditorBrush(:final entryId, :final tilesetId)
        when tilesetId == assignedTilesetId &&
            _paletteEntryExists(source.project, tilesetId, entryId) =>
      source.activeBrush,
    ProjectElementEditorBrush() => _compatibleProjectElementBrushForLayer(
        source,
        map,
        layer,
      ),
    _ => const EditorBrush.none(),
  };
}

EditorBrush _compatibleProjectElementBrushForLayer(
  WorldMapToolActivationSource source,
  MapData map,
  TileLayer layer,
) {
  final brush = source.activeBrush;
  if (brush is! ProjectElementEditorBrush) {
    return const EditorBrush.none();
  }
  final assignedTilesetId = _assignedTilesetIdForLayer(map, layer);
  final element = source.project?.elements
      .where((candidate) => candidate.id == brush.elementId)
      .firstOrNull;
  if (element == null || element.tilesetId != assignedTilesetId) {
    return const EditorBrush.none();
  }
  return brush;
}

String? _assignedTilesetIdForLayer(MapData map, TileLayer layer) {
  final layerTilesetId = layer.tilesetId?.trim();
  if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
    return layerTilesetId;
  }
  final mapTilesetId = map.tilesetId.trim();
  return mapTilesetId.isEmpty ? null : mapTilesetId;
}

bool _paletteEntryExists(
  ProjectManifest? project,
  String tilesetId,
  String entryId,
) {
  final tileset = project?.tilesets
      .where((candidate) => candidate.id == tilesetId)
      .firstOrNull;
  return tileset?.paletteEntries.any((candidate) => candidate.id == entryId) ==
      true;
}
