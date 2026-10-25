import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../theme/pokemap_player_layout_theme.dart';
import 'player_paged_layout.dart';
import 'player_menu_icon.dart';
import 'player_input_scope.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerMenuPanel extends StatelessWidget {
  const PlayerMenuPanel({
    super.key,
    required this.child,
    this.primary = false,
    this.padding = const EdgeInsets.all(PlayerSpacing.lg),
  });

  final Widget child;
  final bool primary;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return DecoratedBox(
      decoration: theme.panelDecoration(primary: primary),
      child: DefaultTextStyle(
        style: theme.body,
        child: IconTheme(
          data: IconThemeData(color: theme.text),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PlayerMenuFrame extends StatelessWidget {
  const PlayerMenuFrame({
    super.key,
    required this.header,
    required this.child,
    required this.footer,
    this.backdrop,
    this.scrollable = true,
    this.visible = true,
    this.role = ProjectPresentationSurfaceRole.pauseMenu,
    this.contentPadding,
  });

  final Widget header;
  final Widget child;
  final Widget footer;
  final Widget? backdrop;
  final bool scrollable;
  final bool visible;
  final ProjectPresentationSurfaceRole role;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = const ProjectPresentationLayoutResolver().classify(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final compact =
            breakpoint == ProjectPresentationBreakpoint.compact ||
            constraints.maxHeight < 500;
        final authored = context.playerLayoutTheme?.tryResolve(
          role,
          constraints,
        );
        final companion = PlayerCompanionScope.of(context);
        final edgeToEdge =
            authored == null &&
            (constraints.biggest.shortestSide < 600 || companion);
        if (edgeToEdge) {
          final safe = MediaQuery.paddingOf(context);
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final horizontal = companion
              ? 16.0
              : landscape
              ? 44.0
              : 0.0;
          return PlayerMenuTransition(
            visible: visible,
            child: DecoratedBox(
              key: const ValueKey('player-menu-edge-to-edge'),
              decoration: BoxDecoration(color: theme.backdrop),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  math.max(horizontal, safe.left),
                  companion ? math.max(12, safe.top) : safe.top,
                  math.max(horizontal, safe.right),
                  math.max(landscape && !companion ? 20 : 0, safe.bottom),
                ),
                child: Column(
                  children: [
                    header,
                    Expanded(
                      child: Padding(
                        padding:
                            contentPadding ??
                            EdgeInsets.symmetric(
                              horizontal: landscape || companion ? 0 : 16,
                              vertical: 12,
                            ),
                        child: scrollable && child is Column
                            ? PlayerPagedList(
                                children: (child as Column).children,
                              )
                            : child,
                      ),
                    ),
                    footer,
                  ],
                ),
              ),
            ),
          );
        }
        final margin =
            authored?.additionalSafeAreaPadding ??
            (compact
                ? 12.0
                : breakpoint == ProjectPresentationBreakpoint.expanded
                ? 48.0
                : 24.0);
        final safePadding = MediaQuery.paddingOf(context);
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - margin * 2 - safePadding.horizontal,
        );
        final width = math.min(
          1600.0,
          authored == null
              ? availableWidth
              : availableWidth * authored.maxWidthFactor,
        );
        final frame = PlayerMenuPanel(
          key: const ValueKey('player-menu-frame-panel'),
          primary: true,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              PokeMapPlayerMenuTheme.frameRadius,
            ),
            child: Column(
              children: [
                header,
                Expanded(
                  child: Padding(
                    padding:
                        contentPadding ??
                        EdgeInsets.all(compact ? 12 : PlayerSpacing.lg),
                    child: scrollable && child is Column
                        ? PlayerPagedList(children: (child as Column).children)
                        : child,
                  ),
                ),
                footer,
              ],
            ),
          ),
        );
        return PlayerMenuTransition(
          visible: visible,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: theme.backdrop),
                if (backdrop != null) ExcludeSemantics(child: backdrop!),
                if (!theme.opaque)
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: ColoredBox(
                      color: theme.backdrop.withValues(
                        alpha: theme.backdropOpacity,
                      ),
                    ),
                  )
                else
                  ColoredBox(
                    color: theme.backdrop.withValues(
                      alpha: theme.backdropOpacity,
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(margin),
                    child: Center(
                      child: SizedBox(width: width, child: frame),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerMenuHeader extends StatelessWidget {
  const PlayerMenuHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.secondary,
    this.alignSecondaryEnd = false,
    this.onBack,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget? secondary;
  final bool alignSecondaryEnd;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < projectPresentationCompactWidth;
        final compact =
            narrow ||
            MediaQuery.sizeOf(context).height <
                projectPresentationCompactHeight;
        final shortLandscape =
            PlayerCompanionScope.of(context) ||
            (MediaQuery.sizeOf(context).height < 500 &&
                MediaQuery.sizeOf(context).width >
                    MediaQuery.sizeOf(context).height);
        final titleMeasure = TextPainter(
          text: TextSpan(text: title, style: theme.title),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout(maxWidth: math.max(0, constraints.maxWidth / 2 - 56));
        final stackSecondary =
            !shortLandscape || titleMeasure.didExceedMaxLines;
        final heading = Row(
          children: [
            if (onBack != null)
              PlayerMenuBackButton(onPressed: onBack!)
            else
              Icon(
                icon,
                size: compact ? 24 : 32,
                color: iconColor ?? theme.accent,
              ),
            const SizedBox(width: PlayerSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: compact
                        ? theme.title.copyWith(fontSize: 23, height: 1.15)
                        : theme.title,
                  ),
                  if (onBack != null &&
                      secondary != null &&
                      !alignSecondaryEnd) ...[
                    const SizedBox(height: 3),
                    DefaultTextStyle(
                      style: theme.meta.copyWith(
                        fontSize: 12,
                        height: 1.35,
                        color: theme.secondary,
                      ),
                      child: secondary!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
        return Container(
          width: alignSecondaryEnd ? double.infinity : null,
          constraints: BoxConstraints(minHeight: shortLandscape ? 56 : 64),
          padding: shortLandscape
              ? const EdgeInsets.only(bottom: 8)
              : EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 24,
                  vertical: compact ? 8 : 15.5,
                ),
          decoration: BoxDecoration(
            color: shortLandscape ? null : theme.header,
            border: Border(
              bottom: BorderSide(color: theme.border.withValues(alpha: .22)),
            ),
          ),
          child: onBack != null
              ? Row(
                  children: [
                    Expanded(child: heading),
                    if (alignSecondaryEnd && secondary != null) ...[
                      const SizedBox(width: 12),
                      Flexible(child: secondary!),
                    ],
                  ],
                )
              : stackSecondary &&
                    (narrow || MediaQuery.textScalerOf(context).scale(18) > 27)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (secondary != null) ...[
                      const SizedBox(height: PlayerSpacing.xs),
                      DefaultTextStyle(
                        style: theme.meta.copyWith(color: theme.secondary),
                        child: secondary!,
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: heading),
                    if (secondary != null) ...[
                      const SizedBox(width: PlayerSpacing.lg),
                      Flexible(
                        child: alignSecondaryEnd
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: DefaultTextStyle(
                                  style: theme.meta.copyWith(
                                    color: theme.secondary,
                                  ),
                                  child: secondary!,
                                ),
                              )
                            : DefaultTextStyle(
                                style: theme.meta.copyWith(
                                  color: theme.secondary,
                                ),
                                child: secondary!,
                              ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class PlayerMenuBackButton extends StatelessWidget {
  const PlayerMenuBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return ClipPath(
      clipper: const _PlayerMenuBevelClipper(7),
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed,
        icon: const PlayerMenuIcon(PlayerMenuGlyph.back, size: 20),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          maximumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          foregroundColor: theme.text,
          backgroundColor: theme.recessed,
          side: BorderSide.none,
          shape: const RoundedRectangleBorder(),
        ),
      ),
    );
  }
}

class _PlayerMenuBevelClipper extends CustomClipper<Path> {
  const _PlayerMenuBevelClipper(this.cut);

  final double cut;

  @override
  Path getClip(Size size) {
    final inset = math.min(cut, size.width / 2);
    return Path()
      ..moveTo(inset, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - inset, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_PlayerMenuBevelClipper oldClipper) =>
      oldClipper.cut != cut;
}

class PlayerMenuFooter extends StatelessWidget {
  const PlayerMenuFooter({
    super.key,
    required this.hints,
    this.returnAction,
    this.hintsFlex = 1,
    this.stackActions = false,
    this.alignReturnEnd = false,
    this.actionsBuilder,
    this.padding,
  });
  final EdgeInsetsGeometry? padding;
  final List<Widget> hints;
  final Widget? returnAction;
  final int hintsFlex;
  final bool stackActions;
  final bool alignReturnEnd;
  final Widget Function(BuildContext context, Widget returnAction)?
  actionsBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final companion = PlayerCompanionScope.of(context);
    final landscape = MediaQuery.sizeOf(context).aspectRatio > 1;
    final wide = landscape || companion;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding:
          padding ??
          (wide
              ? EdgeInsets.only(top: 8, bottom: companion ? 12 : 0)
              : const EdgeInsets.fromLTRB(16, 8, 16, 16)),
      decoration: BoxDecoration(color: wide ? null : theme.header),
      foregroundDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.border.withValues(alpha: .22)),
        ),
      ),
      child: returnAction != null && actionsBuilder != null
          ? actionsBuilder!(context, returnAction!)
          : returnAction != null && hints.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 168),
                child: returnAction!,
              ),
            )
          : returnAction == null
          ? Wrap(
              spacing: PlayerSpacing.lg,
              runSpacing: PlayerSpacing.xs,
              children: hints,
            )
          : stackActions
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...hints,
                if (hints.isNotEmpty) const SizedBox(height: 8),
                returnAction!,
              ],
            )
          : Row(
              mainAxisAlignment: alignReturnEnd
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: hintsFlex,
                  child: Wrap(
                    spacing: PlayerSpacing.lg,
                    runSpacing: PlayerSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: hints,
                  ),
                ),
                const SizedBox(width: PlayerSpacing.lg),
                Flexible(
                  flex: 3,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: returnAction!,
                  ),
                ),
              ],
            ),
    );
  }
}

class PlayerMenuActionGroup extends StatelessWidget {
  const PlayerMenuActionGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final compact = constraints.maxWidth < 600 && children.length > 1;
        final minimumWidth = compact
            ? 72 + math.max(0, scale - 1) * 48
            : 132 + math.max(0, scale - 1) * 70;
        var columns = ((constraints.maxWidth + 8) / (minimumWidth + 8))
            .floor()
            .clamp(1, children.length);
        if (children.length == 4 && columns == 3) columns = 2;
        final availableWidth =
            (constraints.maxWidth - (columns - 1) * 8) / columns;
        final width = math.min(availableWidth, (compact ? 112 : 168) * scale);
        return _PlayerMenuActionScope(
          compact: compact,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (
                var start = 0;
                start < children.length;
                start += columns
              ) ...[
                if (start > 0) const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var index = start;
                        index < math.min(start + columns, children.length);
                        index++
                      ) ...[
                        if (index > start) const SizedBox(width: 8),
                        SizedBox(width: width, child: children[index]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlayerMenuActionScope extends InheritedWidget {
  const _PlayerMenuActionScope({required this.compact, required super.child});

  final bool compact;

  @override
  bool updateShouldNotify(_PlayerMenuActionScope oldWidget) =>
      compact != oldWidget.compact;
}

class PlayerMenuKeyHint extends StatelessWidget {
  const PlayerMenuKeyHint({
    super.key,
    required this.glyph,
    required this.label,
    this.compact = false,
  });
  final String glyph;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final symbol = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.recessed,
        borderRadius: BorderRadius.circular(PokeMapPlayerMenuTheme.badgeRadius),
        border: Border.all(color: theme.border),
      ),
      child: Text(glyph, style: theme.meta),
    );
    return Semantics(
      label: '$glyph, $label',
      excludeSemantics: true,
      child: compact
          ? Tooltip(
              message: '$glyph · $label',
              child: Align(alignment: Alignment.centerLeft, child: symbol),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(flex: 2, child: symbol),
                const SizedBox(width: PlayerSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    style: theme.meta.copyWith(color: theme.secondary),
                  ),
                ),
              ],
            ),
    );
  }
}

class PlayerMenuSelectableRow extends StatefulWidget {
  const PlayerMenuSelectableRow({
    super.key,
    required this.id,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.trailingWidth,
    this.subtitle,
    this.supportingContent,
    this.labelMaxLines,
    this.labelStyle,
    this.showDisabledReason = true,
    this.showLabel = true,
    this.reserveFocusMarker = false,
    this.semanticValue,
    this.onFocusChanged,
    this.selected = false,
    this.focused = false,
    this.hovered = false,
    this.pressed = false,
    this.busy = false,
    this.disabledReason,
    this.focusNode,
    this.integrated = false,
    this.tab = false,
    this.button = false,
    this.bevel = 0,
    this.iconOnly = false,
    this.tile = false,
    this.fitTileContent = false,
    this.minimumHeight = 48,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    this.contentGap = 12,
    this.showFocusHighlight = true,
  });

  final String id;
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final double? trailingWidth;
  final String? subtitle;
  final Widget? supportingContent;
  final int? labelMaxLines;
  final TextStyle? labelStyle;
  final bool showDisabledReason;
  final bool showLabel;
  final bool reserveFocusMarker;
  final String? semanticValue;
  final ValueChanged<bool>? onFocusChanged;
  final bool selected;
  final bool focused;
  final bool hovered;
  final bool pressed;
  final bool busy;
  final String? disabledReason;
  final FocusNode? focusNode;
  final bool integrated;
  final bool tab;
  final bool button;
  final double bevel;
  final bool iconOnly;
  final bool tile;
  final bool fitTileContent;
  final double minimumHeight;
  final EdgeInsetsGeometry contentPadding;
  final double contentGap;
  final bool showFocusHighlight;

  @override
  State<PlayerMenuSelectableRow> createState() =>
      _PlayerMenuSelectableRowState();
}

class _PlayerMenuSelectableRowState extends State<PlayerMenuSelectableRow> {
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled =>
      widget.onPressed != null && widget.disabledReason == null && !widget.busy;

  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final actionScope = context
        .dependOnInheritedWidgetOfExactType<_PlayerMenuActionScope>();
    final integrated = widget.integrated || actionScope != null;
    final focused = widget.showFocusHighlight && (widget.focused || _focused);
    final highlighted = widget.selected || focused;
    final hovered = widget.hovered || _hovered;
    final pressed = widget.pressed || _pressed;
    final unselected = pressed && _enabled
        ? Color.alphaBlend(theme.shadow.withValues(alpha: .08), theme.panel)
        : hovered && _enabled
        ? theme.recessed
        : widget.button
        ? theme.recessed
        : theme.panel;
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        colors: highlighted
            ? theme.selectionGradientColors()
            : List.filled(
                2,
                widget.tab || integrated ? theme.base : unselected,
              ),
      ),
      borderRadius: BorderRadius.circular(
        widget.button && widget.bevel == 0
            ? 4
            : PokeMapPlayerMenuTheme.rowRadius,
      ),
      border: widget.button
          ? null
          : widget.tab
          ? Border(
              bottom: BorderSide(
                color: highlighted ? theme.accent : theme.border,
                width: highlighted ? 4 : 2,
              ),
            )
          : highlighted
          ? Border(left: BorderSide(color: theme.accent, width: 4))
          : widget.button
          ? null
          : Border(
              bottom: BorderSide(
                color: theme.border,
                width: integrated ? 0 : 1,
              ),
            ),
    );
    final row = TweenAnimationBuilder<Decoration>(
      tween: DecorationTween(begin: decoration, end: decoration),
      curve: Curves.easeOutCubic,
      duration: pressed
          ? theme.pressDuration
          : hovered
          ? theme.hoverDuration
          : theme.selectionDuration,
      builder: (context, animated, _) {
        final painted = animated as BoxDecoration;
        final gradient = painted.gradient! as LinearGradient;
        final presentation = theme.rowPresentation(
          gradient.colors,
          preferredForeground: highlighted
              ? theme.selectionText
              : !_enabled && !widget.busy
              ? theme.disabled
              : theme.text,
        );
        final foreground = presentation.foreground;
        final secondary = theme
            .rowPresentation(
              presentation.backgrounds,
              preferredForeground: highlighted ? foreground : theme.secondary,
            )
            .foreground;
        final focusColor = theme
            .rowPresentation(
              presentation.backgrounds,
              preferredForeground: highlighted
                  ? theme.selectionText
                  : theme.focus,
            )
            .foreground;
        return Container(
          key: ValueKey('${widget.id}-surface'),
          constraints: BoxConstraints(
            minHeight: actionScope?.compact == true
                ? math.max(48, widget.minimumHeight)
                : widget.minimumHeight,
          ),
          padding: actionScope == null
              ? widget.contentPadding
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          foregroundDecoration: widget.button && highlighted
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: theme.accent, width: 4),
                  ),
                )
              : null,
          decoration: painted.copyWith(
            gradient: LinearGradient(
              begin: gradient.begin,
              end: gradient.end,
              colors:
                  (integrated || widget.tab) &&
                      !highlighted &&
                      !hovered &&
                      !pressed
                  ? List.filled(2, theme.base.withValues(alpha: 0))
                  : presentation.backgrounds,
            ),
          ),
          child: IconTheme(
            data: IconThemeData(color: foreground, size: 24),
            child: DefaultTextStyle(
              style:
                  (actionScope == null
                          ? widget.labelStyle ?? theme.label
                          : theme.actionLabel)
                      .copyWith(color: foreground),
              child: actionScope != null
                  ? _actionContent(actionScope.compact)
                  : widget.tile
                  ? Tooltip(
                      message: widget.disabledReason ?? widget.label,
                      child: widget.fitTileContent
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _tileContent(),
                            )
                          : _tileContent(),
                    )
                  : widget.iconOnly
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(child: widget.leading),
                        if (focused)
                          Positioned(
                            left: 0,
                            child: Container(
                              key: ValueKey('${widget.id}-focus-marker'),
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: focusColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        if (widget.reserveFocusMarker)
                          SizedBox(
                            width: 6,
                            height: 20,
                            child: focused
                                ? DecoratedBox(
                                    key: ValueKey('${widget.id}-focus-marker'),
                                    decoration: BoxDecoration(
                                      color: focusColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )
                                : null,
                          ),
                        if (widget.reserveFocusMarker)
                          const SizedBox(width: PlayerSpacing.sm),
                        if (widget.leading != null) ...[
                          widget.leading!,
                          SizedBox(width: widget.contentGap),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.showLabel && widget.label.isNotEmpty)
                                Text(
                                  widget.label,
                                  maxLines: widget.labelMaxLines,
                                  overflow: widget.labelMaxLines == null
                                      ? null
                                      : TextOverflow.ellipsis,
                                ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: theme.meta.copyWith(color: secondary),
                                ),
                              if (widget.supportingContent != null)
                                widget.supportingContent!,
                              if (widget.showDisabledReason &&
                                  widget.disabledReason != null)
                                Text(
                                  widget.disabledReason!,
                                  style: theme.meta.copyWith(color: foreground),
                                ),
                            ],
                          ),
                        ),
                        if (widget.busy) ...[
                          const SizedBox(width: PlayerSpacing.sm),
                          Icon(Icons.hourglass_top_rounded, color: foreground),
                        ] else if (widget.trailing != null) ...[
                          SizedBox(width: widget.contentGap),
                          if (widget.trailingWidth case final width?)
                            SizedBox(width: width, child: widget.trailing!)
                          else
                            Flexible(child: widget.trailing!),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
    return Semantics(
      identifier: widget.id,
      label: widget.label,
      value: [
        if (widget.semanticValue != null) widget.semanticValue!,
        if (widget.subtitle != null) widget.subtitle!,
        if (widget.busy) 'Chargement',
      ].join(', '),
      hint: widget.disabledReason,
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      focusable: true,
      focused: focused,
      onTap: _enabled ? _activate : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        onFocusChange: (value) {
          setState(() => _focused = value);
          widget.onFocusChanged?.call(value);
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
              ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter):
              DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
              ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space):
              DoNothingAndStopPropagationIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _activate : null,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: pressed && _enabled && !theme.reducedMotion ? .985 : 1,
            duration: theme.pressDuration,
            curve: Curves.easeOutCubic,
            child: widget.bevel > 0
                ? ClipPath(
                    clipper: _PlayerMenuBevelClipper(widget.bevel),
                    child: row,
                  )
                : row,
          ),
        ),
      ),
    );
  }

  Widget _tileContent() => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (widget.leading != null) ...[
        widget.leading!,
        const SizedBox(height: 6),
      ],
      Text(widget.label, textAlign: TextAlign.center),
    ],
  );

  Widget _actionContent(bool compact) {
    final icon = widget.busy
        ? const Icon(Icons.hourglass_top_rounded)
        : widget.leading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconTheme.merge(data: const IconThemeData(size: 18), child: icon),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(widget.label, textAlign: TextAlign.center)),
      ],
    );
  }
}

class PlayerMenuPortrait extends StatelessWidget {
  const PlayerMenuPortrait({
    super.key,
    required this.child,
    this.circular = false,
    this.size = 64,
    this.semanticLabel,
  });
  final Widget child;
  final bool circular;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final viewport = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.recessed,
        border: Border.all(color: theme.border.withValues(alpha: .7)),
        borderRadius: circular
            ? null
            : BorderRadius.circular(PokeMapPlayerMenuTheme.badgeRadius),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: FittedBox(fit: BoxFit.contain, child: child),
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: circular ? ClipOval(child: viewport) : viewport,
    );
  }
}

enum PlayerMenuGaugeKind { health, experience }

enum PlayerMenuGaugeTone { normal, warning, danger }

class PlayerMenuGauge extends StatelessWidget {
  const PlayerMenuGauge({
    super.key,
    required this.value,
    required this.maximum,
    required this.label,
    this.status,
    this.showLabel = true,
    this.kind = PlayerMenuGaugeKind.health,
    this.tone = PlayerMenuGaugeTone.normal,
  });
  final double value;
  final double maximum;
  final String label;
  final String? status;
  final bool showLabel;
  final PlayerMenuGaugeKind kind;
  final PlayerMenuGaugeTone tone;

  double get fraction => value.isFinite && maximum.isFinite && maximum > 0
      ? (value / maximum).clamp(0.0, 1.0)
      : 0;
  String _number(double number) =>
      number.isFinite && number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toString();

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final color = switch (tone) {
      PlayerMenuGaugeTone.warning => theme.warning,
      PlayerMenuGaugeTone.danger => theme.danger,
      PlayerMenuGaugeTone.normal =>
        kind == PlayerMenuGaugeKind.health ? theme.health : theme.accent,
    };
    final amount = '${_number(value)} / ${_number(maximum)}';
    return Semantics(
      label: label,
      value: [amount, if (status != null) status!].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLabel)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(label, style: theme.meta.copyWith(color: theme.secondary)),
                Text(amount, style: theme.numbers, textAlign: TextAlign.right),
              ],
            ),
          if (showLabel) const SizedBox(height: 4),
          Container(
            height: kind == PlayerMenuGaugeKind.health ? 10 : 8,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.recessed,
              borderRadius: BorderRadius.circular(
                kind == PlayerMenuGaugeKind.health ? 5 : 4,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: ColoredBox(color: color),
              ),
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 4),
            Text(status!, style: theme.meta.copyWith(color: theme.secondary)),
          ],
        ],
      ),
    );
  }
}

enum PlayerMenuBadgeKind { neutral, type, status }

class PlayerMenuBadge extends StatelessWidget {
  const PlayerMenuBadge({
    super.key,
    required this.label,
    this.kind = PlayerMenuBadgeKind.neutral,
  });
  final String label;
  final PlayerMenuBadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final color = switch (kind) {
      PlayerMenuBadgeKind.neutral => theme.secondary,
      PlayerMenuBadgeKind.type => theme.accent,
      PlayerMenuBadgeKind.status => theme.warning,
    };
    return Semantics(
      label: switch (kind) {
        PlayerMenuBadgeKind.neutral => label,
        PlayerMenuBadgeKind.type => 'Type : $label',
        PlayerMenuBadgeKind.status => 'Statut : $label',
      },
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.recessed,
          border: Border.all(color: color.withValues(alpha: .7)),
          borderRadius: BorderRadius.circular(
            PokeMapPlayerMenuTheme.badgeRadius,
          ),
        ),
        child: Text(label, style: theme.meta.copyWith(color: color)),
      ),
    );
  }
}

enum PlayerMenuFeedbackKind { empty, error, receipt }

class PlayerMenuFeedback extends StatelessWidget {
  const PlayerMenuFeedback({
    super.key,
    required this.id,
    required this.title,
    this.message,
    this.kind = PlayerMenuFeedbackKind.empty,
    this.action,
  });
  final String id;
  final String title;
  final String? message;
  final PlayerMenuFeedbackKind kind;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            identifier: id,
            container: true,
            liveRegion: kind != PlayerMenuFeedbackKind.empty,
            label: [title, if (message != null) message!].join('. '),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (kind) {
                    PlayerMenuFeedbackKind.empty => Icons.inbox_outlined,
                    PlayerMenuFeedbackKind.error => Icons.error_outline,
                    PlayerMenuFeedbackKind.receipt =>
                      Icons.check_circle_outline,
                  },
                  color: switch (kind) {
                    PlayerMenuFeedbackKind.empty => theme.secondary,
                    PlayerMenuFeedbackKind.error => theme.danger,
                    PlayerMenuFeedbackKind.receipt => theme.health,
                  },
                ),
                const SizedBox(width: PlayerSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.subtitle),
                      if (message != null) ...[
                        const SizedBox(height: PlayerSpacing.xs),
                        Text(
                          message!,
                          style: theme.body.copyWith(color: theme.secondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: PlayerSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class PlayerMenuTransition extends StatefulWidget {
  const PlayerMenuTransition({
    super.key,
    required this.child,
    this.visible = true,
  });
  final Widget child;
  final bool visible;

  @override
  State<PlayerMenuTransition> createState() => _PlayerMenuTransitionState();
}

class _PlayerMenuTransitionState extends State<PlayerMenuTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = context.playerMenuTheme;
    _controller.duration = theme.openDuration;
    _controller.reverseDuration = theme.closeDuration;
    _updateTarget();
  }

  @override
  void didUpdateWidget(PlayerMenuTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _updateTarget();
  }

  void _updateTarget() {
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return ExcludeFocus(
      excluding: !widget.visible,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: ExcludeSemantics(
          excluding: !widget.visible,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: Curves.easeOutCubic.transform(_controller.value),
              child: Transform.translate(
                key: const ValueKey('player-menu-opening-transform'),
                offset: Offset(
                  0,
                  (1 - Curves.easeOutCubic.transform(_controller.value)) *
                      theme.openTranslation,
                ),
                child: child,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class PlayerMenuDetailTransition extends StatelessWidget {
  const PlayerMenuDetailTransition({
    super.key,
    required this.contentKey,
    required this.child,
  });
  final Key contentKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: context.playerMenuTheme.detailDuration,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          key: const ValueKey('player-menu-detail-transform'),
          offset: Offset(
            (1 - animation.value) * context.playerMenuTheme.openTranslation,
            0,
          ),
          child: child,
        ),
        child: child,
      ),
    ),
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: Alignment.center,
      children: [
        for (final previous in previousChildren)
          _entry(previous, active: false),
        if (currentChild != null) _entry(currentChild, active: true),
      ],
    ),
    child: KeyedSubtree(key: contentKey, child: child),
  );
  Widget _entry(Widget child, {required bool active}) => ExcludeFocus(
    key: child.key,
    excluding: !active,
    child: IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(excluding: !active, child: child),
    ),
  );
}
