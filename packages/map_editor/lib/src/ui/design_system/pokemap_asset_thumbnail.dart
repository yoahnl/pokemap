import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../../theme/theme.dart';

/// Token-driven pixel-art thumbnail used by asset authoring workflows.
class PokeMapAssetThumbnail extends StatelessWidget {
  const PokeMapAssetThumbnail({
    super.key,
    required this.semanticLabel,
    this.imageBytes,
    this.size = 56,
  });

  final String semanticLabel;
  final Uint8List? imageBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final bytes = imageBytes;
    return Semantics(
      image: bytes != null,
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
        child: bytes == null
            ? Icon(
                CupertinoIcons.photo,
                color: colors.textMuted,
                size: size * 0.4,
              )
            : Image.memory(
                bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: colors.error,
                  size: size * 0.4,
                ),
              ),
      ),
    );
  }
}
