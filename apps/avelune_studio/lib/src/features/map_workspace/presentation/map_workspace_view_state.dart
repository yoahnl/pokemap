import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

enum StudioMapTool { select, place, paint, erase, pan }

class MapWorkspaceViewState {
  final transform = TransformationController();
  StudioMapTool tool = StudioMapTool.select;
  ProjectElementEntry? brush;
  TileLayerPaletteEntry? tile;
  bool grid = true;
  bool positioned = false;
  VoidCallback? recenter;

  void dispose() => transform.dispose();
}
