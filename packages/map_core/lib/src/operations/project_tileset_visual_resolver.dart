import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';

enum ProjectTilesetVisualAnchor {
  automatic,
  topLeft,
  bottomLeft,
}

sealed class ProjectTilesetVisualSelection {
  const ProjectTilesetVisualSelection();

  const factory ProjectTilesetVisualSelection.regularAtlas({
    required TilesetSourceRect source,
  }) = ProjectRegularAtlasVisualSelection;

  const factory ProjectTilesetVisualSelection.imageCollection({
    required int tileId,
  }) = ProjectImageCollectionVisualSelection;
}

final class ProjectRegularAtlasVisualSelection
    extends ProjectTilesetVisualSelection {
  const ProjectRegularAtlasVisualSelection({required this.source});

  final TilesetSourceRect source;
}

final class ProjectImageCollectionVisualSelection
    extends ProjectTilesetVisualSelection {
  const ProjectImageCollectionVisualSelection({required this.tileId});

  final int tileId;
}

final class ProjectTilesetVisualResolutionException implements Exception {
  const ProjectTilesetVisualResolutionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'ProjectTilesetVisualResolutionException($code): $message';
}

/// One exact source-to-destination draw owned by a resolved visual frame.
///
/// Rectangles use canonical project pixels. Platform renderers may apply the
/// project display scale after resolution, but must not recalculate atlas or
/// image-collection geometry themselves.
final class ProjectTilesetVisualSlice {
  const ProjectTilesetVisualSlice({
    required this.assetId,
    required this.sourceRect,
    required this.destinationRect,
  });

  final String assetId;
  final ProjectTilesetPixelRect sourceRect;
  final ProjectTilesetPixelRect destinationRect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTilesetVisualSlice &&
          other.assetId == assetId &&
          other.sourceRect == sourceRect &&
          other.destinationRect == destinationRect;

  @override
  int get hashCode => Object.hash(assetId, sourceRect, destinationRect);
}

final class ProjectTilesetVisualFrameResolution {
  factory ProjectTilesetVisualFrameResolution({
    required int? tileId,
    required int durationMs,
    required Iterable<ProjectTilesetVisualSlice> slices,
  }) {
    final values = List<ProjectTilesetVisualSlice>.unmodifiable(slices);
    return ProjectTilesetVisualFrameResolution._(
      tileId: tileId,
      durationMs: durationMs,
      slices: values,
      bounds: _boundsOf(
        values.map((slice) => slice.destinationRect),
        code: 'tileset.visual.frame_empty',
      ),
    );
  }

  const ProjectTilesetVisualFrameResolution._({
    required this.tileId,
    required this.durationMs,
    required this.slices,
    required this.bounds,
  });

  /// Sparse local tile identity for collections, otherwise `null`.
  final int? tileId;
  final int durationMs;
  final List<ProjectTilesetVisualSlice> slices;
  final ProjectTilesetPixelRect bounds;
}

final class ProjectTilesetVisualResolution {
  factory ProjectTilesetVisualResolution({
    required Iterable<ProjectTilesetVisualFrameResolution> frames,
  }) {
    final values =
        List<ProjectTilesetVisualFrameResolution>.unmodifiable(frames);
    final totalDurationMs = values.fold<int>(
      0,
      (total, frame) => total + frame.durationMs,
    );
    if (values.length > 1 &&
        (totalDurationMs <= 0 ||
            values.any((frame) => frame.durationMs <= 0))) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.animation_invalid',
        'Animated visual frames must all have a positive duration.',
      );
    }
    return ProjectTilesetVisualResolution._(
      frames: values,
      animationBounds: _boundsOf(
        values.map((frame) => frame.bounds),
        code: 'tileset.visual.frames_empty',
      ),
      totalDurationMs: totalDurationMs,
    );
  }

  const ProjectTilesetVisualResolution._({
    required this.frames,
    required this.animationBounds,
    required this.totalDurationMs,
  });

  final List<ProjectTilesetVisualFrameResolution> frames;
  final ProjectTilesetPixelRect animationBounds;
  final int totalDurationMs;

  bool get isAnimated => frames.length > 1;

  ProjectTilesetVisualFrameResolution frameAt(int elapsedMs) {
    if (!isAnimated || totalDurationMs <= 0) return frames.first;
    final normalized =
        ((elapsedMs % totalDurationMs) + totalDurationMs) % totalDurationMs;
    var cursor = 0;
    for (final frame in frames) {
      cursor += frame.durationMs;
      if (normalized < cursor) return frame;
    }
    return frames.last;
  }

  ProjectTilesetPixelRect cullingRectAt(
    int elapsedMs, {
    required int originX,
    required int originY,
    bool conservativeAnimationBounds = false,
  }) {
    final bounds = conservativeAnimationBounds
        ? animationBounds
        : frameAt(elapsedMs).bounds;
    return ProjectTilesetPixelRect(
      x: originX + bounds.x,
      y: originY + bounds.y,
      width: bounds.width,
      height: bounds.height,
    );
  }

  bool isVisibleAt(
    int elapsedMs, {
    required int originX,
    required int originY,
    required ProjectTilesetPixelRect viewport,
    bool conservativeAnimationBounds = false,
  }) {
    if (viewport.width <= 0 || viewport.height <= 0) return false;
    final bounds = cullingRectAt(
      elapsedMs,
      originX: originX,
      originY: originY,
      conservativeAnimationBounds: conservativeAnimationBounds,
    );
    return bounds.x < viewport.x + viewport.width &&
        viewport.x < bounds.x + bounds.width &&
        bounds.y < viewport.y + viewport.height &&
        viewport.y < bounds.y + bounds.height;
  }
}

/// Canonical resolver shared by editor previews and runtime render plans.
///
/// Regular atlases are sliced cell by cell so margins and gutters are never
/// painted as sprite pixels. Image-collection tiles keep their native size,
/// use Tiled-compatible bottom-left anchoring by default and can change page,
/// dimensions and offsets on every animation frame.
final class ProjectTilesetVisualResolver {
  const ProjectTilesetVisualResolver();

  ProjectTilesetVisualResolution resolve({
    required ProjectTilesetSource source,
    required ProjectTilesetVisualSelection selection,
    required int cellWidth,
    required int cellHeight,
    ProjectTilesetVisualAnchor anchor = ProjectTilesetVisualAnchor.automatic,
  }) {
    if (cellWidth <= 0 || cellHeight <= 0) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.cell_size_invalid',
        'Visual cell dimensions must be positive.',
      );
    }
    if (source is ProjectRegularAtlasTilesetSource &&
        selection is ProjectRegularAtlasVisualSelection) {
      return _resolveRegularAtlas(
        source,
        selection.source,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        anchor: anchor,
      );
    }
    if (source is ProjectImageCollectionTilesetSource &&
        selection is ProjectImageCollectionVisualSelection) {
      return _resolveImageCollection(
        source,
        selection.tileId,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        anchor: anchor,
      );
    }
    throw const ProjectTilesetVisualResolutionException(
      'tileset.visual.selection_mismatch',
      'The visual selection does not match the tileset source kind.',
    );
  }
}

ProjectTilesetVisualResolution _resolveRegularAtlas(
  ProjectRegularAtlasTilesetSource atlas,
  TilesetSourceRect source, {
  required int cellWidth,
  required int cellHeight,
  required ProjectTilesetVisualAnchor anchor,
}) {
  if (atlas.assetId.trim().isEmpty ||
      atlas.pixelWidth <= 0 ||
      atlas.pixelHeight <= 0 ||
      atlas.tileWidth <= 0 ||
      atlas.tileHeight <= 0 ||
      atlas.marginX < 0 ||
      atlas.marginY < 0 ||
      atlas.spacingX < 0 ||
      atlas.spacingY < 0 ||
      atlas.columns <= 0 ||
      atlas.rows <= 0 ||
      atlas.marginX * 2 +
              atlas.columns * atlas.tileWidth +
              (atlas.columns - 1) * atlas.spacingX !=
          atlas.pixelWidth ||
      atlas.marginY * 2 +
              atlas.rows * atlas.tileHeight +
              (atlas.rows - 1) * atlas.spacingY !=
          atlas.pixelHeight) {
    throw const ProjectTilesetVisualResolutionException(
      'tileset.visual.atlas_invalid',
      'The regular atlas has invalid canonical geometry.',
    );
  }
  if (source.x < 0 ||
      source.y < 0 ||
      source.width <= 0 ||
      source.height <= 0 ||
      source.x + source.width > atlas.columns ||
      source.y + source.height > atlas.rows) {
    throw const ProjectTilesetVisualResolutionException(
      'tileset.visual.source_out_of_bounds',
      'The regular-atlas visual source leaves the canonical tile grid.',
    );
  }
  final effectiveAnchor = anchor == ProjectTilesetVisualAnchor.automatic
      ? ProjectTilesetVisualAnchor.topLeft
      : anchor;
  final visualHeight = source.height * cellHeight;
  final anchorTop = effectiveAnchor == ProjectTilesetVisualAnchor.bottomLeft
      ? cellHeight - visualHeight
      : 0;
  final slices = <ProjectTilesetVisualSlice>[];
  for (var row = 0; row < source.height; row += 1) {
    for (var column = 0; column < source.width; column += 1) {
      slices.add(
        ProjectTilesetVisualSlice(
          assetId: atlas.assetId,
          sourceRect: ProjectTilesetPixelRect(
            x: atlas.marginX +
                (source.x + column) * (atlas.tileWidth + atlas.spacingX),
            y: atlas.marginY +
                (source.y + row) * (atlas.tileHeight + atlas.spacingY),
            width: atlas.tileWidth,
            height: atlas.tileHeight,
          ),
          destinationRect: ProjectTilesetPixelRect(
            x: atlas.pixelOffsetX + column * cellWidth,
            y: atlas.pixelOffsetY + anchorTop + row * cellHeight,
            width: cellWidth,
            height: cellHeight,
          ),
        ),
      );
    }
  }
  return ProjectTilesetVisualResolution(
    frames: <ProjectTilesetVisualFrameResolution>[
      ProjectTilesetVisualFrameResolution(
        tileId: null,
        durationMs: 0,
        slices: slices,
      ),
    ],
  );
}

ProjectTilesetVisualResolution _resolveImageCollection(
  ProjectImageCollectionTilesetSource collection,
  int tileId, {
  required int cellWidth,
  required int cellHeight,
  required ProjectTilesetVisualAnchor anchor,
}) {
  final pages = <String, ProjectImageCollectionPage>{};
  final assetIds = <String>{};
  for (final page in collection.pages) {
    if (page.id.trim().isEmpty ||
        page.assetId.trim().isEmpty ||
        page.pixelWidth <= 0 ||
        page.pixelHeight <= 0 ||
        pages.containsKey(page.id) ||
        !assetIds.add(page.assetId)) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.page_invalid',
        'Image-collection pages must have unique valid identities and sizes.',
      );
    }
    pages[page.id] = page;
  }
  final tiles = <int, ProjectImageCollectionTileDefinition>{};
  for (final tile in collection.tileDefinitions) {
    if (tiles.containsKey(tile.tileId)) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.tile_duplicate',
        'Image-collection tile identities must be unique.',
      );
    }
    tiles[tile.tileId] = tile;
  }
  final rootTile = tiles[tileId];
  if (rootTile == null) {
    throw const ProjectTilesetVisualResolutionException(
      'tileset.visual.tile_missing',
      'The requested image-collection tile does not exist.',
    );
  }
  final timeline = rootTile.animation.isEmpty
      ? <ProjectImageCollectionAnimationFrame>[
          ProjectImageCollectionAnimationFrame(
            tileId: rootTile.tileId,
            durationMs: 0,
          ),
        ]
      : rootTile.animation;
  final effectiveAnchor = anchor == ProjectTilesetVisualAnchor.automatic
      ? ProjectTilesetVisualAnchor.bottomLeft
      : anchor;
  final frames = <ProjectTilesetVisualFrameResolution>[];
  for (final timelineFrame in timeline) {
    final tile = tiles[timelineFrame.tileId];
    if (tile == null) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.animation_tile_missing',
        'An image-collection animation references a missing tile.',
      );
    }
    if (rootTile.animation.isNotEmpty && timelineFrame.durationMs <= 0) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.animation_invalid',
        'Animated visual frames must all have a positive duration.',
      );
    }
    final page = pages[tile.pageId];
    if (page == null) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.page_missing',
        'An image-collection tile references a missing packed page.',
      );
    }
    final rect = tile.sourceRect;
    if (rect.x < 0 ||
        rect.y < 0 ||
        rect.width <= 0 ||
        rect.height <= 0 ||
        rect.x + rect.width > page.pixelWidth ||
        rect.y + rect.height > page.pixelHeight) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.source_out_of_bounds',
        'An image-collection source rectangle leaves its packed page.',
      );
    }
    final anchorTop = effectiveAnchor == ProjectTilesetVisualAnchor.bottomLeft
        ? cellHeight - rect.height
        : 0;
    frames.add(
      ProjectTilesetVisualFrameResolution(
        tileId: tile.tileId,
        durationMs: timelineFrame.durationMs,
        slices: <ProjectTilesetVisualSlice>[
          ProjectTilesetVisualSlice(
            assetId: page.assetId,
            sourceRect: rect,
            destinationRect: ProjectTilesetPixelRect(
              x: tile.offsetX,
              y: tile.offsetY + anchorTop,
              width: rect.width,
              height: rect.height,
            ),
          ),
        ],
      ),
    );
  }
  return ProjectTilesetVisualResolution(frames: frames);
}

ProjectTilesetPixelRect _boundsOf(
  Iterable<ProjectTilesetPixelRect> rects, {
  required String code,
}) {
  final values = rects.toList(growable: false);
  if (values.isEmpty) {
    throw ProjectTilesetVisualResolutionException(
      code,
      'A resolved visual must contain at least one drawable rectangle.',
    );
  }
  var left = values.first.x;
  var top = values.first.y;
  var right = values.first.x + values.first.width;
  var bottom = values.first.y + values.first.height;
  for (final rect in values) {
    if (rect.width <= 0 || rect.height <= 0) {
      throw const ProjectTilesetVisualResolutionException(
        'tileset.visual.rectangle_invalid',
        'Resolved visual rectangles must have positive dimensions.',
      );
    }
    if (rect.x < left) left = rect.x;
    if (rect.y < top) top = rect.y;
    if (rect.x + rect.width > right) right = rect.x + rect.width;
    if (rect.y + rect.height > bottom) bottom = rect.y + rect.height;
  }
  return ProjectTilesetPixelRect(
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );
}
