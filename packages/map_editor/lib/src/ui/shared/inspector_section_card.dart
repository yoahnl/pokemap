import 'package:flutter/cupertino.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

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
    /// Boutons ou actions entre le titre et le badge (n’ouvrent pas / ne ferment pas la section).
    this.headerTrailing,
    /// Rayon des coins ; défaut 12 (inspecteur).
    this.borderRadius = 12,
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
  final Widget? headerTrailing;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final badgeText = this.badgeText?.trim();
    final hasBadge = badgeText != null && badgeText.isNotEmpty;

    // Smooth soft tint using accent color mixed with design system neutrals
    final fillBg = expanded ? colors.surfaceBase : colors.surfaceSubtle;
    final subtitleColor = colors.textMuted;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 3, 10, 11),
        decoration: BoxDecoration(
          color: fillBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    minimumSize: Size.zero,
                    onPressed: onToggle,
                    child: Row(
                      children: [
                        // Colored prefix icon box
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color.lerp(colors.surfaceSubtle, accentColor, 0.12)!,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color.lerp(colors.borderSubtle, accentColor, 0.25)!,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 16,
                            color: Color.lerp(colors.textSecondary, accentColor, 0.6)!,
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
                                  color: colors.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              if (subtitle != null &&
                                  subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
                if (hasBadge) ...[
                  PokeMapBadge(
                    label: badgeText,
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                  const SizedBox(width: 10),
                ],
                CupertinoButton(
                  padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                  minimumSize: Size.zero,
                  onPressed: onToggle,
                  child: Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 18,
                    color: subtitleColor,
                  ),
                ),
              ],
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
