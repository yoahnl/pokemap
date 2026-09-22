import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

enum StudioMapTool {
  select,
  place,
  paint,
  terrain,
  character,
  warp,
  spawn,
  sign,
  zone,
  gameplayZone,
  erase,
  pan,
}

class MapWorkspaceViewState {
  final transform = TransformationController();
  StudioMapTool tool = StudioMapTool.select;
  ProjectElementEntry? brush;
  TileLayerPaletteEntry? tile;
  ProjectSmartTilePreset? terrain;
  ProjectCharacterEntry? character;
  ProjectMapEntry? warpDestination;
  String? selectedEntityId;
  String? selectedTriggerId;
  String? selectedWarpId;
  String? selectedPlacementId;
  String? selectedZoneId;
  GameplayZoneKind zoneKind = GameplayZoneKind.encounter;
  String characterQuery = '';
  double characterScrollOffset = 0;
  bool grid = true;
  bool paletteTiles = false;
  bool revealPalette = false;
  String paletteTab = 'Décors';
  final paletteScrollOffsets = <String, double>{};
  String? paletteAtlasId;
  final paletteAtlasTransforms = <String, TransformationController>{};
  final fittedPaletteAtlases = <String>{};
  bool positioned = false;
  VoidCallback? recenter;
  void Function(GridPos)? centerOn;

  void fitViewport(Size viewport, Size content) {
    final scale = math.min(
      1.0,
      math.min(
        viewport.width / content.width,
        viewport.height / content.height,
      ),
    );
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - content.width * scale) / 2,
        (viewport.height - content.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void centerCell(GridPos cell, Size viewport, Size tile) {
    final scale = transform.value.getMaxScaleOnAxis();
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - (cell.x + .5) * tile.width * scale,
        viewport.height / 2 - (cell.y + .5) * tile.height * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void prepareCharacterPlacement() {
    paletteTab = 'Personnages';
    brush = null;
    tile = null;
    terrain = null;
    tool = character == null ? StudioMapTool.select : StudioMapTool.character;
  }

  void prepareWarpPlacement() {
    paletteTab = 'Passages';
    brush = null;
    tile = null;
    terrain = null;
    character = null;
    tool = warpDestination == null
        ? StudioMapTool.select
        : StudioMapTool.warp;
  }

  void clearSelection() {
    selectedEntityId = null;
    selectedWarpId = null;
    selectedTriggerId = null;
    selectedPlacementId = null;
    selectedZoneId = null;
  }

  void dispose() {
    transform.dispose();
    for (final controller in paletteAtlasTransforms.values) {
      controller.dispose();
    }
  }
}
