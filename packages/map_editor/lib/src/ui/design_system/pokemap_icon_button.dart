import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.size = 32.0,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.disabledReason,
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

  /// Custom size for the button width/height.
  final double size;

  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final String? disabledReason;

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
            ? colors.cardSelected
            : (_isHovered
                ? colors.cardHover
                : colors.controlSurface.withValues(alpha: 0));
        fg = widget.isSelected ? colors.brandPrimary : colors.textSecondary;
        break;
      case PokeMapIconButtonVariant.soft:
        if (widget.isSelected) {
          bg = colors.cardSelected;
          border = Border.all(color: colors.brandPrimaryBorder, width: 1);
          fg = colors.brandPrimary;
        } else {
          bg = _isHovered ? colors.cardHover : colors.controlSurface;
          border = Border.all(color: colors.borderSubtle, width: 1);
          fg = colors.textPrimary;
        }
        break;
      case PokeMapIconButtonVariant.danger:
        bg = _isHovered
            ? colors.errorSoft
            : colors.controlSurface.withValues(alpha: 0);
        fg = colors.error;
        break;
    }

    if (isDisabled) {
      bg = colors.controlSurface.withValues(alpha: 0);
      fg = fg.withValues(alpha: 0.35);
      if (border != null) {
        border = Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.3), width: 1);
      }
    }

    void activate() {
      if (isDisabled) return;
      widget.focusNode?.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      widget.onPressed?.call();
    }

    final disabledReason = widget.disabledReason?.trim();
    final accessibleName = (widget.semanticLabel?.trim().isNotEmpty ?? false)
        ? widget.semanticLabel!.trim()
        : widget.tooltip?.trim();
    final semanticLabel = isDisabled &&
            disabledReason != null &&
            disabledReason.isNotEmpty &&
            accessibleName != null &&
            accessibleName.isNotEmpty
        ? '$accessibleName. Désactivé. $disabledReason'
        : accessibleName;
    Widget content = Semantics(
      button: true,
      enabled: !isDisabled,
      selected: widget.isSelected,
      label: semanticLabel,
      hint: semanticLabel == null && isDisabled ? disabledReason : null,
      excludeSemantics: true,
      onTap: isDisabled ? null : activate,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: !isDisabled,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              activate();
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
          behavior: HitTestBehavior.opaque,
          onTap: isDisabled ? null : activate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(
                  widget.size >= 32 ? 6 : 4), // Standard small radius
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

    final tooltip =
        isDisabled && disabledReason != null && disabledReason.isNotEmpty
            ? disabledReason
            : widget.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      content = Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: content,
      );
    }

    return content;
  }
}
