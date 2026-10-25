import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
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
  contacts,
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

  String action(PlayerPauseAction action, PokeMapPlayerLocalizations l10n) =>
      switch (action) {
        PlayerPauseAction.resume => resume ?? l10n.resume,
        PlayerPauseAction.party => party ?? l10n.party,
        PlayerPauseAction.bag => bag ?? l10n.bag,
        PlayerPauseAction.pokedex => pokedex ?? l10n.pokedex,
        PlayerPauseAction.map => map ?? l10n.map,
        PlayerPauseAction.quests => quests ?? l10n.quests,
        PlayerPauseAction.contacts =>
          l10n.locale.languageCode == 'fr' ? 'Téléphone' : 'Phone',
        PlayerPauseAction.profile => profile ?? l10n.profile,
        PlayerPauseAction.save => save ?? l10n.save,
        PlayerPauseAction.options => options ?? l10n.options,
        PlayerPauseAction.returnToTitle => returnToTitle ?? l10n.returnToTitle,
      };
}

@immutable
final class PlayerPausePresentation {
  const PlayerPausePresentation({
    ProjectPauseMenuStyle? style,
    this.background,
    this.backgroundImage,
    this.title,
    this.hint,
    this.actionOrder,
    this.actionLabels = const <PlayerPauseAction, String>{},
    this.actionIcons = const <PlayerPauseAction, ProjectPauseActionIcon>{},
    this.hiddenActions = const <PlayerPauseAction>{},
    this.composition,
  }) : style = style ?? ProjectPauseMenuStyle.nightIllustrated;

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

  factory PlayerPausePresentation.fromLabels(
    PlayerPauseMenuLabels labels,
  ) => PlayerPausePresentation(
    title: labels.pauseTitle,
    actionLabels: <PlayerPauseAction, String>{
      if (labels.resume case final value?) PlayerPauseAction.resume: value,
      if (labels.party case final value?) PlayerPauseAction.party: value,
      if (labels.bag case final value?) PlayerPauseAction.bag: value,
      if (labels.pokedex case final value?) PlayerPauseAction.pokedex: value,
      if (labels.map case final value?) PlayerPauseAction.map: value,
      if (labels.quests case final value?) PlayerPauseAction.quests: value,
      if (labels.profile case final value?) PlayerPauseAction.profile: value,
      if (labels.save case final value?) PlayerPauseAction.save: value,
      if (labels.options case final value?) PlayerPauseAction.options: value,
      if (labels.returnToTitle case final value?)
        PlayerPauseAction.returnToTitle: value,
    },
  );

  final ProjectPauseMenuStyle style;
  final ProjectPauseBackgroundProfile? background;
  final ImageProvider? backgroundImage;
  final String? title;
  final String? hint;
  final List<PlayerPauseAction>? actionOrder;
  final Map<PlayerPauseAction, String> actionLabels;
  final Map<PlayerPauseAction, ProjectPauseActionIcon> actionIcons;
  final Set<PlayerPauseAction> hiddenActions;
  final ProjectResponsivePauseCompositionProfile? composition;

  PlayerPausePresentation resolveVisibility(
    PlayerPauseMenuState state, {
    bool contactsAvailable = true,
  }) {
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
          if (action == PlayerPauseAction.contacts && !contactsAvailable ||
              !state.isActionVisible(
                _projectPauseAction(action),
                projectDefaultVisibility:
                    !hiddenActions.contains(action) &&
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

  IconData icon(PlayerPauseAction action) {
    if (action == PlayerPauseAction.contacts &&
        !actionIcons.containsKey(action))
      return Icons.call_outlined;
    return switch (actionIcons[action] ?? _defaultPauseActionIcon(action)) {
      ProjectPauseActionIcon.play => Icons.play_arrow_rounded,
      ProjectPauseActionIcon.party => Icons.catching_pokemon,
      ProjectPauseActionIcon.bag => Icons.backpack_rounded,
      ProjectPauseActionIcon.book => Icons.menu_book_rounded,
      ProjectPauseActionIcon.map => Icons.map_rounded,
      ProjectPauseActionIcon.person => Icons.person_rounded,
      ProjectPauseActionIcon.save => Icons.save_rounded,
      ProjectPauseActionIcon.settings => Icons.settings_rounded,
      ProjectPauseActionIcon.exit => Icons.logout_rounded,
    };
  }
}

PlayerPauseAction _pauseAction(ProjectPauseActionId id) => switch (id) {
  ProjectPauseActionId.resume => PlayerPauseAction.resume,
  ProjectPauseActionId.party => PlayerPauseAction.party,
  ProjectPauseActionId.bag => PlayerPauseAction.bag,
  ProjectPauseActionId.pokedex => PlayerPauseAction.pokedex,
  ProjectPauseActionId.map => PlayerPauseAction.map,
  ProjectPauseActionId.quests => PlayerPauseAction.quests,
  ProjectPauseActionId.contacts => PlayerPauseAction.contacts,
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
      PlayerPauseAction.contacts => ProjectPauseActionId.contacts,
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
      PlayerPauseAction.contacts => ProjectPauseActionIcon.book,
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
            final showGameTitle =
                resolved == null ||
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
                Text(gameTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: PlayerSpacing.lg),
              Expanded(
                child: PlayerPagedList(
                  key: ValueKey(
                    wide ? 'player-pause-grid' : 'player-pause-list',
                  ),
                  children: [
                    for (
                      var i = 0;
                      i < visibleActions.length;
                      i += wide ? 2 : 1
                    )
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _action(
                                context,
                                visibleActions[i],
                                firstEnabledAction,
                                pausePresentation,
                              ),
                            ),
                            if (wide) ...[
                              const SizedBox(width: PlayerSpacing.sm),
                              Expanded(
                                child: i + 1 < visibleActions.length
                                    ? _action(
                                        context,
                                        visibleActions[i + 1],
                                        firstEnabledAction,
                                        pausePresentation,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
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
      PlayerActionAvailability.disabled(context.playerL10n.actionUnavailable);
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
    this.confirmShortcut,
    this.labels = const PlayerPauseMenuLabels(),
    this.presentation,
    this.showGameTitle = true,
    this.composition,
    this.compositionLayoutName,
    this.illustrated = false,
    this.mobileGrid = false,
    this.fillViewport = false,
    this.sideNavigation = false,
    this.additionalContent = const [],
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final bool useGrid;
  final Key? scrollKey;
  final ScrollController? scrollController;
  final RuntimePlayerFocusController? focusController;
  final String? confirmShortcut;
  final PlayerPauseMenuLabels labels;
  final PlayerPausePresentation? presentation;
  final bool showGameTitle;
  final ProjectPauseCompositionVariantProfile? composition;
  final String? compositionLayoutName;
  final bool illustrated;
  final bool mobileGrid;
  final bool fillViewport;
  final bool sideNavigation;
  final List<Widget> additionalContent;

  @override
  Widget build(BuildContext context) {
    final pausePresentation =
        presentation ?? PlayerPausePresentation.fromLabels(labels);
    final visibleActions = pausePresentation.visibleActions;
    final firstEnabledAction = visibleActions
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    return LayoutBuilder(
      key: fillViewport
          ? const ValueKey('runtime-pause-action-grid')
          : scrollKey,
      builder: (context, constraints) {
        final compactRows =
            sideNavigation ||
            !mobileGrid &&
                !fillViewport &&
                constraints.maxWidth < 450 &&
                constraints.maxHeight < 300;
        final columns = compactRows
            ? 1
            : fillViewport
            ? ((constraints.maxWidth + 8) / (120 + 8))
                  .floor()
                  .clamp(1, math.max(1, math.min(4, visibleActions.length)))
                  .toInt()
            : mobileGrid && constraints.maxWidth >= 240
            ? 2
            : useGrid
            ? 2
            : 1;
        final selectedIndex = visibleActions.indexWhere(
          (action) => _logicalId(action) == focusController?.logicalSelectionId,
        );
        final rows = <Widget>[
          for (var index = 0; index < visibleActions.length; index += columns)
            IntrinsicHeight(
              key: ValueKey('pause-row-${visibleActions[index].name}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0)
                      SizedBox(width: fillViewport ? 8 : PlayerSpacing.sm),
                    Expanded(
                      child: index + column < visibleActions.length
                          ? _action(
                              context,
                              visibleActions[index + column],
                              firstEnabledAction,
                              pausePresentation,
                              compactRows: compactRows,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
        ];
        rows.addAll(additionalContent);
        final entries = PlayerPagedList(
          sideNavigation: sideNavigation,
          revealChildKey: selectedIndex < 0
              ? null
              : ValueKey(
                  'pause-row-${visibleActions[selectedIndex ~/ columns * columns].name}',
                ),
          spacing: fillViewport || mobileGrid
              ? 8
              : composition == null
              ? PlayerSpacing.sm
              : _entrySpacing(composition!),
          onPageReady: () => focusController?.restoreSelection(
            focusController?.logicalSelectionId,
          ),
          children: rows,
        );
        final heading = <Widget>[
          if (!fillViewport && (composition?.showTitle ?? true))
            Semantics(
              header: true,
              child: Text(
                pausePresentation.resolvedTitle(context.playerL10n),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          if (!fillViewport && showGameTitle)
            Text(gameTitle, style: Theme.of(context).textTheme.titleMedium),
          if (!fillViewport &&
              (composition?.showHint ?? true) &&
              pausePresentation.hint != null)
            Text(
              pausePresentation.hint!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ];
        return Column(
          key: composition == null
              ? const ValueKey('runtime-pause-navigation')
              : ValueKey(
                  'runtime-pause-composition-${compositionLayoutName ?? 'custom'}-${_compositionName(composition!)}',
                ),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: constraints.hasBoundedHeight
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            ...heading,
            if (heading.isNotEmpty) const SizedBox(height: PlayerSpacing.sm),
            if (constraints.hasBoundedHeight)
              Expanded(child: entries)
            else
              entries,
          ],
        );
      },
    );
  }

  Widget _action(
    BuildContext context,
    PlayerPauseAction action,
    PlayerPauseAction? firstEnabledAction,
    PlayerPausePresentation presentation, {
    bool compactRows = false,
  }) {
    final mobileTiles = mobileGrid && !compactRows;
    final availability = _availability(context, action);
    final logicalId = _logicalId(action);
    final controller = focusController;
    if (illustrated || fillViewport) {
      final theme = context.playerMenuTheme;
      final selected = controller?.logicalSelectionId == logicalId;
      final color = selected
          ? theme.selectionText
          : switch (action) {
              PlayerPauseAction.party => theme.danger,
              PlayerPauseAction.bag => theme.warning,
              PlayerPauseAction.quests => theme.health,
              PlayerPauseAction.contacts => theme.health,
              PlayerPauseAction.map ||
              PlayerPauseAction.pokedex ||
              PlayerPauseAction.save => theme.accent,
              _ => theme.secondary,
            };
      return PlayerMenuSelectableRow(
        key: ValueKey(logicalId),
        id: logicalId,
        label: presentation.label(action, context.playerL10n),
        labelStyle: mobileGrid || fillViewport
            ? theme.label.copyWith(
                fontSize: MediaQuery.sizeOf(context).width >= 650 ? 14 : 16,
                height: 1.3,
                fontWeight: FontWeight.w600,
              )
            : null,
        reserveFocusMarker: !mobileGrid && !fillViewport,
        trailing: mobileGrid || fillViewport
            ? const Icon(Icons.chevron_right_rounded, size: 16)
            : null,
        trailingWidth: mobileGrid || fillViewport ? 16 : null,
        labelMaxLines: mobileGrid || fillViewport ? 1 : null,
        contentGap: mobileGrid || fillViewport ? 8 : 12,
        leading: SizedBox(
          width: fillViewport
              ? 32
              : mobileTiles
              ? 20
              : 48,
          child: Icon(
            presentation.icon(action),
            size: mobileTiles ? 20 : 32,
            color: mobileGrid || fillViewport
                ? (selected ? theme.selectionText : theme.text)
                : color,
          ),
        ),
        integrated: !mobileTiles && !fillViewport,
        tile: false,
        fitTileContent: false,
        contentPadding: EdgeInsets.symmetric(
          horizontal: mobileTiles ? 6 : 12,
          vertical: mobileTiles ? 8 : 10,
        ),
        minimumHeight: fillViewport
            ? 52
            : mobileTiles
            ? 48
            : composition == null ||
                  composition!.entrySize == ProjectPauseEntrySize.regular
            ? 64
            : _entryHeight(composition!.entrySize),
        selected: selected,
        showFocusHighlight: controller?.showFocusHighlight ?? false,
        focusNode: controller?.nodeFor(
          logicalId,
          debugLabel:
              'Player action: ${presentation.label(action, context.playerL10n)}',
        ),
        disabledReason: availability.disabledReason,
        showDisabledReason: !mobileGrid && !fillViewport,
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
      shortcutLabel: confirmShortcut ?? context.playerL10n.confirmShortcut,
      minimumHeight: composition == null
          ? 48
          : _entryHeight(composition!.entrySize),
      autofocus:
          controller?.logicalSelectionId == null &&
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
      PlayerActionAvailability.disabled(context.playerL10n.actionUnavailable);

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
