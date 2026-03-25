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
    /// Boutons ou actions entre le titre et le badge (n’ouvrent pas / ne ferment pas la section).
    this.headerTrailing,
    /// Rayon des coins ; défaut 20 (inspecteur), ~28 pour tuiles type « pilule ».
    this.borderRadius = 20,
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

  static const Color _iconHi = Color(0xFFFFFFFF);
  static const Color _iconLo = Color(0xFF120808);

  @override
  Widget build(BuildContext context) {
    final badgeText = this.badgeText?.trim();
    final hasBadge = badgeText != null && badgeText.isNotEmpty;
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final baseHi = EditorChrome.islandFillElevated(context);
    final baseLo = EditorChrome.islandFill(context);

    final fillTop = Color.lerp(baseHi, accentColor, 0.46)!;
    final fillBottom = Color.lerp(baseLo, accentColor, 0.32)!;

    final iconTop = Color.lerp(_iconHi, accentColor, 0.88)!;
    final iconBottom = Color.lerp(accentColor, _iconLo, 0.42)!;

    final subtitleTinted = Color.lerp(subtle, accentColor, 0.45)!;

    final iconOnAccent = _luminance(accentColor) > 0.62
        ? const Color(0xFF1A0A08)
        : CupertinoColors.white;

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
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.65),
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
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                iconTop,
                                iconBottom,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.85),
                              width: 1.25,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: MacosIcon(
                            icon,
                            size: 19,
                            color: iconOnAccent,
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
                                  maxLines: 2,
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
                      ],
                    ),
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
                if (hasBadge) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color.lerp(accentColor, _iconLo, 0.28)!,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.9),
                        width: 1,
                      ),
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
                CupertinoButton(
                  padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                  minimumSize: Size.zero,
                  onPressed: onToggle,
                  child: MacosIcon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 18,
                    color: subtitleTinted,
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

  /// Luminance relative 0–1 (sRGB), pour choisir icône claire ou foncée.
  static double _luminance(Color c) {
    final r = c.r;
    final g = c.g;
    final b = c.b;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}
