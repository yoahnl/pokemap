import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_session_surfaces.dart';

class PlayerWorldLoadingSurface extends StatelessWidget {
  const PlayerWorldLoadingSurface({
    super.key,
    required this.gameTitle,
    required this.stage,
    this.logo,
    this.wordmark,
    this.progress,
    this.onCancel,
    this.reducedMotion = false,
  });

  final String gameTitle;
  final String stage;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final double? progress;
  final VoidCallback? onCancel;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final title = gameTitle.trim().isEmpty
        ? context.playerL10n.loading
        : gameTitle;
    final fraction = progress?.clamp(0.0, 1.0);
    final percentage = fraction == null ? null : '${(fraction * 100).round()}%';
    return Semantics(
      container: true,
      label: '$title. $stage',
      value: percentage,
      child: PlayerSessionPanel(
        key: const ValueKey('runtime-player-loading-art'),
        title: title,
        framed: false,
        titleAlign: TextAlign.center,
        body: [
          if (logo != null)
            SizedBox.square(
              dimension: math.min(96, MediaQuery.sizeOf(context).height * .18),
              child: Image(
                key: const ValueKey('runtime-player-loading-logo'),
                image: ResizeImage(logo!, width: 256),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          if (wordmark != null)
            SizedBox(
              height: 48,
              child: Image(
                key: const ValueKey('runtime-player-loading-wordmark'),
                image: ResizeImage(wordmark!, width: 640),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          Text(stage, textAlign: TextAlign.center),
          if (percentage != null) Text(percentage, textAlign: TextAlign.center),
          Builder(
            builder: (context) {
              final theme = context.playerMenuTheme;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: fraction ?? 0),
                duration: reducedMotion || theme.reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => TickerMode(
                  enabled: fraction != null,
                  child: LinearProgressIndicator(
                    key: const ValueKey('runtime-player-loading-progress'),
                    minHeight: 4,
                    value: fraction == null ? null : value,
                    color: theme.accent,
                    backgroundColor: theme.recessed,
                  ),
                ),
              );
            },
          ),
        ],
        actions: [
          if (onCancel != null)
            PlayerActionButton(
              label: context.playerL10n.cancel,
              icon: Icons.close,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}
