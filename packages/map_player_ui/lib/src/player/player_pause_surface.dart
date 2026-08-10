import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_window_theme.dart';
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

final class PlayerPauseMenuLabels {
  const PlayerPauseMenuLabels({
    this.pauseTitle,
    this.resume,
    this.party,
    this.bag,
    this.pokedex,
    this.map,
    this.save,
    this.options,
    this.returnToTitle,
  });

  final String? pauseTitle;
  final String? resume;
  final String? party;
  final String? bag;
  final String? pokedex;
  final String? map;
  final String? save;
  final String? options;
  final String? returnToTitle;

  String title(PokeMapPlayerLocalizations l10n) => pauseTitle ?? l10n.pause;

  String action(
    PlayerPauseAction action,
    PokeMapPlayerLocalizations l10n,
  ) =>
      switch (action) {
        PlayerPauseAction.resume => resume ?? l10n.resume,
        PlayerPauseAction.party => party ?? l10n.party,
        PlayerPauseAction.bag => bag ?? l10n.bag,
        PlayerPauseAction.pokedex => pokedex ?? l10n.pokedex,
        PlayerPauseAction.map => map ?? l10n.map,
        PlayerPauseAction.save => save ?? l10n.save,
        PlayerPauseAction.options => options ?? l10n.options,
        PlayerPauseAction.returnToTitle => returnToTitle ?? l10n.returnToTitle,
      };
}

class PlayerPauseSurface extends StatelessWidget {
  const PlayerPauseSurface({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.onSelected,
    this.labels = const PlayerPauseMenuLabels(),
  }) : child = null;

  const PlayerPauseSurface.composed({super.key, required this.child})
      : gameTitle = '',
        actions = const <PlayerPauseAction, PlayerActionAvailability>{},
        onSelected = null,
        labels = const PlayerPauseMenuLabels();

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction>? onSelected;
  final PlayerPauseMenuLabels labels;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child case final content?) return content;
    final firstEnabledAction = PlayerPauseAction.values
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    return Material(
      key: const ValueKey<String>('player-pause-backdrop'),
      color: context.playerPauseBackdropColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolved = context.playerLayoutTheme?.resolve(
              ProjectPresentationSurfaceRole.pauseMenu,
              constraints,
            );
            final wide = resolved == null
                ? constraints.maxWidth >= 720
                : resolved.breakpoint != ProjectPresentationBreakpoint.compact;
            final showGameTitle = resolved == null ||
                resolved.variant.visibleSecondaryElements.contains(
                  ProjectPresentationSecondaryElement.pauseGameTitle,
                );
            final content = <Widget>[
              Semantics(
                header: true,
                child: Text(
                  labels.title(context.playerL10n),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: PlayerSpacing.xs),
              if (showGameTitle)
                Text(
                  gameTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
            final alignment = resolved == null
                ? (wide ? Alignment.centerRight : Alignment.center)
                : switch (resolved.variant.slot) {
                    ProjectPresentationLayoutSlot.left ||
                    ProjectPresentationLayoutSlot.leftPane =>
                      Alignment.centerLeft,
                    ProjectPresentationLayoutSlot.right =>
                      Alignment.centerRight,
                    ProjectPresentationLayoutSlot.bottomCenter =>
                      Alignment.bottomCenter,
                    _ => Alignment.center,
                  };
            final margin = resolved?.additionalSafeAreaPadding ?? 0;
            final panel = Align(
              key: resolved == null
                  ? null
                  : ValueKey<String>(
                      'player-pause-responsive-${resolved.breakpoint.name}',
                    ),
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: resolved == null
                      ? (wide ? 640 : 480)
                      : constraints.maxWidth * resolved.maxWidthFactor,
                  maxHeight: constraints.maxHeight - margin * 2,
                ),
                child: PlayerPanel(
                  elevated: true,
                  role: PlayerPanelRole.menu,
                  padding: resolved == null
                      ? const EdgeInsets.all(PlayerSpacing.lg)
                      : EdgeInsets.all(
                          PlayerSpacing.lg * resolved.spacingScale,
                        ),
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
            return margin == 0
                ? panel
                : Padding(padding: EdgeInsets.all(margin), child: panel);
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
      onPressed: availability.isEnabled ? () => onSelected!(action) : null,
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

  String _label(BuildContext context, PlayerPauseAction action) =>
      labels.action(action, context.playerL10n);

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
    this.labels = const PlayerPauseMenuLabels(),
    this.showGameTitle = true,
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final bool useGrid;
  final Key? scrollKey;
  final ScrollController? scrollController;
  final RuntimePlayerFocusController? focusController;
  final PlayerPauseMenuLabels labels;
  final bool showGameTitle;

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
              labels.title(context.playerL10n),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: PlayerSpacing.xs),
          if (showGameTitle)
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

  String _label(BuildContext context, PlayerPauseAction action) =>
      labels.action(action, context.playerL10n);

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
