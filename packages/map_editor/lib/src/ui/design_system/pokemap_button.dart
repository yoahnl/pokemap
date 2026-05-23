import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Available variants for PokeMap buttons, influencing backgrounds and borders.
enum PokeMapButtonVariant {
  /// Primary solid action button utilizing brand colors.
  primary,

  /// Secondary action button with a subtle background and border.
  secondary,

  /// Flat transparent button which highlights on hover.
  ghost,

  /// High-priority warning or destructive action button.
  danger,

  /// Validation or success confirmation button.
  success,
}

/// Preconfigured height and padding configurations for buttons.
enum PokeMapButtonSize {
  /// Compact height (32px) for crowded UI sections.
  small,

  /// Standard height (40px) for general forms and settings.
  medium,

  /// Large height (48px) for prominent shell actions.
  large,
}

/// A custom, highly polished PokeMap action button.
///
/// Designed to follow the PokeMap design language without relying on default Material
/// shape guidelines. Respects light/dark modes, shows loader loops when [isLoading] is active,
/// and handles states (hover, focus, disabled).
class PokeMapButton extends StatefulWidget {
  const PokeMapButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = PokeMapButtonVariant.primary,
    this.size = PokeMapButtonSize.medium,
    this.leading,
    this.trailing,
    this.isLoading = false,
  });

  /// Action callback. If null, the button is rendered in a disabled state.
  final VoidCallback? onPressed;

  /// Main label or custom widget hierarchy inside the button.
  final Widget child;

  /// Colors variant profile.
  final PokeMapButtonVariant variant;

  /// Button dimensions profile.
  final PokeMapButtonSize size;

  /// Optional prefix icon or widget.
  final Widget? leading;

  /// Optional suffix icon or widget.
  final Widget? trailing;

  /// If true, disables action calls and replaces the leading item with a loading spinner.
  final bool isLoading;

  @override
  State<PokeMapButton> createState() => _PokeMapButtonState();
}

class _PokeMapButtonState extends State<PokeMapButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    // Sizing attributes
    final double height;
    final double horizontalPadding;
    final double fontSize;
    final double iconSize;

    switch (widget.size) {
      case PokeMapButtonSize.small:
        height = 32;
        horizontalPadding = 12;
        fontSize = 12;
        iconSize = 14;
        break;
      case PokeMapButtonSize.medium:
        height = 40;
        horizontalPadding = 16;
        fontSize = 14;
        iconSize = 16;
        break;
      case PokeMapButtonSize.large:
        height = 48;
        horizontalPadding = 20;
        fontSize = 16;
        iconSize = 18;
        break;
    }

    // Core styling attributes
    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case PokeMapButtonVariant.primary:
        bg = _isHovered ? colors.brandPrimaryHover : colors.brandPrimary;
        fg = colors.textInverse;
        break;
      case PokeMapButtonVariant.secondary:
        bg = _isHovered ? colors.surfaceHover : colors.surfaceSubtle;
        fg = colors.textPrimary;
        border = Border.all(color: colors.borderSubtle, width: 1);
        break;
      case PokeMapButtonVariant.ghost:
        bg = _isHovered ? colors.surfaceHover : Colors.transparent;
        fg = colors.textPrimary;
        break;
      case PokeMapButtonVariant.danger:
        bg = _isHovered
            ? Color.lerp(colors.error, Colors.black, 0.08)!
            : colors.error;
        fg = colors.textInverse;
        break;
      case PokeMapButtonVariant.success:
        bg = _isHovered
            ? Color.lerp(colors.success, Colors.black, 0.08)!
            : colors.success;
        fg = colors.textInverse;
        break;
    }

    // Apply disabled values
    if (isDisabled) {
      bg = widget.variant == PokeMapButtonVariant.ghost
          ? Colors.transparent
          : bg.withValues(alpha: 0.5);
      fg = fg.withValues(alpha: 0.5);
      if (border != null) {
        border = Border.all(color: colors.borderSubtle.withValues(alpha: 0.3), width: 1);
      }
    }

    return Semantics(
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
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8), // standard border radius: 8
              border: border,
              boxShadow: _isFocused && !isDisabled
                  ? [
                      BoxShadow(
                        color: colors.brandPrimary.withValues(alpha: 0.24),
                        blurRadius: 0,
                        spreadRadius: 3,
                      )
                    ]
                  : null,
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  if (widget.leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: fg, size: iconSize),
                      child: widget.leading!,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
                Flexible(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: fg,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    child: widget.child,
                  ),
                ),
                if (widget.trailing != null && !widget.isLoading) ...[
                  const SizedBox(width: 8),
                  IconTheme.merge(
                    data: IconThemeData(color: fg, size: iconSize),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
