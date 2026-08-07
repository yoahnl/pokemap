import 'package:flutter/material.dart';

import '../foundation/avelune_shape_tokens.dart';
import '../theme/avelune_theme_extensions.dart';

class AvelunePressable extends StatefulWidget {
  const AvelunePressable({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.selectedOutline = true,
    this.invalid = false,
    this.autofocus = false,
    this.borderRadius = AveluneShapes.md,
    this.pressedScale = 0.97,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final bool enabled;
  final bool selected;
  final bool selectedOutline;
  final bool invalid;
  final bool autofocus;
  final BorderRadius borderRadius;
  final double pressedScale;

  @override
  State<AvelunePressable> createState() => _AvelunePressableState();
}

class _AvelunePressableState extends State<AvelunePressable> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final motion = context.aveluneMotion;
    final borderColor = widget.invalid
        ? colors.error
        : _focused || widget.selected && widget.selectedOutline
            ? colors.focus
            : colors.outline.withValues(alpha: 0);

    return Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onPressed : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? widget.pressedScale : 1,
        duration: motion.press,
        curve: motion.pressCurve,
        child: AnimatedContainer(
          duration: motion.selection,
          curve: motion.movementCurve,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: borderColor,
              width: AveluneShapes.focusStroke,
            ),
          ),
          // No Material, no ink. A splash spreading across a rectangle is the
          // single most Material-looking thing in a UI; the press reads through
          // the scale and, on a glass surface, through the lens deforming under
          // the finger.
          child: Focus(
            autofocus: widget.autofocus,
            canRequestFocus: widget.enabled,
            onFocusChange: (value) => setState(() => _focused = value),
            child: GestureDetector(
              // The wrapping Semantics node already declares the button, its
              // label and its actions; without this the detector publishes a
              // second tap action and a disabled control still looks tappable.
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              onTap: widget.enabled ? widget.onPressed : null,
              onLongPress: widget.enabled ? widget.onLongPress : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
