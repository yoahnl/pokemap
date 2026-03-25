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

  /// Blanc cassé chaud pour les pastilles d’icônes.
  static const Color _iconWellHi = Color(0xFFFFF4EB);
  static const Color _warmLift = Color(0xFFFFE8CC);

  @override
  Widget build(BuildContext context) {
    final badgeText = this.badgeText?.trim();
    final hasBadge = badgeText != null && badgeText.isNotEmpty;
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final baseHi = EditorChrome.islandFillElevated(context);
    final baseLo = EditorChrome.islandFill(context);

    final fillTop = Color.lerp(baseHi, accentColor, 0.34)!;
    final fillMid = Color.lerp(
      Color.lerp(baseHi, accentColor, 0.24)!,
      _warmLift,
      0.14,
    )!;
    final fillBottom = Color.lerp(baseLo, accentColor, 0.15)!;

    final iconWellTop = Color.lerp(_iconWellHi, accentColor, 0.78)!;
    final iconWellBottom =
        Color.lerp(accentColor, const Color(0xFF4A2820), 0.38)!;

    final subtitleTinted =
        Color.lerp(subtle, accentColor, 0.32)!.withValues(alpha: 0.96);

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
              fillMid,
              fillBottom,
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            ...EditorChrome.sectionCardShadows(context),
            BoxShadow(
              color: EditorChrome.inspectorJoyApricot.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconWellTop,
                          iconWellBottom,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: MacosIcon(
                      icon,
                      size: 19,
                      color: CupertinoColors.white,
                    ),
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
                              color: subtitleTinted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(accentColor, CupertinoColors.white, 0.5)!,
                            Color.lerp(
                              accentColor,
                              const Color(0xFF5A3028),
                              0.18,
                            )!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: CupertinoColors.white,
                          letterSpacing: 0.2,
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
                    color: Color.lerp(subtle, accentColor, 0.35)!,
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
