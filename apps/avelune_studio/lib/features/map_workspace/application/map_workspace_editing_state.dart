import 'package:map_core/map_core_domain.dart';

import '../../resources/application/resource_catalog.dart';
import 'map_border_review.dart';

import 'editable_map_document.dart';
import 'environment_editing_commands.dart';
import 'map_border_drawing_draft.dart';
import 'map_border_editing_commands.dart';
import 'map_terrain_patterns.dart';
import 'spatial_ramp_editing_commands.dart';
import 'spatial_terrain_stroke.dart';
import 'spatial_terrain_surface_editing_commands.dart';
import 'map_selection_target.dart';
import 'studio_map_tool.dart';

export 'map_selection_target.dart';
export 'studio_map_tool.dart';

part 'map_workspace_border_editing_state.dart';
part 'map_workspace_tool_preparation.dart';
part 'map_workspace_resource_reconciliation.dart';

class MapWorkspaceEditingState {
  bool highlightTerrain = true;
  bool revealCollisions = false;
  Set<GameplayZoneKind> revealedZones = const {};
  StudioMapTool tool = StudioMapTool.select;

  SpatialTerrainMode spatialTerrainMode = SpatialTerrainMode.ground;
  int spatialTerrainLevel = 1;
  SpatialRampEditingPreview? rampPreview;
  bool spatialContinuousTerrain = false;
  bool spatialSurfaceSelect = false;
  bool spatialSurfaceReanchorInstances = true;
  String spatialSurfaceLowLevel = '0';
  String spatialSurfaceHighLevel = '1';
  SpatialRampDirection spatialSurfaceDirection = SpatialRampDirection.north;
  String? spatialSurfaceId;
  SpatialTerrainSurfaceEditingPreview? terrainSurfacePreview;
  (bool, String, String, SpatialRampDirection, bool)
  get terrainSurfaceOptions => (
    spatialContinuousTerrain,
    spatialSurfaceLowLevel,
    spatialSurfaceHighLevel,
    spatialSurfaceDirection,
    spatialSurfaceReanchorInstances,
  );
  ProjectElementEntry? brush;
  FieldObstacleKind fieldObstacleKind = FieldObstacleKind.cutTree;
  FieldObstacleResetPolicy fieldObstacleResetPolicy =
      FieldObstacleResetPolicy.mapInstance;
  ProjectModel3dEntry? model3d;
  TileLayerPaletteEntry? tile;
  ProjectSmartTilePreset? terrain;
  String? terrainMaterialId;
  String? terrainPatternId;
  SmartTilePatternSelectionKind terrainPatternMode =
      SmartTilePatternSelectionKind.stamp;
  ProjectCharacterEntry? character;
  ProjectMapEntry? warpDestination;
  MapWarpTriggerMode warpPlacementMode = MapWarpTriggerMode.onEnter;

  String? borderBlueprintId;
  MapBorderDrawingDraft? borderDraft;
  final Map<String, MapBorderDrawingDraft> _retainedBorderDrafts = {};
  int? borderMovingAngle;
  ({MapBorderDrawingDraft draft, String message})? borderDraftFailure;

  BorderStrokeEditingMode borderEditingMode = BorderStrokeEditingMode.draw;
  ({String layerId, String featureId})? borderFeature;
  MapBorderRegenerationPreview? borderPreview;

  MapEnvironmentSession? environment;
  String? exteriorEnvironmentPresetId;

  MapSelectionTarget? _target;
  MapSelectionTarget? get target => _target;

  MapSelectionTarget? _pendingMove;
  String? _moveHint;

  MapSelectionTarget? get pendingMove => _pendingMove;
  set pendingMove(MapSelectionTarget? target) {
    _pendingMove = target;
    _moveHint = null;
  }

  String? get moveHint => _pendingMove == null ? null : _moveHint;

  void armMove(MapSelectionTarget target, String hint) {
    _pendingMove = target;
    _moveHint = hint;
  }

  MapPlacedElement? armedDecorIn(MapData map) {
    final armed = _pendingMove;
    if (armed == null ||
        armed.family != MapSelectionFamily.decor ||
        armed.mapId != map.id ||
        tool != StudioMapTool.select) {
      return null;
    }
    return map.placedElements.where((item) => item.id == armed.id).firstOrNull;
  }

  GameplayZoneKind zoneKind = GameplayZoneKind.encounter;
  ProjectSmartTilePattern? terrainPatternFor(
    ProjectManifest project,
    MapData map,
  ) {
    final preset = terrain;
    if (preset == null || terrainPatternId == null) return null;
    return availableTerrainPatterns(
      project: project,
      map: map,
      preset: preset,
    ).where((pattern) => pattern.id == terrainPatternId).firstOrNull;
  }

  String? selectedFor(String mapId, MapSelectionFamily family) {
    final target = _target;
    return target != null && target.mapId == mapId && target.family == family
        ? target.id
        : null;
  }

  bool hasSelectionIn(String mapId) => _target?.mapId == mapId;

  bool isUnavailable(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    final kind = switch (family) {
      MapSelectionFamily.decor =>
        document.current.spatialScene?.instances.any(
                  (entry) => entry.id == id,
                ) ==
                true
            ? 'model'
            : 'decor',
      MapSelectionFamily.character || MapSelectionFamily.marker => 'entity',
      MapSelectionFamily.warp => 'warp',
      MapSelectionFamily.zone => 'zone',
      MapSelectionFamily.trigger => 'trigger',
    };
    return document.isElementUnavailable(kind, id);
  }

  void reconcileLocks(EditableMapDocument document) {
    final target = _target;
    if (target != null &&
        target.mapId == document.current.id &&
        isUnavailable(document, target.family, target.id)) {
      clearSelection(document);
    }
    final armed = pendingMove;
    if (armed != null &&
        armed.mapId == document.current.id &&
        isUnavailable(document, armed.family, armed.id)) {
      pendingMove = null;
    }
  }

  final _extraDecorIds = <String>{};
  String? _extraDecorMapId;

  Set<String> selectedDecorIds(String mapId) {
    final target = _target;
    return {
      if (target != null &&
          target.mapId == mapId &&
          target.family == MapSelectionFamily.decor)
        target.id,
      if (_extraDecorMapId == mapId) ..._extraDecorIds,
    };
  }

  void toggleDecorInSelection(EditableMapDocument document, String id) {
    final mapId = document.current.id;
    final target = _target;
    if (target == null ||
        target.mapId != mapId ||
        target.family != MapSelectionFamily.decor) {
      select(document, MapSelectionFamily.decor, id);
      return;
    }
    if (isUnavailable(document, MapSelectionFamily.decor, id)) return;
    if (_extraDecorMapId != mapId) {
      _extraDecorIds.clear();
      _extraDecorMapId = mapId;
    }
    if (id == target.id) {
      if (_extraDecorIds.isEmpty) {
        clearSelection(document);
        return;
      }
      final remaining = _extraDecorIds.toList();
      select(document, MapSelectionFamily.decor, remaining.removeAt(0));
      _extraDecorIds.addAll(remaining);
      _extraDecorMapId = mapId;
      return;
    }
    if (!_extraDecorIds.remove(id)) _extraDecorIds.add(id);
  }

  void select(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    if (isUnavailable(document, family, id)) return;
    _extraDecorIds.clear();
    _extraDecorMapId = null;
    _target = MapSelectionTarget(
      mapId: document.current.id,
      family: family,
      id: id,
    );
    document.selectedId = family == MapSelectionFamily.decor ? id : null;
  }

  void clearSelection(EditableMapDocument document) {
    _target = null;
    _extraDecorIds.clear();
    _extraDecorMapId = null;
    pendingMove = null;
    document.selectedId = null;
  }

  final resourceFilters = ResourceCatalogFilterState();
  String? _resourceMapId;
  String? paletteAtlasId;
  bool _selectInitialTerrainConstruction = false;

  void prepareTerrainPainting(ProjectSmartTilePreset preset) {
    _selectInitialTerrainConstruction = true;
    if (terrain?.id != preset.id) terrainPatternId = null;
    if (terrain?.id != preset.id ||
        !preset.allowedMaterialIds.contains(terrainMaterialId)) {
      terrainMaterialId = preset.defaultMaterialId;
    }
    terrain = preset;
    brush = null;
    model3d = null;
    tile = null;
    character = null;
    spatialTerrainMode = SpatialTerrainMode.ground;
    tool = StudioMapTool.terrain;
  }
}
