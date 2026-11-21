import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_session_surfaces.dart';
import 'player_world_map_loading_scene.dart';

typedef PlayerWorldLoadingSceneBuilder = Widget Function(
  BuildContext context,
  Widget details,
);

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
    this.showMapScene = false,
    this.sceneBuilder,
  });

  final String gameTitle;
  final String stage;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final double? progress;
  final VoidCallback? onCancel;
  final bool reducedMotion;
  final bool showMapScene;
  final PlayerWorldLoadingSceneBuilder? sceneBuilder;

  @override
  Widget build(BuildContext context) {
    final title = gameTitle.trim().isEmpty
        ? context.playerL10n.loading
        : gameTitle;
    final fraction = progress?.clamp(0.0, 1.0);
    final percentage = fraction == null
        ? null
        : fraction == 1
        ? '100%'
        : '${math.min(99, (fraction * 100).round())}%';
    final scene = sceneBuilder;
    return Semantics(
      container: true,
      label: '$title. $stage',
      value: percentage,
      child: switch (scene) {
        final builder? => builder(context, _sceneDetails(title, fraction, percentage)),
        null when showMapScene => PlayerWorldMapLoadingScene(
          progress: fraction,
          reducedMotion: reducedMotion,
          details: _sceneDetails(title, fraction, percentage),
        ),
        null => _standardPanel(context, title, fraction, percentage),
      },
    );
  }

  Widget _standardPanel(
    BuildContext context,
    String title,
    double? fraction,
    String? percentage,
  ) => PlayerSessionPanel(
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
      Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percentage != null)
              Text(
                percentage,
                textAlign: TextAlign.center,
                style: context.playerMenuTheme.body,
              ),
            _indicator(fraction),
          ],
        ),
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
  );

  Widget _sceneDetails(String title, double? fraction, String? percentage) =>
      PlayerMenuThemeScope(
        key: const ValueKey('runtime-player-loading-art'),
        child: Builder(
          builder: (context) {
            final theme = context.playerMenuTheme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  key: const ValueKey('player-session-title'),
                  textAlign: TextAlign.center,
                  style: theme.title,
                ),
                const SizedBox(height: 10),
                Text(
                  stage,
                  textAlign: TextAlign.center,
                  style: theme.body.copyWith(color: theme.secondary),
                ),
                if (percentage != null)
                  Text(
                    percentage,
                    textAlign: TextAlign.center,
                    style: theme.body,
                  ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: _indicator(fraction, rounded: true),
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: 20),
                  PlayerActionButton(
                    label: context.playerL10n.cancel,
                    icon: Icons.close,
                    onPressed: onCancel,
                    secondary: true,
                    expandWidth: false,
                  ),
                ],
              ],
            );
          },
        ),
      );

  Widget _indicator(double? fraction, {bool rounded = false}) => Builder(
    builder: (context) {
      final menu = context.playerMenuTheme;
      final indicatorTheme = ProgressIndicatorTheme.of(context);
      final still =
          reducedMotion ||
          menu.reducedMotion ||
          MediaQuery.disableAnimationsOf(context);
      return TickerMode(
        enabled: !still,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: fraction ?? 0),
          duration: still || fraction == 1
              ? Duration.zero
              : const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(
            key: const ValueKey('runtime-player-loading-progress'),
            minHeight: 4,
            value: fraction == null ? null : value,
            color: indicatorTheme.color ?? menu.accent,
            backgroundColor: indicatorTheme.linearTrackColor ?? menu.recessed,
            borderRadius: rounded
                ? const BorderRadius.all(Radius.circular(2))
                : null,
          ),
        ),
      );
    },
  );
}
