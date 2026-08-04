import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

class ImageCollectionPropPreviewGrid extends StatelessWidget {
  const ImageCollectionPropPreviewGrid({
    super.key,
    required this.source,
    required this.cellWidth,
    required this.cellHeight,
    required this.imagesByAssetId,
    required this.selectedTileId,
    required this.elapsedMs,
    required this.onSelected,
  });

  final ProjectImageCollectionTilesetSource source;
  final int cellWidth;
  final int cellHeight;
  final Map<String, ui.Image> imagesByAssetId;
  final int? selectedTileId;
  final int elapsedMs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = buildImageCollectionPropPreviewItems(
      source: source,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
    if (items.isEmpty) {
      return const PokeMapEmptyState(
        icon: Icon(CupertinoIcons.square_grid_2x2),
        title: 'Aucun élément illustré',
        description:
            'Cette collection ne contient aucun prop autonome à prévisualiser.',
      );
    }
    return GridView.builder(
      key: const Key('image-collection-prop-preview-grid'),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return PokeMapAssetCard(
          key: Key('image-collection-prop-card-${item.tileId}'),
          thumbnail: ProjectTilesetVisualPreview(
            key: Key('image-collection-prop-preview-${item.tileId}'),
            visual: item.visual,
            imagesByAssetId: imagesByAssetId,
            elapsedMs: elapsedMs,
          ),
          label: item.displayName,
          description: item.isAnimated
              ? 'Animé · ${item.frameCount} images · ${item.pixelSizeLabel}'
              : 'Statique · ${item.pixelSizeLabel}',
          selected: selectedTileId == item.tileId,
          onPressed: () => onSelected(item.tileId),
          trailing: PokeMapBadge(
            label: item.isAnimated ? 'Animé' : 'Prop',
            variant: item.isAnimated
                ? PokeMapBadgeVariant.info
                : PokeMapBadgeVariant.neutral,
          ),
        );
      },
    );
  }
}

/// Pixel-perfect preview for any visual produced by the shared core resolver.
class ProjectTilesetVisualPreview extends StatelessWidget {
  const ProjectTilesetVisualPreview({
    super.key,
    required this.visual,
    required this.imagesByAssetId,
    required this.elapsedMs,
    this.extent = 56,
  });

  final ProjectTilesetVisualResolution visual;
  final Map<String, ui.Image> imagesByAssetId;
  final int elapsedMs;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final frame = visual.frameAt(elapsedMs);
    final hasEveryImage = frame.slices.every(
      (slice) => imagesByAssetId.containsKey(slice.assetId),
    );
    final colors = context.pokeMapColors;
    return Container(
      width: extent,
      height: extent,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasEveryImage
          ? CustomPaint(
              size: Size.square(extent),
              painter: _ProjectTilesetVisualPainter(
                visual: visual,
                imagesByAssetId: imagesByAssetId,
                elapsedMs: elapsedMs,
              ),
            )
          : Icon(
              CupertinoIcons.photo,
              size: 18,
              color: colors.textDisabled,
            ),
    );
  }
}

final class _ProjectTilesetVisualPainter extends CustomPainter {
  const _ProjectTilesetVisualPainter({
    required this.visual,
    required this.imagesByAssetId,
    required this.elapsedMs,
  });

  final ProjectTilesetVisualResolution visual;
  final Map<String, ui.Image> imagesByAssetId;
  final int elapsedMs;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = visual.animationBounds;
    if (bounds.width <= 0 || bounds.height <= 0) return;
    final availableWidth = math.max(0.0, size.width - 8);
    final availableHeight = math.max(0.0, size.height - 8);
    final scale = math.min(
      availableWidth / bounds.width,
      availableHeight / bounds.height,
    );
    if (!scale.isFinite || scale <= 0) return;
    final visualWidth = bounds.width * scale;
    final visualHeight = bounds.height * scale;
    final originX = (size.width - visualWidth) / 2 - bounds.x * scale;
    final originY = (size.height - visualHeight) / 2 - bounds.y * scale;
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    canvas.save();
    canvas.translate(originX, originY);
    canvas.scale(scale, scale);
    for (final slice in visual.frameAt(elapsedMs).slices) {
      final image = imagesByAssetId[slice.assetId];
      if (image == null) continue;
      final source = slice.sourceRect;
      final destination = slice.destinationRect;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          source.x.toDouble(),
          source.y.toDouble(),
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        Rect.fromLTWH(
          destination.x.toDouble(),
          destination.y.toDouble(),
          destination.width.toDouble(),
          destination.height.toDouble(),
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProjectTilesetVisualPainter oldDelegate) =>
      !identical(oldDelegate.visual, visual) ||
      !identical(oldDelegate.imagesByAssetId, imagesByAssetId) ||
      oldDelegate.elapsedMs != elapsedMs;
}
