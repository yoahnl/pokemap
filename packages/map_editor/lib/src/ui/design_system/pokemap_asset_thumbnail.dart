import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../../theme/theme.dart';

/// Token-driven pixel-art thumbnail used by asset authoring workflows.
class PokeMapAssetThumbnail extends StatelessWidget {
  const PokeMapAssetThumbnail({
    super.key,
    required this.semanticLabel,
    this.imageBytes,
    this.imageFilePath,
    this.size = 56,
    this.imageScale = 1,
  }) : assert(imageBytes == null || imageFilePath == null),
       assert(imageScale > 0);

  final String semanticLabel;
  final Uint8List? imageBytes;
  final String? imageFilePath;
  final double size;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final bytes = imageBytes;
    final filePath = imageFilePath;
    final hasImage = bytes != null || filePath != null;
    final content = bytes != null
        ? Image.memory(
            bytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            frameBuilder: imageScale == 1
                ? null
                : (_, child, frame, _) => frame == null
                      ? child
                      : Transform.scale(scale: imageScale, child: child),
            errorBuilder: (_, _, _) => Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: colors.error,
              size: size * 0.4,
            ),
          )
        : filePath != null
        ? Image.file(
            File(filePath),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            frameBuilder: imageScale == 1
                ? null
                : (_, child, frame, _) => frame == null
                      ? child
                      : Transform.scale(scale: imageScale, child: child),
            errorBuilder: (_, _, _) => Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: colors.error,
              size: size * 0.4,
            ),
          )
        : Icon(CupertinoIcons.photo, color: colors.textMuted, size: size * 0.4);
    return Semantics(
      image: hasImage,
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
