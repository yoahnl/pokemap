import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'pokemap_badge.dart';

/// A sleek, compact card specifically for left Project Explorer sidebar modules.
///
/// Follows the premium dark design system theme of PokeMap:
/// - Highlights borders/backgrounds on hover and active selection.
/// - Renders business/accent icons inside a soft background container.
/// - Supports collapsible [child] or [children] for tree rendering.
class ProjectExplorerModuleCard extends StatefulWidget {
  const ProjectExplorerModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.count,
    this.countLabel,
    this.selected = false,
    this.expanded = false,
    this.trailing,
    this.onTap,
    this.onExpandToggle,
    this.expandedHeight,
    this.child,
    this.children = const [],
    this.borderRadius = 12,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int? count;
  final String? countLabel;
  final bool selected;
  final bool expanded;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final double? expandedHeight;
  final Widget? child;
  final List<Widget> children;
  final double borderRadius;

  @override
  State<ProjectExplorerModuleCard> createState() => _ProjectExplorerModuleCardState();
}

class _ProjectExplorerModuleCardState extends State<ProjectExplorerModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    // In dark mode, surfaceBase is very dark blue. We want a more marked gradient
    // blending the accentColor on the top-left, fading down to a very subtle accent blend at the bottom-right.
    final Color fillTop = widget.selected
        ? Color.lerp(colors.surfaceSelected, widget.accentColor, 0.42)!
        : (_hovered
            ? Color.lerp(colors.surfaceHover, widget.accentColor, 0.32)!
            : Color.lerp(colors.surfaceBase, widget.accentColor, 0.24)!);

    final Color fillBottom = widget.selected
        ? Color.lerp(colors.surfaceSelected, widget.accentColor, 0.08)!
        : (_hovered
            ? Color.lerp(colors.surfaceHover, widget.accentColor, 0.04)!
            : Color.lerp(colors.surfaceSubtle, widget.accentColor, 0.02)!);

    // Each module card gets a color-tinted border that matches its own accentColor,
    // bringing a distinct premium identity to each section and highlighting selection/hover states.
    final Color borderColor = widget.selected
        ? widget.accentColor.withValues(alpha: 0.85)
        : (_hovered
            ? widget.accentColor.withValues(alpha: 0.50)
            : widget.accentColor.withValues(alpha: 0.22));

    final bool hasExpandToggle = widget.onExpandToggle != null && (widget.child != null || widget.children.isNotEmpty);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 3, 10, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [fillTop, fillBottom],
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap ?? widget.onExpandToggle,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() => _hovered = false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        // Colored Prefix Icon Box
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.3),
                              width: 1.25,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            widget.icon,
                            size: 16,
                            color: widget.accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title & Subtitle/Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trailing actions (e.g. plus button, import folder button)
                        if (widget.trailing != null) ...[
                          widget.trailing!,
                          const SizedBox(width: 6),
                        ],

                        // Count Badge
                        if (widget.countLabel != null || widget.count != null) ...[
                          PokeMapBadge(
                            label: widget.countLabel ?? '${widget.count}',
                            variant: PokeMapBadgeVariant.neutral,
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Expand/Collapse Chevron
                        if (hasExpandToggle)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onExpandToggle,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                widget.expanded
                                    ? CupertinoIcons.chevron_up
                                    : CupertinoIcons.chevron_down,
                                size: 14,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Expanded content
            if (widget.expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: widget.expandedHeight != null
                    ? SizedBox(
                        height: widget.expandedHeight,
                        child: widget.child ?? Column(children: widget.children),
                      )
                    : (widget.child ?? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.children,
                      )),
              ),
          ],
        ),
      ),
    );
  }
}
