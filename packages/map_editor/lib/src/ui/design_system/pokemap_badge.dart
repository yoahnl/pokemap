import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Available variants for PokeMap badges/tags.
enum PokeMapBadgeVariant {
  /// Default neutral grey tag.
  neutral,

  /// Blue information label.
  info,

  /// Green confirmation label.
  success,

  /// Yellow warning label.
  warning,

  /// Red error or system alert label.
  error,

  /// Purple narrative step tag.
  narrative,

  /// Pink/Red combat action tag.
  combat,

  /// Light/Dark green Map Editor context tag. Uses colors.mapAccent.
  mapAccent,
}

/// A compact, read-only tag/badge used to label states, types, or categories.
///
/// Automatically retrieves appropriate colors based on the requested [variant].
/// Respects light/dark modes and maps [PokeMapBadgeVariant.mapAccent] directly to the
/// design system's [mapAccent] color token.
class PokeMapBadge extends StatelessWidget {
  const PokeMapBadge({
    super.key,
    required this.label,
    this.variant = PokeMapBadgeVariant.neutral,
    this.icon,
  });

  /// The text string shown on the badge.
  final String label;

  /// Semantic styling variant profile.
  final PokeMapBadgeVariant variant;

  /// Optional prefix icon shown before the label text.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    Color bg;
    Color fg;
    Border border;

    switch (variant) {
      case PokeMapBadgeVariant.neutral:
        bg = colors.surfaceSubtle;
        border = Border.all(color: colors.borderSubtle, width: 1);
        fg = colors.textSecondary;
        break;
      case PokeMapBadgeVariant.info:
        bg = colors.infoSoft;
        border =
            Border.all(color: colors.info.withValues(alpha: 0.28), width: 1);
        fg = colors.info;
        break;
      case PokeMapBadgeVariant.success:
        bg = colors.successSoft;
        border = Border.all(color: colors.successBorder, width: 1);
        fg = colors.success;
        break;
      case PokeMapBadgeVariant.warning:
        bg = colors.warningSoft;
        border = Border.all(color: colors.warningBorder, width: 1);
        fg = colors.warning;
        break;
      case PokeMapBadgeVariant.error:
        bg = colors.errorSoft;
        border = Border.all(color: colors.errorBorder, width: 1);
        fg = colors.error;
        break;
      case PokeMapBadgeVariant.narrative:
        bg = colors.narrativeSoft;
        border = Border.all(
            color: colors.narrative.withValues(alpha: 0.28), width: 1);
        fg = colors.narrative;
        break;
      case PokeMapBadgeVariant.combat:
        bg = colors.errorSoft;
        border =
            Border.all(color: colors.combat.withValues(alpha: 0.28), width: 1);
        fg = colors.combat;
        break;
      case PokeMapBadgeVariant.mapAccent:
        bg = colors.successSoft;
        border = Border.all(
            color: colors.mapAccent.withValues(alpha: 0.28), width: 1);
        fg = colors.mapAccent;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100), // Capsule look
        border: border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: fg, size: 12),
                child: icon!,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
