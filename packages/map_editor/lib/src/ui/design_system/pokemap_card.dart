import 'package:flutter/material.dart';
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
    this.selected = false,
    this.onTap,
  });

  /// Main content within the card.
  final Widget child;

  /// Custom padding inside the card. Defaults to 12.
  final EdgeInsetsGeometry? padding;

  /// If true, applies high-contrast primary selection borders.
  final bool selected;

  /// Optional card tap callback. If provided, renders hover cursors and background transitions.
  final VoidCallback? onTap;

  @override
  State<PokeMapCard> createState() => _PokeMapCardState();
}

class _PokeMapCardState extends State<PokeMapCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBg = isDark ? colors.cardSurface : colors.surfaceBase;
    final bg = (widget.onTap != null && _isHovered) ? colors.cardHover : baseBg;

    final border = Border.all(
      color: widget.selected
          ? colors.brandPrimaryBorder
          : (_isHovered && widget.onTap != null
              ? colors.controlBorder
              : colors.borderSubtle),
      width: 1.2,
    );

    Widget content = Padding(
      padding: widget.padding ?? const EdgeInsets.all(12),
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12), // Standard card radius: 12
        border: border,
      ),
      child: content,
    );
  }
}
