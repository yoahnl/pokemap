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
    this.accentColor = const Color(0xFF4A90E2),
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
    final fill = Color.alphaBlend(
      accentColor.withValues(alpha: 0.08),
      EditorChrome.elevatedPanelBackground(context),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 3, 10, 11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: MacosIcon(icon, size: 17, color: accentColor),
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
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor.withValues(alpha: 0.92),
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
