import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/assets/editor_image_cache.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../smart_tiles_studio/application/smart_tile_sprite_source.dart';

class WorldMapSmartTileAtlasThumbnail extends StatefulWidget {
  const WorldMapSmartTileAtlasThumbnail({
    super.key,
    required this.usage,
    required this.preset,
    required this.atlasUsage,
    required this.tilesets,
    required this.projectRootPath,
  });

  final SmartTileUsage usage;
  final ProjectSmartTilePreset preset;
  final WorldMapSmartTileAtlasUsage atlasUsage;
  final List<ProjectTilesetEntry> tilesets;
  final String? projectRootPath;

  @override
  State<WorldMapSmartTileAtlasThumbnail> createState() =>
      _WorldMapSmartTileAtlasThumbnailState();
}

class _WorldMapSmartTileAtlasThumbnailState
    extends State<WorldMapSmartTileAtlasThumbnail> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final keyPrefix =
        'world-map-smart-${widget.usage.name}-preset-${widget.preset.id}';
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.centerLeft,
        followerAnchor: Alignment.centerRight,
        offset: const Offset(-12, 0),
        showWhenUnlinked: false,
        child: IgnorePointer(
          child: SizedBox(
            key: ValueKey<String>('$keyPrefix-atlas-hover-preview'),
            width: 430,
            child: PokeMapCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Atlas utilisé',
                    style: TextStyle(
                      color: context.pokeMapColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.atlasUsage.atlas.name,
                    style: TextStyle(
                      color: context.pokeMapColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 280,
                    child: _SmartTileAtlasImage(
                      atlasUsage: widget.atlasUsage,
                      tilesets: widget.tilesets,
                      projectRootPath: widget.projectRootPath,
                      imageKey: ValueKey<String>(
                        '$keyPrefix-atlas-hover-image',
                      ),
                      semanticLabel:
                          'Atlas ${widget.atlasUsage.atlas.name}, zones utilisées surlignées',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: context.pokeMapColors.brandPrimarySoft,
                          border: Border.all(
                            color: context.pokeMapColors.brandPrimaryBorder,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${widget.atlasUsage.frames.length} '
                          'zone${widget.atlasUsage.frames.length > 1 ? 's' : ''} '
                          'utilisée${widget.atlasUsage.frames.length > 1 ? 's' : ''} '
                          'par ce preset',
                          style: TextStyle(
                            color: context.pokeMapColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Tooltip(
          message: 'Survoler pour inspecter ${widget.atlasUsage.atlas.name}',
          child: MouseRegion(
            onEnter: (_) => _overlayController.show(),
            onExit: (_) => _overlayController.hide(),
            child: KeyedSubtree(
              key: ValueKey<String>('$keyPrefix-atlas-thumbnail'),
              child: SizedBox(
                width: 58,
                height: 58,
                child: _SmartTileAtlasImage(
                  atlasUsage: widget.atlasUsage,
                  tilesets: widget.tilesets,
                  projectRootPath: widget.projectRootPath,
                  imageKey: ValueKey<String>('$keyPrefix-atlas-image'),
                  semanticLabel:
                      'Atlas utilisé : ${widget.atlasUsage.atlas.name}',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmartTileAtlasImage extends ConsumerStatefulWidget {
  const _SmartTileAtlasImage({
    required this.atlasUsage,
    required this.tilesets,
    required this.projectRootPath,
    required this.semanticLabel,
    this.imageKey,
  });

  final WorldMapSmartTileAtlasUsage atlasUsage;
  final List<ProjectTilesetEntry> tilesets;
  final String? projectRootPath;
  final String semanticLabel;
  final Key? imageKey;

  @override
  ConsumerState<_SmartTileAtlasImage> createState() =>
      _SmartTileAtlasImageState();
}

class _SmartTileAtlasImageState extends ConsumerState<_SmartTileAtlasImage> {
  EditorImageLoadResult? _result;
  String? _requestedKey;
  var _requestEpoch = 0;

  @override
  void dispose() {
    _result?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _resolveAtlasSource(
      usage: widget.atlasUsage,
      tilesets: widget.tilesets,
      projectRootPath: widget.projectRootPath,
    );
    if (source == null) {
      _releaseCurrent();
      return _fallback(context);
    }
    final cache = ref.watch(editorImageCacheProvider(source.projectRootPath));
    _ensureLoad(cache, source);
    final image = _result?.image;
    if (image == null) {
      return _result == null ? _loading(context) : _fallback(context);
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: Container(
        key: widget.imageKey,
        decoration: BoxDecoration(
          color: context.pokeMapColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: context.pokeMapColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(4),
        child: CustomPaint(
          painter: _SmartTileAtlasPainter(
            image: image,
            atlas: widget.atlasUsage.atlas,
            frames: widget.atlasUsage.frames,
            highlightFill: context.pokeMapColors.brandPrimarySoft.withValues(
              alpha: 0.38,
            ),
            highlightBorder: context.pokeMapColors.brandPrimaryBorder,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  void _ensureLoad(EditorImageCache cache, _AtlasImageSource source) {
    final key = '${source.absolutePath}#${source.sourceRect}';
    if (_requestedKey == key) return;
    _requestedKey = key;
    final epoch = ++_requestEpoch;
    _result?.dispose();
    _result = null;
    unawaited(() async {
      final result = await cache.loadCrop(
        source.absolutePath,
        sourceRect: source.sourceRect,
        variantKey: 'smart-tile-atlas-preview-${widget.atlasUsage.atlas.id}',
        sourceVariantKey: 'smart-tile-atlas',
      );
      if (!mounted || epoch != _requestEpoch) {
        result.dispose();
        return;
      }
      setState(() => _result = result);
    }());
  }

  void _releaseCurrent() {
    if (_requestedKey == null && _result == null) return;
    _requestedKey = null;
    _requestEpoch += 1;
    _result?.dispose();
    _result = null;
  }

  Widget _loading(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.pokeMapColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: context.pokeMapColors.borderSubtle),
    ),
    child: Icon(
      Icons.hourglass_empty_rounded,
      color: context.pokeMapColors.textMuted,
      size: 18,
    ),
  );

  Widget _fallback(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.pokeMapColors.controlSurface,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: context.pokeMapColors.borderSubtle),
    ),
    child: Icon(
      Icons.broken_image_outlined,
      color: context.pokeMapColors.textMuted,
      size: 18,
    ),
  );
}

class _SmartTileAtlasPainter extends CustomPainter {
  const _SmartTileAtlasPainter({
    required this.image,
    required this.atlas,
    required this.frames,
    required this.highlightFill,
    required this.highlightBorder,
  });

  final ui.Image image;
  final ProjectSmartTileAtlas atlas;
  final List<SmartTileFrameRef> frames;
  final Color highlightFill;
  final Color highlightBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imageSize, size);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      Offset.zero & imageSize,
      destination,
      Paint()..filterQuality = FilterQuality.none,
    );
    final atlasOriginX = atlas.originX + atlas.marginX;
    final atlasOriginY = atlas.originY + atlas.marginY;
    final fillPaint = Paint()
      ..color = highlightFill
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = highlightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final frame in frames) {
      late final SmartTileSourceRect source;
      try {
        source = atlas.sourceRectFor(
          column: frame.column,
          row: frame.row,
          columnSpan: frame.columnSpan,
          rowSpan: frame.rowSpan,
        );
      } on RangeError {
        continue;
      }
      final highlighted = Rect.fromLTWH(
        destination.left +
            (source.x - atlasOriginX) / image.width * destination.width,
        destination.top +
            (source.y - atlasOriginY) / image.height * destination.height,
        source.width / image.width * destination.width,
        source.height / image.height * destination.height,
      );
      canvas.drawRect(highlighted, fillPaint);
      canvas.drawRect(highlighted, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmartTileAtlasPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.atlas != atlas ||
      oldDelegate.frames != frames ||
      oldDelegate.highlightFill != highlightFill ||
      oldDelegate.highlightBorder != highlightBorder;
}

final class WorldMapSmartTileAtlasUsage {
  const WorldMapSmartTileAtlasUsage({
    required this.atlas,
    required this.frames,
  });

  final ProjectSmartTileAtlas atlas;
  final List<SmartTileFrameRef> frames;
}

final class _AtlasImageSource {
  const _AtlasImageSource({
    required this.absolutePath,
    required this.projectRootPath,
    required this.sourceRect,
  });

  final String absolutePath;
  final String projectRootPath;
  final Rect sourceRect;
}

List<WorldMapSmartTileAtlasUsage> collectWorldMapSmartTileAtlasUsages(
  ProjectSmartTilePreset preset,
  ProjectSmartTileCatalog catalog,
) {
  final frames = <SmartTileFrameRef>[];
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        switch (part.source) {
          case SmartTileFrameSource(:final frame):
            frames.add(frame);
          case SmartTileAnimationSource(:final animationId):
            final animation = catalog.animations
                .where((entry) => entry.id == animationId)
                .firstOrNull;
            if (animation != null) {
              frames.addAll(animation.frames.map((entry) => entry.frame));
            }
        }
      }
    }
  }
  final seen = <String>{};
  final grouped = <String, List<SmartTileFrameRef>>{};
  for (final frame in frames) {
    final identity =
        '${frame.atlasId}:${frame.column}:${frame.row}:'
        '${frame.columnSpan}:${frame.rowSpan}';
    if (!seen.add(identity)) continue;
    grouped.putIfAbsent(frame.atlasId, () => <SmartTileFrameRef>[]).add(frame);
  }
  return grouped.entries
      .map((entry) {
        final atlas = catalog.atlases
            .where((candidate) => candidate.id == entry.key)
            .firstOrNull;
        if (atlas == null) return null;
        return WorldMapSmartTileAtlasUsage(atlas: atlas, frames: entry.value);
      })
      .whereType<WorldMapSmartTileAtlasUsage>()
      .toList(growable: false);
}

_AtlasImageSource? _resolveAtlasSource({
  required WorldMapSmartTileAtlasUsage usage,
  required List<ProjectTilesetEntry> tilesets,
  required String? projectRootPath,
}) {
  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty || usage.frames.isEmpty) return null;
  final spriteSource = resolveSmartTileSpriteSource(
    frame: usage.frames.first,
    atlases: <ProjectSmartTileAtlas>[usage.atlas],
    tilesets: tilesets,
    projectRootPath: root,
  );
  if (spriteSource == null) return null;
  final atlas = usage.atlas;
  final width =
      atlas.columns * atlas.cellWidth + (atlas.columns - 1) * atlas.spacingX;
  final height =
      atlas.rows * atlas.cellHeight + (atlas.rows - 1) * atlas.spacingY;
  return _AtlasImageSource(
    absolutePath: spriteSource.absolutePath,
    projectRootPath: root,
    sourceRect: Rect.fromLTWH(
      (atlas.originX + atlas.marginX).toDouble(),
      (atlas.originY + atlas.marginY).toDouble(),
      width.toDouble(),
      height.toDouble(),
    ),
  );
}
