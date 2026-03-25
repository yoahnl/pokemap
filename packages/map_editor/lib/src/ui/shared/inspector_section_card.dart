import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'cupertino_editor_widgets.dart';

class InspectorSectionCard extends StatelessWidget {
  const InspectorSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    required this.expandedHeight,
    this.subtitle,
    this.badgeText,
    this.accentColor = EditorChrome.accentPrimary,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final double expandedHeight;
  final String? badgeText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final badgeText = this.badgeText?.trim();
    final hasBadge = badgeText != null && badgeText.isNotEmpty;
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final baseHi = EditorChrome.islandFillElevated(context);
    final baseLo = EditorChrome.islandFill(context);
    final fillTop = Color.lerp(baseHi, accentColor, 0.14)!;
    final fillBottom = Color.lerp(baseLo, accentColor, 0.055)!;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 3, 10, 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              fillTop,
              fillBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              minimumSize: Size.zero,
              onPressed: onToggle,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(baseHi, accentColor, 0.34)!,
                          Color.lerp(baseLo, accentColor, 0.16)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: MacosIcon(icon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: label,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (subtitle != null &&
                            subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: subtle,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(baseHi, accentColor, 0.2)!,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  MacosIcon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 18,
                    color: subtle,
                  ),
                ],
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  height: expandedHeight,
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
