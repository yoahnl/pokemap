part of 'studio_map_visual_widgets.dart';

extension _StudioMapVisualAnimationScan on _StudioMapVisualState {
  ProjectTilesetVisualResolution? _animationFor(TileLayerPaletteEntry tile) =>
      _animations.putIfAbsent((tile.tilesetId, tile.localTileId), () {
        final source = widget.resources.tilesets[tile.tilesetId]?.source;
        if (source is! ProjectRegularAtlasTilesetSource ||
            source.columns <= 0 ||
            tile.localTileId < 0 ||
            tile.localTileId >= source.tileCount ||
            !source.tileAnimations.any(
              (animation) =>
                  animation.tileId == tile.localTileId &&
                  animation.frames.length > 1,
            )) {
          return null;
        }
        final settings = widget.resources.manifest.settings;
        try {
          return const ProjectTilesetVisualResolver().resolve(
            source: source,
            selection: ProjectTilesetVisualSelection.regularAtlas(
              source: TilesetSourceRect(
                x: tile.localTileId % source.columns,
                y: tile.localTileId ~/ source.columns,
              ),
            ),
            cellWidth: settings.tileWidth,
            cellHeight: settings.tileHeight,
          );
        } on ProjectTilesetVisualResolutionException {
          return null;
        }
      });

  bool _loaded(ProjectTilesetVisualResolution visual, String tilesetId) =>
      visual.frames.every(
        (frame) => frame.slices.every((slice) {
          final image =
              widget.resources.images[slice.assetId] ??
              widget.resources.images[tilesetId];
          final source = slice.sourceRect;
          return image != null &&
              image.containsSourceRect(
                Rect.fromLTWH(
                  source.x.toDouble(),
                  source.y.toDouble(),
                  source.width.toDouble(),
                  source.height.toDouble(),
                ),
              );
        }),
      );

  Set<ProjectTilesetVisualResolution> _animationsIn(Rect viewport) {
    final found = <ProjectTilesetVisualResolution>{};
    if (viewport.isEmpty) return found;
    final settings = widget.resources.manifest.settings;
    final scale = settings.displayScale;
    final cellWidth = settings.tileWidth * scale;
    final cellHeight = settings.tileHeight * scale;
    if (cellWidth <= 0 || cellHeight <= 0) return found;
    for (final layer in widget.map.layers) {
      if (!layer.isVisible ||
          layer.opacity <= 0 ||
          !mapLayerParticipatesInVisualComposition(layer)) {
        continue;
      }
      if (layer is TileLayer) {
        final palette = <int, ProjectTilesetVisualResolution>{};
        Rect? bounds;
        for (var i = 0; i < layer.palette.length; i++) {
          final tile = layer.palette[i];
          final visual = _animationFor(tile);
          if (visual == null || !_loaded(visual, tile.tilesetId)) continue;
          palette[i + 1] = visual;
          final extent = visual.animationBounds;
          final rect = Rect.fromLTWH(
            extent.x * scale.toDouble(),
            extent.y * scale.toDouble(),
            extent.width * scale.toDouble(),
            extent.height * scale.toDouble(),
          );
          bounds = bounds?.expandToInclude(rect) ?? rect;
        }
        if (bounds == null) continue;
        final width = widget.map.size.width;
        final height = widget.map.size.height;
        final startX = ((viewport.left - bounds.right) / cellWidth)
            .floor()
            .clamp(0, width);
        final endX = ((viewport.right - bounds.left) / cellWidth).ceil().clamp(
          0,
          width,
        );
        final startY = ((viewport.top - bounds.bottom) / cellHeight)
            .floor()
            .clamp(0, height);
        final endY = ((viewport.bottom - bounds.top) / cellHeight).ceil().clamp(
          0,
          height,
        );
        for (var y = startY; y < endY; y++) {
          for (var x = startX; x < endX; x++) {
            final index = y * width + x;
            if (index >= layer.cells.length) continue;
            final visual = palette[layer.cells[index]];
            if (visual == null) continue;
            final extent = visual.animationBounds;
            final rect = Rect.fromLTWH(
              x * cellWidth + extent.x * scale.toDouble(),
              y * cellHeight + extent.y * scale.toDouble(),
              extent.width * scale.toDouble(),
              extent.height * scale.toDouble(),
            );
            if (rect.overlaps(viewport)) found.add(visual);
          }
        }
      } else if (layer is ObjectLayer) {
        final animatedObjects = _objectAnimations.putIfAbsent(layer, () {
          final animations = <String, ProjectTilesetVisualResolution>{};
          for (final object in layer.tileObjects) {
            if (!object.isVisible || object.opacity <= 0) continue;
            final visual = _animationFor(object.tile);
            if (visual != null) animations[object.id] = visual;
          }
          return animations;
        });
        if (animatedObjects.isEmpty) continue;
        try {
          final index = _objectIndices.putIfAbsent(
            layer,
            () => MapPlacedTileVisualIndex.build(
              layer: layer,
              tilesetsById: {
                for (final entry in widget.resources.manifest.tilesets)
                  entry.id: ?entry.source,
              },
              sourceCellWidth: settings.tileWidth,
              sourceCellHeight: settings.tileHeight,
              destinationCellWidth: cellWidth.toDouble(),
              destinationCellHeight: cellHeight.toDouble(),
            ),
          );
          for (final instruction
              in index
                  .resolve(
                    elapsedMs: _elapsed.inMilliseconds,
                    viewport: SmartTileGeometryRect(
                      left: viewport.left,
                      top: viewport.top,
                      width: viewport.width,
                      height: viewport.height,
                    ),
                  )
                  .visuals) {
            final visual = animatedObjects[instruction.objectId];
            if (visual != null && _loaded(visual, instruction.tilesetId)) {
              found.add(visual);
            }
          }
        } on MapPlacedTileVisualResolutionException {
          continue;
        }
      }
    }
    return found;
  }
}
