import 'package:flutter/material.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_new_game_identity.dart';

enum PlayerTitleMenuAction {
  continueGame,
  newGame,
  load,
  options,
  creditsAbout,
  returnToHub,
}

enum PlayerTitleLayoutVariant {
  standard,
  centered,
  cinematic;

  static PlayerTitleLayoutVariant fromManifest(String? value) =>
      switch (value) {
        'centered' => PlayerTitleLayoutVariant.centered,
        'cinematic' => PlayerTitleLayoutVariant.cinematic,
        _ => PlayerTitleLayoutVariant.standard,
      };
}

@immutable
final class RuntimePlayerTitlePresentation {
  const RuntimePlayerTitlePresentation({
    required this.author,
    this.description,
    this.background,
    this.logo,
    this.accentColor,
    this.layoutVariant = PlayerTitleLayoutVariant.standard,
    this.newGameIdentity,
  });

  final String author;
  final String? description;
  final ImageProvider? background;
  final ImageProvider? logo;
  final Color? accentColor;
  final PlayerTitleLayoutVariant layoutVariant;
  final PlayerNewGameIdentityPresentation? newGameIdentity;
}

@immutable
final class PlayerTitleViewData {
  PlayerTitleViewData({
    required this.gameTitle,
    required this.author,
    this.description,
    this.background,
    this.logo,
    this.accentColor,
    this.layoutVariant = PlayerTitleLayoutVariant.standard,
    required Map<PlayerTitleMenuAction, PlayerActionAvailability> actions,
  }) : actions = Map.unmodifiable(actions);

  final String gameTitle;
  final String author;
  final String? description;
  final ImageProvider? background;
  final ImageProvider? logo;
  final Color? accentColor;
  final PlayerTitleLayoutVariant layoutVariant;
  final Map<PlayerTitleMenuAction, PlayerActionAvailability> actions;
}

class PlayerTitleScreen extends StatelessWidget {
  const PlayerTitleScreen({
    super.key,
    required this.data,
    required this.onSelected,
  });

  final PlayerTitleViewData data;
  final ValueChanged<PlayerTitleMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final accent = data.accentColor ?? colors.primary;
    final firstEnabledAction = PlayerTitleMenuAction.values
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    final cinematic = data.layoutVariant == PlayerTitleLayoutVariant.cinematic;
    final contentAlignment =
        cinematic ? Alignment.bottomLeft : Alignment.center;
    final textAlignment = cinematic ? TextAlign.start : TextAlign.center;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          image: data.background == null
              ? null
              : DecorationImage(
                  image: data.background!,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    colors.scrim.withValues(alpha: 0.45),
                    BlendMode.srcOver,
                  ),
                ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const ValueKey<String>('player-title-scroll'),
              padding: const EdgeInsets.all(PlayerSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > PlayerSpacing.xxl
                      ? constraints.maxHeight - PlayerSpacing.xxl
                      : 0,
                ),
                child: Align(
                  key: const ValueKey<String>(
                    'player-title-content-alignment',
                  ),
                  alignment: contentAlignment,
                  child: ConstrainedBox(
                    key: ValueKey<String>(
                      'player-title-layout-${data.layoutVariant.name}',
                    ),
                    constraints: BoxConstraints(
                      maxWidth: cinematic ? 680 : 560,
                    ),
                    child: PlayerPanel(
                      elevated: true,
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: cinematic
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.center,
                          children: <Widget>[
                            if (data.logo != null)
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 150),
                                child: Image(
                                  image: data.logo!,
                                  fit: BoxFit.contain,
                                  semanticLabel: data.gameTitle,
                                ),
                              )
                            else
                              Icon(
                                Icons.explore_rounded,
                                size: 64,
                                color: accent,
                              ),
                            const SizedBox(height: PlayerSpacing.md),
                            Text(
                              data.gameTitle,
                              textAlign: textAlignment,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: PlayerSpacing.xs),
                            Text(
                              data.author,
                              textAlign: textAlignment,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (data.description case final description?) ...[
                              const SizedBox(height: PlayerSpacing.md),
                              Text(
                                description,
                                textAlign: textAlignment,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                            const SizedBox(height: PlayerSpacing.xl),
                            for (final action in PlayerTitleMenuAction.values)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: PlayerSpacing.xs,
                                ),
                                child: PlayerActionButton(
                                  label: _label(context, action),
                                  icon: _icon(action),
                                  autofocus: action == firstEnabledAction,
                                  secondary: action ==
                                      PlayerTitleMenuAction.returnToHub,
                                  disabledReason: _availability(context, action)
                                      .disabledReason,
                                  onPressed:
                                      _availability(context, action).isEnabled
                                          ? () => onSelected(action)
                                          : null,
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
          ),
        ),
      ),
    );
  }

  PlayerActionAvailability _availability(
    BuildContext context,
    PlayerTitleMenuAction action,
  ) =>
      data.actions[action] ??
      PlayerActionAvailability.disabled(
        action == PlayerTitleMenuAction.continueGame
            ? context.playerL10n.noSaveAvailable
            : context.playerL10n.actionUnavailable,
      );

  String _label(BuildContext context, PlayerTitleMenuAction action) {
    final l10n = context.playerL10n;
    return switch (action) {
      PlayerTitleMenuAction.continueGame => l10n.continueGame,
      PlayerTitleMenuAction.newGame => l10n.newGame,
      PlayerTitleMenuAction.load => l10n.load,
      PlayerTitleMenuAction.options => l10n.options,
      PlayerTitleMenuAction.creditsAbout => l10n.creditsAbout,
      PlayerTitleMenuAction.returnToHub => l10n.returnToHub,
    };
  }

  IconData _icon(PlayerTitleMenuAction action) => switch (action) {
        PlayerTitleMenuAction.continueGame => Icons.play_circle_fill_rounded,
        PlayerTitleMenuAction.newGame => Icons.auto_awesome_rounded,
        PlayerTitleMenuAction.load => Icons.folder_open_rounded,
        PlayerTitleMenuAction.options => Icons.tune_rounded,
        PlayerTitleMenuAction.creditsAbout => Icons.info_outline_rounded,
        PlayerTitleMenuAction.returnToHub => Icons.home_rounded,
      };
}
