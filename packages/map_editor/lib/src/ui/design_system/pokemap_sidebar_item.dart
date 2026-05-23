import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A polished, custom list item designed for the editor navigation sidebar.
///
/// Handles hover, active selection, focus, and disabled states. Renders an optional
/// leading [icon], a text [label], and an optional [trailing] widget (such as badges,
/// state checkmarks, or menu options). Consumes the design system's theme color tokens.
class PokeMapSidebarItem extends StatefulWidget {
  const PokeMapSidebarItem({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  /// The primary item label.
  final String label;

  /// Optional prefix icon or graphic widget.
  final Widget? icon;

  /// Optional suffix widget (e.g. status dot, badge, or chevron).
  final Widget? trailing;

  /// If true, highlights the item as the current active page/selection.
  final bool selected;

  /// If true, disables clicks and grey-outs visual components.
  final bool disabled;

  /// Triggered when the sidebar item is tapped.
  final VoidCallback? onTap;

  @override
  State<PokeMapSidebarItem> createState() => _PokeMapSidebarItemState();
}

class _PokeMapSidebarItemState extends State<PokeMapSidebarItem> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isActive = widget.selected;
    final isDisabled = widget.disabled || widget.onTap == null;

    // Visual attributes resolution
    Color bg = Colors.transparent;
    Color fg = colors.textSecondary;

    if (isDisabled) {
      fg = colors.textDisabled;
    } else if (isActive) {
      bg = colors.surfaceSelected;
      fg = colors.brandPrimary;
    } else if (_isHovered) {
      bg = colors.surfaceHover;
      fg = colors.textPrimary;
    }

    return FocusableActionDetector(
      onShowHoverHighlight: (val) {
        if (!isDisabled) setState(() => _isHovered = val);
      },
      onShowFocusHighlight: (val) {
        if (!isDisabled) setState(() => _isFocused = val);
      },
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8), // Standard radius: 8
              border: _isFocused && !isDisabled
                  ? Border.all(color: colors.brandPrimaryBorder, width: 1.2)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      color: fg,
                      size: 16,
                    ),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                      child: widget.trailing!,
                    ),
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
