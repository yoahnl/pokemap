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
    this.subtitle,
    this.icon,
    this.trailing,
    this.compact = false,
    this.collapsed = false,
    this.growForTextScale = false,
    this.selected = false,
    this.disabled = false,
    this.onTap,
    this.focusNode,
  });

  /// The primary item label.
  final String label;

  /// Optional secondary line shown under [label].
  final String? subtitle;

  /// Optional prefix icon or graphic widget.
  final Widget? icon;

  /// Optional suffix widget (e.g. status dot, badge, or chevron).
  final Widget? trailing;

  /// Uses the denser row budget required by long desktop authoring lists.
  ///
  /// Navigation keeps the established dimensions by default. Feature screens
  /// opt in explicitly so the design-system primitive still owns spacing,
  /// typography and focus treatment instead of duplicating a local row.
  final bool compact;

  /// Shows an icon-only navigation row while preserving its accessible label.
  ///
  /// The label, subtitle and trailing widgets are deliberately not laid out in
  /// this mode; the tooltip and semantics remain the source of truth.
  final bool collapsed;

  /// Keeps the established row height as a minimum while allowing scaled
  /// labels and subtitles to request the vertical space they need.
  final bool growForTextScale;

  /// If true, highlights the item as the current active page/selection.
  final bool selected;

  /// If true, disables clicks and grey-outs visual components.
  final bool disabled;

  /// Triggered when the sidebar item is tapped.
  final VoidCallback? onTap;

  /// Optional external focus anchor for reversible workspace navigation.
  final FocusNode? focusNode;

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
    final horizontalPadding = widget.collapsed
        ? 0.0
        : widget.compact
            ? 8.0
            : 12.0;
    final iconGap = widget.compact ? 7.0 : 10.0;
    final trailingGap = widget.compact ? 5.0 : 8.0;
    final labelSize = widget.compact ? 11.0 : 13.0;
    final itemHeight = widget.subtitle == null
        ? (widget.compact ? 34.0 : 38.0)
        : (widget.compact ? 42.0 : 46.0);

    // Visual attributes resolution
    Color? bg;
    Color fg = colors.textSecondary;

    if (isDisabled) {
      fg = colors.textDisabled;
    } else if (isActive) {
      bg = colors.cardSelected;
      fg = colors.brandPrimary;
    } else if (_isHovered) {
      bg = colors.cardHover;
      fg = colors.textPrimary;
    }

    final item = Semantics(
      label: widget.collapsed ? widget.label : null,
      excludeSemantics: widget.collapsed,
      button: true,
      selected: isActive,
      enabled: !isDisabled,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (!isDisabled) {
                widget.onTap?.call();
              }
              return null;
            },
          ),
        },
        onShowHoverHighlight: (val) {
          if (!isDisabled) setState(() => _isHovered = val);
        },
        onFocusChange: (value) {
          if (!isDisabled) setState(() => _isFocused = value);
        },
        child: GestureDetector(
          onTap: isDisabled ? null : widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: isDisabled
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 100),
              height: widget.growForTextScale ? null : itemHeight,
              constraints: widget.growForTextScale
                  ? BoxConstraints(minHeight: itemHeight)
                  : null,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8), // Standard radius: 8
                border: _isFocused && !isDisabled
                    ? Border.all(
                        color: colors.focusRing,
                        width: MediaQuery.highContrastOf(context) ? 2.0 : 1.2,
                      )
                    : null,
              ),
              child: widget.collapsed
                  ? Center(
                      child: widget.icon == null
                          ? const SizedBox.shrink()
                          : IconTheme.merge(
                              data: IconThemeData(color: fg, size: 16),
                              child: widget.icon!,
                            ),
                    )
                  : Row(
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
                          SizedBox(width: iconGap),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: labelSize,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isActive
                                        ? colors.brandPrimary
                                        : colors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          SizedBox(width: trailingGap),
                          if (widget.compact)
                            Opacity(
                              opacity: isDisabled ? 0.4 : 1.0,
                              child: DefaultTextStyle.merge(
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                ),
                                child: widget.trailing!,
                              ),
                            )
                          else
                            Flexible(
                              child: Opacity(
                                opacity: isDisabled ? 0.4 : 1.0,
                                child: DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  child: widget.trailing!,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    // A tooltip keeps pointer discovery available even though collapsed mode
    // intentionally removes all visible text from the rail.
    return widget.collapsed
        ? Tooltip(message: widget.label, child: item)
        : item;
  }
}
