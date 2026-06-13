import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';

class CinematicFadePreviewOverlay extends StatelessWidget {
  const CinematicFadePreviewOverlay({
    super.key,
    required this.fadeState,
  });

  final CinematicFadePlaybackState fadeState;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final opacity = fadeState.opacity.clamp(0.0, 1.0).toDouble();
    return IgnorePointer(
      key: const ValueKey('cinematic-builder-fade-preview-overlay'),
      child: Opacity(
        key: const ValueKey('cinematic-builder-fade-preview-opacity'),
        opacity: opacity,
        child: ColoredBox(
          color: _darkestTokenColor(colors),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

Color _darkestTokenColor(PokeMapColorTokens colors) {
  final primaryLuminance = colors.textPrimary.computeLuminance();
  final inverseLuminance = colors.textInverse.computeLuminance();
  return primaryLuminance <= inverseLuminance
      ? colors.textPrimary
      : colors.textInverse;
}
