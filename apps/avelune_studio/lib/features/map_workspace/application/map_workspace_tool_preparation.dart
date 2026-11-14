part of 'map_workspace_editing_state.dart';

extension MapWorkspaceToolPreparation on MapWorkspaceEditingState {
  void prepareWarpPlacement() {
    brush = null;
    model3d = null;
    tile = null;
    terrain = null;
    character = null;
    tool =
        warpDestination == null &&
            warpPlacementMode != MapWarpTriggerMode.sceneOnly
        ? StudioMapTool.select
        : StudioMapTool.warp;
  }

  void selectEnvironmentPreset(
    EditableMapDocument document,
    ProjectManifest project,
    EnvironmentPreset preset,
  ) {
    final exterior = document.exteriorDecoration;
    if (exterior?.editingExterior == true) {
      exteriorEnvironmentPresetId = preset.id;
      environment = null;
    } else {
      exteriorEnvironmentPresetId = null;
      environment = EnvironmentEditingCommands(
        document,
        project,
      ).create(preset);
    }
    tool = StudioMapTool.environment;
  }

  void selectFieldObstacleKind(FieldObstacleKind value) {
    fieldObstacleKind = value;
    if (value == FieldObstacleKind.strengthBoulder ||
        value == FieldObstacleKind.iceBlock) {
      fieldObstacleResetPolicy = FieldObstacleResetPolicy.mapInstance;
    }
  }

  void prepareExteriorEditing(bool enabled) {
    pendingMove = null;
    if (enabled && !isExteriorDecorationTool(tool)) tool = StudioMapTool.select;
  }

  void prepareFieldObstaclePlacement(FieldObstacleKind kind) {
    fieldObstacleKind = kind;
    tool = StudioMapTool.fieldObstacle;
  }

  void prepareCharacterPlacement() {
    brush = null;
    model3d = null;
    tile = null;
    terrain = null;
    tool = character == null ? StudioMapTool.select : StudioMapTool.character;
  }

  void selectTerrainPattern(ProjectSmartTilePattern? pattern) {
    terrainPatternId = pattern?.id;
    if (pattern?.repeatMode == SmartTilePatternRepeatMode.stamp) {
      terrainPatternMode = SmartTilePatternSelectionKind.stamp;
    } else if (pattern?.construction != null) {
      terrainPatternMode = defaultTerrainPatternSelection(pattern!);
    }
    spatialTerrainMode = SpatialTerrainMode.ground;
    tool = StudioMapTool.terrain;
  }
}
