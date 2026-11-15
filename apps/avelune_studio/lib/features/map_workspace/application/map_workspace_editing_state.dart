import 'package:map_core/map_core_domain.dart';

import '../../resources/application/resource_catalog.dart';
import 'map_border_review.dart';

import 'editable_map_document.dart';
import 'environment_editing_commands.dart';
import 'map_border_drawing_draft.dart';
import 'map_failure_message.dart';
import 'map_relief_tool.dart';
import 'map_slope_tool.dart';
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
part 'map_workspace_selection.dart';

class MapWorkspaceEditingState with _MapWorkspaceSelectionState {
  bool highlightTerrain = true;
  bool revealCollisions = false;
  Set<GameplayZoneKind> revealedZones = const {};
  StudioMapTool _tool = StudioMapTool.select;
  StudioMapTool get tool => _tool;
  set tool(StudioMapTool value) {
    if (value != _tool) {
      relief.outcome = null;
      slope.outcome = null;
    }
    _tool = value;
  }

  final relief = MapReliefToolState();
  final slope = MapSlopeToolState();
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

  MapSelectionTarget? _pendingMove;
  String? _moveHint;

  MapSelectionTarget? get pendingMove => _pendingMove;
  @override
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

  void reconcileLocks(EditableMapDocument document) {
    _pruneUnavailable(document);
    final armed = pendingMove;
    if (armed != null &&
        armed.mapId == document.current.id &&
        isUnavailable(document, armed.family, armed.id)) {
      pendingMove = null;
    }
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
