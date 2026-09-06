import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_menu_theme.dart';

class PlayerPokemonImage extends StatelessWidget {
  const PlayerPokemonImage({
    super.key,
    required this.summary,
    this.thumbnail = false,
    this.width = 320,
    this.height = 272,
  });

  final RuntimePokemonSummarySnapshot summary;
  final bool thumbnail;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final media =
        thumbnail ? summary.media.thumbnail : summary.media.illustration;
    final placeholder = Icon(Icons.catching_pokemon,
        key: ValueKey('pokemon-image-missing-${summary.targetId}'),
        size: thumbnail ? 36 : 96,
        color: context.playerMenuTheme.secondary);
    return Semantics(
      image: true,
      label: summary.displayLabel,
      child: SizedBox(
        width: width,
        height: height,
        child: media == null
            ? placeholder
            : Image.file(
                File(media.absoluteFilePath),
                key: ValueKey(
                    '${summary.targetId}-${thumbnail ? 'thumbnail' : 'illustration'}-${media.absoluteFilePath}'),
                fit: BoxFit.contain,
                gaplessPlayback: false,
                filterQuality:
                    media.sampling == ProjectMenuImageSampling.pixelArt
                        ? FilterQuality.none
                        : FilterQuality.medium,
                frameBuilder: (_, child, frame, synchronous) =>
                    synchronous || frame != null ? child : placeholder,
                errorBuilder: (_, error, stack) => placeholder,
              ),
      ),
    );
  }
}
