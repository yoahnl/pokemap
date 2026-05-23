import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Available variants for PokeMap icon buttons.
enum PokeMapIconButtonVariant {
  /// Flat icon button that shows a subtle background on hover.
  ghost,

  /// Elevated icon button with a solid background and borders.
  soft,

  /// Action button that indicates high alert or delete options.
  danger,
}

/// A compact PokeMap action icon button.
///
/// Wraps an icon widget, supporting tooltips, active selections,
/// hover/focus indicators, and disabled states.
class PokeMapIconButton extends StatefulWidget {
  const PokeMapIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.variant = PokeMapIconButtonVariant.ghost,
    this.isSelected = false,
  });

  /// Action callback. If null, renders in a disabled state.
  final VoidCallback? onPressed;

  /// The icon widget inside the button (usually an Icon).
  final Widget icon;

  /// Optional tooltip message.
  final String? tooltip;

  /// Layout and color palette styling.
  final PokeMapIconButtonVariant variant;

  /// If true, applies active selection styling cues.
  final bool isSelected;

  @override
  State<PokeMapIconButton> createState() => _PokeMapIconButtonState();
}

class _PokeMapIconButtonState extends State<PokeMapIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDisabled = widget.onPressed == null;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case PokeMapIconButtonVariant.ghost:
        bg = widget.isSelected
            ? colors.surfaceSelected
            : (_isHovered ? colors.surfaceHover : Colors.transparent);
        fg = widget.isSelected ? colors.brandPrimary : colors.textSecondary;
        break;
      case PokeMapIconButtonVariant.soft:
        if (widget.isSelected) {
          bg = colors.surfaceSelected;
          border = Border.all(color: colors.brandPrimaryBorder, width: 1);
          fg = colors.brandPrimary;
        } else {
          bg = _isHovered ? colors.surfaceHover : colors.surfaceSubtle;
          border = Border.all(color: colors.borderSubtle, width: 1);
          fg = colors.textPrimary;
        }
        break;
      case PokeMapIconButtonVariant.danger:
        bg = _isHovered ? colors.errorSoft : Colors.transparent;
        fg = colors.error;
        break;
    }

    if (isDisabled) {
      bg = Colors.transparent;
      fg = fg.withValues(alpha: 0.35);
      if (border != null) {
        border = Border.all(color: colors.borderSubtle.withValues(alpha: 0.3), width: 1);
      }
    }

    Widget content = Semantics(
      button: true,
      enabled: !isDisabled,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (!isDisabled) {
                widget.onPressed?.call();
              }
              return null;
            },
          ),
        },
        onShowHoverHighlight: (val) {
          if (!isDisabled) setState(() => _isHovered = val);
        },
        onShowFocusHighlight: (val) {
          if (!isDisabled) setState(() => _isFocused = val);
        },
        child: GestureDetector(
          onTap: isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6), // Standard small radius: 6 or 8
              border: border,
              boxShadow: _isFocused && !isDisabled
                  ? [
                      BoxShadow(
                        color: colors.brandPrimary.withValues(alpha: 0.2),
                        blurRadius: 0,
                        spreadRadius: 2.5,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: 16),
                child: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      content = Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }

    return content;
  }
}
