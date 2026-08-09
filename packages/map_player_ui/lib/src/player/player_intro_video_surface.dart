import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_intro_video_strings.dart';

/// Player-safe presentation surface for intro video, poster, and fallbacks.
class PlayerIntroVideoSurface extends StatefulWidget {
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
  State<PlayerIntroVideoSurface> createState() =>
      _PlayerIntroVideoSurfaceState();
}

class _PlayerIntroVideoSurfaceState extends State<PlayerIntroVideoSurface> {
  bool _skipVisible = false;

  @override
  void didUpdateWidget(PlayerIntroVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPoster != widget.isPoster) {
      _skipVisible = false;
    }
  }

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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.isPoster ? _primaryAction : null,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(
                color: colors.background,
                child: widget.media ??
                    _UnavailableMedia(
                      message: widget.failureMessage ?? strings.unavailable,
                    ),
              ),
              if (widget.isBuffering)
                ColoredBox(
                  color: colors.scrim,
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                ),
              if (widget.caption case final caption?
                  when caption.trim().isNotEmpty)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(PlayerSpacing.lg),
                      padding: const EdgeInsets.symmetric(
                        horizontal: PlayerSpacing.md,
                        vertical: PlayerSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.scrim,
                        borderRadius: BorderRadius.circular(PlayerRadii.sm),
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
                ),
              if (widget.isPoster)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(PlayerSpacing.md),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: PlayerSpacing.sm,
                        runSpacing: PlayerSpacing.sm,
                        children: <Widget>[
                          if (widget.onReplay != null)
                            SizedBox(
                              width: 132,
                              child: PlayerActionButton(
                                label: widget.replayLabel ?? strings.replay,
                                icon: Icons.replay_outlined,
                                secondary: true,
                                onPressed: widget.onReplay,
                              ),
                            ),
                          if (widget.onContinue != null)
                            SizedBox(
                              width: 136,
                              child: PlayerActionButton(
                                label: widget.continueLabel ??
                                    strings.continueAction,
                                icon: Icons.play_arrow_rounded,
                                onPressed: widget.onContinue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...<Widget>[
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 144,
                  height: 112,
                  child: Semantics(
                    button: true,
                    label: widget.skipLabel ?? strings.skip,
                    onTap: _revealSkip,
                    child: GestureDetector(
                      key: const ValueKey<String>(
                        'player-intro-skip-reveal-hit-area',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: _revealSkip,
                    ),
                  ),
                ),
                if (_skipVisible)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(PlayerSpacing.md),
                        child: SizedBox(
                          key: const ValueKey<String>(
                            'player-intro-skip-action',
                          ),
                          width: 112,
                          height: 54,
                          child: PlayerActionButton(
                            label: widget.skipLabel ?? strings.skip,
                            icon: Icons.skip_next_outlined,
                            secondary: true,
                            onPressed: widget.onSkip,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _primaryAction() {
    if (widget.isPoster && widget.onContinue != null) {
      widget.onContinue!();
    } else {
      widget.onSkip();
    }
  }

  void _revealSkip() {
    if (!_skipVisible) setState(() => _skipVisible = true);
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
