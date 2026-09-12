import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/pokemap_player_overworld_theme.dart';

class PlayerOverworldMenuButton extends StatelessWidget {
  const PlayerOverworldMenuButton(
      {super.key,
      required this.label,
      this.icon = Icons.menu_rounded,
      this.onPressed,
      this.visible = true,
      this.enabled = true,
      this.pressed = false,
      this.focused = false,
      this.focusNode,
      this.autofocus = false});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool visible;
  final bool enabled;
  final bool pressed;
  final bool focused;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => !visible
      ? const SizedBox.shrink()
      : _OverworldButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
          enabled: enabled,
          pressed: pressed,
          focused: focused,
          focusNode: focusNode,
          autofocus: autofocus,
          menu: true);
}

class PlayerOverworldActionCapsule extends StatelessWidget {
  const PlayerOverworldActionCapsule(
      {super.key,
      required this.label,
      required this.icon,
      this.glyph,
      this.onPressed,
      this.visible = true,
      this.enabled = true,
      this.pressed = false,
      this.focused = false,
      this.focusNode,
      this.autofocus = false});

  final String label;
  final IconData icon;
  final String? glyph;
  final VoidCallback? onPressed;
  final bool visible;
  final bool enabled;
  final bool pressed;
  final bool focused;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => !visible
      ? const SizedBox.shrink()
      : _OverworldButton(
          label: label,
          icon: icon,
          glyph: glyph,
          onPressed: onPressed,
          enabled: enabled,
          pressed: pressed,
          focused: focused,
          focusNode: focusNode,
          autofocus: autofocus,
          menu: false);
}

class _OverworldButton extends StatefulWidget {
  const _OverworldButton(
      {required this.label,
      required this.icon,
      required this.onPressed,
      required this.enabled,
      required this.pressed,
      required this.focused,
      required this.focusNode,
      required this.autofocus,
      required this.menu,
      this.glyph});
  final String label;
  final IconData icon;
  final String? glyph;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool pressed;
  final bool focused;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool menu;

  @override
  State<_OverworldButton> createState() => _OverworldButtonState();
}

class _OverworldButtonState extends State<_OverworldButton> {
  bool _pointerPressed = false;
  bool _focused = false;
  LogicalKeyboardKey? _activationKey;
  bool get _enabled => widget.enabled && widget.onPressed != null;

  @override
  void didUpdateWidget(_OverworldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _pointerPressed = false;
      _activationKey = null;
    }
  }

  void _activate() {
    if (_enabled) widget.onPressed?.call();
  }

  KeyEventResult _keyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (!_enabled ||
        (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.space)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && !event.synthesized && _activationKey == null) {
      setState(() => _activationKey = key);
      _activate();
    } else if (event is KeyUpEvent && _activationKey == key) {
      setState(() => _activationKey = null);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.playerOverworldTheme;
    final pressed = _enabled &&
        (widget.pressed || _pointerPressed || _activationKey != null);
    final focused = _enabled && (widget.focused || _focused);
    final foreground = _enabled ? tokens.text : tokens.disabled;
    final content = widget.menu
        ? SizedBox.square(
            dimension: PokeMapPlayerOverworldTheme.menuSize,
            child: Icon(widget.icon,
                size: PokeMapPlayerOverworldTheme.iconSize, color: foreground))
        : LayoutBuilder(builder: (context, constraints) {
            final label = Text(widget.label,
                style: tokens.label.copyWith(color: foreground),
                softWrap: true);
            final action = Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon,
                  size: PokeMapPlayerOverworldTheme.iconSize,
                  color: foreground),
              const SizedBox(width: PokeMapPlayerOverworldTheme.contentGap),
              Flexible(child: label),
            ]);
            final glyph = widget.glyph;
            Widget content = action;
            if (glyph != null) {
              final keycap = DecoratedBox(
                decoration:
                    tokens.surfaceDecoration(enabled: _enabled, glyph: true),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: PokeMapPlayerOverworldTheme.glyphSize,
                    minHeight: PokeMapPlayerOverworldTheme.glyphSize,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        PokeMapPlayerOverworldTheme.glyphInset),
                    child: Text(glyph,
                        textAlign: TextAlign.center,
                        style: tokens.glyphLabel.copyWith(color: foreground)),
                  ),
                ),
              );
              final available = constraints.maxWidth -
                  PokeMapPlayerOverworldTheme.compactInset * 2;
              final inlineWidth =
                  _textWidth(context, widget.label, tokens.label) +
                      math.max(
                          PokeMapPlayerOverworldTheme.glyphSize,
                          _textWidth(context, glyph, tokens.glyphLabel) +
                              PokeMapPlayerOverworldTheme.glyphInset * 2) +
                      PokeMapPlayerOverworldTheme.iconSize +
                      PokeMapPlayerOverworldTheme.contentGap * 2;
              content = inlineWidth <= available
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(child: action),
                      const SizedBox(
                          width: PokeMapPlayerOverworldTheme.contentGap),
                      keycap,
                    ])
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                          action,
                          const SizedBox(
                              height: PokeMapPlayerOverworldTheme.contentGap),
                          keycap,
                        ]);
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(
                  minHeight: PokeMapPlayerOverworldTheme.minimumTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: PokeMapPlayerOverworldTheme.compactInset,
                    vertical: PokeMapPlayerOverworldTheme.contentGap),
                child: content,
              ),
            );
          });
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus && _enabled,
      canRequestFocus: _enabled,
      skipTraversal: !_enabled,
      onFocusChange: (focused) {
        if (mounted) {
          setState(() {
            _focused = focused;
            if (!focused) _activationKey = null;
          });
        }
      },
      onKeyEvent: _keyEvent,
      child: Semantics(
          button: true,
          enabled: _enabled,
          label: widget.label,
          hint: widget.glyph,
          onTap: _enabled ? _activate : null,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enabled ? _activate : null,
            onTapDown:
                _enabled ? (_) => setState(() => _pointerPressed = true) : null,
            onTapUp: _enabled
                ? (_) => setState(() => _pointerPressed = false)
                : null,
            onTapCancel:
                _enabled ? () => setState(() => _pointerPressed = false) : null,
            child: _OverworldAppearance(
                child: AnimatedScale(
                    scale:
                        pressed ? PokeMapPlayerOverworldTheme.pressedScale : 1,
                    duration: tokens.pressDuration,
                    child: DecoratedBox(
                        decoration: tokens.surfaceDecoration(
                            focused: focused,
                            pressed: pressed,
                            enabled: _enabled,
                            circular: widget.menu),
                        child: content))),
          )),
    );
  }

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _OverworldAppearance extends StatelessWidget {
  const _OverworldAppearance({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.playerOverworldTheme;
    if (tokens.reducedMotion) return child;
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: tokens.appearanceDuration,
        child: child,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child));
  }
}

class PlayerOverworldControlsLayout extends StatelessWidget {
  const PlayerOverworldControlsLayout(
      {super.key,
      required this.menuButton,
      this.actionCapsule,
      this.joystick,
      this.visible = true});
  final Widget menuButton;
  final Widget? actionCapsule;
  final Widget? joystick;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final inset =
          constraints.maxWidth >= PokeMapPlayerOverworldTheme.wideBreakpoint
              ? PokeMapPlayerOverworldTheme.wideInset
              : PokeMapPlayerOverworldTheme.compactInset;
      final fontSize = context.playerOverworldTheme.label.fontSize!;
      final textScale =
          MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
      final maxWidth = PokeMapPlayerOverworldTheme.capsuleMaxWidth +
          (constraints.maxWidth - PokeMapPlayerOverworldTheme.capsuleMaxWidth) *
              (textScale - 1).clamp(0.0, 1.0);
      return Stack(fit: StackFit.expand, children: [
        if (joystick != null) joystick!,
        SafeArea(
            child: Padding(
                padding: EdgeInsets.all(inset),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (actionCapsule != null) ...[
                                actionCapsule!,
                                const SizedBox(
                                    height:
                                        PokeMapPlayerOverworldTheme.actionGap)
                              ],
                              menuButton,
                            ]))))),
      ]);
    });
  }
}

class PlayerOverworldJoystickVisual extends StatelessWidget {
  const PlayerOverworldJoystickVisual(
      {super.key,
      required this.anchor,
      this.displacement = Offset.zero,
      this.running = false,
      this.visible = true,
      this.enabled = true});
  final Offset anchor;
  final Offset displacement;
  final bool running;
  final bool visible;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final tokens = context.playerOverworldTheme;
    const size = PokeMapPlayerOverworldTheme.joystickSize;
    const knobSize = PokeMapPlayerOverworldTheme.joystickKnobSize;
    final normalized = displacement.distance > 1
        ? displacement / displacement.distance
        : displacement;
    final offset = normalized * PokeMapPlayerOverworldTheme.joystickTravel;
    return Positioned(
        left: anchor.dx - size / 2,
        top: anchor.dy - size / 2,
        width: size,
        height: size,
        child: IgnorePointer(
            child: ExcludeSemantics(
                child: _OverworldAppearance(
                    child: Stack(children: [
          Positioned.fill(
              child: DecoratedBox(
                  key: const ValueKey('player-overworld-joystick-base'),
                  decoration: tokens.surfaceDecoration(
                      enabled: enabled, circular: true))),
          if (running)
            Positioned.fill(
                child: CustomPaint(painter: _RunningArcPainter(tokens))),
          Positioned(
              left: (size - knobSize) / 2 + offset.dx,
              top: (size - knobSize) / 2 + offset.dy,
              width: knobSize,
              height: knobSize,
              child: DecoratedBox(
                  key: const ValueKey('player-overworld-joystick-knob'),
                  decoration: tokens.surfaceDecoration(
                      enabled: enabled, knob: true, circular: true))),
        ])))));
  }
}

class _RunningArcPainter extends CustomPainter {
  const _RunningArcPainter(this.tokens);
  final PokeMapPlayerOverworldTheme tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
        (Offset.zero & size).deflate(PokeMapPlayerOverworldTheme.runningInset),
        -math.pi / 2,
        math.pi / 2,
        false,
        Paint()
          ..color = tokens.accent
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = PokeMapPlayerOverworldTheme.runningWidth);
  }

  @override
  bool shouldRepaint(_RunningArcPainter oldDelegate) =>
      oldDelegate.tokens.accent != tokens.accent;
}
