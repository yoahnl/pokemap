import 'package:map_core/map_core.dart';

/// Smart Tile input held while the editor saves unrelated local map edits.
final class DeferredSmartTileGesture {
  DeferredSmartTileGesture({
    required this.projectRootPath,
    required this.mapId,
    required this.layerId,
    required this.materialId,
    required Iterable<GridPos> cells,
    this.selection,
  }) : cells = cells.toSet();

  final String projectRootPath;
  final String mapId;
  final String layerId;
  final String? materialId;
  SmartTileGestureSelection? selection;
  final Set<GridPos> cells;

  bool targets({
    required String projectRootPath,
    required String mapId,
    required String layerId,
    required String? materialId,
  }) =>
      this.projectRootPath == projectRootPath &&
      this.mapId == mapId &&
      this.layerId == layerId &&
      this.materialId == materialId;

  void merge(
    Iterable<GridPos> additions, {
    SmartTileGestureSelection? selection,
  }) {
    cells.addAll(additions);
    if (this.selection != selection) this.selection = null;
  }
}
