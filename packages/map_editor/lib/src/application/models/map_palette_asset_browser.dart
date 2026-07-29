import 'package:map_core/map_core.dart';

enum MapPaletteAssetBrowserStatus {
  ready,
  noProject,
  noMap,
  noActiveLayer,
  activeLayerMissing,
  unsupportedLayer,
  invalidMapScope,
  assignedSourceMissing,
}

enum MapPaletteAssetAssignmentState {
  alreadyAssigned,
  canAssign,
  noMap,
  noLayer,
  layerMissing,
  layerNotTile,
  outsideMapScope,
  layerNotEmpty,
}

class MapPaletteAssetFolderRow {
  const MapPaletteAssetFolderRow({
    required this.id,
    required this.name,
    required this.path,
    required this.depth,
  });

  final String id;
  final String name;
  final String path;
  final int depth;
}

class MapPaletteAssetCategoryRow {
  const MapPaletteAssetCategoryRow({
    required this.id,
    required this.name,
    required this.path,
    required this.depth,
  });

  final String id;
  final String name;
  final String path;
  final int depth;
}

class MapPaletteAssetBrowserItem {
  const MapPaletteAssetBrowserItem({
    required this.tileset,
    required this.folderPath,
    required this.scopeLabel,
    required this.explicitCategoryLabels,
    required this.isAssigned,
    required this.isSelected,
    required this.isFavorite,
    required this.isRecent,
    required this.isScopeAssignable,
    required this.isCompatible,
    required this.canAssign,
    required this.assignmentState,
    required this.disabledReason,
  });

  final ProjectTilesetEntry tileset;
  final String folderPath;
  final String scopeLabel;
  final List<String> explicitCategoryLabels;
  final bool isAssigned;
  final bool isSelected;
  final bool isFavorite;
  final bool isRecent;
  final bool isScopeAssignable;
  final bool isCompatible;
  final bool canAssign;
  final MapPaletteAssetAssignmentState assignmentState;
  final String? disabledReason;
}

class MapPaletteAssetBrowserProjection {
  const MapPaletteAssetBrowserProjection({
    required this.status,
    required this.activeLayerName,
    required this.assignedTilesetId,
    required this.selectedTilesetId,
    required this.folders,
    required this.categories,
    required this.items,
    required this.hiddenIncompatibleCount,
    required this.hasUnclassifiedSources,
    required this.diagnostic,
  });

  final MapPaletteAssetBrowserStatus status;
  final String? activeLayerName;
  final String? assignedTilesetId;
  final String? selectedTilesetId;
  final List<MapPaletteAssetFolderRow> folders;
  final List<MapPaletteAssetCategoryRow> categories;
  final List<MapPaletteAssetBrowserItem> items;
  final int hiddenIncompatibleCount;
  final bool hasUnclassifiedSources;
  final String? diagnostic;
}
