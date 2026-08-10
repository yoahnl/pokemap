import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../application/character_studio_media_resolver.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';

class CharacterStudioSpriteThumbnail extends StatefulWidget {
  const CharacterStudioSpriteThumbnail({
    super.key,
    required this.semanticLabel,
    required this.source,
    required this.framePixelWidth,
    required this.framePixelHeight,
    this.imagePath,
    this.mediaResolver,
    this.mediaRequest,
    this.size = 44,
  }) : assert(
         (mediaResolver == null) == (mediaRequest == null),
         'mediaResolver and mediaRequest must be provided together',
       );

  final String semanticLabel;
  final String? imagePath;
  final CharacterStudioMediaResolverContract? mediaResolver;
  final CharacterStudioMediaRequest? mediaRequest;
  final TilesetSourceRect source;
  final int framePixelWidth;
  final int framePixelHeight;
  final double size;

  @override
  State<CharacterStudioSpriteThumbnail> createState() =>
      _CharacterStudioSpriteThumbnailState();
}

class _CharacterStudioSpriteThumbnailState
    extends State<CharacterStudioSpriteThumbnail> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  ImageInfo? _imageInfo;
  bool _failed = false;
  bool _dependenciesReady = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesReady) return;
    _dependenciesReady = true;
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant CharacterStudioSpriteThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.mediaResolver != widget.mediaResolver ||
        oldWidget.mediaRequest != widget.mediaRequest) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _generation++;
    _detachImageStream();
    _imageInfo?.dispose();
    super.dispose();
  }

  Future<void> _resolveImage() async {
    final generation = ++_generation;
    _detachImageStream();
    _replaceImageInfo(null, failed: false);
    ImageProvider<Object>? provider;
    final request = widget.mediaRequest;
    final resolver = widget.mediaResolver;
    try {
      if (request != null && resolver != null) {
        final bytes = await resolver.resolve(request);
        if (!mounted || generation != _generation) return;
        provider = MemoryImage(bytes);
      } else {
        final path = widget.imagePath?.trim();
        if (path == null || path.isEmpty) return;
        provider = FileImage(File(path));
      }
      if (!mounted || generation != _generation) return;
      final stream = provider.resolve(createLocalImageConfiguration(context));
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!mounted || generation != _generation) {
            info.dispose();
            return;
          }
          _replaceImageInfo(info, failed: false);
        },
        onError: (Object _, StackTrace? _) {
          if (!mounted || generation != _generation) return;
          _replaceImageInfo(null, failed: true);
        },
      );
      _imageStream = stream;
      _imageListener = listener;
      stream.addListener(listener);
    } on Object {
      if (!mounted || generation != _generation) return;
      _replaceImageInfo(null, failed: true);
    }
  }

  void _detachImageStream() {
    final stream = _imageStream;
    final listener = _imageListener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _imageStream = null;
    _imageListener = null;
  }

  void _replaceImageInfo(ImageInfo? imageInfo, {required bool failed}) {
    final previous = _imageInfo;
    if (mounted) {
      setState(() {
        _imageInfo = imageInfo;
        _failed = failed;
      });
    } else {
      imageInfo?.dispose();
    }
    if (!identical(previous, imageInfo)) previous?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageInfo?.image;
    return SizedBox.square(
      dimension: widget.size,
      child: PokeMapMediaPreviewSurface(
        semanticLabel: widget.semanticLabel,
        borderRadius: 8,
        child: image != null
            ? CustomPaint(
                key: const ValueKey<String>(
                  'character-studio-sprite-thumbnail-content',
                ),
                painter: _CharacterSpritePainter(
                  image: image,
                  source: widget.source,
                  framePixelWidth: widget.framePixelWidth,
                  framePixelHeight: widget.framePixelHeight,
                ),
              )
            : Icon(
                _failed
                    ? CupertinoIcons.exclamationmark_triangle
                    : CupertinoIcons.person_crop_circle,
                color: _failed
                    ? context.pokeMapColors.error
                    : context.pokeMapColors.textMuted,
                size: widget.size * 0.42,
              ),
      ),
    );
  }
}

final class _CharacterSpritePainter extends CustomPainter {
  const _CharacterSpritePainter({
    required this.image,
    required this.source,
    required this.framePixelWidth,
    required this.framePixelHeight,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int framePixelWidth;
  final int framePixelHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceRect = Rect.fromLTWH(
      (source.x * framePixelWidth).toDouble(),
      (source.y * framePixelHeight).toDouble(),
      (source.width * framePixelWidth).toDouble(),
      (source.height * framePixelHeight).toDouble(),
    );
    if (sourceRect.left < 0 ||
        sourceRect.top < 0 ||
        sourceRect.right > image.width ||
        sourceRect.bottom > image.height ||
        sourceRect.isEmpty) {
      return;
    }
    const padding = 4.0;
    final available = Size(
      (size.width - padding * 2).clamp(0, double.infinity).toDouble(),
      (size.height - padding * 2).clamp(0, double.infinity).toDouble(),
    );
    final scale = (available.width / sourceRect.width).clamp(
      0,
      available.height / sourceRect.height,
    );
    final destinationSize = Size(
      sourceRect.width * scale,
      sourceRect.height * scale,
    );
    final destination = Alignment.center.inscribe(
      destinationSize,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      sourceRect,
      destination,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.framePixelWidth != framePixelWidth ||
        oldDelegate.framePixelHeight != framePixelHeight;
  }
}
