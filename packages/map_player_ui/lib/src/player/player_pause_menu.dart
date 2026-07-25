import 'package:flutter/material.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'runtime_player_focus_controller.dart';

enum PlayerPauseAction {
  resume,
  party,
  bag,
  pokedex,
  map,
  save,
  options,
  returnToTitle,
}

class PlayerPauseMenu extends StatelessWidget {
  const PlayerPauseMenu({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.onSelected,
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstEnabledAction = PlayerPauseAction.values
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    return Material(
      color: context.playerColors.scrim,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final content = <Widget>[
              Semantics(
                header: true,
                child: Text(
                  context.playerL10n.pause,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: PlayerSpacing.xs),
              Text(gameTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: PlayerSpacing.lg),
              Expanded(
                child: wide
                    ? GridView.builder(
                        key: const ValueKey<String>('player-pause-grid'),
                        itemCount: PlayerPauseAction.values.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 68,
                          crossAxisSpacing: PlayerSpacing.sm,
                          mainAxisSpacing: PlayerSpacing.sm,
                        ),
                        itemBuilder: (context, index) => _action(
                          context,
                          PlayerPauseAction.values[index],
                          firstEnabledAction,
                        ),
                      )
                    : ListView.separated(
                        key: const ValueKey<String>('player-pause-list'),
                        itemCount: PlayerPauseAction.values.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: PlayerSpacing.xs),
                        itemBuilder: (context, index) => _action(
                          context,
                          PlayerPauseAction.values[index],
                          firstEnabledAction,
                        ),
                      ),
              ),
            ];
            return Align(
              alignment: wide ? Alignment.centerRight : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wide ? 640 : 480,
                  maxHeight: constraints.maxHeight,
                ),
                child: PlayerPanel(
                  elevated: true,
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    PlayerPauseAction action,
    PlayerPauseAction? firstEnabledAction,
  ) {
    final availability = _availability(context, action);
    return PlayerActionButton(
      label: _label(context, action),
      icon: _icon(action),
      autofocus: action == firstEnabledAction,
      secondary: action == PlayerPauseAction.returnToTitle,
      disabledReason: availability.disabledReason,
      onPressed: availability.isEnabled ? () => onSelected(action) : null,
    );
  }

  PlayerActionAvailability _availability(
    BuildContext context,
    PlayerPauseAction action,
  ) =>
      actions[action] ??
      PlayerActionAvailability.disabled(
        context.playerL10n.actionUnavailable,
      );

  String _label(BuildContext context, PlayerPauseAction action) {
    final l10n = context.playerL10n;
    return switch (action) {
      PlayerPauseAction.resume => l10n.resume,
      PlayerPauseAction.party => l10n.party,
      PlayerPauseAction.bag => l10n.bag,
      PlayerPauseAction.pokedex => l10n.pokedex,
      PlayerPauseAction.map => l10n.map,
      PlayerPauseAction.save => l10n.save,
      PlayerPauseAction.options => l10n.options,
      PlayerPauseAction.returnToTitle => l10n.returnToTitle,
    };
  }

  IconData _icon(PlayerPauseAction action) => switch (action) {
        PlayerPauseAction.resume => Icons.play_arrow_rounded,
        PlayerPauseAction.party => Icons.groups_rounded,
        PlayerPauseAction.bag => Icons.backpack_rounded,
        PlayerPauseAction.pokedex => Icons.menu_book_rounded,
        PlayerPauseAction.map => Icons.map_rounded,
        PlayerPauseAction.save => Icons.save_rounded,
        PlayerPauseAction.options => Icons.tune_rounded,
        PlayerPauseAction.returnToTitle => Icons.logout_rounded,
      };
}

/// Root navigation reused inside the responsive runtime-owned pause shell.
class PlayerPauseNavigation extends StatelessWidget {
  const PlayerPauseNavigation({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.onSelected,
    this.useGrid = false,
    this.scrollKey,
    this.scrollController,
    this.focusController,
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final bool useGrid;
  final Key? scrollKey;
  final ScrollController? scrollController;
  final RuntimePlayerFocusController? focusController;

  @override
  Widget build(BuildContext context) {
    final firstEnabledAction = PlayerPauseAction.values
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    return SingleChildScrollView(
      key: scrollKey ??
          ValueKey<String>(
            useGrid ? 'player-pause-grid' : 'player-pause-list',
          ),
      controller: scrollController,
      child: Column(
        key: const ValueKey<String>('runtime-pause-navigation'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              context.playerL10n.pause,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: PlayerSpacing.xs),
          Text(gameTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: PlayerSpacing.lg),
          if (useGrid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: PlayerPauseAction.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 68,
                crossAxisSpacing: PlayerSpacing.sm,
                mainAxisSpacing: PlayerSpacing.sm,
              ),
              itemBuilder: (context, index) => _action(
                context,
                PlayerPauseAction.values[index],
                firstEnabledAction,
              ),
            )
          else
            for (var index = 0;
                index < PlayerPauseAction.values.length;
                index++) ...<Widget>[
              _action(
                context,
                PlayerPauseAction.values[index],
                firstEnabledAction,
              ),
              if (index != PlayerPauseAction.values.length - 1)
                const SizedBox(height: PlayerSpacing.xs),
            ],
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    PlayerPauseAction action,
    PlayerPauseAction? firstEnabledAction,
  ) {
    final availability = _availability(context, action);
    final logicalId = _logicalId(action);
    final controller = focusController;
    return PlayerActionButton(
      key: ValueKey<String>(logicalId),
      label: _label(context, action),
      icon: _icon(action),
      focusNode: controller?.nodeFor(
        logicalId,
        debugLabel: 'Player action: ${_label(context, action)}',
      ),
      showFocusHighlight: controller?.showFocusHighlight ?? true,
      selected: controller?.logicalSelectionId == logicalId,
      shortcutLabel: context.playerL10n.confirmShortcut,
      autofocus: controller?.logicalSelectionId == null &&
          action == firstEnabledAction,
      secondary: action == PlayerPauseAction.returnToTitle,
      disabledReason: availability.disabledReason,
      onPressed: availability.isEnabled
          ? () {
              controller?.select(
                logicalId,
                source: controller.activeInputSource,
              );
              onSelected(action);
            }
          : null,
    );
  }

  PlayerActionAvailability _availability(
    BuildContext context,
    PlayerPauseAction action,
  ) =>
      actions[action] ??
      PlayerActionAvailability.disabled(
        context.playerL10n.actionUnavailable,
      );

  String _label(BuildContext context, PlayerPauseAction action) {
    final l10n = context.playerL10n;
    return switch (action) {
      PlayerPauseAction.resume => l10n.resume,
      PlayerPauseAction.party => l10n.party,
      PlayerPauseAction.bag => l10n.bag,
      PlayerPauseAction.pokedex => l10n.pokedex,
      PlayerPauseAction.map => l10n.map,
      PlayerPauseAction.save => l10n.save,
      PlayerPauseAction.options => l10n.options,
      PlayerPauseAction.returnToTitle => l10n.returnToTitle,
    };
  }

  IconData _icon(PlayerPauseAction action) => switch (action) {
        PlayerPauseAction.resume => Icons.play_arrow_rounded,
        PlayerPauseAction.party => Icons.groups_rounded,
        PlayerPauseAction.bag => Icons.backpack_rounded,
        PlayerPauseAction.pokedex => Icons.menu_book_rounded,
        PlayerPauseAction.map => Icons.map_rounded,
        PlayerPauseAction.save => Icons.save_rounded,
        PlayerPauseAction.options => Icons.tune_rounded,
        PlayerPauseAction.returnToTitle => Icons.logout_rounded,
      };

  String _logicalId(PlayerPauseAction action) => 'pause.${action.name}';
}
