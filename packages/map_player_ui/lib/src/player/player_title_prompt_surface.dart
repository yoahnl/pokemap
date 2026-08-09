import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_cinematic_stage.dart';
import 'player_startup_strings.dart';

/// The title attract surface shown between the intro and the title menu.
class PlayerTitlePromptSurface extends StatelessWidget {
  const PlayerTitlePromptSurface({
    super.key,
    required this.gameTitle,
    required this.onStart,
    this.background,
    this.backgroundContent,
    this.logo,
    this.onReplayIntro,
    this.eyebrow,
    this.footer,
  });

  final String gameTitle;
  final ImageProvider? background;
  final Widget? backgroundContent;
  final ImageProvider? logo;
  final VoidCallback onStart;
  final VoidCallback? onReplayIntro;
  final String? eyebrow;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final strings = PlayerStartupStrings.of(context);
    final content = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): onStart,
        const SingleActivator(LogicalKeyboardKey.space): onStart,
      },
      child: Focus(
        autofocus: true,
        child: Semantics(
          button: true,
          label: '$gameTitle. ${strings.pressStart}',
          onTap: onStart,
          child: GestureDetector(
            key: const ValueKey<String>('player-title-prompt-hit-area'),
            behavior: HitTestBehavior.opaque,
            onTap: onStart,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background,
                    image: background == null
                        ? null
                        : DecorationImage(
                            image: background!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                if (backgroundContent != null) backgroundContent!,
                ColoredBox(color: colors.scrim.withValues(alpha: .16)),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth <= 760;
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Align(
                            alignment: compact
                                ? const Alignment(0, -.18)
                                : const Alignment(-.78, -.04),
                            child: FractionallySizedBox(
                              widthFactor: compact ? .86 : .48,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: compact
                                    ? CrossAxisAlignment.center
                                    : CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (eyebrow case final eyebrow?
                                      when eyebrow.trim().isNotEmpty) ...[
                                    Text(
                                      eyebrow.toUpperCase(),
                                      textAlign: compact
                                          ? TextAlign.center
                                          : TextAlign.start,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: colors.textPrimary,
                                            letterSpacing: 3.2,
                                          ),
                                    ),
                                    const SizedBox(height: PlayerSpacing.sm),
                                  ],
                                  if (logo != null)
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: compact ? 160 : 240,
                                      ),
                                      child: Image(
                                        image: logo!,
                                        fit: BoxFit.contain,
                                        alignment: compact
                                            ? Alignment.center
                                            : Alignment.centerLeft,
                                        semanticLabel: gameTitle,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    )
                                  else
                                    Text(
                                      gameTitle,
                                      textAlign: compact
                                          ? TextAlign.center
                                          : TextAlign.start,
                                      style:
                                          context.playerTypography.displayStyle(
                                        Theme.of(context)
                                                .textTheme
                                                .displayLarge ??
                                            const TextStyle(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(PlayerSpacing.lg),
                              child: onReplayIntro == null
                                  ? const SizedBox.shrink()
                                  : PlayerActionButton(
                                      label: strings.replayIntro,
                                      icon: Icons.replay_rounded,
                                      secondary: true,
                                      onPressed: onReplayIntro,
                                    ),
                            ),
                          ),
                          Align(
                            alignment: compact
                                ? Alignment.bottomCenter
                                : Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(PlayerSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: compact
                                    ? CrossAxisAlignment.center
                                    : CrossAxisAlignment.start,
                                children: <Widget>[
                                  Semantics(
                                    liveRegion: true,
                                    child: PlayerPanel(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: PlayerSpacing.lg,
                                        vertical: PlayerSpacing.sm,
                                      ),
                                      child: Text(
                                        strings.pressStart,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                  ),
                                  if (footer case final footer?
                                      when footer.trim().isNotEmpty) ...[
                                    const SizedBox(height: PlayerSpacing.sm),
                                    Text(
                                      footer.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                            letterSpacing: 1.6,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: PlayerCinematicStage(child: content),
    );
  }
}
