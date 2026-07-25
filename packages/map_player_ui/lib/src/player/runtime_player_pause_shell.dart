import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_pause_menu.dart';
import 'runtime_player_layout.dart';

class RuntimePlayerPauseShell extends StatelessWidget {
  const RuntimePlayerPauseShell({
    super.key,
    required this.gameTitle,
    required this.pauseSection,
    required this.actions,
    required this.onSelected,
    required this.onBackToRoot,
    required this.detail,
    this.onTouchMenu,
    this.activeInputSource,
  });

  final String gameTitle;
  final RuntimePlayerPauseSection pauseSection;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final VoidCallback onBackToRoot;
  final Widget detail;
  final VoidCallback? onTouchMenu;
  final PlayerInputSource? activeInputSource;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.playerColors.scrim,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = classifyRuntimePlayerLayout(constraints);
            return Stack(
              key: ValueKey<String>(
                'runtime-pause-layout-${layout.name}',
              ),
              fit: StackFit.expand,
              children: <Widget>[
                switch (layout) {
                  RuntimePlayerLayoutClass.compactPortrait =>
                    _compactPortrait(context),
                  RuntimePlayerLayoutClass.compactLandscape => _twoColumn(
                      context,
                      widthFactor: .78,
                      navigationWidth: 220,
                    ),
                  RuntimePlayerLayoutClass.expanded => _twoColumn(
                      context,
                      widthFactor: null,
                      navigationWidth: 280,
                    ),
                },
                if (layout != RuntimePlayerLayoutClass.expanded &&
                    onTouchMenu != null)
                  Positioned(
                    top: PlayerSpacing.sm,
                    right: PlayerSpacing.sm,
                    child: AnimatedOpacity(
                      key: const ValueKey<String>(
                        'runtime-pause-touch-menu-opacity',
                      ),
                      opacity: activeInputSource == PlayerInputSource.controller
                          ? .42
                          : 1,
                      duration: context.playerMotion.fast,
                      child: IconButton.filled(
                        key: const ValueKey<String>(
                          'runtime-pause-touch-menu',
                        ),
                        tooltip: context.playerL10n.resume,
                        onPressed: onTouchMenu,
                        constraints: const BoxConstraints.tightFor(
                          width: 56,
                          height: 56,
                        ),
                        icon: const Icon(Icons.pause_rounded),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _compactPortrait(BuildContext context) {
    if (pauseSection != RuntimePlayerPauseSection.root) {
      return PlayerPanel(
        padding: const EdgeInsets.all(PlayerSpacing.md),
        child: _detailPane(context),
      );
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: .86,
        widthFactor: 1,
        child: PlayerPanel(
          padding: const EdgeInsets.all(PlayerSpacing.md),
          elevated: true,
          child: PlayerPauseNavigation(
            gameTitle: gameTitle,
            actions: actions,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  Widget _twoColumn(
    BuildContext context, {
    required double? widthFactor,
    required double navigationWidth,
  }) {
    Widget panel = ConstrainedBox(
      key: widthFactor == null
          ? const ValueKey<String>('runtime-pause-expanded-panel')
          : null,
      constraints: BoxConstraints(
        maxWidth: widthFactor == null ? 820 : double.infinity,
      ),
      child: PlayerPanel(
        padding: const EdgeInsets.all(PlayerSpacing.md),
        elevated: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: navigationWidth,
              child: PlayerPauseNavigation(
                gameTitle: gameTitle,
                actions: actions,
                onSelected: onSelected,
                scrollKey: const ValueKey<String>(
                  'runtime-pause-navigation-scroll',
                ),
              ),
            ),
            const SizedBox(width: PlayerSpacing.md),
            Expanded(child: _detailPane(context)),
          ],
        ),
      ),
    );
    if (widthFactor != null) {
      panel = FractionallySizedBox(
        widthFactor: widthFactor,
        child: panel,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(PlayerSpacing.md),
      child: Align(
        alignment: Alignment.centerRight,
        child: panel,
      ),
    );
  }

  Widget _detailPane(BuildContext context) {
    final hasDetail = pauseSection != RuntimePlayerPauseSection.root;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (hasDetail)
              IconButton(
                key: const ValueKey<String>('runtime-pause-back-to-root'),
                tooltip: context.playerL10n.back,
                onPressed: onBackToRoot,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            Expanded(
              child: Text(
                hasDetail
                    ? _sectionLabel(context, pauseSection)
                    : context.playerL10n.pause,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: PlayerSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey<String>('runtime-pause-detail-scroll'),
            child: hasDetail
                ? detail
                : PlayerEmptyState(
                    icon: Icons.gamepad_rounded,
                    title: context.playerL10n.pause,
                    message: context.playerL10n.actionUnavailable,
                  ),
          ),
        ),
      ],
    );
  }

  String _sectionLabel(
    BuildContext context,
    RuntimePlayerPauseSection section,
  ) {
    final l10n = context.playerL10n;
    return switch (section) {
      RuntimePlayerPauseSection.root => l10n.pause,
      RuntimePlayerPauseSection.party => l10n.party,
      RuntimePlayerPauseSection.bag => l10n.bag,
      RuntimePlayerPauseSection.pokedex => l10n.pokedex,
      RuntimePlayerPauseSection.map => l10n.map,
      RuntimePlayerPauseSection.options => l10n.options,
    };
  }
}
