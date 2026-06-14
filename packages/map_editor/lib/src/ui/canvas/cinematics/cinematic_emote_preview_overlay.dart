import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

class CinematicEmotePreviewOverlay extends StatefulWidget {
  const CinematicEmotePreviewOverlay({
    super.key,
    required this.playbackFrame,
    required this.mapWidth,
    required this.mapHeight,
    required this.compact,
    this.atlasImagesById,
  });

  final CinematicPreviewPlaybackFrame playbackFrame;
  final int mapWidth;
  final int mapHeight;
  final bool compact;
  final Map<String, ui.Image?>? atlasImagesById;

  @override
  State<CinematicEmotePreviewOverlay> createState() =>
      _CinematicEmotePreviewOverlayState();
}

class CinematicEmoteCatalogThumbnail extends StatefulWidget {
  const CinematicEmoteCatalogThumbnail({
    super.key,
    required this.entry,
    this.size = 18,
  });

  final CinematicEmoteCatalogEntry entry;
  final double size;

  @override
  State<CinematicEmoteCatalogThumbnail> createState() =>
      _CinematicEmoteCatalogThumbnailState();
}

class _CinematicEmoteCatalogThumbnailState
    extends State<CinematicEmoteCatalogThumbnail> {
  AssetBundle? _bundle;
  String? _assetKey;
  Future<ui.Image?>? _imageFuture;

  @override
  Widget build(BuildContext context) {
    final atlas = cinematicEmoteAtlasById(widget.entry.atlasId);
    final size = widget.size;
    if (atlas == null) {
      return SizedBox(
        width: size,
        height: size,
        child: _CinematicEmoteFallback(label: widget.entry.label, size: size),
      );
    }

    final bundle = DefaultAssetBundle.of(context);
    if (_bundle != bundle || _assetKey != atlas.assetKey) {
      _bundle = bundle;
      _assetKey = atlas.assetKey;
      _imageFuture = _loadAtlasImage(bundle, atlas.assetKey);
    }

    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<ui.Image?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) {
            return _CinematicEmoteFallback(
                label: widget.entry.label, size: size);
          }
          return CustomPaint(
            painter: _CinematicEmoteSpritePainter(
              image: image,
              frame: widget.entry.frame,
              fallbackTextColor: context.pokeMapColors.textPrimary,
              fallbackBackgroundColor: context.pokeMapColors.surfaceSubtle,
              fallbackBorderColor: context.pokeMapColors.controlBorder,
            ),
          );
        },
      ),
    );
  }
}

class _CinematicEmotePreviewOverlayState
    extends State<CinematicEmotePreviewOverlay> {
  AssetBundle? _bundle;
  String _atlasSignature = '';
  Future<Map<String, ui.Image?>>? _atlasImagesFuture;

  @override
  Widget build(BuildContext context) {
    if (widget.playbackFrame.activeEmotes.isEmpty ||
        widget.mapWidth <= 0 ||
        widget.mapHeight <= 0) {
      return const SizedBox.shrink();
    }

    final providedImages = widget.atlasImagesById;
    if (providedImages != null) {
      return _CinematicEmotePreviewOverlayStack(
        playbackFrame: widget.playbackFrame,
        mapWidth: widget.mapWidth,
        mapHeight: widget.mapHeight,
        compact: widget.compact,
        atlasImagesById: providedImages,
      );
    }

    final bundle = DefaultAssetBundle.of(context);
    final atlasesById = _activeAtlasesById(widget.playbackFrame.activeEmotes);
    final signature = _atlasSignatureFor(atlasesById.keys);
    if (_bundle != bundle || _atlasSignature != signature) {
      _bundle = bundle;
      _atlasSignature = signature;
      _atlasImagesFuture = _loadAtlasImages(
        bundle: bundle,
        atlasesById: atlasesById,
      );
    }

    return FutureBuilder<Map<String, ui.Image?>>(
      future: _atlasImagesFuture,
      builder: (context, snapshot) {
        return _CinematicEmotePreviewOverlayStack(
          playbackFrame: widget.playbackFrame,
          mapWidth: widget.mapWidth,
          mapHeight: widget.mapHeight,
          compact: widget.compact,
          atlasImagesById: snapshot.data ?? const {},
        );
      },
    );
  }
}

class _CinematicEmotePreviewOverlayStack extends StatelessWidget {
  const _CinematicEmotePreviewOverlayStack({
    required this.playbackFrame,
    required this.mapWidth,
    required this.mapHeight,
    required this.compact,
    required this.atlasImagesById,
  });

  final CinematicPreviewPlaybackFrame playbackFrame;
  final int mapWidth;
  final int mapHeight;
  final bool compact;
  final Map<String, ui.Image?> atlasImagesById;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final transform = CinematicMapBackdropViewportTransform.fill(
            viewportSize: size,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
          );
          if (!transform.isUsable) {
            return const SizedBox.shrink();
          }

          final emotes = _visibleEmotes(
            playbackFrame: playbackFrame,
            transform: transform,
            compact: compact,
            atlasImagesById: atlasImagesById,
          );
          if (emotes.isEmpty) {
            return const SizedBox.shrink();
          }

          return Stack(
            key: const ValueKey('cinematic-builder-emote-preview-overlay'),
            clipBehavior: Clip.none,
            children: [
              for (final emote in emotes)
                Positioned(
                  left: emote.bounds.left,
                  top: emote.bounds.top,
                  width: emote.bounds.width,
                  height: emote.bounds.height,
                  child: SizedBox(
                    key: ValueKey(
                      'cinematic-builder-emote-preview-step-${emote.state.activeStepId}',
                    ),
                    width: emote.bounds.width,
                    height: emote.bounds.height,
                    child: emote.image == null || emote.entry == null
                        ? _CinematicEmoteFallback(
                            label: emote.state.emoteLabel,
                            size: emote.bounds.width,
                          )
                        : CustomPaint(
                            key: ValueKey(
                              'cinematic-builder-emote-preview-actor-${emote.state.actorId}',
                            ),
                            painter: _CinematicEmoteSpritePainter(
                              image: emote.image!,
                              frame: emote.entry!.frame,
                              fallbackTextColor: colors.textPrimary,
                              fallbackBackgroundColor: colors.surfaceSubtle,
                              fallbackBorderColor: colors.controlBorder,
                            ),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CinematicEmoteFallback extends StatelessWidget {
  const _CinematicEmoteFallback({
    required this.label,
    required this.size,
  });

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.controlBorder),
        borderRadius: BorderRadius.circular(math.max(4, size * 0.18)),
      ),
      child: Center(
        child: Text(
          '?',
          semanticsLabel: label ?? 'Émotion',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: math.max(11, size * 0.52),
            height: 1,
          ),
        ),
      ),
    );
  }
}

final class _VisibleCinematicEmote {
  const _VisibleCinematicEmote({
    required this.state,
    required this.bounds,
    required this.entry,
    required this.image,
  });

  final CinematicActorEmotePlaybackState state;
  final Rect bounds;
  final CinematicEmoteCatalogEntry? entry;
  final ui.Image? image;
}

List<_VisibleCinematicEmote> _visibleEmotes({
  required CinematicPreviewPlaybackFrame playbackFrame,
  required CinematicMapBackdropViewportTransform transform,
  required bool compact,
  required Map<String, ui.Image?> atlasImagesById,
}) {
  final cellWidth = transform.frame.width / transform.mapWidth;
  final cellHeight = transform.frame.height / transform.mapHeight;
  final emoteSize = math.min(
    compact ? 28.0 : 34.0,
    math.max(22.0, math.min(cellWidth, cellHeight) * 0.92),
  );
  final actorHeadOffset = math.max(
    compact ? 22.0 : 28.0,
    cellHeight * 1.25,
  );
  final verticalGap = compact ? 4.0 : 6.0;
  final result = <_VisibleCinematicEmote>[];

  for (final state in playbackFrame.activeEmotes) {
    final actorId = state.actorId?.trim();
    if (actorId == null || actorId.isEmpty) {
      continue;
    }
    final pose = playbackFrame.actorPoseById(actorId);
    if (pose == null || !pose.hasPosition) {
      continue;
    }

    final entry = state.emoteId == null
        ? null
        : cinematicEmoteCatalogEntryById(state.emoteId);
    final atlas = entry == null ? null : cinematicEmoteAtlasById(entry.atlasId);
    final image = atlas == null ? null : atlasImagesById[atlas.id];
    final anchor = transform.tileToPreview(pose.x!, pose.y!);
    final left = (anchor.dx - emoteSize / 2)
        .clamp(transform.frame.left, transform.frame.right - emoteSize)
        .toDouble();
    final top = (anchor.dy - actorHeadOffset - emoteSize - verticalGap)
        .clamp(transform.frame.top, transform.frame.bottom - emoteSize)
        .toDouble();
    result.add(
      _VisibleCinematicEmote(
        state: state,
        bounds: Rect.fromLTWH(left, top, emoteSize, emoteSize),
        entry: entry,
        image: image,
      ),
    );
  }

  return result;
}

Map<String, CinematicEmoteAtlas> _activeAtlasesById(
  Iterable<CinematicActorEmotePlaybackState> activeEmotes,
) {
  final atlasesById = <String, CinematicEmoteAtlas>{};
  for (final state in activeEmotes) {
    final entry = state.emoteId == null
        ? null
        : cinematicEmoteCatalogEntryById(state.emoteId);
    if (entry == null) {
      continue;
    }
    final atlas = cinematicEmoteAtlasById(entry.atlasId);
    if (atlas != null) {
      atlasesById[atlas.id] = atlas;
    }
  }
  return atlasesById;
}

String _atlasSignatureFor(Iterable<String> atlasIds) {
  final ids = atlasIds.toList(growable: false)..sort();
  return ids.join('|');
}

Future<Map<String, ui.Image?>> _loadAtlasImages({
  required AssetBundle bundle,
  required Map<String, CinematicEmoteAtlas> atlasesById,
}) async {
  final imagesById = <String, ui.Image?>{};
  for (final entry in atlasesById.entries) {
    imagesById[entry.key] = await _loadAtlasImage(bundle, entry.value.assetKey);
  }
  return imagesById;
}

Future<ui.Image?> _loadAtlasImage(AssetBundle bundle, String assetKey) async {
  try {
    final data = await bundle.load(assetKey);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

class _CinematicEmoteSpritePainter extends CustomPainter {
  const _CinematicEmoteSpritePainter({
    required this.image,
    required this.frame,
    required this.fallbackTextColor,
    required this.fallbackBackgroundColor,
    required this.fallbackBorderColor,
  });

  final ui.Image image;
  final CinematicEmoteFrameRect frame;
  final Color fallbackTextColor;
  final Color fallbackBackgroundColor;
  final Color fallbackBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      frame.x.toDouble(),
      frame.y.toDouble(),
      frame.width.toDouble(),
      frame.height.toDouble(),
    );
    if (source.left < 0 ||
        source.top < 0 ||
        source.right > image.width ||
        source.bottom > image.height ||
        size.isEmpty) {
      final rect = Offset.zero & size;
      final radius = Radius.circular(math.max(4, size.shortestSide * 0.18));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = fallbackBackgroundColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.5), radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = fallbackBorderColor,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: fallbackTextColor,
            fontWeight: FontWeight.w900,
            fontSize: math.max(11, size.shortestSide * 0.52),
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, rect.center - painter.size.center(Offset.zero));
      return;
    }

    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _CinematicEmoteSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frame != frame ||
        oldDelegate.fallbackTextColor != fallbackTextColor ||
        oldDelegate.fallbackBackgroundColor != fallbackBackgroundColor ||
        oldDelegate.fallbackBorderColor != fallbackBorderColor;
  }
}
