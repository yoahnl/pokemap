import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../theme/pokemap_player_layout_theme.dart';
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
  });

  final Widget header;
  final Widget child;
  final Widget footer;
  final Widget? backdrop;
  final bool scrollable;
  final bool visible;
  final ProjectPresentationSurfaceRole role;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return LayoutBuilder(builder: (context, constraints) {
      final breakpoint = const ProjectPresentationLayoutResolver().classify(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      );
      final compact = breakpoint == ProjectPresentationBreakpoint.compact;
      final authored = context.playerLayoutTheme?.tryResolve(role, constraints);
      final margin = authored?.additionalSafeAreaPadding ??
          (compact
              ? 12.0
              : breakpoint == ProjectPresentationBreakpoint.expanded
                  ? 48.0
                  : 24.0);
      final safePadding = MediaQuery.paddingOf(context);
      final availableWidth = math.max(
          0.0, constraints.maxWidth - margin * 2 - safePadding.horizontal);
      final availableHeight = math.max(
          0.0, constraints.maxHeight - margin * 2 - safePadding.vertical);
      final headerBudget =
          math.max(0.0, availableHeight - 48 - availableHeight * .3);
      final width = math.min(
          1600.0,
          authored == null
              ? availableWidth
              : availableWidth * authored.maxWidthFactor);
      final frame = PlayerMenuPanel(
        primary: true,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(PokeMapPlayerMenuTheme.frameRadius),
          child: Column(children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: headerBudget),
              child: SingleChildScrollView(child: header),
            ),
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: EdgeInsets.all(
                          compact ? PlayerSpacing.sm : PlayerSpacing.lg),
                      child: child,
                    )
                  : Padding(
                      padding: EdgeInsets.all(
                          compact ? PlayerSpacing.sm : PlayerSpacing.lg),
                      child: child,
                    ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: availableHeight * .3),
              child: SingleChildScrollView(child: footer),
            ),
          ]),
        ),
      );
      return PlayerMenuTransition(
          visible: visible,
          child: ClipRect(
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: theme.backdrop),
              if (backdrop != null) ExcludeSemantics(child: backdrop!),
              if (!theme.opaque)
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColoredBox(
                      color: theme.backdrop
                          .withValues(alpha: theme.backdropOpacity)),
                )
              else
                ColoredBox(
                    color: theme.backdrop
                        .withValues(alpha: theme.backdropOpacity)),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(margin),
                  child: Center(child: SizedBox(width: width, child: frame)),
                ),
              ),
            ]),
          ));
    });
  }
}

class PlayerMenuHeader extends StatelessWidget {
  const PlayerMenuHeader(
      {super.key, required this.icon, required this.title, this.secondary});

  final IconData icon;
  final String title;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < projectPresentationCompactWidth;
      final compact = narrow ||
          MediaQuery.sizeOf(context).height < projectPresentationCompactHeight;
      final heading = narrow && MediaQuery.textScalerOf(context).scale(18) > 27
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 32, color: theme.accent),
              const SizedBox(height: PlayerSpacing.xs),
              Text(title, style: theme.title),
            ])
          : Row(children: [
              Icon(icon, size: 32, color: theme.accent),
              const SizedBox(width: PlayerSpacing.sm),
              Expanded(child: Text(title, style: theme.title)),
            ]);
      return Container(
        constraints: BoxConstraints(minHeight: compact ? 44 : 64),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 24, vertical: compact ? 4 : 16),
        decoration: BoxDecoration(
          color: theme.header.withValues(alpha: theme.panelOpacity),
          border: Border(
              bottom: BorderSide(color: theme.border.withValues(alpha: .22))),
        ),
        child: narrow || MediaQuery.textScalerOf(context).scale(18) > 27
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                heading,
                if (secondary != null) ...[
                  const SizedBox(height: PlayerSpacing.xs),
                  DefaultTextStyle(
                      style: theme.meta.copyWith(color: theme.secondary),
                      child: secondary!),
                ],
              ])
            : Row(children: [
                Expanded(child: heading),
                if (secondary != null) ...[
                  const SizedBox(width: PlayerSpacing.lg),
                  Flexible(
                      child: DefaultTextStyle(
                          style: theme.meta.copyWith(color: theme.secondary),
                          child: secondary!)),
                ],
              ]),
      );
    });
  }
}

class PlayerMenuFooter extends StatelessWidget {
  const PlayerMenuFooter({super.key, required this.hints, this.returnAction});
  final List<Widget> hints;
  final Widget? returnAction;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: returnAction == null ? 8 : 0),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: theme.border.withValues(alpha: .22)))),
      child: returnAction == null
          ? Wrap(
              spacing: PlayerSpacing.lg,
              runSpacing: PlayerSpacing.xs,
              children: hints,
            )
          : Row(children: [
              Expanded(
                  child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (var index = 0; index < hints.length; index++) ...[
                    if (index > 0) const SizedBox(width: PlayerSpacing.lg),
                    hints[index],
                  ]
                ]),
              )),
              const SizedBox(width: PlayerSpacing.lg),
              Flexible(flex: 3, child: returnAction!),
            ]),
    );
  }
}

class PlayerMenuKeyHint extends StatelessWidget {
  const PlayerMenuKeyHint(
      {super.key, required this.glyph, required this.label});
  final String glyph;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return Semantics(
      label: '$glyph, $label',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.recessed,
            borderRadius:
                BorderRadius.circular(PokeMapPlayerMenuTheme.badgeRadius),
            border: Border.all(color: theme.border),
          ),
          child: Text(glyph, style: theme.meta),
        ),
        const SizedBox(width: PlayerSpacing.xs),
        Flexible(
            child: Text(label,
                style: theme.meta.copyWith(color: theme.secondary))),
      ]),
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
    this.subtitle,
    this.selected = false,
    this.focused = false,
    this.hovered = false,
    this.pressed = false,
    this.busy = false,
    this.disabledReason,
    this.focusNode,
  });

  final String id;
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final String? subtitle;
  final bool selected;
  final bool focused;
  final bool hovered;
  final bool pressed;
  final bool busy;
  final String? disabledReason;
  final FocusNode? focusNode;

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
    final focused = widget.focused || _focused;
    final hovered = widget.hovered || _hovered;
    final pressed = widget.pressed || _pressed;
    final unselected = pressed && _enabled
        ? Color.alphaBlend(theme.shadow.withValues(alpha: .24), theme.recessed)
        : hovered && _enabled
            ? theme.accent.withValues(alpha: .09)
            : theme.recessed.withValues(alpha: .4);
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: widget.selected
            ? theme.selectionGradientColors(
                shade: pressed && _enabled
                    ? .10
                    : hovered && _enabled
                        ? .04
                        : 0)
            : List.filled(
                2,
                Color.alphaBlend(
                    unselected, theme.opaque ? theme.base : theme.panel)),
      ),
      borderRadius: BorderRadius.circular(PokeMapPlayerMenuTheme.rowRadius),
      border: Border.all(
        width: 1.5,
        color: focused || widget.selected
            ? theme.focus
            : theme.border.withValues(alpha: hovered ? .7 : .22),
      ),
      boxShadow: widget.selected && !theme.opaque
          ? [
              BoxShadow(
                  color: theme.accent.withValues(alpha: .28), blurRadius: 14)
            ]
          : null,
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
        final presentation = theme.rowPresentation(gradient.colors,
            preferredForeground: widget.selected
                ? theme.selectionText
                : !_enabled && !widget.busy
                    ? theme.disabled
                    : theme.text);
        final foreground = presentation.foreground;
        final secondary = theme
            .rowPresentation(presentation.backgrounds,
                preferredForeground:
                    widget.selected ? foreground : theme.secondary)
            .foreground;
        final focusColor = theme
            .rowPresentation(presentation.backgrounds,
                preferredForeground:
                    widget.selected ? theme.selectionText : theme.focus)
            .foreground;
        return Container(
          key: ValueKey('${widget.id}-surface'),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: painted.copyWith(
              gradient: LinearGradient(
            begin: gradient.begin,
            end: gradient.end,
            colors: presentation.backgrounds,
          )),
          child: IconTheme(
            data: IconThemeData(color: foreground, size: 24),
            child: DefaultTextStyle(
              style: theme.label.copyWith(color: foreground),
              child: Row(children: [
                SizedBox(
                  width: 6,
                  height: 20,
                  child: focused
                      ? DecoratedBox(
                          key: ValueKey('${widget.id}-focus-marker'),
                          decoration: BoxDecoration(
                              color: focusColor,
                              borderRadius: BorderRadius.circular(3)),
                        )
                      : null,
                ),
                const SizedBox(width: PlayerSpacing.sm),
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: PlayerSpacing.sm)
                ],
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.label),
                      if (widget.subtitle != null)
                        Text(widget.subtitle!,
                            style: theme.meta.copyWith(color: secondary)),
                      if (widget.disabledReason != null)
                        Text(widget.disabledReason!,
                            style: theme.meta.copyWith(color: foreground)),
                    ])),
                if (widget.busy) ...[
                  const SizedBox(width: PlayerSpacing.sm),
                  Icon(Icons.hourglass_top_rounded, color: foreground),
                ] else if (widget.trailing != null) ...[
                  const SizedBox(width: PlayerSpacing.sm),
                  Flexible(child: widget.trailing!),
                ],
              ]),
            ),
          ),
        );
      },
    );
    return Semantics(
      identifier: widget.id,
      label: widget.label,
      value: [
        if (widget.subtitle != null) widget.subtitle!,
        if (widget.busy) 'Chargement'
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
        focusNode: widget.focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        mouseCursor:
            _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _activate();
            return null;
          }),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _activate : null,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: row,
        ),
      ),
    );
  }
}

class PlayerMenuPortrait extends StatelessWidget {
  const PlayerMenuPortrait(
      {super.key,
      required this.child,
      this.circular = false,
      this.semanticLabel});
  final Widget child;
  final bool circular;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final viewport = Container(
      width: 64,
      height: 64,
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
        child: circular ? ClipOval(child: viewport) : viewport);
  }
}

enum PlayerMenuGaugeKind { health, experience }

enum PlayerMenuGaugeTone { normal, warning, danger }

class PlayerMenuGauge extends StatelessWidget {
  const PlayerMenuGauge(
      {super.key,
      required this.value,
      required this.maximum,
      required this.label,
      this.status,
      this.kind = PlayerMenuGaugeKind.health,
      this.tone = PlayerMenuGaugeTone.normal});
  final double value;
  final double maximum;
  final String label;
  final String? status;
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(label, style: theme.meta.copyWith(color: theme.secondary)),
              Text(amount, style: theme.numbers, textAlign: TextAlign.right),
            ]),
        const SizedBox(height: 4),
        Container(
          height: kind == PlayerMenuGaugeKind.health ? 10 : 8,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              color: theme.recessed,
              borderRadius: BorderRadius.circular(
                  kind == PlayerMenuGaugeKind.health ? 5 : 4)),
          child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                  widthFactor: fraction,
                  heightFactor: 1,
                  child: ColoredBox(color: color))),
        ),
        if (status != null) ...[
          const SizedBox(height: 4),
          Text(status!, style: theme.meta.copyWith(color: theme.secondary))
        ],
      ]),
    );
  }
}

enum PlayerMenuBadgeKind { neutral, type, status }

class PlayerMenuBadge extends StatelessWidget {
  const PlayerMenuBadge(
      {super.key,
      required this.label,
      this.kind = PlayerMenuBadgeKind.neutral});
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
            borderRadius:
                BorderRadius.circular(PokeMapPlayerMenuTheme.badgeRadius)),
        child: Text(label, style: theme.meta.copyWith(color: color)),
      ),
    );
  }
}

enum PlayerMenuFeedbackKind { empty, error, receipt }

class PlayerMenuFeedback extends StatelessWidget {
  const PlayerMenuFeedback(
      {super.key,
      required this.id,
      required this.title,
      this.message,
      this.kind = PlayerMenuFeedbackKind.empty,
      this.action});
  final String id;
  final String title;
  final String? message;
  final PlayerMenuFeedbackKind kind;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          identifier: id,
          container: true,
          liveRegion: kind != PlayerMenuFeedbackKind.empty,
          label: [title, if (message != null) message!].join('. '),
          excludeSemantics: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
                switch (kind) {
                  PlayerMenuFeedbackKind.empty => Icons.inbox_outlined,
                  PlayerMenuFeedbackKind.error => Icons.error_outline,
                  PlayerMenuFeedbackKind.receipt => Icons.check_circle_outline,
                },
                color: switch (kind) {
                  PlayerMenuFeedbackKind.empty => theme.secondary,
                  PlayerMenuFeedbackKind.error => theme.danger,
                  PlayerMenuFeedbackKind.receipt => theme.health,
                }),
            const SizedBox(width: PlayerSpacing.sm),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: theme.subtitle),
                  if (message != null) ...[
                    const SizedBox(height: PlayerSpacing.xs),
                    Text(message!,
                        style: theme.body.copyWith(color: theme.secondary))
                  ],
                ])),
          ]),
        ),
        if (action != null) ...[
          const SizedBox(height: PlayerSpacing.md),
          action!
        ],
      ]),
    );
  }
}

class PlayerMenuTransition extends StatefulWidget {
  const PlayerMenuTransition(
      {super.key, required this.child, this.visible = true});
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
                    offset: Offset(
                        0,
                        (1 - Curves.easeOutCubic.transform(_controller.value)) *
                            theme.openTranslation),
                    child: child),
              ),
              child: widget.child,
            ),
          ),
        ));
  }
}

class PlayerMenuDetailTransition extends StatelessWidget {
  const PlayerMenuDetailTransition(
      {super.key, required this.contentKey, required this.child});
  final Key contentKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: context.playerMenuTheme.detailDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
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
