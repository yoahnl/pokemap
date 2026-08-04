import 'package:map_core/map_core.dart';

/// Runtime entry point for the platform-neutral tileset visual contract.
///
/// Coordinates remain in canonical project pixels. Flame applies display
/// scaling only after this function has resolved atlas gutters, prop anchoring,
/// animation frames and culling bounds.
ProjectTilesetVisualResolution resolveRuntimeProjectTilesetVisual({
  required ProjectTilesetSource source,
  required ProjectTilesetVisualSelection selection,
  required int cellWidth,
  required int cellHeight,
  ProjectTilesetVisualAnchor anchor = ProjectTilesetVisualAnchor.automatic,
}) {
  return const ProjectTilesetVisualResolver().resolve(
    source: source,
    selection: selection,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    anchor: anchor,
  );
}
