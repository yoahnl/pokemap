import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';

extension MapBuilderToolLabels on AppLocalizations {
  String mapBuilderSpace(MapBuilderSpace space) => switch (space) {
    MapBuilderSpace.construction => spaceConstruction,
    MapBuilderSpace.gameplay => spaceGameplay,
    MapBuilderSpace.story => spaceStory,
    MapBuilderSpace.ambiance => spaceAmbiance,
  };

  String toolAction(MapWorkspaceEditingState view, {required bool spatial}) =>
      switch (view.tool) {
        StudioMapTool.select => toolSelect,
        StudioMapTool.pan => toolPan,
        StudioMapTool.place => toolPlaceDecor,
        StudioMapTool.paint => toolPaintTiles,
        StudioMapTool.terrain =>
          !spatial || view.spatialTerrainMode == SpatialTerrainMode.ground
              ? toolTerrain
              : view.spatialTerrainMode == SpatialTerrainMode.relief
              ? toolRelief
              : toolSlope,
        StudioMapTool.erase => toolEraseTiles,
        StudioMapTool.eraseDecor => toolEraseDecor,
        StudioMapTool.border => toolBorder,
        StudioMapTool.environment => toolEnvironment,
        StudioMapTool.character => toolCharacter,
        StudioMapTool.spawn => toolSpawn,
        StudioMapTool.sign => toolSign,
        StudioMapTool.fieldObstacle => toolFieldObstacle,
        StudioMapTool.warp => toolWarp,
        StudioMapTool.connection => toolConnection,
        StudioMapTool.zone => toolStoryZone,
        StudioMapTool.gameplayZone ||
        StudioMapTool.encounterPaint ||
        StudioMapTool.encounterErase => toolGameplayZone,
        StudioMapTool.collisionPaint => toolBlockCells,
        StudioMapTool.collisionErase => toolFreeCells,
      };

  String toolHint(MapWorkspaceEditingState view, {required bool armed}) =>
      switch (view.tool) {
        StudioMapTool.select => toolHintSelect,
        StudioMapTool.pan => toolHintPan,
        _ => armed ? toolHintArmed : toolHintChoose,
      };
}
