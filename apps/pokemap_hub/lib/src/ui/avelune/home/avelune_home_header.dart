import 'package:flutter/material.dart';

import '../assets/avelune_material_catalog.dart';
import '../avelune_theme.dart';

/// Branded header of the console home: logo mark, wordmark and the profile
/// affordance the approved prototype shows in the top-right corner.
///
/// The profile avatar is deliberately decorative. AVELUNE-510 bars duplicating
/// Paramètres behind it, and no local profile exists to open yet, so painting a
/// live-looking control that does nothing would be worse than painting none.
/// It is excluded from semantics until a real profile surface exists.
class AveluneHomeHeader extends StatelessWidget {
  const AveluneHomeHeader({
    super.key,
    this.productName = 'Avelune',
    this.compact = false,
  });

  /// Injected product identity. Rendered as the wordmark, so a differently
  /// branded build shows its own name rather than a hardcoded one.
  final String productName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final markSize = compact ? 32.0 : 38.0;

    return Padding(
      key: const ValueKey<String>('avelune-home-header'),
      padding: EdgeInsets.symmetric(
        horizontal: AveluneSpacing.lg,
        vertical: compact ? AveluneSpacing.xxs : AveluneSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            image: true,
            label: productName,
            child: SizedBox.square(
              dimension: markSize,
              child: Image.asset(
                AveluneMaterialCatalog.logo.path,
                key: const ValueKey<String>('avelune-home-header-mark'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.nightlight_round,
                  color: colors.primaryBright,
                  size: markSize * 0.78,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? AveluneSpacing.sm : AveluneSpacing.md),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                productName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: compact ? 17 : 19,
                  fontWeight: FontWeight.w300,
                  letterSpacing: compact ? 4.4 : 5.6,
                  height: 1,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Container(
              width: markSize,
              height: markSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceRaised.withValues(alpha: 0.72),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.72),
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: markSize * 0.52,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
