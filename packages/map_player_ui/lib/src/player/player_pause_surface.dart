import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_window_theme.dart';
import 'runtime_player_focus_controller.dart';

enum PlayerPauseAction {
  resume,
  party,
  bag,
  pokedex,
  quests,
  map,
  profile,
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
    this.quests,
    this.profile,
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
  final String? quests;
  final String? profile;
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
        PlayerPauseAction.quests => quests ?? l10n.quests,
        PlayerPauseAction.profile => profile ?? l10n.profile,
        PlayerPauseAction.save => save ?? l10n.save,
        PlayerPauseAction.options => options ?? l10n.options,
        PlayerPauseAction.returnToTitle => returnToTitle ?? l10n.returnToTitle,
      };
}

@immutable
final class PlayerPausePresentation {
  const PlayerPausePresentation({
    this.style,
    this.background,
    this.backgroundImage,
    this.title,
    this.hint,
    this.actionOrder,
    this.actionLabels = const <PlayerPauseAction, String>{},
    this.actionIcons = const <PlayerPauseAction, ProjectPauseActionIcon>{},
    this.hiddenActions = const <PlayerPauseAction>{},
    this.composition,
  });

  factory PlayerPausePresentation.fromProfile(
    ProjectPausePresentationProfile? profile, {
    ImageProvider? backgroundImage,
  }) {
    if (profile == null) return const PlayerPausePresentation();
    final actions = profile.effectiveActions;
    return PlayerPausePresentation(
      style: profile.style,
      background: profile.background,
      backgroundImage: backgroundImage,
      title: profile.title,
      hint: profile.hint,
      actionOrder: profile.actions == null
          ? null
          : <PlayerPauseAction>[
              for (final action in actions) _pauseAction(action.id),
            ],
      actionLabels: <PlayerPauseAction, String>{
        for (final action in actions)
          if (action.label case final label?) _pauseAction(action.id): label,
      },
      actionIcons: <PlayerPauseAction, ProjectPauseActionIcon>{
        for (final action in actions)
          if (action.icon case final icon?) _pauseAction(action.id): icon,
      },
      hiddenActions: <PlayerPauseAction>{
        for (final action in actions)
          if (!action.visible) _pauseAction(action.id),
      },
      composition: profile.composition,
    );
  }

  factory PlayerPausePresentation.fromLabels(PlayerPauseMenuLabels labels) =>
      PlayerPausePresentation(
        title: labels.pauseTitle,
        actionLabels: <PlayerPauseAction, String>{
          if (labels.resume case final value?) PlayerPauseAction.resume: value,
          if (labels.party case final value?) PlayerPauseAction.party: value,
          if (labels.bag case final value?) PlayerPauseAction.bag: value,
          if (labels.pokedex case final value?)
            PlayerPauseAction.pokedex: value,
          if (labels.map case final value?) PlayerPauseAction.map: value,
          if (labels.quests case final value?) PlayerPauseAction.quests: value,
          if (labels.profile case final value?)
            PlayerPauseAction.profile: value,
          if (labels.save case final value?) PlayerPauseAction.save: value,
          if (labels.options case final value?)
            PlayerPauseAction.options: value,
          if (labels.returnToTitle case final value?)
            PlayerPauseAction.returnToTitle: value,
        },
      );

  final ProjectPauseMenuStyle? style;
  final ProjectPauseBackgroundProfile? background;
  final ImageProvider? backgroundImage;
  final String? title;
  final String? hint;
  final List<PlayerPauseAction>? actionOrder;
  final Map<PlayerPauseAction, String> actionLabels;
  final Map<PlayerPauseAction, ProjectPauseActionIcon> actionIcons;
  final Set<PlayerPauseAction> hiddenActions;
  final ProjectResponsivePauseCompositionProfile? composition;

  PlayerPausePresentation resolveVisibility(PlayerPauseMenuState state) {
    return PlayerPausePresentation(
      style: style,
      background: background,
      backgroundImage: backgroundImage,
      title: title,
      hint: hint,
      actionOrder: actionOrder,
      actionLabels: actionLabels,
      actionIcons: actionIcons,
      hiddenActions: <PlayerPauseAction>{
        for (final action in PlayerPauseAction.values)
          if (!state.isActionVisible(
            _projectPauseAction(action),
            projectDefaultVisibility: !hiddenActions.contains(action) &&
                (actionOrder == null || actionOrder!.contains(action)),
          ))
            action,
      },
      composition: composition,
    );
  }

  List<PlayerPauseAction> get visibleActions =>
      List<PlayerPauseAction>.unmodifiable(
        (actionOrder ?? PlayerPauseAction.values).where(
          (action) => !hiddenActions.contains(action),
        ),
      );

  String resolvedTitle(PokeMapPlayerLocalizations l10n) => title ?? l10n.pause;

  String label(PlayerPauseAction action, PokeMapPlayerLocalizations l10n) =>
      actionLabels[action] ??
      const PlayerPauseMenuLabels().action(action, l10n);

  IconData icon(PlayerPauseAction action) =>
      switch (actionIcons[action] ?? _defaultPauseActionIcon(action)) {
        ProjectPauseActionIcon.play => Icons.play_arrow_rounded,
        ProjectPauseActionIcon.party => Icons.groups_rounded,
        ProjectPauseActionIcon.bag => Icons.backpack_rounded,
        ProjectPauseActionIcon.book => Icons.menu_book_rounded,
        ProjectPauseActionIcon.map => Icons.map_rounded,
        ProjectPauseActionIcon.person => Icons.person_rounded,
        ProjectPauseActionIcon.save => Icons.save_rounded,
        ProjectPauseActionIcon.settings => Icons.tune_rounded,
        ProjectPauseActionIcon.exit => Icons.logout_rounded,
      };
}

PlayerPauseAction _pauseAction(ProjectPauseActionId id) => switch (id) {
      ProjectPauseActionId.resume => PlayerPauseAction.resume,
      ProjectPauseActionId.party => PlayerPauseAction.party,
      ProjectPauseActionId.bag => PlayerPauseAction.bag,
      ProjectPauseActionId.pokedex => PlayerPauseAction.pokedex,
      ProjectPauseActionId.map => PlayerPauseAction.map,
      ProjectPauseActionId.quests => PlayerPauseAction.quests,
      ProjectPauseActionId.profile => PlayerPauseAction.profile,
      ProjectPauseActionId.save => PlayerPauseAction.save,
      ProjectPauseActionId.options => PlayerPauseAction.options,
      ProjectPauseActionId.returnToTitle => PlayerPauseAction.returnToTitle,
    };

ProjectPauseActionId _projectPauseAction(PlayerPauseAction action) =>
    switch (action) {
      PlayerPauseAction.resume => ProjectPauseActionId.resume,
      PlayerPauseAction.party => ProjectPauseActionId.party,
      PlayerPauseAction.bag => ProjectPauseActionId.bag,
      PlayerPauseAction.pokedex => ProjectPauseActionId.pokedex,
      PlayerPauseAction.map => ProjectPauseActionId.map,
      PlayerPauseAction.quests => ProjectPauseActionId.quests,
      PlayerPauseAction.profile => ProjectPauseActionId.profile,
      PlayerPauseAction.save => ProjectPauseActionId.save,
      PlayerPauseAction.options => ProjectPauseActionId.options,
      PlayerPauseAction.returnToTitle => ProjectPauseActionId.returnToTitle,
    };

ProjectPauseActionIcon _defaultPauseActionIcon(PlayerPauseAction action) =>
    switch (action) {
      PlayerPauseAction.resume => ProjectPauseActionIcon.play,
      PlayerPauseAction.party => ProjectPauseActionIcon.party,
      PlayerPauseAction.bag => ProjectPauseActionIcon.bag,
      PlayerPauseAction.pokedex => ProjectPauseActionIcon.book,
      PlayerPauseAction.map => ProjectPauseActionIcon.map,
      PlayerPauseAction.quests => ProjectPauseActionIcon.book,
      PlayerPauseAction.profile => ProjectPauseActionIcon.person,
      PlayerPauseAction.save => ProjectPauseActionIcon.save,
      PlayerPauseAction.options => ProjectPauseActionIcon.settings,
      PlayerPauseAction.returnToTitle => ProjectPauseActionIcon.exit,
    };

class PlayerPauseSurface extends StatelessWidget {
  const PlayerPauseSurface({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.onSelected,
    this.labels = const PlayerPauseMenuLabels(),
    this.presentation,
  }) : child = null;

  const PlayerPauseSurface.composed({super.key, required this.child})
      : gameTitle = '',
        actions = const <PlayerPauseAction, PlayerActionAvailability>{},
        onSelected = null,
        labels = const PlayerPauseMenuLabels(),
        presentation = null;

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction>? onSelected;
  final PlayerPauseMenuLabels labels;
  final PlayerPausePresentation? presentation;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child case final content?) return content;
    return PlayerSurfacePaletteScope(
      role: ProjectPresentationSurfaceRole.pauseMenu,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final pausePresentation =
        presentation ?? PlayerPausePresentation.fromLabels(labels);
    final visibleActions = pausePresentation.visibleActions;
    final firstEnabledAction = visibleActions
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
                  pausePresentation.resolvedTitle(context.playerL10n),
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
                        itemCount: visibleActions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 68,
                          crossAxisSpacing: PlayerSpacing.sm,
                          mainAxisSpacing: PlayerSpacing.sm,
                        ),
                        itemBuilder: (context, index) => _action(
                          context,
                          visibleActions[index],
                          firstEnabledAction,
                          pausePresentation,
                        ),
                      )
                    : ListView.separated(
                        key: const ValueKey<String>('player-pause-list'),
                        itemCount: visibleActions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: PlayerSpacing.xs),
                        itemBuilder: (context, index) => _action(
                          context,
                          visibleActions[index],
                          firstEnabledAction,
                          pausePresentation,
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
    PlayerPausePresentation presentation,
  ) {
    final availability = _availability(context, action);
    return PlayerActionButton(
      label: presentation.label(action, context.playerL10n),
      icon: presentation.icon(action),
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
    this.presentation,
    this.showGameTitle = true,
    this.composition,
    this.compositionLayoutName,
    this.illustrated = false,
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final bool useGrid;
  final Key? scrollKey;
  final ScrollController? scrollController;
  final RuntimePlayerFocusController? focusController;
  final PlayerPauseMenuLabels labels;
  final PlayerPausePresentation? presentation;
  final bool showGameTitle;
  final ProjectPauseCompositionVariantProfile? composition;
  final String? compositionLayoutName;
  final bool illustrated;

  @override
  Widget build(BuildContext context) {
    final pausePresentation =
        presentation ?? PlayerPausePresentation.fromLabels(labels);
    final visibleActions = pausePresentation.visibleActions;
    final firstEnabledAction = visibleActions
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    return SingleChildScrollView(
      key: scrollKey ??
          ValueKey<String>(
            useGrid ? 'player-pause-grid' : 'player-pause-list',
          ),
      controller: scrollController,
      child: Column(
        key: composition == null
            ? const ValueKey<String>('runtime-pause-navigation')
            : ValueKey<String>(
                'runtime-pause-composition-'
                '${compositionLayoutName ?? 'custom'}-'
                '${_compositionName(composition!)}',
              ),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (composition?.showTitle ?? true) ...<Widget>[
            Semantics(
              header: true,
              child: Text(
                pausePresentation.resolvedTitle(context.playerL10n),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: PlayerSpacing.xs),
          ],
          if (showGameTitle)
            Text(gameTitle, style: Theme.of(context).textTheme.titleMedium),
          if (composition?.showHint ?? true)
            if (pausePresentation.hint case final hint?) ...<Widget>[
              const SizedBox(height: PlayerSpacing.xs),
              Text(hint, style: Theme.of(context).textTheme.bodySmall),
            ],
          SizedBox(
            height: illustrated
                ? 0
                : composition == null
                    ? PlayerSpacing.lg
                    : _entrySpacing(composition!),
          ),
          if (useGrid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 68,
                crossAxisSpacing: PlayerSpacing.sm,
                mainAxisSpacing: PlayerSpacing.sm,
              ),
              itemBuilder: (context, index) => _action(
                context,
                visibleActions[index],
                firstEnabledAction,
                pausePresentation,
              ),
            )
          else
            for (var index = 0;
                index < visibleActions.length;
                index++) ...<Widget>[
              _action(
                context,
                visibleActions[index],
                firstEnabledAction,
                pausePresentation,
              ),
              if (index != visibleActions.length - 1)
                SizedBox(
                  height: illustrated &&
                          (composition == null ||
                              composition!.entrySpacing ==
                                  ProjectPauseEntrySpacing.regular)
                      ? 8
                      : composition == null
                          ? illustrated
                              ? 8
                              : PlayerSpacing.xs
                          : _entrySpacing(composition!),
                ),
            ],
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    PlayerPauseAction action,
    PlayerPauseAction? firstEnabledAction,
    PlayerPausePresentation presentation,
  ) {
    final availability = _availability(context, action);
    final logicalId = _logicalId(action);
    final controller = focusController;
    if (illustrated) {
      final theme = context.playerMenuTheme;
      final selected = controller?.logicalSelectionId == logicalId;
      final color = selected
          ? theme.selectionText
          : switch (action) {
              PlayerPauseAction.party => theme.danger,
              PlayerPauseAction.bag => theme.warning,
              PlayerPauseAction.quests => theme.health,
              PlayerPauseAction.map ||
              PlayerPauseAction.pokedex ||
              PlayerPauseAction.save =>
                theme.accent,
              _ => theme.secondary,
            };
      return PlayerMenuSelectableRow(
        key: ValueKey(logicalId),
        id: logicalId,
        label: presentation.label(action, context.playerL10n),
        leading: SizedBox(
            width: 48,
            child: Icon(presentation.icon(action), size: 32, color: color)),
        integrated: true,
        minimumHeight: composition == null ||
                composition!.entrySize == ProjectPauseEntrySize.regular
            ? 64
            : _entryHeight(composition!.entrySize),
        selected: selected,
        showFocusHighlight: controller?.showFocusHighlight ?? false,
        focusNode: controller?.nodeFor(logicalId,
            debugLabel:
                'Player action: ${presentation.label(action, context.playerL10n)}'),
        disabledReason: availability.disabledReason,
        onPressed: availability.isEnabled
            ? () {
                controller?.select(logicalId,
                    source: controller.activeInputSource);
                onSelected(action);
              }
            : null,
      );
    }
    return PlayerActionButton(
      key: ValueKey<String>(logicalId),
      label: presentation.label(action, context.playerL10n),
      icon: presentation.icon(action),
      focusNode: controller?.nodeFor(
        logicalId,
        debugLabel:
            'Player action: ${presentation.label(action, context.playerL10n)}',
      ),
      showFocusHighlight: controller?.showFocusHighlight ?? true,
      selected: controller?.logicalSelectionId == logicalId,
      shortcutLabel: context.playerL10n.confirmShortcut,
      minimumHeight:
          composition == null ? 48 : _entryHeight(composition!.entrySize),
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

  String _logicalId(PlayerPauseAction action) => 'pause.${action.name}';
}

double _entryHeight(ProjectPauseEntrySize size) => switch (size) {
      ProjectPauseEntrySize.compact => 48,
      ProjectPauseEntrySize.regular => 56,
      ProjectPauseEntrySize.large => 68,
    };

double _entrySpacing(ProjectPauseCompositionVariantProfile composition) =>
    switch (composition.entrySpacing) {
      ProjectPauseEntrySpacing.tight => PlayerSpacing.xs,
      ProjectPauseEntrySpacing.regular => PlayerSpacing.sm,
      ProjectPauseEntrySpacing.airy => PlayerSpacing.md,
    };

String _compositionName(ProjectPauseCompositionVariantProfile composition) =>
    '${composition.entrySize.name}-${composition.entrySpacing.name}';
