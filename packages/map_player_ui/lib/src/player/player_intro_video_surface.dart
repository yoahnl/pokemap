import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_intro_video_strings.dart';

/// Player-safe presentation surface for intro video, poster, and fallbacks.
class PlayerIntroVideoSurface extends StatelessWidget {
  const PlayerIntroVideoSurface({
    super.key,
    required this.media,
    required this.onSkip,
    this.caption,
    this.isPoster = false,
    this.isBuffering = false,
    this.failureMessage,
    this.onReplay,
    this.onContinue,
    this.skipLabel,
    this.replayLabel,
    this.continueLabel,
  });

  final Widget? media;
  final VoidCallback onSkip;
  final String? caption;
  final bool isPoster;
  final bool isBuffering;
  final String? failureMessage;
  final VoidCallback? onReplay;
  final VoidCallback? onContinue;
  final String? skipLabel;
  final String? replayLabel;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final strings = PlayerIntroVideoStrings.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): _primaryAction,
        const SingleActivator(LogicalKeyboardKey.space): _primaryAction,
      },
      child: Focus(
        autofocus: true,
        child: PlayerSurface(
          maxWidth: 1120,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PlayerPanel(
                    padding: EdgeInsets.zero,
                    elevated: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(PlayerRadii.md),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: GestureDetector(
                          key: const ValueKey<String>(
                            'player-intro-primary-hit-area',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onTap: _primaryAction,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ColoredBox(
                                color: colors.background,
                                child: media ??
                                    _UnavailableMedia(
                                      message:
                                          failureMessage ?? strings.unavailable,
                                    ),
                              ),
                              if (isBuffering)
                                ColoredBox(
                                  color: colors.scrim,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              if (caption case final caption?
                                  when caption.trim().isNotEmpty)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.all(PlayerSpacing.sm),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: PlayerSpacing.sm,
                                      vertical: PlayerSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.scrim,
                                      borderRadius:
                                          BorderRadius.circular(PlayerRadii.sm),
                                    ),
                                    child: Text(
                                      caption,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: colors.textPrimary),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: PlayerSpacing.sm,
                    runSpacing: PlayerSpacing.sm,
                    children: <Widget>[
                      if (onReplay != null)
                        PlayerActionButton(
                          label: replayLabel ?? strings.replay,
                          icon: Icons.replay_outlined,
                          secondary: true,
                          onPressed: onReplay,
                        ),
                      if (isPoster && onContinue != null)
                        PlayerActionButton(
                          label: continueLabel ?? strings.continueAction,
                          icon: Icons.play_arrow_rounded,
                          onPressed: onContinue,
                        )
                      else
                        PlayerActionButton(
                          label: skipLabel ?? strings.skip,
                          icon: Icons.skip_next_outlined,
                          secondary: true,
                          onPressed: onSkip,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _primaryAction() {
    if (isPoster && onContinue != null) {
      onContinue!();
    } else {
      onSkip();
    }
  }
}

class _UnavailableMedia extends StatelessWidget {
  const _UnavailableMedia({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(PlayerSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.broken_image_outlined,
                color: context.playerColors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: PlayerSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.playerColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}
