import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

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
    final cardFill =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final subtle = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        decoration: BoxDecoration(
          color: cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              minimumSize: Size.zero,
              onPressed: onToggle,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.34),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: MacosIcon(icon, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: label,
                          ),
                        ),
                        if (subtitle != null &&
                            subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: subtle,
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.quaternarySystemFill
                            .resolveFrom(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
              Container(
                height: 1,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            if (expanded)
              SizedBox(
                height: expandedHeight,
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
