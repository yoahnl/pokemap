import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

/// A customizable, styled container for PokeMap sections and settings.
///
/// Automatically resolves background colors based on active theme brightness
/// ([surfaceBase] for light mode, [surfaceRaised] for dark mode) to follow PokeMap aesthetics.
/// Highlights borders on selection and supports hover highlights if [onTap] is provided.
class PokeMapCard extends StatefulWidget {
  const PokeMapCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.focused = false,
    this.selected = false,
    this.onTap,
    this.backgroundColor,
    this.keyboardInteractive = false,
    this.semanticLabel,
  });

  /// Main content within the card.
  final Widget child;

  /// Custom padding inside the card. Defaults to 12.
  final EdgeInsetsGeometry? padding;

  final double borderRadius;

  final bool focused;

  /// If true, applies high-contrast primary selection borders.
  final bool selected;

  /// Optional card tap callback. If provided, renders hover cursors and background transitions.
  final VoidCallback? onTap;

  /// Optional explicit background color override.
  /// When provided, overrides the automatic theme-based surface color.
  final Color? backgroundColor;

  final bool keyboardInteractive;

  final String? semanticLabel;

  @override
  State<PokeMapCard> createState() => _PokeMapCardState();
}

class _PokeMapCardState extends State<PokeMapCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PokeMapCard');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBg =
        widget.backgroundColor ??
        (isDark ? colors.cardSurface : colors.surfaceBase);
    final bg = (widget.onTap != null && _isHovered) ? colors.cardHover : baseBg;

    final focused = widget.focused || _isFocused;
    final border = Border.all(
      color: widget.selected
          ? colors.brandPrimaryBorder
          : (focused
                ? colors.brandPrimaryBorder
                : (_isHovered && widget.onTap != null
                      ? colors.controlBorder
                      : colors.borderSubtle)),
      width: focused ? 1.8 : 1.2,
    );

    Widget content = Padding(
      padding: widget.padding ?? const EdgeInsets.all(12),
      child: widget.child,
    );

    if (widget.onTap != null) {
      Widget interactiveContent = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (widget.keyboardInteractive) {
              _focusNode.requestFocus();
            }
            widget.onTap!();
          },
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
      if (widget.keyboardInteractive) {
        interactiveContent = Semantics(
          button: true,
          selected: widget.selected,
          label: widget.semanticLabel,
          child: FocusableActionDetector(
            focusNode: _focusNode,
            onShowFocusHighlight: (focused) {
              if (_isFocused != focused) {
                setState(() => _isFocused = focused);
              }
            },
            shortcuts: <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onTap!();
                  return null;
                },
              ),
            },
            child: interactiveContent,
          ),
        );
      }
      content = interactiveContent;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: border,
      ),
      child: content,
    );
  }
}
