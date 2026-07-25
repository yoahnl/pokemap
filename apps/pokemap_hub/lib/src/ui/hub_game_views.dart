import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'hub_dashboard_controller.dart';

final class HubUiActions {
  const HubUiActions({
    this.onImportRequested,
    this.onContinue,
    this.onNewGame,
    this.onUpdate,
    this.onRepair,
    this.onManageSaves,
    this.onUninstall,
  });

  final VoidCallback? onImportRequested;
  final ValueChanged<HubGameView>? onContinue;
  final ValueChanged<HubGameView>? onNewGame;
  final ValueChanged<HubGameView>? onUpdate;
  final ValueChanged<HubGameView>? onRepair;
  final ValueChanged<HubGameView>? onManageSaves;
  final ValueChanged<HubGameView>? onUninstall;
}

class HubGameGrid extends StatelessWidget {
  const HubGameGrid({
    super.key,
    required this.games,
    required this.onSelected,
    this.gridKey,
    this.emptyState,
  });

  final List<HubGameView> games;
  final ValueChanged<String> onSelected;
  final Key? gridKey;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return emptyState ?? const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 500
                    ? 2
                    : 1;
        return GridView.builder(
          key: gridKey,
          itemCount: games.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 230,
            crossAxisSpacing: PlayerSpacing.md,
            mainAxisSpacing: PlayerSpacing.md,
          ),
          itemBuilder: (context, index) {
            final view = games[index];
            return _HubGameCard(
              view: view,
              onPressed: () => onSelected(view.game.gameId),
            );
          },
        );
      },
    );
  }
}

class _HubGameCard extends StatelessWidget {
  const _HubGameCard({
    required this.view,
    required this.onPressed,
  });

  final HubGameView view;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final game = view.game;
    final activity = view.activity;
    return Semantics(
      button: true,
      label: '${game.title}, ${game.authorName}',
      hint: activity.installationHealthy
          ? context.playerL10n.viewGameDetails
          : context.playerL10n.repairRequired,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(PlayerRadii.md),
          child: PlayerPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(PlayerRadii.md - 1),
                    ),
                    child: HubArtwork(
                      path: activity.coverPath ?? activity.heroPath,
                      icon: Icons.landscape_rounded,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(PlayerSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              game.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: PlayerSpacing.xs),
                          Icon(
                            activity.installationHealthy
                                ? Icons.verified_rounded
                                : Icons.build_circle_outlined,
                            size: 20,
                            color: activity.installationHealthy
                                ? context.playerColors.success
                                : context.playerColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: PlayerSpacing.xxs),
                      Text(
                        game.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: PlayerSpacing.xs),
                      Text(
                        activity.canContinue
                            ? _formatPlayTime(activity.playTimeSeconds)
                            : context.playerL10n.noSave,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HubGameDetailView extends StatelessWidget {
  const HubGameDetailView({
    super.key,
    required this.game,
    required this.actions,
    required this.onBack,
  });

  final HubGameView game;
  final HubUiActions actions;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final installation = game.game;
    final activity = game.activity;
    final healthy = activity.installationHealthy;
    return PlayerSurface(
      maxWidth: 1180,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: context.playerL10n.close,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: PlayerSpacing.xs),
                Expanded(
                  child: Text(
                    installation.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: PlayerSpacing.md),
          ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 780;
                final artwork = AspectRatio(
                  aspectRatio: wide ? 4 / 3 : 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(PlayerRadii.lg),
                    child: HubArtwork(
                      path: activity.heroPath ?? activity.coverPath,
                      icon: Icons.explore_rounded,
                    ),
                  ),
                );
                final information = _HubGameInformation(game: game);
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 5, child: artwork),
                          const SizedBox(width: PlayerSpacing.xl),
                          Expanded(flex: 6, child: information),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          artwork,
                          const SizedBox(height: PlayerSpacing.lg),
                          information,
                        ],
                      );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: PlayerSpacing.xl),
          ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent >= 760 ? 3 : 1;
              final entries = <Widget>[
                PlayerActionButton(
                  label: context.playerL10n.continueGame,
                  icon: Icons.play_circle_fill_rounded,
                  autofocus: activity.canContinue && healthy,
                  disabledReason: !healthy
                      ? context.playerL10n.repairBeforePlaying
                      : !activity.canContinue
                          ? context.playerL10n.noSaveAvailable
                          : actions.onContinue == null
                              ? context.playerL10n.launchUnavailable
                              : null,
                  onPressed: activity.canContinue &&
                          healthy &&
                          actions.onContinue != null
                      ? () => actions.onContinue!(game)
                      : null,
                ),
                PlayerActionButton(
                  label: context.playerL10n.newGame,
                  icon: Icons.auto_awesome_rounded,
                  autofocus: !activity.canContinue &&
                      healthy &&
                      actions.onNewGame != null,
                  disabledReason: !healthy
                      ? context.playerL10n.repairBeforePlaying
                      : actions.onNewGame == null
                          ? context.playerL10n.launchUnavailable
                          : null,
                  onPressed: healthy && actions.onNewGame != null
                      ? () => actions.onNewGame!(game)
                      : null,
                ),
                PlayerActionButton(
                  label: context.playerL10n.update,
                  icon: Icons.system_update_alt_rounded,
                  disabledReason: !activity.updateAvailable
                      ? context.playerL10n.noUpdateAvailable
                      : actions.onUpdate == null
                          ? context.playerL10n.updateUnavailable
                          : null,
                  onPressed:
                      activity.updateAvailable && actions.onUpdate != null
                          ? () => actions.onUpdate!(game)
                          : null,
                ),
                PlayerActionButton(
                  label: context.playerL10n.repair,
                  icon: Icons.build_rounded,
                  secondary: true,
                  disabledReason: actions.onRepair == null
                      ? context.playerL10n.repairSourceMissing
                      : null,
                  onPressed: actions.onRepair == null
                      ? null
                      : () => actions.onRepair!(game),
                ),
                PlayerActionButton(
                  label: context.playerL10n.manageSaves,
                  icon: Icons.save_as_rounded,
                  secondary: true,
                  disabledReason: actions.onManageSaves == null
                      ? context.playerL10n.saveManagementUnavailable
                      : null,
                  onPressed: actions.onManageSaves == null
                      ? null
                      : () => actions.onManageSaves!(game),
                ),
                PlayerActionButton(
                  label: context.playerL10n.uninstall,
                  icon: Icons.delete_outline_rounded,
                  secondary: true,
                  disabledReason: actions.onUninstall == null
                      ? context.playerL10n.uninstallUnavailable
                      : null,
                  onPressed: actions.onUninstall == null
                      ? null
                      : () => actions.onUninstall!(game),
                ),
              ];
              return SliverGrid(
                delegate: SliverChildListDelegate(entries),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: 68,
                  crossAxisSpacing: PlayerSpacing.sm,
                  mainAxisSpacing: PlayerSpacing.sm,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: PlayerSpacing.xl),
          ),
        ],
      ),
    );
  }
}

class _HubGameInformation extends StatelessWidget {
  const _HubGameInformation({required this.game});

  final HubGameView game;

  @override
  Widget build(BuildContext context) {
    final installation = game.game;
    final activity = game.activity;
    return PlayerPanel(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(PlayerRadii.sm),
                child: SizedBox.square(
                  dimension: 72,
                  child: HubArtwork(
                    path: activity.iconPath,
                    icon: Icons.catching_pokemon_rounded,
                  ),
                ),
              ),
              const SizedBox(width: PlayerSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      installation.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(installation.authorName),
                  ],
                ),
              ),
            ],
          ),
          if (installation.description case final description?) ...<Widget>[
            const SizedBox(height: PlayerSpacing.lg),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: PlayerSpacing.lg),
          Wrap(
            spacing: PlayerSpacing.xs,
            runSpacing: PlayerSpacing.xs,
            children: <Widget>[
              PlayerBadge(
                label:
                    '${context.playerL10n.version} ${installation.current.gameVersion}',
                icon: Icons.inventory_2_outlined,
              ),
              PlayerBadge(
                label: activity.installationHealthy
                    ? context.playerL10n.healthy
                    : context.playerL10n.needsRepair,
                icon: activity.installationHealthy
                    ? Icons.verified_rounded
                    : Icons.build_circle_outlined,
                tone: activity.installationHealthy
                    ? PlayerBadgeTone.success
                    : PlayerBadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: PlayerSpacing.lg),
          _DetailLine(
            label: context.playerL10n.lastSave,
            value: activity.lastSaveAt == null
                ? context.playerL10n.noSave
                : _formatDate(activity.lastSaveAt!),
          ),
          const SizedBox(height: PlayerSpacing.xs),
          _DetailLine(
            label: context.playerL10n.playTime,
            value: _formatPlayTime(activity.playTimeSeconds),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          const SizedBox(width: PlayerSpacing.md),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: context.playerColors.textPrimary),
          ),
        ],
      );
}

class HubArtwork extends StatelessWidget {
  const HubArtwork({
    super.key,
    required this.path,
    required this.icon,
  });

  final String? path;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            context.playerColors.primary.withValues(alpha: 0.32),
            context.playerColors.surfaceElevated,
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 64, color: context.playerColors.primary),
      ),
    );
    final assetPath = path;
    if (assetPath == null) return fallback;
    return Image.file(
      File(assetPath),
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

String _formatPlayTime(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours > 0
      ? '${hours}h ${minutes.toString().padLeft(2, '0')}min'
      : '$minutes min';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
