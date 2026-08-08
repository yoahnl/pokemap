import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_startup_strings.dart';

/// The title attract surface shown between the intro and the title menu.
class PlayerTitlePromptSurface extends StatelessWidget {
  const PlayerTitlePromptSurface({
    super.key,
    required this.gameTitle,
    required this.onStart,
    this.background,
    this.logo,
    this.onReplayIntro,
  });

  final String gameTitle;
  final ImageProvider? background;
  final ImageProvider? logo;
  final VoidCallback onStart;
  final VoidCallback? onReplayIntro;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final strings = PlayerStartupStrings.of(context);
    return Scaffold(
      body: CallbackShortcuts(
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  image: background == null
                      ? null
                      : DecorationImage(
                          image: background!,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            colors.scrim.withValues(alpha: .28),
                            BlendMode.srcOver,
                          ),
                        ),
                ),
                child: SafeArea(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(PlayerSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (logo != null)
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 210),
                                  child: Image(
                                    image: logo!,
                                    fit: BoxFit.contain,
                                    semanticLabel: gameTitle,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                )
                              else
                                Text(
                                  gameTitle,
                                  textAlign: TextAlign.center,
                                  style: context.playerTypography.displayStyle(
                                    Theme.of(context).textTheme.displayMedium ??
                                        const TextStyle(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(PlayerSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                              if (onReplayIntro != null) ...<Widget>[
                                const SizedBox(height: PlayerSpacing.sm),
                                TextButton.icon(
                                  onPressed: onReplayIntro,
                                  icon: const Icon(Icons.replay_rounded),
                                  label: Text(strings.replayIntro),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
