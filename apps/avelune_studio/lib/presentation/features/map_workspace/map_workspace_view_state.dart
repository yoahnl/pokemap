import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

enum StudioMapTool {
  select,
  place,
  paint,
  terrain,
  character,
  zone,
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
  String? selectedEntityId;
  String characterQuery = '';
  double characterScrollOffset = 0;
  bool grid = true;
  bool paletteTiles = false;
  String paletteTab = 'Décors';
  final paletteScrollOffsets = <String, double>{};
  String? paletteAtlasId;
  final paletteAtlasTransforms = <String, TransformationController>{};
  final fittedPaletteAtlases = <String>{};
  bool positioned = false;
  VoidCallback? recenter;

  void dispose() {
    transform.dispose();
    for (final controller in paletteAtlasTransforms.values) {
      controller.dispose();
    }
  }
}
