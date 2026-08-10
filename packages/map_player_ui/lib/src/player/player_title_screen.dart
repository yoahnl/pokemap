import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
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
  runtimeStartup,
  runtimeStartupCinematic;

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
  });

  final String author;
  final String? description;
  final ImageProvider? background;
  final ImageProvider? logo;
  final Color? accentColor;
  final PlayerTitleLayoutVariant layoutVariant;
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
    this.continueSave,
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
  final PlayerSaveSummary? continueSave;
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
    if (data.layoutVariant == PlayerTitleLayoutVariant.runtimeStartup ||
        data.layoutVariant ==
            PlayerTitleLayoutVariant.runtimeStartupCinematic) {
      return _buildRuntimeStartup(
        context,
        cinematic: data.layoutVariant ==
            PlayerTitleLayoutVariant.runtimeStartupCinematic,
      );
    }
    final colors = context.playerColors;
    final accent = data.accentColor ?? colors.primary;
    final firstEnabledAction = PlayerTitleMenuAction.values
        .where((action) => _availability(context, action).isEnabled)
        .firstOrNull;
    final cinematic = data.layoutVariant == PlayerTitleLayoutVariant.cinematic;
    final contentAlignment =
        cinematic ? Alignment.bottomLeft : Alignment.center;
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
            builder: (context, constraints) {
              final resolved = context.playerLayoutTheme?.resolve(
                ProjectPresentationSurfaceRole.title,
                constraints,
              );
              final variant = resolved?.variant;
              final authoredAlignment = variant == null
                  ? contentAlignment
                  : switch (variant.slot) {
                      ProjectPresentationLayoutSlot.center => Alignment.center,
                      ProjectPresentationLayoutSlot.bottomCenter =>
                        Alignment.bottomCenter,
                      ProjectPresentationLayoutSlot.bottomLeft =>
                        Alignment.bottomLeft,
                      ProjectPresentationLayoutSlot.leftPane =>
                        Alignment.centerLeft,
                      _ => contentAlignment,
                    };
              final authoredTextAlignment = switch (authoredAlignment) {
                Alignment.center || Alignment.bottomCenter => TextAlign.center,
                _ => TextAlign.start,
              };
              final spacingScale = resolved?.spacingScale ?? 1;
              final secondary = variant?.visibleSecondaryElements;
              final showLogo = secondary == null ||
                  secondary.contains(
                    ProjectPresentationSecondaryElement.titleLogo,
                  );
              final showAuthor = secondary == null ||
                  secondary.contains(
                    ProjectPresentationSecondaryElement.titleAuthor,
                  );
              final showDescription = secondary == null ||
                  secondary.contains(
                    ProjectPresentationSecondaryElement.titleDescription,
                  );
              double gap(double value) => value * spacingScale;
              return SingleChildScrollView(
                key: const ValueKey<String>('player-title-scroll'),
                padding: EdgeInsets.all(
                  PlayerSpacing.lg + (resolved?.additionalSafeAreaPadding ?? 0),
                ),
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
                    alignment: authoredAlignment,
                    child: KeyedSubtree(
                      key: resolved == null
                          ? null
                          : ValueKey<String>(
                              'player-title-responsive-'
                              '${resolved.breakpoint.name}',
                            ),
                      child: ConstrainedBox(
                        key: ValueKey<String>(
                          'player-title-layout-${data.layoutVariant.name}',
                        ),
                        constraints: BoxConstraints(
                          maxWidth: resolved == null
                              ? (cinematic ? 680 : 560)
                              : math.min(
                                  840,
                                  constraints.maxWidth *
                                      resolved.maxWidthFactor,
                                ),
                        ),
                        child: PlayerPanel(
                          elevated: true,
                          role: PlayerPanelRole.title,
                          surfaceRole:
                              ProjectPresentationSurfaceRole.titlePrompt,
                          child: FocusTraversalGroup(
                            policy: OrderedTraversalPolicy(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: cinematic ||
                                      authoredTextAlignment == TextAlign.start
                                  ? CrossAxisAlignment.stretch
                                  : CrossAxisAlignment.center,
                              children: <Widget>[
                                if (showLogo && data.logo != null)
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 150),
                                    child: Image(
                                      image: data.logo!,
                                      fit: BoxFit.contain,
                                      semanticLabel: data.gameTitle,
                                    ),
                                  )
                                else if (showLogo)
                                  Icon(
                                    Icons.explore_rounded,
                                    size: 64,
                                    color: accent,
                                  ),
                                SizedBox(height: gap(PlayerSpacing.md)),
                                Text(
                                  data.gameTitle,
                                  textAlign: authoredTextAlignment,
                                  style: context.playerTypography.displayStyle(
                                    Theme.of(context).textTheme.displaySmall ??
                                        const TextStyle(),
                                  ),
                                ),
                                if (showAuthor) ...<Widget>[
                                  SizedBox(height: gap(PlayerSpacing.xs)),
                                  Text(
                                    data.author,
                                    textAlign: authoredTextAlignment,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                                if (showDescription)
                                  if (data.description
                                      case final description?) ...[
                                    SizedBox(height: gap(PlayerSpacing.md)),
                                    Text(
                                      description,
                                      textAlign: authoredTextAlignment,
                                      style: context.playerTypography.bodyStyle(
                                        Theme.of(context).textTheme.bodyLarge ??
                                            const TextStyle(),
                                      ),
                                    ),
                                  ],
                                SizedBox(height: gap(PlayerSpacing.xl)),
                                for (final action
                                    in PlayerTitleMenuAction.values)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: gap(PlayerSpacing.xs),
                                    ),
                                    child: PlayerActionButton(
                                      label: _label(context, action),
                                      icon: _icon(action),
                                      autofocus: action == firstEnabledAction,
                                      secondary: action ==
                                          PlayerTitleMenuAction.returnToHub,
                                      disabledReason:
                                          _availability(context, action)
                                              .disabledReason,
                                      focusNode: _focusNode(action),
                                      showFocusHighlight:
                                          focusController?.showFocusHighlight ??
                                              true,
                                      selected: _isSelected(action),
                                      onPressed: _availability(context, action)
                                              .isEnabled
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRuntimeStartup(
    BuildContext context, {
    required bool cinematic,
  }) {
    final content = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth <= 760;
          if (cinematic) {
            if (compact) {
              return _startupPremiumMenu(context);
            }
            return Row(
              key: const ValueKey<String>('player-title-startup-expanded'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(width: 392, child: _startupPremiumMenu(context)),
                Expanded(child: _startupVisual(context)),
              ],
            );
          }
          if (compact) {
            final visualHeight = constraints.maxHeight * .58;
            final menuHeight = math.min(
              410.0,
              math.max(340.0, constraints.maxHeight * .45),
            );
            return Stack(
              key: const ValueKey<String>('player-title-startup-compact'),
              fit: StackFit.expand,
              children: <Widget>[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: visualHeight,
                  child: _startupVisual(context),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: menuHeight,
                  child: _startupMenu(context, compact: true),
                ),
              ],
            );
          }
          final panelWidth = math.min(
            640.0,
            math.max(390.0, constraints.maxWidth * .43),
          );
          return Row(
            key: const ValueKey<String>('player-title-startup-expanded'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
    );
    return Scaffold(body: content);
  }

  Widget _startupPremiumMenu(BuildContext context) {
    final colors = context.playerColors;
    final semantic = context.playerSemanticTheme;
    final firstEnabledAction = data.initialSelection ??
        data.actions.keys
            .where((action) => _availability(context, action).isEnabled)
            .firstOrNull;
    return Material(
      key: const ValueKey<String>('player-title-startup-menu'),
      color: semantic.background,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const <double>[0, .18, .46, .64, .78, 1],
                colors: <Color>[
                  Color.lerp(semantic.background, semantic.surface, .38)!,
                  Color.lerp(semantic.background, semantic.surface, .66)!,
                  Color.lerp(semantic.background, semantic.surface, .86)!,
                  Color.lerp(semantic.background, semantic.surface, .18)!,
                  semantic.background,
                  Color.lerp(semantic.background, semantic.surface, .46)!,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  semantic.surfaceElevated.withValues(alpha: 0),
                  semantic.surfaceElevated.withValues(alpha: .32),
                  semantic.surfaceElevated.withValues(alpha: .42),
                  semantic.surfaceElevated.withValues(alpha: .38),
                  semantic.surfaceElevated.withValues(alpha: .18),
                  semantic.surfaceElevated.withValues(alpha: 0),
                ],
                stops: const <double>[.08, .15, .18, .22, .35, .43],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  semantic.onPrimary.withValues(alpha: 0),
                  semantic.onPrimary.withValues(alpha: .19),
                  semantic.onPrimary.withValues(alpha: .25),
                  semantic.onPrimary.withValues(alpha: .2),
                  semantic.onPrimary.withValues(alpha: 0),
                ],
                stops: const <double>[.08, .15, .18, .22, .3],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(.48, -.1),
                radius: .68,
                colors: <Color>[
                  semantic.surface.withValues(alpha: .2),
                  semantic.surface.withValues(alpha: .08),
                  semantic.surface.withValues(alpha: 0),
                ],
                stops: const <double>[0, .46, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(.34, 1.08),
                radius: .66,
                colors: <Color>[
                  semantic.surface.withValues(alpha: .16),
                  semantic.surface.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 46, right: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 74),
                SizedBox(
                  key: const ValueKey<String>('player-title-premium-title'),
                  height: 64,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _premiumTitle,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: context.playerTypography.displayStyle(
                        (Theme.of(context).textTheme.headlineLarge ??
                                const TextStyle())
                            .copyWith(
                          color: colors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                          height: .82,
                          letterSpacing: -1.25,
                          fontFeatures: const <FontFeature>[
                            FontFeature.liningFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                for (final (index, action) in data.actions.keys.indexed) ...[
                  if (index > 0) const SizedBox(height: 5),
                  _startupPremiumAction(
                    context,
                    action: action,
                    selected: _isStartupHighlighted(action, firstEnabledAction),
                  ),
                ],
                const Spacer(),
                _startupPremiumControls(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _startupPremiumAction(
    BuildContext context, {
    required PlayerTitleMenuAction action,
    required bool selected,
  }) {
    final colors = context.playerColors;
    final availability = _availability(context, action);
    final enabled = availability.isEnabled;
    final foreground = selected ? colors.onPrimary : colors.textSecondary;
    final focusNode = _focusNode(action);
    final firstEnabledAction = data.initialSelection ??
        data.actions.keys
            .where((candidate) => _availability(context, candidate).isEnabled)
            .firstOrNull;
    return SizedBox(
      height: 58,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          key: ValueKey<String>('player-title-premium-action-${action.name}'),
          height: selected ? 58 : 48,
          child: Focus(
            focusNode: focusNode,
            autofocus: focusController?.logicalSelectionId == null
                ? action == firstEnabledAction
                : _isSelected(action),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: colors.primary.withValues(alpha: .16),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Material(
                color: selected
                    ? colors.primary
                    : colors.background.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: enabled ? () => _select(action) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.circle,
                                size: selected ? 18 : 7,
                                color: selected
                                    ? (data.accentColor ?? colors.warning)
                                        .withValues(alpha: .22)
                                    : colors.outline.withValues(
                                        alpha: enabled ? .48 : .28,
                                      ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: data.accentColor ?? colors.warning,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: Text(
                            _label(context, action),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.playerTypography.bodyStyle(
                              (Theme.of(context).textTheme.labelLarge ??
                                      const TextStyle())
                                  .copyWith(
                                color: enabled
                                    ? foreground
                                    : foreground.withValues(alpha: .45),
                                fontSize: 16,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                letterSpacing: .05,
                              ),
                            ),
                          ),
                        ),
                        if (action == PlayerTitleMenuAction.continueGame)
                          _continueSaveMetadata(
                                context,
                                color: selected
                                    ? colors.onPrimary.withValues(alpha: .58)
                                    : colors.textSecondary.withValues(
                                        alpha: .68,
                                      ),
                                fontSize: 9,
                              ) ??
                              const SizedBox.shrink(),
                      ],
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

  Widget _startupPremiumControls(BuildContext context) {
    final colors = context.playerColors;
    final labelStyle = context.playerTypography.bodyStyle(
      (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
        color: colors.textSecondary.withValues(alpha: .82),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    return SizedBox(
      key: const ValueKey<String>('player-title-premium-controls'),
      height: 26,
      child: Row(
        children: <Widget>[
          _startupPremiumKey(
            context,
            width: 31,
            child: Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(context.playerL10n.choose, style: labelStyle),
          const SizedBox(width: 18),
          _startupPremiumKey(
            context,
            width: 47,
            child: Text(
              'ENTER',
              style: context.playerTypography.numbersStyle(
                TextStyle(
                  color: colors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .45,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(context.playerL10n.validate, style: labelStyle),
        ],
      ),
    );
  }

  Widget _startupPremiumKey(
    BuildContext context, {
    required double width,
    required Widget child,
  }) =>
      Container(
        width: width,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.playerColors.surfaceElevated.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      );

  String get _premiumTitle {
    final words = data.gameTitle.trim().split(RegExp(r'\s+'));
    if (words.length < 4) return data.gameTitle;
    final split = (words.length / 2).ceil();
    return '${words.take(split).join(' ')}\n${words.skip(split).join(' ')}';
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
      key: const ValueKey<String>('player-title-startup-menu'),
      color: colors.surface,
      elevation: compact ? 16 : 0,
      borderRadius: compact
          ? const BorderRadius.vertical(top: Radius.circular(PlayerRadii.xl))
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
                      quiet: !_isStartupHighlighted(
                        action,
                        firstEnabledAction,
                      ),
                      expandContent: true,
                      autofocus: focusController?.logicalSelectionId == null
                          ? action == firstEnabledAction
                          : _isSelected(action),
                      disabledReason:
                          _availability(context, action).disabledReason,
                      trailing: action == PlayerTitleMenuAction.continueGame
                          ? _continueSaveMetadata(context)
                          : null,
                      focusNode: _focusNode(action),
                      showFocusHighlight:
                          focusController?.showFocusHighlight ?? true,
                      selected: _isStartupHighlighted(
                        action,
                        firstEnabledAction,
                      ),
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

  Widget? _continueSaveMetadata(
    BuildContext context, {
    Color? color,
    double? fontSize,
  }) {
    final save = data.continueSave;
    if (save == null) return null;
    final totalMinutes = save.playTimeSeconds ~/ 60;
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    final location = save.locationLabel;
    final updatedAt = save.updatedAt.toLocal();
    final savedOn = '${updatedAt.day.toString().padLeft(2, '0')}/'
        '${updatedAt.month.toString().padLeft(2, '0')}/'
        '${updatedAt.year}';
    final secondary = location ?? savedOn;
    return Text(
      '$hours:$minutes · $secondary',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color ?? context.playerColors.textSecondary,
            fontSize: fontSize,
          ),
    );
  }

  FocusNode? _focusNode(PlayerTitleMenuAction action) =>
      focusController?.nodeFor(
        _logicalId(action),
        debugLabel: 'Title ${action.name}',
      );

  bool _isSelected(PlayerTitleMenuAction action) =>
      focusController?.logicalSelectionId == _logicalId(action);

  bool _isStartupHighlighted(
    PlayerTitleMenuAction action,
    PlayerTitleMenuAction? fallback,
  ) {
    final selection = focusController?.logicalSelectionId;
    return selection == null
        ? action == fallback
        : selection == _logicalId(action);
  }

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
