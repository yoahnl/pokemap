import '../exceptions/map_exceptions.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';
import '../models/scene_warp_presentation.dart';
import 'project_tileset_visual_resolver.dart';

final class ResolvedSceneWarpIllustration {
  const ResolvedSceneWarpIllustration({
    required this.elementId,
    required this.tilesetId,
    required this.frame,
  });

  final String elementId;
  final String tilesetId;
  final ProjectTilesetVisualFrameResolution frame;
}

ResolvedSceneWarpIllustration? resolveSceneWarpPresentationVisual(
  SceneWarpPresentation presentation,
  ProjectManifest project,
) {
  if (project.settings.dimension != ProjectDimension.twoD) {
    throw const ValidationException('Warp presentations require a 2D project.');
  }
  final id = presentation.illustrationElementId;
  if (id == null) return null;
  final elements = project.elements
      .where((element) => element.id == id)
      .toList();
  if (elements.length != 1 ||
      elements.single.frames.length != 1 ||
      elements.single.collisionProfile != null) {
    throw const ValidationException(
      'Warp illustration must be one unique static native element.',
    );
  }
  final element = elements.single;
  final frame = element.frames.single;
  final tilesetId = frame.tilesetId.isEmpty
      ? element.tilesetId
      : frame.tilesetId;
  final tilesets = project.tilesets
      .where((tileset) => tileset.id == tilesetId)
      .toList();
  if (tilesets.length != 1 ||
      tilesets.single.source is! ProjectRegularAtlasTilesetSource) {
    throw const ValidationException(
      'Warp illustration requires a unique regular native atlas.',
    );
  }
  final source = tilesets.single.source! as ProjectRegularAtlasTilesetSource;
  final ProjectTilesetVisualResolution resolved;
  try {
    resolved = const ProjectTilesetVisualResolver().resolve(
      source: source,
      selection: ProjectTilesetVisualSelection.regularAtlas(
        source: frame.source,
      ),
      cellWidth: source.tileWidth,
      cellHeight: source.tileHeight,
    );
  } on ProjectTilesetVisualResolutionException {
    throw const ValidationException(
      'Warp illustration frame is outside its native atlas.',
    );
  }
  final bounds = resolved.animationBounds;
  if (resolved.isAnimated ||
      bounds.width <= 0 ||
      bounds.height <= 0 ||
      bounds.width > 2048 ||
      bounds.height > 2048) {
    throw const ValidationException(
      'Warp illustration must be static and bounded to 2048 pixels per side.',
    );
  }
  return ResolvedSceneWarpIllustration(
    elementId: id,
    tilesetId: tilesetId,
    frame: resolved.frames.single,
  );
}
