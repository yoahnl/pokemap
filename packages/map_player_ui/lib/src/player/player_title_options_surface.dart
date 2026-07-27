import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'runtime_player_detail_router.dart';

/// Standalone options surface opened from the title screen.
///
/// It reuses the same persisted preference controls as the pause menu without
/// pretending that a gameplay session exists.
class PlayerTitleOptionsSurface extends StatelessWidget {
  const PlayerTitleOptionsSurface({
    super.key,
    required this.snapshot,
    required this.onReturnToTitle,
    this.onPreferencesChanged,
  });

  final RuntimePlayerSnapshot snapshot;
  final VoidCallback? onReturnToTitle;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PlayerSurface(
          maxWidth: 760,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const ValueKey<String>('runtime-player-title-options'),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.tune_rounded,
                      size: 56,
                      color: context.playerColors.primary,
                    ),
                    const SizedBox(height: PlayerSpacing.sm),
                    Text(
                      context.playerL10n.options,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: PlayerSpacing.xs),
                    Text(
                      snapshot.gameTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: PlayerSpacing.lg),
                    RuntimePlayerDetailRouter(
                      snapshot: snapshot,
                      onPreferencesChanged: onPreferencesChanged,
                    ),
                    const SizedBox(height: PlayerSpacing.lg),
                    PlayerActionButton(
                      key: const ValueKey<String>(
                        'runtime-player-title-options-back',
                      ),
                      label: context.playerL10n.returnToTitle,
                      icon: Icons.arrow_back_rounded,
                      secondary: true,
                      autofocus: true,
                      onPressed: onReturnToTitle,
                      disabledReason: onReturnToTitle == null
                          ? context.playerL10n.actionUnavailable
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
