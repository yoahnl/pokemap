import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_new_game_identity.dart';
import 'runtime_player_focus_controller.dart';

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
  cinematic,
  runtimeStartup;

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
    this.backgroundContent,
    this.logo,
    this.accentColor,
    this.layoutVariant = PlayerTitleLayoutVariant.standard,
    required Map<PlayerTitleMenuAction, PlayerActionAvailability> actions,
    this.initialSelection,
  }) : actions = Map.unmodifiable(actions);

  final String gameTitle;
  final String author;
  final String? description;
  final ImageProvider? background;
  final Widget? backgroundContent;
  final ImageProvider? logo;
  final Color? accentColor;
  final PlayerTitleLayoutVariant layoutVariant;
  final Map<PlayerTitleMenuAction, PlayerActionAvailability> actions;
  final PlayerTitleMenuAction? initialSelection;
}

class PlayerTitleScreen extends StatelessWidget {
  const PlayerTitleScreen({
    super.key,
    required this.data,
    required this.onSelected,
    this.focusController,
  });

  final PlayerTitleViewData data;
  final ValueChanged<PlayerTitleMenuAction> onSelected;
  final RuntimePlayerFocusController? focusController;

  @override
  Widget build(BuildContext context) {
    if (data.layoutVariant == PlayerTitleLayoutVariant.runtimeStartup) {
      return _buildRuntimeStartup(context);
    }
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
                      role: PlayerPanelRole.title,
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
                              style: context.playerTypography.displayStyle(
                                Theme.of(context).textTheme.displaySmall ??
                                    const TextStyle(),
                              ),
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
                                style: context.playerTypography.bodyStyle(
                                  Theme.of(context).textTheme.bodyLarge ??
                                      const TextStyle(),
                                ),
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
                                  focusNode: _focusNode(action),
                                  showFocusHighlight:
                                      focusController?.showFocusHighlight ??
                                          true,
                                  selected: _isSelected(action),
                                  onPressed:
                                      _availability(context, action).isEnabled
                                          ? () => _select(action)
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

  Widget _buildRuntimeStartup(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            if (compact) {
              return Stack(
                key: const ValueKey<String>('player-title-startup-compact'),
                fit: StackFit.expand,
                children: <Widget>[
                  _startupVisual(context),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(420, constraints.maxHeight * .68),
                      ),
                      child: _startupMenu(context, compact: true),
                    ),
                  ),
                ],
              );
            }
            final panelWidth = math.min(
              480.0,
              math.max(380.0, constraints.maxWidth * .38),
            );
            return Row(
              key: const ValueKey<String>('player-title-startup-expanded'),
              children: <Widget>[
                SizedBox(
                  width: panelWidth,
                  child: _startupMenu(context, compact: false),
                ),
                Expanded(child: _startupVisual(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _startupVisual(BuildContext context) {
    final colors = context.playerColors;
    final fallback = DecoratedBox(
      key: const ValueKey<String>('player-title-startup-visual'),
      decoration: BoxDecoration(
        color: colors.background,
        image: data.background == null
            ? null
            : DecorationImage(image: data.background!, fit: BoxFit.cover),
      ),
      child: data.background == null
          ? Center(
              child: Icon(
                Icons.landscape_rounded,
                size: 84,
                color: colors.primary.withValues(alpha: .38),
              ),
            )
          : const SizedBox.expand(),
    );
    final backgroundContent = data.backgroundContent;
    if (backgroundContent == null) return fallback;
    return Stack(
      key: const ValueKey<String>('player-title-startup-visual'),
      fit: StackFit.expand,
      children: <Widget>[fallback, backgroundContent],
    );
  }

  Widget _startupMenu(BuildContext context, {required bool compact}) {
    final colors = context.playerColors;
    final firstEnabledAction = data.initialSelection ??
        data.actions.keys
            .where((action) => _availability(context, action).isEnabled)
            .firstOrNull;
    final horizontal = compact ? PlayerSpacing.lg : PlayerSpacing.xl;
    return Material(
      color: colors.surface,
      elevation: compact ? 16 : 0,
      borderRadius: compact
          ? const BorderRadius.vertical(top: Radius.circular(PlayerRadii.lg))
          : BorderRadius.zero,
      child: SingleChildScrollView(
        key: const ValueKey<String>('player-title-startup-menu-scroll'),
        padding: EdgeInsets.fromLTRB(
          horizontal,
          compact ? PlayerSpacing.lg : PlayerSpacing.xl,
          horizontal,
          PlayerSpacing.lg,
        ),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (data.logo != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 92),
                    child: Image(
                      image: data.logo!,
                      fit: BoxFit.contain,
                      semanticLabel: data.gameTitle,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                )
              else
                Text(
                  data.gameTitle,
                  style: context.playerTypography.displayStyle(
                    Theme.of(context).textTheme.headlineLarge ??
                        const TextStyle(),
                  ),
                ),
              const SizedBox(height: PlayerSpacing.xs),
              Text(
                data.author,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colors.textSecondary),
              ),
              if (!compact && data.description != null) ...[
                const SizedBox(height: PlayerSpacing.sm),
                Text(
                  data.description!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: PlayerSpacing.lg),
              for (final action in data.actions.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: PlayerActionButton(
                      label: _label(context, action),
                      icon: _icon(action),
                      autofocus: focusController?.logicalSelectionId == null
                          ? action == firstEnabledAction
                          : _isSelected(action),
                      disabledReason:
                          _availability(context, action).disabledReason,
                      focusNode: _focusNode(action),
                      showFocusHighlight:
                          focusController?.showFocusHighlight ?? true,
                      selected: _isSelected(action),
                      onPressed: _availability(context, action).isEnabled
                          ? () => _select(action)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _logicalId(PlayerTitleMenuAction action) => switch (action) {
        PlayerTitleMenuAction.continueGame => 'title.continueGame',
        PlayerTitleMenuAction.newGame => 'title.newGame',
        PlayerTitleMenuAction.load => 'title.load',
        PlayerTitleMenuAction.options => 'title.openOptions',
        PlayerTitleMenuAction.creditsAbout => 'title.showCredits',
        PlayerTitleMenuAction.returnToHub => 'title.returnToHost',
      };

  FocusNode? _focusNode(PlayerTitleMenuAction action) =>
      focusController?.nodeFor(
        _logicalId(action),
        debugLabel: 'Title ${action.name}',
      );

  bool _isSelected(PlayerTitleMenuAction action) =>
      focusController?.logicalSelectionId == _logicalId(action);

  void _select(PlayerTitleMenuAction action) {
    focusController?.select(
      _logicalId(action),
      source: PlayerInputSource.touch,
    );
    onSelected(action);
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
